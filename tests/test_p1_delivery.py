from __future__ import annotations

import asyncio
import json
import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path
from typing import Any

import pytest

import lattice.adapters.hook as hook_module
import lattice.adapters.mcp as mcp_module
import lattice.diagnostics as diagnostics_module
from lattice.adapters.cue import admit_context_value
from lattice.adapters.full_index import FullIndexError, normalize_full_index
from lattice.adapters.hook import (
    build_hook_audit,
    derive_codex_prompt_context,
    emit_route_hook,
    verify_prompt_context_audit,
)
from lattice.adapters.kg import resolve_external_kg
from lattice.adapters.mcp import AsyncMCPResources, MCPResources, create_mcp_server
from lattice.diagnostics import run_diagnostics, write_review_bundle
from lattice.rag.cache import ArtifactCache, BoundedExecutor, cache_key
from lattice.rag.materialization import materialize_context
from lattice.rag.provenance import sha256_digest
from lattice.rag.routing import derive_route_packet, routing_policy_with_budgets, validate_graph_route_packet

ROOT = Path(__file__).parents[1]
FIXTURES = ROOT / "tests" / "fixtures" / "full_index"


def _record_process_and_sleep(started: str, completed: str, duration: float) -> None:
    Path(started).write_text(str(os.getpid()), encoding="utf-8")
    time.sleep(duration)
    Path(completed).write_text("completed", encoding="utf-8")


def envelope() -> dict[str, Any]:
    return normalize_full_index(
        (FIXTURES / "graph.json").read_text(encoding="utf-8"),
        json.loads((FIXTURES / "provenance.json").read_text(encoding="utf-8")),
    )


def graph_policy(**budgets: int) -> dict[str, Any]:
    output = subprocess.run(
        ["cue", "export", str(ROOT / ".kg" / "context"), "-e", "graphRoutingPolicy", "--out", "json"],
        check=True,
        capture_output=True,
        text=True,
    )
    policy = json.loads(output.stdout)
    return routing_policy_with_budgets(
        policy,
        max_candidates=budgets.get("maxCandidates"),
        max_entities=budgets.get("maxEntities"),
        max_resources=budgets.get("maxResources"),
    )


def test_graph_derived_route_is_stable_and_explained() -> None:
    policy = graph_policy(maxEntities=1, maxCandidates=2)
    first = derive_route_packet("inspect one decision", envelope(), policy)
    second = derive_route_packet("inspect one decision", envelope(), policy)
    assert first == second
    assert first["requestId"] == second["requestId"]
    assert first["selection"]["entities"] == ["one"]
    assert {item["disposition"] for item in first["candidates"]} == {"included", "down-ranked"}
    assert all(item["reasons"] for item in first["candidates"])
    with tempfile.NamedTemporaryFile("w", suffix=".json") as value:
        json.dump(first, value)
        value.flush()
        subprocess.run(
            [
                "cue",
                "vet",
                *(str(path) for path in sorted((ROOT / ".kg" / "context").glob("*.cue"))),
                value.name,
                "-d",
                "#GraphRoutePacket",
            ],
            check=True,
            capture_output=True,
            text=True,
        )


def test_graph_route_policy_and_packet_budgets_are_enforced() -> None:
    with pytest.raises(ValueError, match="exceeds its CUE-exported ceiling"):
        graph_policy(maxCandidates=129)

    policy = graph_policy(maxCandidates=1, maxEntities=1, maxResources=1)
    packet = derive_route_packet("one", envelope(), policy)
    oversized = json.loads(json.dumps(packet))
    oversized["candidates"].append(dict(oversized["candidates"][0]))
    oversized["packetDigest"] = sha256_digest({key: value for key, value in oversized.items() if key != "packetDigest"})
    with pytest.raises(ValueError, match="candidates exceed policy budget"):
        validate_graph_route_packet(oversized, envelope())


def test_context_packet_is_distinct_closed_and_budget_evidenced() -> None:
    index = envelope()
    route = derive_route_packet("one", index, graph_policy(maxEntities=1))
    packet = materialize_context(
        route,
        index,
        {"maxNodes": 1, "maxEdges": 0, "maxBytes": 4096, "maxDepth": 2},
    )
    assert packet["schema"] == "lattice.context-packet.v1"
    assert packet["requestId"] == route["requestId"]
    assert packet["routePacketDigest"] == route["packetDigest"]
    assert packet["truncated"] is True
    assert packet["diagnostics"][0]["evidence"] == [index["provenance"]["inputDigest"]]
    assert len(packet["projection"]["document"]["@graph"]) == 1
    with tempfile.NamedTemporaryFile("w", suffix=".json") as value:
        json.dump(packet, value)
        value.flush()
        subprocess.run(
            [
                "cue",
                "vet",
                *(str(path) for path in sorted((ROOT / ".kg" / "context").glob("*.cue"))),
                value.name,
                "-d",
                "#MaterializedContextPacket",
            ],
            check=True,
            capture_output=True,
            text=True,
        )


def test_materialization_rejects_stale_and_unknown_selections() -> None:
    index = envelope()
    route = derive_route_packet("one", index, graph_policy())
    mutations = (
        ("repositoryRevision", "other"),
        ("inputDigest", "sha256:" + "f" * 64),
        ("policyDigest", "sha256:" + "e" * 64),
    )
    for field, replacement in mutations:
        stale = json.loads(json.dumps(route))
        stale["index"][field] = replacement
        stale["packetDigest"] = sha256_digest({key: value for key, value in stale.items() if key != "packetDigest"})
        with pytest.raises(FullIndexError, match="provenance mismatch"):
            materialize_context(stale, index)
    stale_tool = json.loads(json.dumps(route))
    stale_tool["index"]["tools"]["cue"] = "other"
    stale_tool["packetDigest"] = sha256_digest(
        {key: value for key, value in stale_tool.items() if key != "packetDigest"}
    )
    with pytest.raises(FullIndexError, match="provenance mismatch"):
        materialize_context(stale_tool, index)
    missing = json.loads(json.dumps(route))
    missing["selection"]["entities"] = ["missing"]
    with pytest.raises(FullIndexError, match="digest mismatch"):
        materialize_context(missing, index)
    policy = json.loads(json.dumps(route))
    policy["policy"]["budgets"]["maxEntities"] += 1
    with pytest.raises(FullIndexError, match="policy digest mismatch"):
        materialize_context(policy, index)


def test_jsonld_projection_matches_canonical_snapshot() -> None:
    index = envelope()
    route = derive_route_packet("one", index, graph_policy(maxEntities=1))
    packet = materialize_context(route, index, {"maxNodes": 2, "maxEdges": 1, "maxBytes": 8192, "maxDepth": 1})
    assert packet["projection"]["document"] == json.loads((FIXTURES / "context.jsonld").read_text())


def test_generic_mcp_resources_and_structured_failures() -> None:
    resources = MCPResources(envelope())
    assert resources.read("kg://entity/one")["id"] == "one"
    assert resources.read("kg://relation/one/related/two")["target"] == "two"
    neighborhood = resources.read("kg://neighborhood/one?depth=1")
    assert set(neighborhood["entities"]) == {"one", "two"}
    assert resources.read("kg://entity/missing")["error"]["code"] == "not_found"
    assert resources.read("kg://unknown")["error"]["code"] == "not_found"
    assert resources.read("kg://projection/entity/one")["schema"] == "lattice.context-packet.v1"
    assert create_mcp_server(envelope()) is not None

    async def read() -> dict[str, object]:
        return await AsyncMCPResources(resources, concurrency=1, timeout=1).read("kg://graph/inventory")

    assert asyncio.run(read())["schema"] == "lattice.mcp-resource-inventory.v1"


def test_cache_keys_isolate_revision_inputs_and_tools() -> None:
    first = cache_key("projection", "one", {"query": "x"}, {"kg": "one"})
    assert first != cache_key("projection", "two", {"query": "x"}, {"kg": "one"})
    assert first != cache_key("projection", "one", {"query": "y"}, {"kg": "one"})
    assert first != cache_key("projection", "one", {"query": "x"}, {"kg": "two"})
    with tempfile.TemporaryDirectory() as temporary:
        cache = ArtifactCache(temporary)
        calls = 0

        def produce() -> dict[str, bool]:
            nonlocal calls
            calls += 1
            return {"ok": True}

        assert cache.get_or_compute("projection", first, produce) == ({"ok": True}, False)
        assert cache.get_or_compute("projection", first, produce) == ({"ok": True}, True)
        assert calls == 1
        changed = cache_key("projection", "one", {"query": "changed"}, {"kg": "one"})
        assert cache.get_or_compute("projection", changed, produce) == ({"ok": True}, False)
        assert calls == 2
        path = cache._path("projection", first)
        entry = json.loads(path.read_text())
        entry["artifact"] = {"ok": False}
        path.write_text(json.dumps(entry))
        assert cache.get("projection", first) is None


def test_bounded_execution_times_out_without_blocking_event_loop() -> None:
    async def execute() -> None:
        executor = BoundedExecutor(concurrency=1, timeout=0.01)
        with pytest.raises(TimeoutError):
            await executor.run(time.sleep, 0.1)

    asyncio.run(execute())


def test_bounded_execution_cancellation_terminates_and_joins_worker() -> None:
    async def execute() -> None:
        executor = BoundedExecutor(concurrency=1, timeout=10)
        with tempfile.TemporaryDirectory() as temporary:
            started = Path(temporary) / "started"
            completed = Path(temporary) / "completed"
            task = asyncio.create_task(executor.run(_record_process_and_sleep, str(started), str(completed), 10))
            for _ in range(300):
                if started.is_file():
                    break
                await asyncio.sleep(0.01)
            assert started.is_file()
            pid = int(started.read_text(encoding="utf-8"))
            task.cancel()
            with pytest.raises(asyncio.CancelledError):
                await task
            assert not completed.exists()
            with pytest.raises(ChildProcessError):
                os.waitpid(pid, os.WNOHANG)

    asyncio.run(execute())


def test_agent_context_generation_is_read_only_and_skips_diagnostic_gates(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    def unexpected(*args: object, **kwargs: object) -> dict[str, Any]:
        raise AssertionError("agent context generation must not execute diagnostic gates or write audit artifacts")

    monkeypatch.setattr(hook_module, "_gate", unexpected)
    monkeypatch.setattr(hook_module, "_write_audit_artifact", unexpected)
    monkeypatch.setattr(Path, "mkdir", unexpected)
    monkeypatch.setattr(Path, "write_bytes", unexpected)
    monkeypatch.setattr(Path, "write_text", unexpected)
    context = derive_codex_prompt_context(
        {"hook_event_name": "UserPromptSubmit", "prompt": "kg maintenance"}, envelope(), ROOT
    )
    assert set(context) == {
        "schema",
        "requestId",
        "route",
        "selection",
        "indexInputDigest",
        "policyDigest",
        "instruction",
    }
    assert list(tmp_path.iterdir()) == []


def test_offline_audit_generation_writes_and_verifies_bound_packet(tmp_path: Path) -> None:
    audit = build_hook_audit(
        event={"hook_event_name": "UserPromptSubmit", "prompt": "kg maintenance"},
        envelope=envelope(),
        root=ROOT,
        output_directory=tmp_path,
    )
    records = list(tmp_path.glob("*.json"))
    assert len(records) == 1
    encoded = records[0].read_bytes()
    assert json.loads(encoded) == audit["auditPacket"]
    verify_prompt_context_audit(
        audit["promptContext"],
        audit["auditPacket"],
        encoded,
        audit_artifact=audit["auditArtifact"],
        gate_summary=audit["gateSummary"],
    )
    mutations = (
        ("promptContext", "requestId", "tampered-request"),
        ("auditArtifact", "digest", "sha256:" + "f" * 64),
        ("gateSummary", "evidenceDigest", "sha256:" + "f" * 64),
    )
    for parent, field, replacement in mutations:
        tampered = json.loads(json.dumps(audit))
        tampered[parent][field] = replacement
        with pytest.raises(ValueError, match="does not match"):
            verify_prompt_context_audit(
                tampered["promptContext"],
                tampered["auditPacket"],
                audit_artifact=tampered["auditArtifact"],
                gate_summary=tampered["gateSummary"],
            )


def test_diagnostics_do_not_invoke_registered_codex_hook(monkeypatch: pytest.MonkeyPatch) -> None:
    original = subprocess.run

    def guarded(*args: Any, **kwargs: Any) -> Any:
        command = args[0] if args else kwargs.get("args", [])
        rendered = " ".join(str(part) for part in command) if not isinstance(command, str) else command
        if ".kg/hooks/codex/user-prompt-submit" in rendered:
            raise AssertionError("diagnostics must call the offline audit API directly")
        return original(*args, **kwargs)

    monkeypatch.setattr(subprocess, "run", guarded)
    report, _ = run_diagnostics(ROOT, checks={"prompt-event-normalization"}, envelope=envelope())
    assert report["summary"]["status"] == "pass"


def test_removing_audit_directory_does_not_affect_user_prompt_submit(tmp_path: Path) -> None:
    event = tmp_path / "event.json"
    event.write_text(json.dumps({"hook_event_name": "UserPromptSubmit", "prompt": "kg maintenance"}))
    audit_directory = tmp_path / "hook-audit"
    audit_directory.mkdir()
    (audit_directory / "stale.json").write_text("{}")
    before = emit_route_hook(event, ROOT, envelope=envelope())
    shutil.rmtree(audit_directory)
    after = emit_route_hook(event, ROOT, envelope=envelope())
    assert before == after


def test_diagnostics_emit_cue_admitted_evidence_and_offline_bundle() -> None:
    report, artifacts = run_diagnostics(ROOT, sections={"package-boundary"})
    assert report["summary"]["status"] == "pass"
    check = report["checks"][0]
    assert check["evidence"] and check["evidence"][0]["record"]["status"] == "pass"
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        result = root / "check.json"
        result.write_text(json.dumps(check), encoding="utf-8")
        subprocess.run(
            [
                "cue",
                "vet",
                str(ROOT / ".kg" / "diagnostics" / "schema.cue"),
                str(result),
                "-d",
                "#DiagnosticCheckResult",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        bundle = write_review_bundle(root / "bundle", report, artifacts)
        manifest = json.loads((bundle / "manifest.json").read_text(encoding="utf-8"))
        assert manifest["schema"] == "lattice.diagnostics-review-bundle.v1"
        assert (bundle / "workbook.html").is_file()
        assert (bundle / "checks.json").is_file()


def test_diagnostic_filters_reject_unknown_values() -> None:
    with pytest.raises(ValueError, match="unknown diagnostic check"):
        run_diagnostics(ROOT, checks={"nonexistent"})
    with pytest.raises(ValueError, match="unknown diagnostic section"):
        run_diagnostics(ROOT, sections={"nonexistent"})


def test_focused_diagnostics_do_not_eagerly_build_full_index(monkeypatch: pytest.MonkeyPatch) -> None:
    def unexpected(*args: object, **kwargs: object) -> dict[str, Any]:
        raise AssertionError("focused package diagnostics must not build a full index")

    monkeypatch.setattr(diagnostics_module, "execute_full_index", unexpected)
    report, _ = run_diagnostics(ROOT, checks={"runtime-surface"})
    assert report["summary"]["status"] == "pass"


def test_diagnostic_contract_rejects_unevidenced_pass() -> None:
    report, _ = run_diagnostics(ROOT, checks={"runtime-surface"})
    check = report["checks"][0]
    check["evidence"] = []
    with tempfile.NamedTemporaryFile("w", suffix=".json") as value:
        json.dump(check, value)
        value.flush()
        result = subprocess.run(
            [
                "cue",
                "vet",
                str(ROOT / ".kg" / "diagnostics" / "schema.cue"),
                value.name,
                "-d",
                "#DiagnosticCheckResult",
            ],
            capture_output=True,
            text=True,
        )
    assert result.returncode != 0


def test_diagnostic_report_contract_rejects_contradictory_summary_counts() -> None:
    report, _ = run_diagnostics(ROOT, checks={"runtime-surface"})
    contradictory = json.loads(json.dumps(report))
    contradictory["summary"]["status"] = "fail"
    contradictory["summary"]["counts"] = {"total": 1, "pass": 0, "nonPassing": 1}
    with pytest.raises(ValueError, match="CUE rejected"):
        diagnostics_module._admit_diagnostic_value(ROOT, contradictory, "#DiagnosticsReport")

    false_pass = json.loads(json.dumps(report))
    false_pass["checks"][0]["status"] = "fail"
    false_pass["checks"][0]["remediation"] = "Repair the failed check."
    with pytest.raises(ValueError, match="CUE rejected"):
        diagnostics_module._admit_diagnostic_value(ROOT, false_pass, "#DiagnosticsReport")


def test_review_bundle_manifest_requires_canonical_files() -> None:
    manifest = {
        "schema": "lattice.diagnostics-review-bundle.v1",
        "repositoryRevision": "revision",
        "summaryDigest": "sha256:" + "1" * 64,
        "files": ["anything.json"],
    }
    with pytest.raises(ValueError, match="CUE rejected"):
        diagnostics_module._admit_diagnostic_value(ROOT, manifest, "#ReviewBundleManifest")


def test_all_declared_gate_failure_states_are_cue_admitted() -> None:
    output = subprocess.run(
        ["cue", "export", str(ROOT / ".kg" / "context"), "-e", "_negativeGateFixtures", "--out", "json"],
        check=True,
        capture_output=True,
        text=True,
    )
    assert set(json.loads(output.stdout)) == {"fail", "skipped", "unsupported", "indeterminate"}


def test_unavailable_index_is_reported_as_unsupported(monkeypatch: pytest.MonkeyPatch) -> None:
    def unavailable(*args: object, **kwargs: object) -> dict[str, Any]:
        raise FullIndexError("kg_index_toolchain_unsupported", "missing kg")

    monkeypatch.setattr(diagnostics_module, "execute_full_index", unavailable)
    report, _ = run_diagnostics(ROOT, checks={"graph-routing"})
    assert report["summary"]["status"] == "fail"
    assert report["checks"][0]["status"] == "unsupported"
    assert report["checks"][0]["remediation"]
    assert report["checks"][0]["evidence"]


def test_unavailable_index_is_reported_as_indeterminate(monkeypatch: pytest.MonkeyPatch) -> None:
    def unavailable(*args: object, **kwargs: object) -> dict[str, Any]:
        raise FullIndexError("kg_index_command_failed", "kg did not complete")

    monkeypatch.setattr(diagnostics_module, "execute_full_index", unavailable)
    report, _ = run_diagnostics(ROOT, checks={"graph-routing"})
    assert report["summary"]["status"] == "fail"
    assert report["checks"][0]["status"] == "indeterminate"
    assert report["checks"][0]["evidence"]


@pytest.mark.integration
def test_diagnostic_semantics_match_golden_fixture(monkeypatch: pytest.MonkeyPatch) -> None:
    runtime_audit_root = ROOT / ".cache" / "lattice" / "hook-audit"
    audit_before = {
        path.name: (path.stat().st_mtime_ns, path.stat().st_size) for path in runtime_audit_root.glob("*.json")
    }

    def reject_cache_write(*args: object, **kwargs: object) -> None:
        raise AssertionError("diagnostics must not write through ArtifactCache")

    monkeypatch.setattr(ArtifactCache, "put", reject_cache_write)
    report, artifacts = run_diagnostics(ROOT)
    semantic = {
        "summary": {
            "status": report["summary"]["status"],
            "counts": report["summary"]["counts"],
        },
        "checks": [[item["checkId"], item["subsystem"], item["status"]] for item in report["checks"]],
    }
    expected = json.loads((ROOT / "tests" / "fixtures" / "diagnostics" / "semantic.json").read_text())
    assert semantic == expected
    audit_after = {
        path.name: (path.stat().st_mtime_ns, path.stat().st_size) for path in runtime_audit_root.glob("*.json")
    }
    assert audit_after == audit_before
    hook = artifacts["prompt-event-normalization"]
    encoded = json.dumps(hook["promptContext"], sort_keys=True, separators=(",", ":")).encode()
    assert len(encoded) <= 4096
    packet = hook["auditPacket"]
    included = [item["entityId"] for item in packet["candidates"] if item["disposition"] == "included"]
    assert included == packet["selection"]["entities"]
    assert any(
        reason["kind"] == "route-policy-exclusion" for item in packet["candidates"] for reason in item["reasons"]
    )
    tampered_binding = json.loads(json.dumps(hook))
    tampered_binding["promptContext"]["requestId"] = "tampered-request"
    with pytest.raises(ValueError, match="CUE rejected"):
        admit_context_value(tampered_binding, "#AuditBoundCodexPromptContext", ROOT)


def test_mcp_drift_compares_complete_provenance(monkeypatch: pytest.MonkeyPatch) -> None:
    index = envelope()
    provenance = index["provenance"]

    def current(*args: object, **kwargs: object) -> tuple[Path, dict[str, str]]:
        return Path("/tmp/kg"), {
            "revision": provenance["repositoryRevision"],
            "inputDigest": provenance["inputDigest"],
            "policyDigest": provenance["policyDigest"],
            "kgVersion": provenance["tools"]["kg"],
            "cueVersion": provenance["tools"]["cue"],
        }

    monkeypatch.setattr(mcp_module, "full_index_provenance", current)
    resources = MCPResources(index)
    assert resources.read("kg://drift")["status"] == "current"

    def stale(*args: object, **kwargs: object) -> tuple[Path, dict[str, str]]:
        path, value = current()
        return path, {**value, "inputDigest": "sha256:" + "f" * 64}

    monkeypatch.setattr(mcp_module, "full_index_provenance", stale)
    drift = resources.read("kg://drift")
    assert drift["status"] == "stale"
    assert drift["changed"] == ["inputDigest"]

    def stale_policy(*args: object, **kwargs: object) -> tuple[Path, dict[str, str]]:
        path, value = current()
        return path, {**value, "policyDigest": "sha256:" + "e" * 64}

    monkeypatch.setattr(mcp_module, "full_index_provenance", stale_policy)
    assert resources.read("kg://drift")["changed"] == ["policyDigest"]

    def unreadable(*args: object, **kwargs: object) -> tuple[Path, dict[str, str]]:
        raise PermissionError("unreadable KG executable")

    monkeypatch.setattr(mcp_module, "full_index_provenance", unreadable)
    indeterminate = resources.read("kg://drift")
    assert indeterminate["status"] == "indeterminate"
    assert indeterminate["stale"] is None


def test_external_kg_falls_back_to_path(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    binary = tmp_path / "kg"
    binary.write_text("#!/bin/sh\nexit 0\n")
    binary.chmod(0o755)
    monkeypatch.delenv("KG_BIN", raising=False)
    monkeypatch.setenv("PATH", str(tmp_path))
    assert resolve_external_kg(tmp_path) == binary.resolve()


def test_bun_mcp_surface_is_only_a_python_compatibility_launcher() -> None:
    bridge = (ROOT / ".kg" / "mcp" / "server.js").read_text()
    launcher = (ROOT / "src" / "lattice" / "adapters" / "mcp_server.js").read_text()
    assert "mcp_server.js" in bridge
    assert "lattice-mcp" in launcher
    assert "McpServer" not in launcher
