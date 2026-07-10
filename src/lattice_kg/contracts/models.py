"""Closed boundary adapters and immutable internal registry values."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from typing import Any


class ContractError(ValueError):
    pass


def _require(value: Any, field: str) -> str:
    if not isinstance(value, str) or not value:
        raise ContractError(f"{field} must be a non-empty string")
    return value


def _strings(value: Any, field: str) -> tuple[str, ...]:
    if not isinstance(value, list) or any(not isinstance(item, str) or not item for item in value):
        raise ContractError(f"{field} must be a list of non-empty strings")
    return tuple(value)


@dataclass(frozen=True)
class SnapshotIdentity:
    id: str
    revision: str
    graph_digest: str
    contract_version: str


@dataclass(frozen=True)
class EvidenceRef:
    id: str
    path: str
    start_line: int
    end_line: int


@dataclass(frozen=True)
class RegistryEntity:
    id: str
    kind: str
    authority: str
    evidence: tuple[str, ...]
    path: str | None = None
    qualified_symbol: str | None = None
    short_symbol: str | None = None


@dataclass(frozen=True)
class RegistryRelation:
    id: str
    predicate: str
    subject: str
    object: str
    evidence: tuple[str, ...]
    external: bool = False


@dataclass(frozen=True)
class ContextBudget:
    max_depth: int = 2
    max_nodes: int = 16
    max_edges: int = 24
    max_scanned_edges: int = 256
    max_diagnostics: int = 32
    max_bytes: int = 8192

    @classmethod
    def from_mapping(cls, value: Mapping[str, Any] | None) -> ContextBudget:
        if value is None:
            value = {}
        if not isinstance(value, Mapping):
            raise ContractError("budget must be an object")
        if set(value) - {"maxDepth", "maxNodes", "maxEdges", "maxScannedEdges", "maxDiagnostics", "maxBytes"}:
            raise ContractError("budget has unsupported fields")
        fields = {
            "max_depth": ("maxDepth", 0, 8),
            "max_nodes": ("maxNodes", 1, 128),
            "max_edges": ("maxEdges", 0, 256),
            "max_scanned_edges": ("maxScannedEdges", 1, 4096),
            "max_diagnostics": ("maxDiagnostics", 0, 128),
            "max_bytes": ("maxBytes", 512, 1048576),
        }
        missing = {key for key, _, _ in fields.values()} - set(value)
        if missing:
            raise ContractError(f"budget is missing required fields: {', '.join(sorted(missing))}")
        parsed: dict[str, int] = {}
        for attr, (key, minimum, maximum) in fields.items():
            candidate = value.get(key, getattr(cls(), attr))
            if isinstance(candidate, bool) or not isinstance(candidate, int) or not minimum <= candidate <= maximum:
                raise ContractError(f"budget.{key} must be an integer from {minimum} to {maximum}")
            parsed[attr] = candidate
        return cls(**parsed)


@dataclass(frozen=True)
class ComposeRequest:
    intent: str
    ids: tuple[str, ...]
    paths: tuple[str, ...]
    symbols: tuple[str, ...]
    budget: ContextBudget

    @classmethod
    def from_mapping(cls, value: Mapping[str, Any]) -> ComposeRequest:
        if not isinstance(value, Mapping) or set(value) - {"schema", "intent", "focus", "budget"}:
            raise ContractError("request has unsupported fields")
        if value.get("schema") != "lattice.compose-request.v1":
            raise ContractError("unsupported request schema")
        intent = _require(value.get("intent"), "intent")
        if intent != "inspect":
            raise ContractError("only inspect intent is supported")
        focus = value.get("focus")
        if not isinstance(focus, Mapping) or set(focus) - {"ids", "paths", "symbols"}:
            raise ContractError("focus has unsupported fields")
        ids = _strings(focus.get("ids", []), "focus.ids")
        paths = _strings(focus.get("paths", []), "focus.paths")
        symbols = _strings(focus.get("symbols", []), "focus.symbols")
        if not ids and not paths and not symbols:
            raise ContractError("focus must contain at least one exact seed")
        if "budget" not in value:
            raise ContractError("request.budget is required")
        return cls(intent, ids, paths, symbols, ContextBudget.from_mapping(value["budget"]))
