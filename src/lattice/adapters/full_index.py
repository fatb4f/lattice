"""Validated JSON envelope between CUE/KG authority and Python execution."""

from __future__ import annotations

import json
from collections.abc import Mapping
from typing import Any

FULL_INDEX_SCHEMA = "lattice.kg-full-index-envelope.v1"
ERROR_SCHEMA = "lattice.mcp-error.v1"


class FullIndexError(ValueError):
    """Raised when a KG export cannot cross the serialized adapter boundary."""

    def __init__(self, code: str, message: str, details: Mapping[str, Any] | None = None) -> None:
        super().__init__(message)
        self.code = code
        self.details = dict(details or {})

    def as_dict(self) -> dict[str, Any]:
        return {"schema": ERROR_SCHEMA, "error": {"code": self.code, "message": str(self), "details": self.details}}


def validate_full_index(graph: Any) -> list[dict[str, str]]:
    """Validate an unwrapped ``kg index --full`` export and derive relations."""
    if not isinstance(graph, dict):
        raise FullIndexError("kg_index_incomplete", "The full KG index must be a JSON object")
    entities = graph.get("entities")
    if not isinstance(entities, dict):
        raise FullIndexError("kg_index_incomplete", "The full KG index does not contain a typed entity inventory")
    total = graph.get("summary", {}).get("total") if isinstance(graph.get("summary"), dict) else None
    if not entities or not isinstance(total, int) or isinstance(total, bool) or total != len(entities):
        raise FullIndexError(
            "kg_index_incomplete",
            "The full KG index entity inventory is incomplete",
            {"declaredTotal": total, "entityCount": len(entities)},
        )
    relations: list[dict[str, str]] = []
    dangling: list[dict[str, str]] = []
    for source, record in entities.items():
        if not isinstance(record, dict) or not record.get("collection") or not isinstance(record.get("value"), dict):
            raise FullIndexError(
                "kg_index_incomplete", "A full KG index entity is missing its type or value", {"id": source}
            )
        related = record["value"].get("related", {})
        if not isinstance(related, dict):
            raise FullIndexError("kg_index_incomplete", "An entity related field must be an object", {"id": source})
        for target, selected in related.items():
            if selected is not True:
                continue
            relation = {"source": source, "predicate": "related", "target": target}
            relations.append(relation)
            if target not in entities:
                dangling.append(relation)
    if dangling:
        raise FullIndexError(
            "kg_index_dangling_relations", "The full KG index contains dangling relations", {"relations": dangling}
        )
    return sorted(relations, key=lambda item: (item["source"], item["predicate"], item["target"]))


def normalize_full_index(raw: str | bytes | Mapping[str, Any], provenance: Mapping[str, str]) -> dict[str, Any]:
    """Wrap one validated KG export with required version and provenance."""
    if isinstance(raw, (str, bytes)):
        try:
            graph = json.loads(raw)
        except (json.JSONDecodeError, UnicodeDecodeError) as exc:
            raise FullIndexError(
                "kg_index_invalid_json", "The full KG index was not valid JSON", {"cause": str(exc)}
            ) from exc
    else:
        graph = dict(raw)
    relations = validate_full_index(graph)
    required = ("revision", "inputDigest", "kgVersion", "cueVersion")
    missing = [field for field in required if not provenance.get(field)]
    if missing:
        raise FullIndexError(
            "kg_index_provenance_missing", "The full KG index provenance is incomplete", {"missing": missing}
        )
    return {
        "schema": FULL_INDEX_SCHEMA,
        "provenance": {
            "repositoryRevision": provenance["revision"],
            "inputDigest": provenance["inputDigest"],
            "tools": {"kg": provenance["kgVersion"], "cue": provenance["cueVersion"]},
        },
        "graph": {**graph, "relations": relations},
    }


def load_full_index_envelope(raw: str | bytes | Mapping[str, Any]) -> dict[str, Any]:
    """Fail closed when loading the sole versioned adapter envelope."""
    value = json.loads(raw) if isinstance(raw, (str, bytes)) else dict(raw)
    provenance = value.get("provenance")
    if value.get("schema") != FULL_INDEX_SCHEMA or not isinstance(provenance, dict):
        raise FullIndexError("kg_index_envelope_invalid", "Unsupported or incomplete full-index envelope")
    tools = provenance.get("tools")
    required_values = (
        provenance.get("repositoryRevision"),
        provenance.get("inputDigest"),
        tools.get("kg") if isinstance(tools, dict) else None,
        tools.get("cue") if isinstance(tools, dict) else None,
    )
    if any(not isinstance(item, str) or not item for item in required_values):
        raise FullIndexError("kg_index_provenance_missing", "The full KG index provenance is incomplete")
    graph = value.get("graph")
    if not isinstance(graph, dict):
        raise FullIndexError("kg_index_envelope_invalid", "Full-index envelope is missing its graph")
    derived = validate_full_index(graph)
    if graph.get("relations") != derived:
        raise FullIndexError("kg_index_relations_invalid", "Full-index relations do not match the KG export")
    return value
