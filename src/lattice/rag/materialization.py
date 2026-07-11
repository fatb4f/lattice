"""Bounded, reproducible JSON-LD materialization from route packets."""

from __future__ import annotations

from collections import deque
from collections.abc import Mapping
from typing import Any
from urllib.parse import quote

from lattice.adapters.full_index import FullIndexError, load_full_index_envelope

from .provenance import canonical_json, sha256_digest
from .routing import validate_graph_route_packet

JSONLD_CONTEXT = {
    "@version": 1.1,
    "kg": "https://quicue.ca/kg#",
    "lattice": "https://lattice.dev/vocab#",
    "related": {"@id": "kg:related", "@type": "@id"},
    "sourceId": "lattice:sourceId",
}


def _iri(entity_id: str, value: Mapping[str, Any]) -> str:
    declared = value.get("@id")
    if isinstance(declared, str) and ("://" in declared or declared.startswith("urn:")):
        return declared
    return "urn:lattice:kg:" + quote(entity_id, safe="")


def _budget(value: Mapping[str, Any] | None) -> dict[str, int]:
    raw = dict(value or {})
    defaults = {"maxNodes": 16, "maxEdges": 24, "maxBytes": 16384, "maxDepth": 2}
    result = {key: raw.get(key, default) for key, default in defaults.items()}
    limits = {"maxNodes": (1, 128), "maxEdges": (0, 512), "maxBytes": (1024, 1048576), "maxDepth": (0, 8)}
    for key, candidate in result.items():
        low, high = limits[key]
        if isinstance(candidate, bool) or not isinstance(candidate, int) or not low <= candidate <= high:
            raise ValueError(f"budget.{key} must be an integer from {low} to {high}")
    return result


def materialize_context(
    route_packet: Mapping[str, Any],
    envelope: Mapping[str, Any],
    budget: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    index = load_full_index_envelope(envelope)
    try:
        admitted_route = validate_graph_route_packet(route_packet, index)
    except ValueError as exc:
        raise FullIndexError("route_packet_invalid", str(exc)) from exc
    request_id = admitted_route["requestId"]
    limits = _budget(budget)
    evidence_ref = index["provenance"]["inputDigest"]

    def diagnostic(kind: str, **details: Any) -> dict[str, Any]:
        return {"kind": kind, "evidence": [evidence_ref], **details}

    entities = index["graph"]["entities"]
    relations = index["graph"]["relations"]
    seeds = admitted_route["selection"]["entities"]
    missing = sorted(set(seeds) - set(entities))
    if missing:
        raise FullIndexError(
            "context_entity_not_found", "Route packet selected entities absent from the index", {"ids": missing}
        )
    adjacency: dict[str, list[dict[str, str]]] = {}
    for relation in relations:
        adjacency.setdefault(relation["source"], []).append(relation)
        adjacency.setdefault(relation["target"], []).append(relation)
    selected: set[str] = set()
    selected_relations: dict[tuple[str, str, str], dict[str, str]] = {}
    frontier = deque((seed, 0) for seed in sorted(set(seeds)))
    truncation: list[dict[str, Any]] = []
    while frontier:
        entity_id, depth = frontier.popleft()
        if entity_id not in selected and len(selected) >= limits["maxNodes"]:
            truncation.append(diagnostic("node-budget", entityId=entity_id))
            continue
        selected.add(entity_id)
        if depth >= limits["maxDepth"]:
            continue
        for relation in sorted(adjacency.get(entity_id, []), key=lambda item: (item["source"], item["target"])):
            key = (relation["source"], relation["predicate"], relation["target"])
            if key not in selected_relations and len(selected_relations) >= limits["maxEdges"]:
                truncation.append(diagnostic("edge-budget", relation=list(key)))
                continue
            other = relation["target"] if relation["source"] == entity_id else relation["source"]
            if other not in selected and len(selected) + len({item for item, _ in frontier}) >= limits["maxNodes"]:
                truncation.append(diagnostic("node-budget", entityId=other))
                continue
            selected_relations[key] = relation
            if other not in selected:
                frontier.append((other, depth + 1))
    iri_by_id = {entity_id: _iri(entity_id, entities[entity_id]["value"]) for entity_id in selected}
    if len(set(iri_by_id.values())) != len(iri_by_id):
        raise FullIndexError("projection_mapping_unsupported", "Selected entities map to duplicate JSON-LD IRIs")
    graph: list[dict[str, Any]] = []
    for entity_id in sorted(selected):
        record = entities[entity_id]
        value = record["value"]
        declared_type = value.get("@type")
        if declared_type is not None and not (
            isinstance(declared_type, str)
            or (
                isinstance(declared_type, list)
                and declared_type
                and all(isinstance(item, str) and item for item in declared_type)
            )
        ):
            raise FullIndexError(
                "projection_mapping_unsupported", "An entity has an unsupported JSON-LD type mapping", {"id": entity_id}
            )
        node = {
            "@id": iri_by_id[entity_id],
            "@type": value.get("@type", f"kg:{record['collection'].rstrip('s').title()}"),
            "sourceId": entity_id,
            "lattice:collection": record["collection"],
            "lattice:payload": value,
        }
        related = [
            iri_by_id[relation["target"]]
            for relation in selected_relations.values()
            if relation["source"] == entity_id and relation["target"] in iri_by_id
        ]
        if related:
            node["related"] = sorted(related)
        graph.append(node)
    projection = {"@context": JSONLD_CONTEXT, "@graph": graph}
    packet: dict[str, Any] = {
        "schema": "lattice.context-packet.v1",
        "requestId": request_id,
        "routePacketDigest": admitted_route["packetDigest"],
        "index": {"schema": index["schema"], **index["provenance"]},
        "budget": limits,
        "selection": {
            "seedEntities": sorted(set(seeds)),
            "materializedEntities": sorted(selected),
            "relations": [
                {**item, "evidence": [evidence_ref]}
                for item in sorted(selected_relations.values(), key=lambda item: (item["source"], item["target"]))
            ],
        },
        "projection": {"format": "application/ld+json", "contextVersion": "v1", "document": projection},
        "truncated": bool(truncation),
        "diagnostics": truncation,
    }

    def finalize() -> dict[str, Any]:
        content = {**packet, "truncated": bool(packet["diagnostics"])}
        return {**content, "packetDigest": sha256_digest(content)}

    finalized = finalize()
    while len(canonical_json(finalized)) > limits["maxBytes"]:
        removable = sorted(set(packet["selection"]["materializedEntities"]) - set(seeds))
        if not removable:
            break
        removed = removable[-1]
        packet["selection"]["materializedEntities"].remove(removed)
        packet["selection"]["relations"] = [
            relation
            for relation in packet["selection"]["relations"]
            if removed not in (relation["source"], relation["target"])
        ]
        packet["projection"]["document"]["@graph"] = [
            node for node in packet["projection"]["document"]["@graph"] if node["sourceId"] != removed
        ]
        admitted_iris = {node["@id"] for node in packet["projection"]["document"]["@graph"]}
        for node in packet["projection"]["document"]["@graph"]:
            if "related" in node:
                node["related"] = [iri for iri in node["related"] if iri in admitted_iris]
                if not node["related"]:
                    del node["related"]
        packet["diagnostics"].append(diagnostic("byte-budget", entityId=removed))
        finalized = finalize()
    if len(canonical_json(finalized)) > limits["maxBytes"]:
        for node in packet["projection"]["document"]["@graph"]:
            payload = node.pop("lattice:payload", None)
            if payload is not None:
                node["lattice:payloadDigest"] = sha256_digest(payload)
        packet["diagnostics"].append(diagnostic("byte-budget-payload-elided"))
        finalized = finalize()
    if len(canonical_json(finalized)) > limits["maxBytes"]:
        raise ValueError("minimum materialized context exceeds budget.maxBytes")
    return finalized


def validate_materialized_context(
    packet: Mapping[str, Any], route_packet: Mapping[str, Any], envelope: Mapping[str, Any]
) -> dict[str, Any]:
    """Validate a cached projection against its route and full-index bindings."""
    value = dict(packet)
    route = validate_graph_route_packet(route_packet, envelope)
    index = load_full_index_envelope(envelope)
    if value.get("schema") != "lattice.context-packet.v1":
        raise ValueError("unsupported materialized context schema")
    if value.get("requestId") != route["requestId"] or value.get("routePacketDigest") != route["packetDigest"]:
        raise ValueError("materialized context route binding mismatch")
    if value.get("index") != {"schema": index["schema"], **index["provenance"]}:
        raise ValueError("materialized context index provenance mismatch")
    digest = value.get("packetDigest")
    content = {key: item for key, item in value.items() if key != "packetDigest"}
    if digest != sha256_digest(content):
        raise ValueError("materialized context packet digest mismatch")
    return value
