"""Atomic loading and validation for a local canonical registry snapshot."""

from __future__ import annotations

import json
import re
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path
from types import MappingProxyType
from typing import Any

from lattice.rag.contracts.models import (
    ContractError,
    EvidenceRef,
    RegistryEntity,
    RegistryRelation,
    SnapshotIdentity,
    _require,
    _strings,
)
from lattice.rag.provenance import sha256_digest

CONTEXT = "https://lattice.dev/context/registry/v1"
AUTHORITIES = frozenset({"asserted", "observed", "derived", "external"})
EXTERNAL_IRI = re.compile(r"^(?:https?://|urn:).+")


class SnapshotValidationError(ContractError):
    pass


def _read_object(path: Path) -> Mapping[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SnapshotValidationError(f"cannot read {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise SnapshotValidationError(f"{path} must contain an object")
    return value


@dataclass(frozen=True)
class RegistrySnapshot:
    identity: SnapshotIdentity
    entities: tuple[RegistryEntity, ...]
    relations: tuple[RegistryRelation, ...]
    evidence: tuple[EvidenceRef, ...]
    nodes_by_id: Mapping[str, RegistryEntity]
    ids_by_path: Mapping[str, tuple[str, ...]]
    ids_by_qualified_symbol: Mapping[str, tuple[str, ...]]
    ids_by_short_symbol: Mapping[str, tuple[str, ...]]
    out_edges: Mapping[str, tuple[RegistryRelation, ...]]
    in_edges: Mapping[str, tuple[RegistryRelation, ...]]
    evidence_by_id: Mapping[str, EvidenceRef]


def _freeze_index(index: dict[str, list[Any]]) -> Mapping[str, tuple[Any, ...]]:
    return MappingProxyType(
        {
            key: tuple(sorted(values, key=lambda item: getattr(item, "id", item)))
            for key, values in sorted(index.items())
        }
    )


def _optional_string(value: Mapping[str, Any], field: str) -> str | None:
    candidate = value.get(field)
    return None if candidate is None else _require(candidate, field)


def _parse_entity(value: Any) -> RegistryEntity:
    if not isinstance(value, Mapping) or set(value) - {
        "id",
        "kind",
        "authority",
        "evidence",
        "path",
        "qualifiedSymbol",
        "shortSymbol",
    }:
        raise SnapshotValidationError("unsupported entity shape")
    return RegistryEntity(
        _require(value["id"], "entity.id"),
        _require(value["kind"], "entity.kind"),
        _require(value["authority"], "entity.authority"),
        _strings(value["evidence"], "entity.evidence"),
        _optional_string(value, "path"),
        _optional_string(value, "qualifiedSymbol"),
        _optional_string(value, "shortSymbol"),
    )


def _parse_relation(value: Any) -> RegistryRelation:
    if not isinstance(value, Mapping) or set(value) - {"id", "predicate", "subject", "object", "evidence", "external"}:
        raise SnapshotValidationError("unsupported relation shape")
    external = value.get("external", False)
    if not isinstance(external, bool):
        raise SnapshotValidationError("relation.external must be a boolean")
    return RegistryRelation(
        _require(value["id"], "relation.id"),
        _require(value["predicate"], "relation.predicate"),
        _require(value["subject"], "relation.subject"),
        _require(value["object"], "relation.object"),
        _strings(value["evidence"], "relation.evidence"),
        external,
    )


def load_snapshot(directory: str | Path) -> RegistrySnapshot:
    root = Path(directory)
    manifest = _read_object(root / "manifest.json")
    if set(manifest) != {"schema", "identity", "graph"} or manifest["schema"] != "lattice.registry-manifest.v1":
        raise SnapshotValidationError("unsupported manifest shape")
    identity_raw = manifest["identity"]
    if not isinstance(identity_raw, Mapping) or set(identity_raw) != {
        "id",
        "revision",
        "graphDigest",
        "contractVersion",
    }:
        raise SnapshotValidationError("unsupported snapshot identity shape")
    identity = SnapshotIdentity(
        _require(identity_raw["id"], "identity.id"),
        _require(identity_raw["revision"], "identity.revision"),
        _require(identity_raw["graphDigest"], "identity.graphDigest"),
        _require(identity_raw["contractVersion"], "identity.contractVersion"),
    )
    if identity.contract_version != "lattice.registry.v1":
        raise SnapshotValidationError("unsupported registry contract version")
    graph_name = manifest["graph"]
    if graph_name != "graph.jsonld" or Path(graph_name).name != graph_name:
        raise SnapshotValidationError("manifest graph must be the local graph.jsonld")
    graph = _read_object(root / graph_name)
    if graph.get("@context") != CONTEXT or set(graph) != {"@context", "entities", "relations", "evidence"}:
        raise SnapshotValidationError("unsupported graph shape or context")
    if sha256_digest(graph) != identity.graph_digest:
        raise SnapshotValidationError("graph digest does not match manifest")
    try:
        evidence = tuple(
            sorted(
                (
                    EvidenceRef(
                        _require(item["id"], "evidence.id"),
                        _require(item["path"], "evidence.path"),
                        item["startLine"],
                        item["endLine"],
                    )
                    for item in graph["evidence"]
                ),
                key=lambda item: item.id,
            )
        )
        for item in evidence:
            if type(item.start_line) is not int or type(item.end_line) is not int:
                raise SnapshotValidationError("evidence source lines must be integers")
            if item.start_line < 1 or item.end_line < item.start_line:
                raise SnapshotValidationError("invalid evidence source range")
        entities = tuple(sorted((_parse_entity(item) for item in graph["entities"]), key=lambda item: item.id))
        relations = tuple(sorted((_parse_relation(item) for item in graph["relations"]), key=lambda item: item.id))
    except (KeyError, TypeError, ContractError) as exc:
        raise SnapshotValidationError(f"invalid graph member: {exc}") from exc
    if any(not isinstance(group, list) for group in (graph["evidence"], graph["entities"], graph["relations"])):
        raise SnapshotValidationError("graph collections must be lists")
    if (
        len({item.id for item in entities}) != len(entities)
        or len({item.id for item in evidence}) != len(evidence)
        or len({item.id for item in relations}) != len(relations)
    ):
        raise SnapshotValidationError("graph identifiers must be unique")
    nodes_by_id = {item.id: item for item in entities}
    evidence_by_id = {item.id: item for item in evidence}
    for entity in entities:
        if (
            entity.authority not in AUTHORITIES
            or not entity.evidence
            or any(ref not in evidence_by_id for ref in entity.evidence)
        ):
            raise SnapshotValidationError(f"invalid entity authority or evidence: {entity.id}")
    for relation in relations:
        if (
            not relation.evidence
            or relation.subject not in nodes_by_id
            or any(ref not in evidence_by_id for ref in relation.evidence)
        ):
            raise SnapshotValidationError(f"dangling relation evidence or subject: {relation.id}")
        if relation.external and relation.object.startswith("urn:lattice:"):
            raise SnapshotValidationError(f"internal relation cannot be external: {relation.id}")
        if relation.object.startswith("urn:lattice:") and relation.object not in nodes_by_id:
            raise SnapshotValidationError(f"dangling internal relation: {relation.id}")
        if relation.object not in nodes_by_id and not (relation.external and EXTERNAL_IRI.fullmatch(relation.object)):
            raise SnapshotValidationError(f"dangling internal relation: {relation.id}")
    paths: dict[str, list[str]] = {}
    qualified: dict[str, list[str]] = {}
    short: dict[str, list[str]] = {}
    out: dict[str, list[RegistryRelation]] = {}
    inbound: dict[str, list[RegistryRelation]] = {}
    for entity in entities:
        if entity.path:
            paths.setdefault(entity.path, []).append(entity.id)
        if entity.qualified_symbol:
            qualified.setdefault(entity.qualified_symbol, []).append(entity.id)
        if entity.short_symbol:
            short.setdefault(entity.short_symbol, []).append(entity.id)
    for relation in relations:
        out.setdefault(relation.subject, []).append(relation)
        if not relation.external:
            inbound.setdefault(relation.object, []).append(relation)
    return RegistrySnapshot(
        identity,
        entities,
        relations,
        evidence,
        MappingProxyType(nodes_by_id),
        _freeze_index(paths),
        _freeze_index(qualified),
        _freeze_index(short),
        _freeze_index(out),
        _freeze_index(inbound),
        MappingProxyType(evidence_by_id),
    )
