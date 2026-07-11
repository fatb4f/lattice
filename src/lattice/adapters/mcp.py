"""Generic, structured, read-only MCP resource implementation."""

from __future__ import annotations

import argparse
import json
from collections.abc import Mapping
from pathlib import Path
from typing import Any
from urllib.parse import parse_qs, unquote, urlsplit

from lattice.rag.cache import BoundedExecutor
from lattice.rag.materialization import materialize_context
from lattice.rag.provenance import canonical_json
from lattice.rag.routing import derive_route_packet, routing_policy_with_budgets

from .cue import admit_context_value, export_context_value
from .full_index import FullIndexError, load_full_index_envelope
from .kg import cached_full_index, full_index_provenance


def mcp_error(code: str, message: str, details: Mapping[str, Any] | None = None) -> dict[str, Any]:
    return {
        "schema": "lattice.mcp-error.v1",
        "error": {"code": code, "message": message, "details": dict(details or {})},
    }


class MCPResources:
    """URI-addressable views over one immutable full-index envelope."""

    def __init__(self, envelope: Mapping[str, Any], root: str | Path = ".") -> None:
        self.envelope = load_full_index_envelope(envelope)
        self.graph = self.envelope["graph"]
        self.root = Path(root).resolve()
        self.routing_policy = export_context_value("graphRoutingPolicy", self.root)
        admit_context_value(self.routing_policy, "#GraphRoutingPolicy", self.root)

    def inventory(self) -> dict[str, Any]:
        return {
            "schema": "lattice.mcp-resource-inventory.v1",
            "revision": self.envelope["provenance"]["repositoryRevision"],
            "templates": [
                "kg://entity/{id}",
                "kg://relation/{source}/{predicate}/{target}",
                "kg://neighborhood/{id}?depth={depth}",
                "kg://graph/inventory",
                "kg://graph/coverage",
                "kg://projection/entity/{id}",
                "kg://drift",
            ],
        }

    def _entity(self, entity_id: str) -> dict[str, Any]:
        entity = self.graph["entities"].get(entity_id)
        if entity is None:
            raise FullIndexError("not_found", "Entity was not found", {"id": entity_id})
        return {"schema": "lattice.mcp-entity.v1", "id": entity_id, **entity, "provenance": self.envelope["provenance"]}

    def _relation(self, source: str, predicate: str, target: str) -> dict[str, Any]:
        expected = {"source": source, "predicate": predicate, "target": target}
        if expected not in self.graph["relations"]:
            raise FullIndexError("not_found", "Relation was not found", expected)
        return {"schema": "lattice.mcp-relation.v1", **expected, "provenance": self.envelope["provenance"]}

    def _neighborhood(self, entity_id: str, depth: int) -> dict[str, Any]:
        if entity_id not in self.graph["entities"]:
            raise FullIndexError("not_found", "Entity was not found", {"id": entity_id})
        if not 0 <= depth <= 4:
            raise FullIndexError("invalid_request", "Neighborhood depth must be from 0 to 4")
        nodes = {entity_id}
        edges: list[dict[str, str]] = []
        frontier = {entity_id}
        for _ in range(depth):
            next_frontier: set[str] = set()
            for relation in self.graph["relations"]:
                if relation["source"] in frontier or relation["target"] in frontier:
                    edges.append(relation)
                    next_frontier.update((relation["source"], relation["target"]))
            next_frontier -= nodes
            nodes |= next_frontier
            frontier = next_frontier
        return {
            "schema": "lattice.mcp-neighborhood.v1",
            "center": entity_id,
            "depth": depth,
            "entities": {item: self.graph["entities"][item] for item in sorted(nodes)},
            "relations": sorted({(item["source"], item["predicate"], item["target"]) for item in edges}),
            "provenance": self.envelope["provenance"],
        }

    def read(self, uri: str, payload: Mapping[str, Any] | None = None) -> dict[str, Any]:
        try:
            parsed = urlsplit(uri)
            if parsed.scheme != "kg":
                raise FullIndexError("invalid_request", "Only kg:// read-only resources are supported")
            parts = [unquote(part) for part in ([parsed.netloc] + parsed.path.split("/")) if part]
            if parts == ["graph", "inventory"]:
                return self.inventory()
            if parts == ["graph", "coverage"]:
                return {
                    "schema": "lattice.mcp-coverage.v1",
                    "entities": len(self.graph["entities"]),
                    "relations": len(self.graph["relations"]),
                    "collections": dict(sorted(self.graph.get("summary", {}).items())),
                    "provenance": self.envelope["provenance"],
                }
            if parts == ["drift"]:
                recorded = self.envelope["provenance"]
                try:
                    _, current_raw = full_index_provenance(self.root)
                    current = {
                        "repositoryRevision": current_raw["revision"],
                        "inputDigest": current_raw["inputDigest"],
                        "policyDigest": current_raw["policyDigest"],
                        "tools": {"kg": current_raw["kgVersion"], "cue": current_raw["cueVersion"]},
                    }
                except (FullIndexError, OSError) as exc:
                    error = exc.as_dict()["error"] if isinstance(exc, FullIndexError) else {
                        "code": "kg_index_provenance_unavailable",
                        "message": str(exc),
                        "details": {},
                    }
                    return {
                        "schema": "lattice.mcp-drift.v1",
                        "status": "indeterminate",
                        "stale": None,
                        "recorded": recorded,
                        "diagnostics": [error],
                    }
                fields = [
                    field
                    for field in ("repositoryRevision", "inputDigest", "policyDigest", "tools")
                    if current[field] != recorded[field]
                ]
                return {
                    "schema": "lattice.mcp-drift.v1",
                    "status": "stale" if fields else "current",
                    "stale": bool(fields),
                    "changed": fields,
                    "recorded": recorded,
                    "current": current,
                }
            if len(parts) == 2 and parts[0] == "entity":
                return self._entity(parts[1])
            if len(parts) == 4 and parts[0] == "relation":
                return self._relation(*parts[1:])
            if len(parts) == 2 and parts[0] == "neighborhood":
                raw_depth = parse_qs(parsed.query).get("depth", ["1"])[0]
                try:
                    depth = int(raw_depth)
                except ValueError as exc:
                    raise FullIndexError("invalid_request", "Neighborhood depth must be an integer") from exc
                return self._neighborhood(parts[1], depth)
            if len(parts) == 3 and parts[0] == "neighborhood":
                try:
                    depth = int(parts[2])
                except ValueError as exc:
                    raise FullIndexError("invalid_request", "Neighborhood depth must be an integer") from exc
                return self._neighborhood(parts[1], depth)
            if parts == ["projection", "context"]:
                if not isinstance(payload, Mapping) or not isinstance(payload.get("routePacket"), Mapping):
                    raise FullIndexError("invalid_request", "Context projection requires a routePacket object")
                try:
                    admit_context_value(payload["routePacket"], "#GraphRoutePacket", self.root)
                    packet = materialize_context(payload["routePacket"], self.envelope, payload.get("budget"))
                    admit_context_value(packet, "#MaterializedContextPacket", self.root)
                    return packet
                except (ValueError, FullIndexError) as exc:
                    raise FullIndexError("projection_error", str(exc)) from exc
            if len(parts) == 3 and parts[:2] == ["projection", "entity"]:
                policy = routing_policy_with_budgets(self.routing_policy, max_entities=1, max_resources=0)
                route = derive_route_packet(parts[2], self.envelope, policy)
                if route["selection"]["entities"] != [parts[2]]:
                    raise FullIndexError("not_found", "Entity was not found", {"id": parts[2]})
                admit_context_value(route, "#GraphRoutePacket", self.root)
                packet = materialize_context(route, self.envelope)
                admit_context_value(packet, "#MaterializedContextPacket", self.root)
                return packet
            raise FullIndexError("not_found", "MCP resource was not found", {"uri": uri})
        except FullIndexError as exc:
            return exc.as_dict()


class AsyncMCPResources:
    def __init__(self, resources: MCPResources, *, concurrency: int = 4, timeout: float = 20.0) -> None:
        self.resources = resources
        self.executor = BoundedExecutor(concurrency, timeout)

    async def read(self, uri: str, payload: Mapping[str, Any] | None = None) -> dict[str, Any]:
        try:
            return await self.executor.run(self.resources.read, uri, payload)
        except TimeoutError:
            return mcp_error("execution_timeout", "MCP resource execution exceeded its time limit")


def create_mcp_server(
    envelope: Mapping[str, Any], *, root: str | Path = ".", concurrency: int = 4, timeout: float = 20.0
) -> Any:
    """Create the admitted stdio server without starting transport side effects."""
    from mcp.server.fastmcp import FastMCP

    server = FastMCP("lattice-kg", instructions="Read-only, revision-aware Lattice graph resources")
    resources = AsyncMCPResources(MCPResources(envelope, root), concurrency=concurrency, timeout=timeout)

    async def read(uri: str) -> str:
        return canonical_json(await resources.read(uri)).decode()

    @server.resource("kg://graph/inventory", mime_type="application/json")
    async def graph_inventory() -> str:
        return await read("kg://graph/inventory")

    @server.resource("kg://graph/coverage", mime_type="application/json")
    async def graph_coverage() -> str:
        return await read("kg://graph/coverage")

    @server.resource("kg://drift", mime_type="application/json")
    async def drift() -> str:
        return await read("kg://drift")

    @server.resource("kg://entity/{entity_id}", mime_type="application/json")
    async def entity(entity_id: str) -> str:
        return await read(f"kg://entity/{entity_id}")

    @server.resource("kg://relation/{source}/{predicate}/{target}", mime_type="application/json")
    async def relation(source: str, predicate: str, target: str) -> str:
        return await read(f"kg://relation/{source}/{predicate}/{target}")

    @server.resource("kg://neighborhood/{entity_id}/{depth}", mime_type="application/json")
    async def neighborhood(entity_id: str, depth: str) -> str:
        return await read(f"kg://neighborhood/{entity_id}/{depth}")

    @server.resource("kg://projection/entity/{entity_id}", mime_type="application/ld+json")
    async def entity_projection(entity_id: str) -> str:
        return await read(f"kg://projection/entity/{entity_id}")

    return server


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="lattice-mcp")
    parser.add_argument("--envelope")
    parser.add_argument("--root", default=".")
    parser.add_argument("--cache-root", default=".cache/lattice")
    parser.add_argument("--concurrency", type=int, default=4)
    parser.add_argument("--timeout", type=float, default=20.0)
    args = parser.parse_args(argv)
    if args.envelope:
        envelope = load_full_index_envelope(json.loads(Path(args.envelope).read_text(encoding="utf-8")))
    else:
        envelope, _ = cached_full_index(args.root, args.cache_root, args.timeout)
    create_mcp_server(envelope, root=args.root, concurrency=args.concurrency, timeout=args.timeout).run("stdio")
    return 0
