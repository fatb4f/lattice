"""Closed command-line surface for the installed engine."""

from __future__ import annotations

import argparse
import json
from importlib.resources import files
from pathlib import Path
from typing import Any

from .adapters.cue import admit_context_value, export_context_value
from .adapters.full_index import FullIndexError, load_full_index_envelope
from .adapters.hook import build_hook_audit, emit_route_hook
from .adapters.kg import cached_full_index, execute_full_index
from .adapters.mcp import MCPResources
from .adapters.runtime_surface import runtime_surface_violations
from .diagnostics import run_diagnostics, write_review_bundle
from .profiles import load_manifest
from .rag.cache import ArtifactCache, cache_key
from .rag.contracts.models import ComposeRequest
from .rag.indexing import load_snapshot
from .rag.materialization import materialize_context, validate_materialized_context
from .rag.provenance import canonical_json
from .rag.retrieval import compose
from .rag.routing import derive_route_packet


def _json(path: str) -> Any:
    with Path(path).open(encoding="utf-8") as source:
        return json.load(source)


def _write(path: str, value: bytes) -> None:
    Path(path).write_bytes(value)


def _snapshot_validate(args: argparse.Namespace) -> int:
    snapshot = load_snapshot(args.snapshot)
    print(snapshot.identity.graph_digest)
    return 0


def _snapshot_inspect(args: argparse.Namespace) -> int:
    snapshot = load_snapshot(args.snapshot)
    print(
        json.dumps(
            {
                "identity": {
                    "id": snapshot.identity.id,
                    "revision": snapshot.identity.revision,
                    "graphDigest": snapshot.identity.graph_digest,
                    "contractVersion": snapshot.identity.contract_version,
                },
                "entities": len(snapshot.entities),
                "relations": len(snapshot.relations),
                "evidence": len(snapshot.evidence),
            },
            sort_keys=True,
            separators=(",", ":"),
        )
    )
    return 0


def _compose(args: argparse.Namespace) -> int:
    artifact = compose(_json(args.request), load_snapshot(args.snapshot))
    _write(args.packet_out, artifact.packet_bytes)
    if args.trace_out:
        _write(args.trace_out, artifact.trace_bytes)
    return 0


def _resolve(args: argparse.Namespace) -> int:
    request = ComposeRequest.from_mapping(_json(args.request))
    artifact = compose(_json(args.request), load_snapshot(args.snapshot))
    print(
        json.dumps(
            {"intent": request.intent, "resolvedSeeds": list(artifact.trace["resolvedSeeds"])},
            sort_keys=True,
            separators=(",", ":"),
        )
    )
    return 0


def _profile_list(_: argparse.Namespace) -> int:
    print("\n".join(profile["id"] for profile in load_manifest()["profiles"]))
    return 0


def _profile_show(args: argparse.Namespace) -> int:
    manifest = load_manifest()
    for profile in manifest["profiles"]:
        if profile["id"] == args.profile:
            print(files("lattice.profiles").joinpath(profile["resource"]).read_text(encoding="utf-8"), end="")
            return 0
    raise ValueError(f"unknown profile: {args.profile}")


def _profile_validate(_: argparse.Namespace) -> int:
    load_manifest()
    return 0


def _index_validate(args: argparse.Namespace) -> int:
    load_full_index_envelope(Path(args.envelope).read_bytes())
    return 0


def _runtime_surface(args: argparse.Namespace) -> int:
    violations = runtime_surface_violations(Path(args.root).resolve())
    if violations:
        raise ValueError("; ".join(violations))
    return 0


def _index_build(args: argparse.Namespace) -> int:
    if args.no_cache:
        value = execute_full_index(args.root, args.timeout)
    else:
        value, _ = cached_full_index(args.root, args.cache_root, args.timeout)
    output = canonical_json(value)
    if args.out:
        Path(args.out).write_bytes(output)
    else:
        print(output.decode())
    return 0


def _route(args: argparse.Namespace) -> int:
    envelope = load_full_index_envelope(Path(args.envelope).read_bytes())
    policy = _json(args.policy) if args.policy else export_context_value("graphRoutingPolicy", args.root)
    admit_context_value(policy, "#GraphRoutingPolicy", args.root)
    value = derive_route_packet(args.query, envelope, policy)
    admit_context_value(value, "#GraphRoutePacket", args.root)
    output = canonical_json(value)
    if args.out:
        Path(args.out).write_bytes(output)
    else:
        print(output.decode())
    return 0


def _materialize(args: argparse.Namespace) -> int:
    envelope = load_full_index_envelope(Path(args.envelope).read_bytes())
    route_packet = _json(args.route_packet)
    admit_context_value(route_packet, "#GraphRoutePacket", args.root)
    budget = _json(args.budget) if args.budget else None
    if args.no_cache:
        value = materialize_context(route_packet, envelope, budget)
    else:
        provenance = envelope["provenance"]
        key = cache_key(
            "projection",
            provenance["repositoryRevision"],
            {"routePacket": route_packet, "budget": budget},
            provenance["tools"],
        )
        value, _ = ArtifactCache(args.cache_root).get_or_compute(
            "projection", key, lambda: materialize_context(route_packet, envelope, budget)
        )
        validate_materialized_context(value, route_packet, envelope)
    admit_context_value(value, "#MaterializedContextPacket", args.root)
    output = canonical_json(value)
    if args.out:
        Path(args.out).write_bytes(output)
    else:
        print(output.decode())
    return 0


def _mcp_read(args: argparse.Namespace) -> int:
    resources = MCPResources(load_full_index_envelope(Path(args.envelope).read_bytes()), args.root)
    payload = _json(args.payload) if args.payload else None
    print(canonical_json(resources.read(args.uri, payload)).decode())
    return 0


def _diagnose(args: argparse.Namespace) -> int:
    envelope = load_full_index_envelope(Path(args.envelope).read_bytes()) if args.envelope else None
    report, artifacts = run_diagnostics(
        args.root,
        sections=set(args.section or []),
        checks=set(args.check or []),
        envelope=envelope,
    )
    if args.bundle:
        write_review_bundle(args.bundle, report, artifacts, args.root)
    if args.format == "json":
        print(canonical_json(report).decode())
    else:
        summary = report["summary"]
        print(f"{summary['status']}: {summary['counts']['pass']}/{summary['counts']['total']} checks passed")
        for item in report["checks"]:
            print(f"{item['status']:>13}  {item['checkId']}")
    return 0 if report["summary"]["status"] == "pass" else 1


def _hook(args: argparse.Namespace) -> int:
    if (args.provider, args.event_name, args.out, args.mode) != (
        "codex",
        "user-prompt-submit",
        "codex-hook-json",
        "route-packet",
    ):
        raise ValueError("unsupported hook operation")
    envelope = load_full_index_envelope(Path(args.envelope).read_bytes()) if args.envelope else None
    print(
        json.dumps(
            emit_route_hook(
                args.event,
                args.root,
                kb=args.kb,
                vocab=args.vocab,
                envelope=envelope,
            ),
            sort_keys=True,
            separators=(",", ":"),
        )
    )
    return 0


def _audit_hook(args: argparse.Namespace) -> int:
    envelope = load_full_index_envelope(Path(args.envelope).read_bytes())
    audit = build_hook_audit(
        event={"hook_event_name": "UserPromptSubmit", "prompt": args.prompt},
        envelope=envelope,
        root=args.root,
    )
    Path(args.out).write_bytes(canonical_json(audit["auditPacket"]))
    if args.context_out:
        Path(args.context_out).write_bytes(canonical_json(audit["promptContext"]))
    return 0


def _workbench(args: argparse.Namespace) -> int:
    if args.headless_smoke_test:
        try:
            from .marimo.app import smoke_test
        except ModuleNotFoundError as exc:
            if exc.name == "marimo":
                raise RuntimeError("workbench support requires lattice[workbench]") from exc
            raise
        smoke_test()
        return 0
    try:
        from .marimo.app import main as workbench_main
    except ModuleNotFoundError as exc:
        if exc.name == "marimo":
            raise RuntimeError("workbench support requires lattice[workbench]") from exc
        raise
    return workbench_main()


def _add_snapshot_commands(subparsers: argparse._SubParsersAction[argparse.ArgumentParser]) -> None:
    snapshot = subparsers.add_parser("snapshot")
    commands = snapshot.add_subparsers(dest="snapshot_command", required=True)
    for name, handler in (("validate", _snapshot_validate), ("inspect", _snapshot_inspect)):
        command = commands.add_parser(name)
        command.add_argument("--snapshot", required=True)
        command.set_defaults(handler=handler)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="lattice")
    commands = parser.add_subparsers(dest="command", required=True)
    _add_snapshot_commands(commands)
    index = commands.add_parser("index")
    index_commands = index.add_subparsers(dest="index_command", required=True)
    index_validate = index_commands.add_parser("validate")
    index_validate.add_argument("--envelope", required=True)
    index_validate.set_defaults(handler=_index_validate)
    index_build = index_commands.add_parser("build")
    index_build.add_argument("--root", default=".")
    index_build.add_argument("--timeout", type=float, default=20.0)
    index_build.add_argument("--cache-root", default=".cache/lattice")
    index_build.add_argument("--no-cache", action="store_true")
    index_build.add_argument("--out")
    index_build.set_defaults(handler=_index_build)
    diagnostics = commands.add_parser("diagnostics")
    diagnostics_commands = diagnostics.add_subparsers(dest="diagnostics_command", required=True)
    runtime_surface = diagnostics_commands.add_parser("runtime-surface")
    runtime_surface.add_argument("--root", default=".")
    runtime_surface.set_defaults(handler=_runtime_surface)
    diagnose = commands.add_parser("diagnose")
    diagnose.add_argument("--root", default=".")
    diagnose.add_argument("--section", action="append")
    diagnose.add_argument("--check", action="append")
    diagnose.add_argument("--format", choices=("text", "json"), default="text")
    diagnose.add_argument("--bundle")
    diagnose.add_argument("--envelope")
    diagnose.set_defaults(handler=_diagnose)
    audit = commands.add_parser("audit")
    audit_commands = audit.add_subparsers(dest="audit_command", required=True)
    audit_hook = audit_commands.add_parser("hook")
    audit_hook.add_argument("--envelope", required=True)
    audit_hook.add_argument("--prompt", required=True)
    audit_hook.add_argument("--out", required=True)
    audit_hook.add_argument("--context-out")
    audit_hook.add_argument("--root", default=".")
    audit_hook.set_defaults(handler=_audit_hook)
    route = commands.add_parser("route")
    route.add_argument("--envelope", required=True)
    route.add_argument("--query", required=True)
    route.add_argument("--policy")
    route.add_argument("--root", default=".")
    route.add_argument("--out")
    route.set_defaults(handler=_route)
    materialize = commands.add_parser("materialize")
    materialize.add_argument("--envelope", required=True)
    materialize.add_argument("--route-packet", required=True)
    materialize.add_argument("--budget")
    materialize.add_argument("--cache-root", default=".cache/lattice")
    materialize.add_argument("--root", default=".")
    materialize.add_argument("--no-cache", action="store_true")
    materialize.add_argument("--out")
    materialize.set_defaults(handler=_materialize)
    mcp = commands.add_parser("mcp")
    mcp_commands = mcp.add_subparsers(dest="mcp_command", required=True)
    mcp_read = mcp_commands.add_parser("read")
    mcp_read.add_argument("uri")
    mcp_read.add_argument("--envelope", required=True)
    mcp_read.add_argument("--payload")
    mcp_read.add_argument("--root", default=".")
    mcp_read.set_defaults(handler=_mcp_read)
    hook = commands.add_parser("hook")
    hook.add_argument("provider")
    hook.add_argument("event_name")
    hook.add_argument("--event", required=True)
    hook.add_argument("--kb")
    hook.add_argument("--vocab")
    hook.add_argument("--envelope")
    hook.add_argument("--out", required=True)
    hook.add_argument("--mode", required=True)
    hook.add_argument("--root", default=".")
    hook.set_defaults(handler=_hook)
    for name, handler in (("resolve", _resolve), ("compose", _compose)):
        command = commands.add_parser(name)
        command.add_argument("--snapshot", required=True)
        command.add_argument("--request", required=True)
        if name == "compose":
            command.add_argument("--packet-out", required=True)
            command.add_argument("--trace-out")
        command.set_defaults(handler=handler)
    profile = commands.add_parser("profile")
    profile_commands = profile.add_subparsers(dest="profile_command", required=True)
    for name, handler in (("list", _profile_list), ("validate", _profile_validate)):
        profile_commands.add_parser(name).set_defaults(handler=handler)
    show = profile_commands.add_parser("show")
    show.add_argument("profile")
    show.set_defaults(handler=_profile_show)
    workbench = commands.add_parser("workbench")
    workbench.add_argument("--headless-smoke-test", action="store_true")
    workbench.set_defaults(handler=_workbench)
    try:
        args = parser.parse_args(argv)
        return args.handler(args)
    except (FullIndexError, OSError, ValueError) as exc:
        parser.error(str(exc))
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
