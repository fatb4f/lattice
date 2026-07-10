"""Closed command-line surface for the installed engine."""

from __future__ import annotations

import argparse
import json
from importlib.resources import files
from pathlib import Path
from typing import Any

from .composition.engine import compose
from .contracts.models import ComposeRequest
from .profiles import load_manifest
from .registry.loader import load_snapshot


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
            print(files("lattice_kg.profiles").joinpath(profile["resource"]).read_text(encoding="utf-8"), end="")
            return 0
    raise ValueError(f"unknown profile: {args.profile}")


def _profile_validate(_: argparse.Namespace) -> int:
    load_manifest()
    return 0


def _workbench(args: argparse.Namespace) -> int:
    if args.headless_smoke_test:
        try:
            from .workbench.app import smoke_test
        except ModuleNotFoundError as exc:
            if exc.name == "marimo":
                raise RuntimeError("workbench support requires lattice-kg[workbench]") from exc
            raise
        smoke_test()
        return 0
    try:
        from .workbench.app import main as workbench_main
    except ModuleNotFoundError as exc:
        if exc.name == "marimo":
            raise RuntimeError("workbench support requires lattice-kg[workbench]") from exc
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
    parser = argparse.ArgumentParser(prog="kg")
    commands = parser.add_subparsers(dest="command", required=True)
    _add_snapshot_commands(commands)
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
    except (OSError, ValueError) as exc:
        parser.error(str(exc))
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
