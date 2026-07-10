"""Pure, bounded inspection composition over an immutable snapshot."""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from types import MappingProxyType
from typing import Any, Protocol

from lattice_kg.contracts.models import ComposeRequest, ContractError, RegistryEntity, RegistryRelation
from lattice_kg.contracts.serialization import canonical_json, sha256_digest
from lattice_kg.registry.loader import RegistrySnapshot

POLICY_VERSION = "inspect-v1"
SERIALIZER_VERSION = "json-v1"
ALLOWED_PREDICATES = frozenset({"contains", "uses", "imports", "defines"})


def _freeze(value: Any) -> Any:
    if isinstance(value, dict):
        return MappingProxyType({key: _freeze(item) for key, item in value.items()})
    if isinstance(value, list):
        return tuple(_freeze(item) for item in value)
    return value


@dataclass(frozen=True)
class CompositionArtifact:
    packet_bytes: bytes
    trace_bytes: bytes
    packet: Mapping[str, Any]
    trace: Mapping[str, Any]


class RegistryEngine(Protocol):
    def compose(self, request: ComposeRequest, snapshot: RegistrySnapshot) -> CompositionArtifact: ...


def _diagnostic(code: str, message: str) -> dict[str, str]:
    return {"code": code, "message": message}


def _append_diagnostic(
    diagnostics: list[dict[str, str]],
    request: ComposeRequest,
    code: str,
    message: str,
) -> None:
    if len(diagnostics) < request.budget.max_diagnostics:
        diagnostics.append(_diagnostic(code, message))


def _entity_json(entity: RegistryEntity) -> dict[str, Any]:
    value: dict[str, Any] = {
        "authority": entity.authority,
        "evidence": list(entity.evidence),
        "id": entity.id,
        "kind": entity.kind,
    }
    if entity.path:
        value["path"] = entity.path
    if entity.qualified_symbol:
        value["qualifiedSymbol"] = entity.qualified_symbol
    if entity.short_symbol:
        value["shortSymbol"] = entity.short_symbol
    return value


def _relation_json(relation: RegistryRelation) -> dict[str, Any]:
    value = {
        "evidence": list(relation.evidence),
        "id": relation.id,
        "object": relation.object,
        "predicate": relation.predicate,
        "subject": relation.subject,
    }
    if relation.external:
        value["external"] = True
    return value


def _resolve(request: ComposeRequest, snapshot: RegistrySnapshot) -> tuple[tuple[str, ...], list[dict[str, str]]]:
    resolved: set[str] = set()
    diagnostics: list[dict[str, str]] = []
    for entity_id in request.ids:
        if entity_id in snapshot.nodes_by_id:
            resolved.add(entity_id)
        else:
            _append_diagnostic(diagnostics, request, "seed_not_found", f"entity ID not found: {entity_id}")
    for path in request.paths:
        matches = snapshot.ids_by_path.get(path, ())
        if matches:
            resolved.update(matches)
        else:
            _append_diagnostic(diagnostics, request, "seed_not_found", f"path not found: {path}")
    for symbol in request.symbols:
        matches = snapshot.ids_by_qualified_symbol.get(symbol, ())
        if not matches:
            matches = snapshot.ids_by_short_symbol.get(symbol, ())
            if len(matches) > 1:
                _append_diagnostic(
                    diagnostics, request, "ambiguous_symbol", f"unqualified symbol is ambiguous: {symbol}"
                )
                continue
        if matches:
            resolved.update(matches)
        else:
            _append_diagnostic(diagnostics, request, "seed_not_found", f"symbol not found: {symbol}")
    if len(resolved) > request.budget.max_nodes:
        raise ContractError("resolved seeds exceed budget.maxNodes")
    return tuple(sorted(resolved)), diagnostics


def _closure(
    seeds: Iterable[str], request: ComposeRequest, snapshot: RegistrySnapshot
) -> tuple[tuple[str, ...], tuple[RegistryRelation, ...], list[dict[str, str]]]:
    nodes = set(seeds)
    edges: dict[str, RegistryRelation] = {}
    diagnostics: list[dict[str, str]] = []
    frontier = tuple(sorted(nodes))
    edge_budget_reported = False
    scanned_edges = 0
    for _ in range(request.budget.max_depth):
        next_frontier: set[str] = set()
        for node_id in frontier:
            for relation in snapshot.out_edges.get(node_id, ()):
                if scanned_edges >= request.budget.max_scanned_edges:
                    _append_diagnostic(diagnostics, request, "scanned_edge_budget_exhausted", "maxScannedEdges reached")
                    return tuple(sorted(nodes)), tuple(sorted(edges.values(), key=lambda item: item.id)), diagnostics
                scanned_edges += 1
                if len(edges) >= request.budget.max_edges and relation.id not in edges:
                    if not edge_budget_reported:
                        _append_diagnostic(diagnostics, request, "edge_budget_exhausted", "maxEdges reached")
                        edge_budget_reported = True
                    break
                if relation.predicate not in ALLOWED_PREDICATES:
                    _append_diagnostic(
                        diagnostics, request, "predicate_excluded", f"predicate excluded: {relation.predicate}"
                    )
                    continue
                if relation.external:
                    _append_diagnostic(
                        diagnostics,
                        request,
                        "external_reference_excluded",
                        f"external relation excluded: {relation.id}",
                    )
                    continue
                if relation.object not in nodes and len(nodes) >= request.budget.max_nodes:
                    _append_diagnostic(diagnostics, request, "node_budget_exhausted", "maxNodes reached")
                    continue
                edges[relation.id] = relation
                if relation.object not in nodes:
                    nodes.add(relation.object)
                    next_frontier.add(relation.object)
        frontier = tuple(sorted(next_frontier))
        if not frontier:
            break
    return tuple(sorted(nodes)), tuple(sorted(edges.values(), key=lambda item: item.id)), diagnostics


def _packet_content(
    snapshot: RegistrySnapshot,
    request: ComposeRequest,
    entities: list[dict[str, Any]],
    relations: list[dict[str, Any]],
    evidence: list[dict[str, Any]],
    diagnostics: list[dict[str, str]],
) -> dict[str, Any]:
    identity = {
        "id": snapshot.identity.id,
        "revision": snapshot.identity.revision,
        "graphDigest": snapshot.identity.graph_digest,
        "contractVersion": snapshot.identity.contract_version,
    }
    return {
        "schema": "lattice.context-packet.v1",
        "snapshot": identity,
        "intent": request.intent,
        "entities": entities,
        "relations": relations,
        "evidence": evidence,
        "diagnostics": diagnostics,
        "compositionPolicyVersion": POLICY_VERSION,
        "serializerVersion": SERIALIZER_VERSION,
    }


def _with_digest(content: dict[str, Any], field: str) -> dict[str, Any]:
    return {**content, field: sha256_digest(content)}


class PythonRegistryEngine:
    def compose(self, request: ComposeRequest, snapshot: RegistrySnapshot) -> CompositionArtifact:
        seeds, diagnostics = _resolve(request, snapshot)
        node_ids, relations, closure_diagnostics = _closure(seeds, request, snapshot)
        diagnostics.extend(closure_diagnostics[: request.budget.max_diagnostics - len(diagnostics)])
        entities = [_entity_json(snapshot.nodes_by_id[node_id]) for node_id in node_ids]
        relation_values = [_relation_json(relation) for relation in relations]
        evidence_ids = sorted(
            {ref for entity in entities for ref in entity["evidence"]}
            | {ref for relation in relation_values for ref in relation["evidence"]}
        )
        evidence = [
            {"id": item.id, "path": item.path, "startLine": item.start_line, "endLine": item.end_line}
            for item in (snapshot.evidence_by_id[ref] for ref in evidence_ids)
        ]
        packet = _with_digest(
            _packet_content(snapshot, request, entities, relation_values, evidence, diagnostics), "packetDigest"
        )
        packet_bytes = canonical_json(packet)
        if len(packet_bytes) > request.budget.max_bytes:
            raise ContractError("canonical packet exceeds budget.maxBytes")
        trace_content = {
            "schema": "lattice.composition-trace.v1",
            "packetDigest": packet["packetDigest"],
            "resolvedSeeds": list(seeds),
            "excluded": diagnostics,
            "compositionPolicyVersion": POLICY_VERSION,
        }
        trace = _with_digest(trace_content, "traceDigest")
        return CompositionArtifact(packet_bytes, canonical_json(trace), _freeze(packet), _freeze(trace))


def compose(request_value: Mapping[str, Any], snapshot: RegistrySnapshot) -> CompositionArtifact:
    return PythonRegistryEngine().compose(ComposeRequest.from_mapping(request_value), snapshot)
