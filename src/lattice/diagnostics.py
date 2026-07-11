"""Evidence-bearing, read-only subsystem diagnostics and review bundles."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import tomllib
from collections.abc import Callable, Mapping
from contextlib import suppress
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

from lattice.adapters.cue import admit_context_value, export_context_value
from lattice.adapters.full_index import FullIndexError, load_full_index_envelope
from lattice.adapters.hook import build_hook_audit, verify_prompt_context_audit
from lattice.adapters.kg import execute_full_index, full_index_provenance, resolve_external_kg
from lattice.adapters.mcp import MCPResources
from lattice.adapters.runtime_surface import runtime_surface_violations
from lattice.marimo.diagnostics import render_workbook
from lattice.rag.materialization import materialize_context
from lattice.rag.provenance import canonical_json, sha256_digest
from lattice.rag.routing import derive_route_packet

STATUS = frozenset({"pass", "fail", "skipped", "unsupported", "indeterminate"})


class DiagnosticState(RuntimeError):
    def __init__(self, status: str, code: str, message: str) -> None:
        super().__init__(message)
        if status not in STATUS or status == "pass":
            raise ValueError("diagnostic state must be non-passing")
        self.status = status
        self.code = code


def _timestamp(value: datetime | None = None) -> str:
    return (value or datetime.now(UTC)).replace(microsecond=0).strftime("%Y-%m-%dT%H:%M:%SZ")


def _command(root: Path, args: list[str], timeout: float = 20.0) -> str:
    completed = subprocess.run(args, cwd=root, check=True, capture_output=True, text=True, timeout=timeout)
    return completed.stdout.strip() or "command completed successfully"


def _result(
    check_id: str,
    subsystem: str,
    operation: str,
    revision: str,
    tools: Mapping[str, Any],
    inputs: Mapping[str, Any],
    runner: Callable[[], Any],
    remediation: str,
    *,
    severity: str = "error",
    blocking: bool = True,
) -> tuple[dict[str, Any], Any | None]:
    started = datetime.now(UTC).replace(microsecond=0)
    value: Any | None = None
    diagnostics: list[dict[str, str]] = []
    try:
        value = runner()
        status = "pass"
        message = "Check completed successfully."
    except DiagnosticState as exc:
        status = exc.status
        message = str(exc)
        diagnostics.append({"code": exc.code, "message": message})
    except FileNotFoundError as exc:
        status = "unsupported"
        message = str(exc)
        diagnostics.append({"code": "checker-unsupported", "message": message})
    except subprocess.TimeoutExpired as exc:
        status = "indeterminate"
        message = str(exc)
        diagnostics.append({"code": "checker-timeout", "message": message})
    except (FullIndexError, OSError, ValueError, subprocess.SubprocessError) as exc:
        status = "unsupported" if getattr(exc, "code", "") == "kg_index_toolchain_unsupported" else "fail"
        message = str(exc)
        diagnostics.append({"code": getattr(exc, "code", "check-failed"), "message": message})
    completed = datetime.now(UTC).replace(microsecond=0)
    normalized_inputs = {"digest": sha256_digest(inputs), "value": inputs}
    evidence_record = {
        "checker": f"lattice.diagnostics.{check_id}",
        "operation": operation,
        "repositoryRevision": revision,
        "toolVersions": dict(tools),
        "normalizedInputs": normalized_inputs,
        "result": message,
        "status": status,
    }
    evidence_digest = sha256_digest(evidence_record)
    result = {
        "schema": "lattice.diagnostic-check-result.v1",
        "checkId": check_id,
        "subsystem": subsystem,
        "status": status,
        "severity": severity,
        "blocking": blocking,
        "checker": evidence_record["checker"],
        "operation": operation,
        "repositoryRevision": revision,
        "toolVersions": dict(tools),
        "normalizedInputs": normalized_inputs,
        "evidence": [
            {
                "ref": f"inline:{evidence_digest}",
                "digest": evidence_digest,
                "observedAt": _timestamp(completed),
                "expiresAt": _timestamp(completed + timedelta(minutes=5)),
                "record": evidence_record,
            }
        ],
        "diagnostics": diagnostics,
        "remediation": "" if status == "pass" else remediation,
        "startedAt": _timestamp(started),
        "completedAt": _timestamp(completed),
        "evaluatedAt": _timestamp(completed),
    }
    return result, value


def run_diagnostics(
    root: str | Path = ".",
    *,
    sections: set[str] | None = None,
    checks: set[str] | None = None,
    envelope: Mapping[str, Any] | None = None,
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Evaluate diagnostics without writing caches, bundles, or authority."""
    repo = Path(root).resolve()
    check_catalog = {
        "runtime-surface": "package-boundary",
        "package-health": "package-boundary",
        "kg-vet": "graph",
        "kg-settle": "graph",
        "full-index": "index",
        "hook-registration": "hooks",
        "prompt-event-normalization": "hooks",
        "transient-output-boundaries": "hooks",
        "forbidden-runtime-inputs": "hooks",
        "vocabulary-authority": "authority",
        "cache-isolation": "cache",
        "graph-routing": "routing",
        "context-materialization": "context",
        "generic-mcp": "mcp",
        "projection-jsonld": "projections",
        "evidence-freshness": "evidence",
        "declared-installed-drift": "drift",
        "registry-index-integrity": "registry",
    }
    unknown_checks = sorted((checks or set()) - set(check_catalog))
    unknown_sections = sorted((sections or set()) - set(check_catalog.values()))
    if unknown_checks:
        raise ValueError(f"unknown diagnostic check: {', '.join(unknown_checks)}")
    if unknown_sections:
        raise ValueError(f"unknown diagnostic section: {', '.join(unknown_sections)}")
    selected = {
        check_id
        for check_id, subsystem in check_catalog.items()
        if (not sections or subsystem in sections) and (not checks or check_id in checks)
    }
    revision = _command(repo, ["git", "rev-parse", "HEAD"])
    index_checks = {
        "full-index",
        "graph-routing",
        "context-materialization",
        "generic-mcp",
        "projection-jsonld",
        "declared-installed-drift",
        "registry-index-integrity",
    }
    hook_checks = {
        "prompt-event-normalization",
        "transient-output-boundaries",
        "forbidden-runtime-inputs",
    }
    kg_checks = {"kg-vet", "kg-settle"} | index_checks | hook_checks
    kg_path: Path | None = None
    kg_error: FullIndexError | None = None
    if selected & kg_checks:
        try:
            kg_path = resolve_external_kg(repo)
        except FullIndexError as exc:
            kg_error = exc
    admitted_envelope = load_full_index_envelope(envelope) if envelope is not None else None
    index_error: FullIndexError | None = kg_error
    if admitted_envelope is not None:
        revision = admitted_envelope["provenance"]["repositoryRevision"]
    elif selected & (index_checks | hook_checks) and kg_path is not None:
        try:
            admitted_envelope = execute_full_index(repo, kg=kg_path)
            revision = admitted_envelope["provenance"]["repositoryRevision"]
        except FullIndexError as exc:
            index_error = exc
    tools: dict[str, Any] = (
        dict(admitted_envelope["provenance"]["tools"])
        if admitted_envelope
        else ({"kgPath": str(kg_path)} if kg_path else {})
    )

    def require_kg() -> Path:
        if kg_path is None:
            raise DiagnosticState(
                "unsupported",
                kg_error.code if kg_error else "kg-index-toolchain-unsupported",
                str(kg_error or "The external kg CLI is unavailable"),
            )
        return kg_path

    def require_envelope() -> dict[str, Any]:
        if admitted_envelope is None:
            status = (
                "unsupported"
                if index_error and index_error.code == "kg_index_toolchain_unsupported"
                else "indeterminate"
            )
            raise DiagnosticState(status, index_error.code if index_error else "kg-index-unavailable", str(index_error))
        return admitted_envelope

    hook_audit: dict[str, Any] | None = None

    def require_hook_audit() -> dict[str, Any]:
        nonlocal hook_audit
        if hook_audit is None:
            hook_audit = _execute_hook_probe(repo, require_envelope())
        return hook_audit

    definitions: list[tuple[str, str, str, Callable[[], Any], str]] = [
        (
            "runtime-surface",
            "package-boundary",
            "validate admitted runtime placement",
            lambda: (
                (_ for _ in ()).throw(ValueError("; ".join(runtime_surface_violations(repo))))
                if runtime_surface_violations(repo)
                else {"violations": []}
            ),
            "Move executable runtime code under src/lattice and generated artifacts outside package source.",
        ),
        (
            "package-health",
            "package-boundary",
            "validate uv lock and installed package boundary",
            lambda: _check_package_health(repo),
            "Repair the uv lock or the src/lattice package declaration.",
        ),
        (
            "kg-vet",
            "graph",
            "kg vet",
            lambda: _command(repo, [str(require_kg()), "vet"]),
            "Repair invalid .kb entries.",
        ),
        (
            "kg-settle",
            "graph",
            "kg settle",
            lambda: _command(repo, [str(require_kg()), "settle"]),
            "Repair dangling KG links.",
        ),
        (
            "full-index",
            "index",
            "execute validated full index",
            require_envelope,
            "Restore the supported kg/CUE toolchain and full-index provenance.",
        ),
        (
            "hook-registration",
            "hooks",
            "inspect hook dispatch surfaces",
            lambda: _check_hooks(repo),
            "Restore thin registered hook wrappers.",
        ),
        (
            "prompt-event-normalization",
            "hooks",
            "build a representative offline prompt audit",
            require_hook_audit,
            "Repair prompt normalization or the offline audit builder.",
        ),
        (
            "transient-output-boundaries",
            "hooks",
            "verify transient audit output boundaries",
            lambda: _check_hook_gate(require_hook_audit(), "transient-projection"),
            "Keep audit intermediates transient and write artifacts only to explicit outputs.",
        ),
        (
            "forbidden-runtime-inputs",
            "hooks",
            "reject generated, plugin-cache, and transcript audit inputs",
            lambda: _check_forbidden_hook_inputs(require_hook_audit()),
            "Remove forbidden generated, plugin-cache, or transcript inputs from the audit manifest.",
        ),
        (
            "vocabulary-authority",
            "authority",
            "inspect vocabulary authority",
            lambda: _check_vocab(repo),
            "Restore the upstream KG vocabulary mapping.",
        ),
        (
            "cache-isolation",
            "cache",
            "inspect cache boundaries",
            lambda: _check_cache(repo),
            "Move caches outside src/lattice, .kb, and .kg.",
        ),
        (
            "registry-index-integrity",
            "registry",
            "validate command, hook, and KG index registries",
            lambda: _check_registry_index(repo, require_envelope()),
            "Repair pyproject commands, Codex hook registration, or the KG index aggregate.",
        ),
    ]
    results: list[dict[str, Any]] = []
    artifacts: dict[str, Any] = {}
    for check_id, subsystem, operation, runner, remediation in definitions:
        if sections and subsystem not in sections or checks and check_id not in checks:
            continue
        result, value = _result(
            check_id, subsystem, operation, revision, tools, {"root": str(repo)}, runner, remediation
        )
        results.append(result)
        if value is not None:
            artifacts[check_id] = value
    route: dict[str, Any] | None = None

    def route_check() -> dict[str, Any]:
        nonlocal route
        admitted = require_envelope()
        policy = export_context_value("graphRoutingPolicy", repo)
        admit_context_value(policy, "#GraphRoutingPolicy", repo)
        route = derive_route_packet("project knowledge graph context", admitted, policy)
        admit_context_value(route, "#GraphRoutePacket", repo)
        return route

    def context_check() -> dict[str, Any]:
        nonlocal route
        admitted = require_envelope()
        if route is None:
            route_check()
        assert route is not None
        packet = materialize_context(route, admitted)
        admit_context_value(packet, "#MaterializedContextPacket", repo)
        return packet

    def mcp_check() -> dict[str, Any]:
        return MCPResources(require_envelope(), repo).read("kg://graph/inventory")

    def evidence_check() -> dict[str, Any]:
        evaluated = datetime.now(UTC).replace(microsecond=0)
        verified: list[str] = []
        for item in results:
            for evidence in item["evidence"]:
                if evidence["digest"] != sha256_digest(evidence["record"]):
                    raise ValueError(f"diagnostic evidence digest mismatch: {item['checkId']}")
                observed = datetime.fromisoformat(evidence["observedAt"].replace("Z", "+00:00"))
                expires = datetime.fromisoformat(evidence["expiresAt"].replace("Z", "+00:00"))
                if not observed <= evaluated < expires:
                    raise ValueError(f"diagnostic evidence is stale: {item['checkId']}")
                verified.append(evidence["digest"])
        if not verified:
            raise DiagnosticState("indeterminate", "evidence-missing", "No diagnostic evidence was available")
        return {"verified": verified}

    def toolchain_check() -> dict[str, Any]:
        admitted = require_envelope()
        _, observed = full_index_provenance(repo, kg=require_kg())
        current = {"kg": observed["kgVersion"], "cue": observed["cueVersion"]}
        if current != admitted["provenance"]["tools"]:
            raise ValueError("declared and installed tool identities differ")
        if observed["policyDigest"] != admitted["provenance"]["policyDigest"]:
            raise ValueError("declared and installed policy identities differ")
        return {
            "recorded": admitted["provenance"]["tools"],
            "observed": current,
            "policyDigest": observed["policyDigest"],
        }

    dynamic = [
        (
            "graph-routing",
            "routing",
            "derive routing candidates",
            route_check,
            "Inspect graph metadata and exported routing policy.",
        ),
        (
            "context-materialization",
            "context",
            "materialize bounded JSON-LD",
            context_check,
            "Repair projection closure or reduce the requested budget.",
        ),
        (
            "generic-mcp",
            "mcp",
            "read generic MCP inventory",
            mcp_check,
            "Repair generic MCP resource dispatch.",
        ),
        (
            "projection-jsonld",
            "projections",
            "validate JSON-LD projection",
            context_check,
            "Repair JSON-LD mapping or graph closure.",
        ),
        (
            "evidence-freshness",
            "evidence",
            "validate diagnostic evidence emission",
            evidence_check,
            "Re-run stale or missing check evidence.",
        ),
        (
            "declared-installed-drift",
            "drift",
            "compare declared and installed toolchain",
            toolchain_check,
            "Install the declared locked toolchain.",
        ),
    ]
    for check_id, subsystem, operation, runner, remediation in dynamic:
        if sections and subsystem not in sections or checks and check_id not in checks:
            continue
        result, value = _result(
            check_id,
            subsystem,
            operation,
            revision,
            tools,
            {"index": admitted_envelope["provenance"] if admitted_envelope else {"unavailable": str(index_error)}},
            runner,
            remediation,
        )
        results.append(result)
        if value is not None:
            artifacts[check_id] = value
    passing = sum(item["status"] == "pass" for item in results)
    summary = {
        "schema": "lattice.diagnostics-summary.v1",
        "repositoryRevision": revision,
        "status": "pass" if passing == len(results) else "fail",
        "counts": {"total": len(results), "pass": passing, "nonPassing": len(results) - passing},
        "evaluatedAt": _timestamp(),
    }
    report = {"summary": summary, "checks": results}
    _admit_diagnostic_value(repo, report, "#DiagnosticsReport")
    return report, artifacts


def _check_hooks(root: Path) -> dict[str, Any]:
    required = [
        root / ".kg" / "hooks" / "codex" / "user-prompt-submit",
        root / "src" / "lattice" / "adapters" / "codex_hook.sh",
        root / ".kg" / "tools" / "kg",
        root / ".codex" / "hooks.json",
    ]
    missing = [str(path.relative_to(root)) for path in required if not path.is_file()]
    if missing:
        raise ValueError(f"missing hook surfaces: {', '.join(missing)}")
    registration = json.loads((root / ".codex" / "hooks.json").read_text(encoding="utf-8"))
    registered_hooks = registration.get("hooks", {})
    prompt_hooks = registered_hooks.get("UserPromptSubmit", [])
    prompt_commands = [
        hook.get("command", "")
        for group in prompt_hooks
        for hook in group.get("hooks", [])
        if isinstance(hook, Mapping)
    ]
    expected = ".kg/hooks/codex/user-prompt-submit"
    if len(prompt_commands) != 1 or expected not in prompt_commands[0]:
        raise ValueError("Codex UserPromptSubmit must register only the compact KG context hook")
    all_commands = [
        hook.get("command", "")
        for groups in registered_hooks.values()
        for group in groups
        for hook in group.get("hooks", [])
        if isinstance(hook, Mapping)
    ]
    if any(".kg/codex/tools/drift-hook" in command for command in all_commands):
        raise ValueError("Codex drift inspection must remain offline")
    diagnostic_markers = ("lattice diagnose", "lattice diagnostics", ".kg/context diagnose", "audit hook")
    if any(marker in command for command in all_commands for marker in diagnostic_markers):
        raise ValueError("offline diagnostics must not be registered as Codex hooks")
    if len(all_commands) != 1:
        raise ValueError("Codex must register exactly one hook command")
    if not os.access(required[0], os.X_OK):
        raise ValueError("Codex UserPromptSubmit wrapper is not executable")
    return {
        "registered": [str(path.relative_to(root)) for path in required],
        "userPromptSubmitCommands": prompt_commands,
    }


def _execute_hook_probe(root: Path, envelope: Mapping[str, Any]) -> dict[str, Any]:
    event = {
        "hook_event_name": "UserPromptSubmit",
        "prompt": "ADR-002 kg maintenance prompt normalization probe",
    }
    audit = build_hook_audit(event=event, envelope=envelope, root=root)
    prompt_context = audit["promptContext"]
    packet = audit["auditPacket"]
    admit_context_value(prompt_context, "#CodexPromptContext", root)
    projection = export_context_value("#RoutePolicyProjection", root)
    if len(canonical_json(prompt_context)) > projection["budget"]["routePacketMaxBytes"]:
        raise ValueError("Codex prompt context exceeds the exported inline budget")
    verify_prompt_context_audit(
        prompt_context,
        packet,
        audit_artifact=audit["auditArtifact"],
        gate_summary=audit["gateSummary"],
    )
    admit_context_value(packet, "#RoutePolicyBoundPacket", root)
    admit_context_value(audit, "#AuditBoundCodexPromptContext", root)
    included = [item["entityId"] for item in packet["candidates"] if item["disposition"] == "included"]
    if included != packet["selection"]["entities"]:
        raise ValueError("offline audit candidate explanations contradict the final selection")
    if any(gate["status"] != "pass" for gate in packet["gates"].values()):
        raise ValueError("offline audit emitted a non-passing gate")
    return audit


def _check_hook_gate(audit: Mapping[str, Any], gate_id: str) -> dict[str, Any]:
    packet = audit["auditPacket"]
    gate = packet["gates"].get(gate_id)
    if not isinstance(gate, Mapping) or gate.get("status") != "pass":
        raise ValueError(f"offline audit gate did not pass: {gate_id}")
    outputs = gate["evidence"][0]["record"]["inputManifest"]["outputs"]
    forbidden_roots = (".kb/", ".kg/", "src/lattice/", "generated/")
    if any(str(item["path"]).startswith(forbidden_roots) for item in outputs):
        raise ValueError("offline audit wrote a transient output into a source or authority boundary")
    return {"gate": gate_id, "status": "pass", "auditArtifact": audit["auditArtifact"]}


def _check_forbidden_hook_inputs(audit: Mapping[str, Any]) -> dict[str, Any]:
    packet = audit["auditPacket"]
    required = {"no-generated-input", "no-plugin-cache-input", "no-raw-transcript-input"}
    if any(packet["gates"].get(gate_id, {}).get("status") != "pass" for gate_id in required):
        raise ValueError("a forbidden audit-input gate did not pass")
    manifests = [gate["evidence"][0]["record"]["inputManifest"] for gate in packet["gates"].values()]
    inputs = [item for manifest in manifests for item in manifest["inputs"]]
    forbidden = ("/generated/", "/plugins/cache/", "raw-transcript")
    if any(any(marker in f"{item['role']}:{item['path']}" for marker in forbidden) for item in inputs):
        raise ValueError("forbidden generated, plugin-cache, or transcript input reached the audit manifest")
    return {"gates": sorted(required), "inputRoles": sorted({item["role"] for item in inputs})}


def _check_package_health(root: Path) -> dict[str, Any]:
    _command(root, ["uv", "lock", "--check"])
    project = tomllib.loads((root / "pyproject.toml").read_text(encoding="utf-8"))
    if project.get("project", {}).get("name") != "lattice":
        raise ValueError("pyproject does not declare the lattice package")
    if not (root / "src" / "lattice" / "__init__.py").is_file():
        raise ValueError("src/lattice package boundary is incomplete")
    return {"lock": "uv.lock", "packageRoot": "src/lattice", "status": "locked"}


def _check_registry_index(root: Path, envelope: Mapping[str, Any]) -> dict[str, Any]:
    project = tomllib.loads((root / "pyproject.toml").read_text(encoding="utf-8"))
    scripts = project.get("project", {}).get("scripts", {})
    required_scripts = {"lattice", "lattice-mcp"}
    if not required_scripts <= set(scripts):
        raise ValueError("pyproject command registry is incomplete")
    _check_hooks(root)
    if not (root / ".kb" / "index.cue").is_file():
        raise ValueError("KG index aggregate is missing")
    graph = envelope["graph"]
    declared = graph.get("summary", {}).get("total")
    counted = sum(record.get("collection") != "context" for record in graph["entities"].values())
    if declared != counted:
        raise ValueError("KG index aggregate count does not match its entity registry")
    return {"commands": sorted(required_scripts), "entities": counted, "index": ".kb/index.cue"}


def _check_vocab(root: Path) -> dict[str, str]:
    path = root / ".kb" / "cue.mod" / "pkg" / "quicue.ca" / "kg" / "vocab" / "context.cue"
    if not path.is_file():
        raise ValueError("upstream vocabulary authority is missing")
    return {"path": str(path.relative_to(root))}


def _check_cache(root: Path) -> dict[str, Any]:
    forbidden = [root / "src" / "lattice" / ".cache", root / ".kb" / ".cache", root / ".kg" / ".cache"]
    present = [str(path.relative_to(root)) for path in forbidden if path.exists()]
    if present:
        raise ValueError(f"runtime cache crossed an authority boundary: {', '.join(present)}")
    return {"cacheRoot": ".cache/lattice", "isolated": True}


def _admit_diagnostic_value(root: Path, value: Mapping[str, Any], selector: str) -> None:
    descriptor, name = tempfile.mkstemp(prefix="lattice-diagnostic-admission-", suffix=".json")
    try:
        with os.fdopen(descriptor, "wb") as output:
            output.write(canonical_json(value))
        try:
            subprocess.run(
                [
                    os.environ.get("CUE_BIN", "cue"),
                    "vet",
                    str(root / ".kg" / "diagnostics" / "schema.cue"),
                    name,
                    "-d",
                    selector,
                ],
                cwd=root,
                check=True,
                capture_output=True,
                text=True,
                timeout=20,
            )
        except (OSError, subprocess.SubprocessError) as exc:
            detail = getattr(exc, "stderr", None) or getattr(exc, "stdout", None) or str(exc)
            raise ValueError(f"CUE rejected {selector}: {detail.strip()}") from exc
    finally:
        with suppress(FileNotFoundError):
            os.unlink(name)


def write_review_bundle(
    target: str | Path,
    report: Mapping[str, Any],
    artifacts: Mapping[str, Any],
    root: str | Path = ".",
) -> Path:
    destination = Path(target).resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = Path(tempfile.mkdtemp(prefix=f".{destination.name}.", dir=destination.parent))
    try:
        (temporary / "evidence").mkdir()
        (temporary / "packets").mkdir()
        (temporary / "projections").mkdir()
        (temporary / "logs").mkdir()
        summary = report["summary"]
        (temporary / "summary.json").write_bytes(canonical_json(summary))
        (temporary / "checks.json").write_bytes(canonical_json(report["checks"]))
        for item in report["checks"]:
            (temporary / "evidence" / f"{item['checkId']}.json").write_bytes(canonical_json(item["evidence"]))
        for name in ("graph-routing", "context-materialization"):
            if name in artifacts:
                directory = "packets" if name == "graph-routing" else "projections"
                (temporary / directory / f"{name}.json").write_bytes(canonical_json(artifacts[name]))
        if "prompt-event-normalization" in artifacts:
            hook = artifacts["prompt-event-normalization"]
            (temporary / "packets" / "hook-prompt-context.json").write_bytes(canonical_json(hook["promptContext"]))
            (temporary / "packets" / "hook-audit.json").write_bytes(canonical_json(hook["auditPacket"]))
            (temporary / "packets" / "hook-audit-binding.json").write_bytes(canonical_json(hook))
        bounded_log = "\n".join(
            f"{item['status']} {item['checkId']} {item['operation']}" for item in report["checks"][:256]
        )
        (temporary / "logs" / "diagnostics.log").write_text(bounded_log + "\n", encoding="utf-8")
        workbook = render_workbook(summary, list(report["checks"]))
        (temporary / "workbook.html").write_text(workbook, encoding="utf-8")
        canonical_files = ["checks.json", "logs/diagnostics.log", "summary.json", "workbook.html"]
        discovered = {path.relative_to(temporary).as_posix() for path in temporary.rglob("*") if path.is_file()}
        files = canonical_files + sorted(discovered - set(canonical_files))
        manifest = {
            "schema": "lattice.diagnostics-review-bundle.v1",
            "repositoryRevision": summary["repositoryRevision"],
            "summaryDigest": sha256_digest(summary),
            "files": files,
        }
        _admit_diagnostic_value(Path(root).resolve(), manifest, "#ReviewBundleManifest")
        (temporary / "manifest.json").write_bytes(canonical_json(manifest))
        if destination.exists():
            shutil.rmtree(destination)
        os.replace(temporary, destination)
    finally:
        if temporary.exists():
            shutil.rmtree(temporary)
    return destination
