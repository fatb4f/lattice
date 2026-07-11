"""Deterministic graph-derived routing over a validated full-index envelope."""

from __future__ import annotations

import re
import uuid
from collections.abc import Mapping
from typing import Any, Literal

from lattice.adapters.full_index import load_full_index_envelope

from .provenance import sha256_digest

GRAPH_ROUTE_SCHEMA = "lattice.graph-route-packet.v1"
GRAPH_ROUTING_POLICY_SCHEMA = "lattice.graph-routing-policy.v1"

Route = Literal["inspect", "retrieve", "diagnostics"]
TOKEN = re.compile(r"[a-z0-9][a-z0-9_.:/-]*")


def route_for_intent(intent: str) -> Route:
    routes: dict[str, Route] = {"inspect": "inspect", "retrieve": "retrieve", "diagnostics": "diagnostics"}
    try:
        return routes[intent]
    except KeyError as exc:
        raise ValueError(f"unsupported runtime intent: {intent}") from exc


def _terms(value: Any) -> set[str]:
    if isinstance(value, str):
        return set(TOKEN.findall(value.casefold()))
    if isinstance(value, Mapping):
        return set().union(*(_terms(key) | _terms(item) for key, item in value.items())) if value else set()
    if isinstance(value, list):
        return set().union(*(_terms(item) for item in value)) if value else set()
    return set()


def _request_id(query: str, provenance: Mapping[str, Any], policy: Mapping[str, Any]) -> str:
    digest = sha256_digest({"query": query, "index": provenance, "policy": policy})
    return str(uuid.uuid5(uuid.NAMESPACE_URL, digest))


def routing_policy_with_budgets(
    policy: Mapping[str, Any],
    *,
    max_candidates: int | None = None,
    max_entities: int | None = None,
    max_resources: int | None = None,
) -> dict[str, Any]:
    """Return a policy copy with bounded execution budgets, preserving CUE-owned rules."""
    normalized = _validate_routing_policy(policy)
    budgets = dict(normalized["budgets"])
    requested = {
        "maxCandidates": max_candidates,
        "maxEntities": max_entities,
        "maxResources": max_resources,
    }
    for field, value in requested.items():
        if value is not None:
            budgets[field] = value
    normalized["budgets"] = budgets
    return _validate_routing_policy(normalized)


def _validate_routing_policy(policy: Mapping[str, Any]) -> dict[str, Any]:
    value = dict(policy)
    required = {
        "schema",
        "version",
        "weights",
        "allowedMetadataFields",
        "relationDistance",
        "candidatePolicy",
        "ceilings",
        "budgets",
    }
    if set(value) != required or value.get("schema") != GRAPH_ROUTING_POLICY_SCHEMA:
        raise ValueError("unsupported or incomplete graph routing policy")
    if not isinstance(value.get("version"), str) or not value["version"]:
        raise ValueError("graph routing policy version is invalid")
    weights = value.get("weights")
    fields = {"id", "type", "tags", "path", "owner", "metadata"}
    if not isinstance(weights, Mapping) or set(weights) != fields:
        raise ValueError("graph routing policy weights are invalid")
    if any(isinstance(item, bool) or not isinstance(item, int) or item < 0 for item in weights.values()):
        raise ValueError("graph routing policy weights must be non-negative integers")
    metadata_fields = value.get("allowedMetadataFields")
    if (
        not isinstance(metadata_fields, list)
        or not metadata_fields
        or any(not isinstance(item, str) or not item for item in metadata_fields)
        or len(metadata_fields) != len(set(metadata_fields))
    ):
        raise ValueError("graph routing allowed metadata fields are invalid")
    relation = value.get("relationDistance")
    if not isinstance(relation, Mapping) or set(relation) != {
        "maxDepth",
        "numerator",
        "denominator",
        "minimumScore",
        "direction",
        "propagationMode",
    }:
        raise ValueError("graph routing relation-distance policy is invalid")
    numeric_relation = (relation["maxDepth"], relation["numerator"], relation["denominator"], relation["minimumScore"])
    if any(isinstance(item, bool) or not isinstance(item, int) or item < 0 for item in numeric_relation):
        raise ValueError("graph routing relation-distance values must be non-negative integers")
    if (
        relation["denominator"] < 1
        or relation["direction"] != "undirected"
        or relation["propagationMode"] != "direct-match-only"
    ):
        raise ValueError("unsupported graph routing relation-distance behavior")
    candidates = value.get("candidatePolicy")
    if candidates != {
        "includeWhen": "positive-score",
        "tieBreak": "score-descending-id-ascending",
    }:
        raise ValueError("unsupported graph routing candidate policy")
    ceilings = value.get("ceilings")
    budgets = value.get("budgets")
    budget_fields = {"maxCandidates", "maxEntities", "maxResources"}
    if not isinstance(ceilings, Mapping) or set(ceilings) != budget_fields:
        raise ValueError("graph routing policy ceilings are invalid")
    if not isinstance(budgets, Mapping) or set(budgets) != budget_fields:
        raise ValueError("graph routing policy budgets are invalid")
    for field in budget_fields:
        ceiling = ceilings[field]
        budget = budgets[field]
        if (
            isinstance(ceiling, bool)
            or not isinstance(ceiling, int)
            or ceiling < 0
            or isinstance(budget, bool)
            or not isinstance(budget, int)
            or budget < 0
            or budget > ceiling
        ):
            raise ValueError(f"graph routing policy {field} exceeds its CUE-exported ceiling")
    return value


def derive_route_packet(
    query: str,
    envelope: Mapping[str, Any],
    policy: Mapping[str, Any],
    *,
    request_id: str | None = None,
) -> dict[str, Any]:
    """Rank graph nodes and explain every inclusion, exclusion, and down-rank."""
    if not isinstance(query, str) or not query.strip():
        raise ValueError("query must be a non-empty string")
    index = load_full_index_envelope(envelope)
    declared = _validate_routing_policy(policy)
    budgets = declared["budgets"]
    max_candidates = budgets["maxCandidates"]
    max_entities = budgets["maxEntities"]
    max_resources = budgets["maxResources"]
    query_terms = _terms(query)
    entities = index["graph"]["entities"]
    relations = index["graph"]["relations"]
    direct: dict[str, int] = {}
    reasons: dict[str, list[dict[str, Any]]] = {}
    for entity_id, record in sorted(entities.items()):
        value = record["value"]
        metadata = {field: value.get(field) for field in declared["allowedMetadataFields"] if field in value}
        fields = {
            "id": _terms(entity_id),
            "type": _terms(value.get("@type", "")) | _terms(record["collection"]),
            "tags": _terms(value.get("tags", [])),
            "path": _terms(value.get("path", "")) | _terms(value.get("repository_path", "")),
            "owner": _terms(value.get("owner", "")) | _terms(value.get("ownership", "")),
            "metadata": _terms(metadata),
        }
        weights = declared["weights"]
        score = 0
        entity_reasons: list[dict[str, Any]] = []
        for field, terms in fields.items():
            matched = sorted(query_terms & terms)
            if matched:
                contribution = weights[field] * len(matched)
                score += contribution
                entity_reasons.append({"kind": field, "terms": matched, "score": contribution})
        direct[entity_id] = score
        reasons[entity_id] = entity_reasons
    relation_policy = declared["relationDistance"]
    direct_matches = {entity_id: score for entity_id, score in direct.items() if score > 0}
    adjacency: dict[str, set[str]] = {entity_id: set() for entity_id in entities}
    for relation in relations:
        adjacency[relation["source"]].add(relation["target"])
        adjacency[relation["target"]].add(relation["source"])
    for source, source_score in sorted(direct_matches.items()):
        visited = {source}
        frontier = {source}
        for distance in range(1, relation_policy["maxDepth"] + 1):
            next_frontier = set().union(*(adjacency[item] for item in frontier)) - visited if frontier else set()
            visited |= next_frontier
            frontier = next_frontier
            propagated = source_score
            for _ in range(distance):
                propagated = propagated * relation_policy["numerator"] // relation_policy["denominator"]
            propagated = max(relation_policy["minimumScore"], propagated)
            for target in sorted(frontier):
                if target in direct_matches or propagated <= direct[target]:
                    continue
                direct[target] = propagated
                reasons[target] = [
                    {"kind": "relation-distance", "from": source, "distance": distance, "score": propagated}
                ]
    ranked = sorted(entities, key=lambda entity_id: (-direct[entity_id], entity_id))
    explanations: list[dict[str, Any]] = []
    selected: list[str] = []
    for rank, entity_id in enumerate(ranked[:max_candidates], 1):
        score = direct[entity_id]
        included = score > 0 and len(selected) < max_entities
        disposition = "included" if included else ("down-ranked" if score > 0 else "excluded")
        if included:
            selected.append(entity_id)
        explanations.append(
            {
                "entityId": entity_id,
                "rank": rank,
                "score": score,
                "disposition": disposition,
                "reasons": reasons[entity_id] or [{"kind": "no-query-match", "score": 0}],
            }
        )
    resources = [f"kg://entity/{entity_id}" for entity_id in selected[:max_resources]]
    packet: dict[str, Any] = {
        "schema": GRAPH_ROUTE_SCHEMA,
        "requestId": request_id or _request_id(query, index["provenance"], declared),
        "query": query,
        "route": "graph-derived",
        "index": {"schema": index["schema"], **index["provenance"]},
        "policy": declared,
        "policyDigest": sha256_digest(declared),
        "selection": {"entities": selected, "resources": resources},
        "candidates": explanations,
    }
    return {**packet, "packetDigest": sha256_digest(packet)}


def validate_graph_route_packet(packet: Mapping[str, Any], envelope: Mapping[str, Any] | None = None) -> dict[str, Any]:
    """Verify the closed graph-route contract and every integrity binding."""
    value = dict(packet)
    required = {
        "schema",
        "requestId",
        "query",
        "route",
        "index",
        "policy",
        "policyDigest",
        "selection",
        "candidates",
        "packetDigest",
    }
    if set(value) != required or value.get("schema") != GRAPH_ROUTE_SCHEMA or value.get("route") != "graph-derived":
        raise ValueError("unsupported or incomplete graph route packet")
    request_id = value.get("requestId")
    query = value.get("query")
    if not isinstance(request_id, str) or not request_id or not isinstance(query, str) or not query.strip():
        raise ValueError("graph route packet identity is invalid")
    policy = value.get("policy")
    if not isinstance(policy, Mapping):
        raise ValueError("graph route packet policy is invalid")
    normalized_policy = _validate_routing_policy(policy)
    if value.get("policyDigest") != sha256_digest(policy):
        raise ValueError("graph route packet policy digest mismatch")
    content = {key: item for key, item in value.items() if key != "packetDigest"}
    if value.get("packetDigest") != sha256_digest(content):
        raise ValueError("graph route packet digest mismatch")
    index = value.get("index")
    if not isinstance(index, Mapping):
        raise ValueError("graph route packet index provenance is invalid")
    if envelope is not None:
        admitted = load_full_index_envelope(envelope)
        expected = {"schema": admitted["schema"], **admitted["provenance"]}
        if dict(index) != expected:
            raise ValueError("graph route packet index provenance mismatch")
    selection = value.get("selection")
    if not isinstance(selection, Mapping) or set(selection) != {"entities", "resources"}:
        raise ValueError("graph route packet selection is invalid")
    entities = selection.get("entities")
    resources = selection.get("resources")
    if not isinstance(entities, list) or any(not isinstance(item, str) or not item for item in entities):
        raise ValueError("graph route packet selection.entities must be a string list")
    if not isinstance(resources, list) or resources != [
        f"kg://entity/{item}" for item in entities[: normalized_policy["budgets"]["maxResources"]]
    ]:
        raise ValueError("graph route packet resources do not match selected entities")
    candidates = value.get("candidates")
    if not isinstance(candidates, list):
        raise ValueError("graph route packet candidates must be a list")
    budgets = normalized_policy["budgets"]
    if len(candidates) > budgets["maxCandidates"]:
        raise ValueError("graph route packet candidates exceed policy budget")
    if len(entities) > budgets["maxEntities"]:
        raise ValueError("graph route packet entities exceed policy budget")
    if len(resources) > budgets["maxResources"]:
        raise ValueError("graph route packet resources exceed policy budget")
    included = [
        item.get("entityId")
        for item in candidates
        if isinstance(item, Mapping) and item.get("disposition") == "included"
    ]
    if entities != included:
        raise ValueError("graph route packet selections do not match included candidates")
    return value
