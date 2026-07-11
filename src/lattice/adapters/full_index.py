"""Validated JSON envelope between CUE/KG authority and Python execution."""

from __future__ import annotations

import json
import re
from collections.abc import Mapping
from typing import Any

FULL_INDEX_SCHEMA = "lattice.kg-full-index-envelope.v1"
ERROR_SCHEMA = "lattice.mcp-error.v1"
SHA256 = re.compile(r"^sha256:[0-9a-f]{64}$")


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
    counted_entities = sum(
        isinstance(record, dict) and record.get("collection") != "context" for record in entities.values()
    )
    if not entities or not isinstance(total, int) or isinstance(total, bool) or total != counted_entities:
        raise FullIndexError(
            "kg_index_incomplete",
            "The full KG index entity inventory is incomplete",
            {"declaredTotal": total, "countedEntityCount": counted_entities, "entityCount": len(entities)},
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
    required = ("revision", "inputDigest", "policyDigest", "kgVersion", "cueVersion")
    missing = [field for field in required if not provenance.get(field)]
    if missing:
        raise FullIndexError(
            "kg_index_provenance_missing", "The full KG index provenance is incomplete", {"missing": missing}
        )
    if (
        not SHA256.fullmatch(provenance["inputDigest"])
        or not SHA256.fullmatch(provenance["policyDigest"])
        or not SHA256.fullmatch(provenance["kgVersion"])
    ):
        raise FullIndexError("kg_index_provenance_invalid", "Full-index provenance digests are invalid")
    return {
        "schema": FULL_INDEX_SCHEMA,
        "provenance": {
            "repositoryRevision": provenance["revision"],
            "inputDigest": provenance["inputDigest"],
            "policyDigest": provenance["policyDigest"],
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
    if not isinstance(tools, dict):
        raise FullIndexError("kg_index_provenance_missing", "The full KG index provenance is incomplete")
    required_values = (
        provenance.get("repositoryRevision"),
        provenance.get("inputDigest"),
        provenance.get("policyDigest"),
        tools.get("kg"),
        tools.get("cue"),
    )
    if any(not isinstance(item, str) or not item for item in required_values):
        raise FullIndexError("kg_index_provenance_missing", "The full KG index provenance is incomplete")
    input_digest = provenance["inputDigest"]
    policy_digest = provenance["policyDigest"]
    kg_digest = tools["kg"]
    if not isinstance(input_digest, str) or not isinstance(policy_digest, str) or not isinstance(kg_digest, str):
        raise FullIndexError("kg_index_provenance_missing", "The full KG index provenance is incomplete")
    if not SHA256.fullmatch(input_digest) or not SHA256.fullmatch(policy_digest) or not SHA256.fullmatch(kg_digest):
        raise FullIndexError("kg_index_provenance_invalid", "Full-index provenance digests are invalid")
    graph = value.get("graph")
    if not isinstance(graph, dict):
        raise FullIndexError("kg_index_envelope_invalid", "Full-index envelope is missing its graph")
    derived = validate_full_index(graph)
    if graph.get("relations") != derived:
        raise FullIndexError("kg_index_relations_invalid", "Full-index relations do not match the KG export")
    return value
