"""Python execution path for the Codex context-route hook."""

from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import tempfile
from collections.abc import Callable, Mapping
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

from lattice.rag.provenance import canonical_json, sha256_digest
from lattice.rag.routing import derive_route_packet, routing_policy_with_budgets

from .cue import admit_context_value
from .full_index import load_full_index_envelope
from .kg import cached_full_index, resolve_external_kg


def _now(value: datetime | None = None) -> str:
    return (value or datetime.now(UTC)).replace(microsecond=0).strftime("%Y-%m-%dT%H:%M:%SZ")


def _file_digest(path: Path) -> str:
    if path.is_dir():
        digest = hashlib.sha256()
        for item in sorted(candidate for candidate in path.rglob("*") if candidate.is_file()):
            digest.update(item.relative_to(path).as_posix().encode())
            digest.update(b"\0")
            digest.update(item.read_bytes())
            digest.update(b"\0")
        return "sha256:" + digest.hexdigest()
    return "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()


def _gate(
    gate_id: str,
    checker: str,
    operation: str,
    revision: str,
    manifest: Mapping[str, Any],
    runner: Callable[[], str],
) -> dict[str, Any]:
    started = datetime.now(UTC).replace(microsecond=0)
    try:
        result = runner() or "checker produced no output; exit status 0"
        status, exit_status = "pass", 0
        diagnostic = {"code": "check-passed", "message": "Checker completed successfully."}
    except (OSError, ValueError, subprocess.SubprocessError) as exc:
        result = str(exc)
        status, exit_status = "fail", 1
        diagnostic = {"code": "check-failed", "message": result}
    completed = datetime.now(UTC).replace(microsecond=0)
    input_digest = sha256_digest(manifest["inputs"])
    execution_digest = sha256_digest(manifest)
    record_base = {
        "gateId": gate_id,
        "checker": checker,
        "operation": operation,
        "repositoryRevision": revision,
        "inputManifest": {**manifest, "inputDigest": input_digest, "executionManifestDigest": execution_digest},
        "exitStatus": exit_status,
        "result": result[:8192],
    }
    digest = sha256_digest(record_base)
    evidence = {
        "ref": f"inline:{digest}",
        "digest": digest,
        "observedAt": _now(completed),
        "expiresAt": _now(completed + timedelta(minutes=5)),
        "record": {**record_base, "resultDigest": digest},
    }
    return {
        "gateId": gate_id,
        "checker": checker,
        "status": status,
        "policy": "fail-closed",
        "startedAt": _now(started),
        "completedAt": _now(completed),
        "evaluatedAt": _now(completed),
        "inputs": [f"runtime-manifest:{execution_digest}"],
        "evidence": [evidence],
        "diagnostics": [diagnostic],
    }


def _run(root: Path, command: list[str]) -> str:
    completed = subprocess.run(command, cwd=root, check=True, capture_output=True, text=True, timeout=20)
    return completed.stdout.strip() or completed.stderr.strip() or "checker completed successfully"


def _policy(root: Path) -> dict[str, Any]:
    output = _run(
        root,
        [
            os.environ.get("CUE_BIN", "cue"),
            "export",
            str(root / ".kg" / "context"),
            "-e",
            "#RoutePolicyProjection",
            "--out",
            "json",
        ],
    )
    return json.loads(output)


def _audit_artifact(packet: Mapping[str, Any]) -> dict[str, str]:
    encoded = canonical_json(packet)
    digest = "sha256:" + hashlib.sha256(encoded).hexdigest()
    return {"uri": f"artifact://lattice/hook-audit/{digest}", "digest": digest}


def _write_audit_artifact(directory: Path, packet: Mapping[str, Any]) -> dict[str, str]:
    encoded = canonical_json(packet)
    artifact = _audit_artifact(packet)
    digest = artifact["digest"]
    directory.mkdir(parents=True, exist_ok=True)
    target = directory / f"{digest.removeprefix('sha256:')}.json"
    descriptor, temporary_name = tempfile.mkstemp(prefix=".audit-", suffix=".json", dir=directory)
    try:
        with os.fdopen(descriptor, "wb") as output:
            output.write(encoded)
        os.replace(temporary_name, target)
    finally:
        if os.path.exists(temporary_name):
            os.unlink(temporary_name)
    return artifact


def verify_prompt_context_audit(
    prompt_context: Mapping[str, Any],
    audit_packet: Mapping[str, Any],
    encoded_audit: bytes | None = None,
    *,
    audit_artifact: Mapping[str, Any],
    gate_summary: Mapping[str, Any],
) -> None:
    """Verify that compact prompt context is bound to one content-addressed audit packet."""
    encoded = encoded_audit if encoded_audit is not None else canonical_json(audit_packet)
    digest = "sha256:" + hashlib.sha256(encoded).hexdigest()
    if audit_artifact.get("digest") != digest:
        raise ValueError("Codex prompt context audit digest does not match its audit packet")
    if audit_artifact.get("uri") != f"artifact://lattice/hook-audit/{digest}":
        raise ValueError("Codex prompt context audit URI does not match its audit digest")
    bindings = {
        "requestId": audit_packet.get("requestId"),
        "route": audit_packet.get("route"),
        "selection": audit_packet.get("selection"),
        "policyDigest": audit_packet.get("policyDigest"),
        "indexInputDigest": audit_packet.get("index", {}).get("inputDigest")
        if isinstance(audit_packet.get("index"), Mapping)
        else None,
        "instruction": audit_packet.get("instruction"),
    }
    for field, expected in bindings.items():
        if prompt_context.get(field) != expected:
            raise ValueError(f"Codex prompt context {field} does not match its audit packet")
    expected_gate_digest = sha256_digest(audit_packet.get("gates"))
    if gate_summary.get("status") != "pass" or gate_summary.get("evidenceDigest") != expected_gate_digest:
        raise ValueError("Codex prompt context gate digest does not match its audit packet")


def _choose_route(query: str, routes: Mapping[str, Any]) -> str:
    query_terms = set(query.casefold().replace("-", " ").split())
    ranked: list[tuple[int, str]] = []
    for route_id, policy in routes.items():
        match_terms = policy.get("matchTerms", [])
        score = sum(
            1 for term in match_terms if str(term).casefold() in query.casefold() or str(term).casefold() in query_terms
        )
        ranked.append((score, route_id))
    score, route_id = min(ranked, key=lambda item: (-item[0], item[1]))
    return route_id if score else "default-minimal"


def _authority_paths(repo: Path, kb: str | Path | None, vocab: str | Path | None) -> tuple[Path, Path]:
    expected_kb = (repo / ".kb").resolve()
    selected_kb = Path(kb).resolve() if kb else expected_kb
    if selected_kb != expected_kb or not selected_kb.is_dir():
        raise ValueError("--kb must select the repository .kb authority")
    preferred = repo / ".kb" / "cue.mod" / "pkg" / "quicue.ca" / "kg" / "vocab" / "context.cue"
    fallback = repo / ".kg" / "vocab" / "context.cue"
    selected_vocab = Path(vocab).resolve() if vocab else (preferred if preferred.is_file() else fallback).resolve()
    admitted_vocab = {path.resolve() for path in (preferred, fallback)}
    if selected_vocab not in admitted_vocab or not selected_vocab.is_file():
        raise ValueError("--vocab must select the preferred or fallback context vocabulary")
    return selected_kb, selected_vocab


def _normalized_event(event: Mapping[str, Any]) -> dict[str, str]:
    if (
        set(event) != {"hook_event_name", "prompt"}
        or event.get("hook_event_name") != "UserPromptSubmit"
        or not isinstance(event.get("prompt"), str)
        or not event["prompt"]
    ):
        raise ValueError("event is not a closed UserPromptSubmit prompt envelope")
    return {"hook_event_name": "UserPromptSubmit", "prompt": event["prompt"]}


def _derive_prompt_context(
    event: Mapping[str, str],
    envelope: Mapping[str, Any],
    projection: Mapping[str, Any],
    repo: Path,
) -> tuple[dict[str, Any], dict[str, Any]]:
    route_id = _choose_route(event["prompt"], projection["routes"])
    route_policy = projection["routes"][route_id]
    routing_policy = routing_policy_with_budgets(
        projection["routing"],
        max_candidates=route_policy["maxCandidates"],
        max_entities=route_policy["maxInlineEntities"],
        max_resources=route_policy["maxResourceHandles"],
    )
    derived = derive_route_packet(event["prompt"], envelope, routing_policy)
    allowed = route_policy.get("allowedEntities", {})
    selected = [entity_id for entity_id in derived["selection"]["entities"] if allowed.get(entity_id) is True]
    selected_set = set(selected)
    candidates = []
    for candidate in derived["candidates"]:
        normalized = {**candidate, "reasons": list(candidate["reasons"])}
        if normalized["disposition"] == "included" and normalized["entityId"] not in selected_set:
            normalized["disposition"] = "excluded"
            normalized["reasons"].append({"kind": "route-policy-exclusion", "route": route_id, "score": 0})
        candidates.append(normalized)
    selection = {
        "entities": selected,
        "resources": route_policy["mcpResources"][: route_policy["maxResourceHandles"]],
        "files": route_policy.get("files", []),
    }
    prompt_context = {
        "schema": "lattice.codex-prompt-context.v1",
        "requestId": derived["requestId"],
        "route": route_id,
        "selection": selection,
        "indexInputDigest": envelope["provenance"]["inputDigest"],
        "policyDigest": sha256_digest(route_policy),
        "instruction": "Use MCP resources for details; do not inline broad KG content.",
    }
    admit_context_value(prompt_context, "#CodexPromptContext", repo)
    encoded = canonical_json(prompt_context)
    if len(encoded) > route_policy["maxInlineBytes"]:
        raise ValueError("Codex prompt context exceeds maxInlineBytes")
    return prompt_context, {"derived": derived, "routePolicy": route_policy, "candidates": candidates}


def derive_codex_prompt_context(
    event: Mapping[str, Any], envelope: Mapping[str, Any], root: str | Path = "."
) -> dict[str, Any]:
    """Derive and admit compact agent context without persistent filesystem writes."""
    repo = Path(root).resolve()
    normalized = _normalized_event(event)
    admitted_envelope = load_full_index_envelope(envelope)
    projection = _policy(repo)
    admit_context_value(projection, "#RoutePolicyProjection", repo)
    prompt_context, _ = _derive_prompt_context(normalized, admitted_envelope, projection, repo)
    return prompt_context


def build_hook_audit(
    *,
    event: Mapping[str, Any],
    envelope: Mapping[str, Any],
    root: str | Path = ".",
    output_directory: str | Path | None = None,
    kb: str | Path | None = None,
    vocab: str | Path | None = None,
) -> dict[str, Any]:
    """Build an evidence-bearing route audit, writing only to an explicit output directory."""
    repo = Path(root).resolve()
    normalized = _normalized_event(event)
    admitted_envelope = load_full_index_envelope(envelope)
    kb_path, vocab_path = _authority_paths(repo, kb, vocab)
    kg_path = resolve_external_kg(repo)
    cue_name = os.environ.get("CUE_BIN", "cue")
    cue_resolved = shutil.which(cue_name) if "/" not in cue_name else cue_name
    if not cue_resolved or not Path(cue_resolved).is_file():
        raise ValueError("CUE toolchain is unavailable")
    cue_path = Path(cue_resolved).resolve()
    projection = _policy(repo)
    admit_context_value(projection, "#RoutePolicyProjection", repo)
    prompt_context, state = _derive_prompt_context(normalized, admitted_envelope, projection, repo)
    route_policy = state["routePolicy"]
    revision = admitted_envelope["provenance"]["repositoryRevision"]
    with tempfile.TemporaryDirectory(prefix="lattice-context-audit-") as temporary:
        temp = Path(temporary)
        (temp / "index.json").write_bytes(canonical_json(admitted_envelope))
        (temp / "policy.json").write_bytes(canonical_json(projection))
        inputs = [
            {
                "role": "normalized-prompt-event",
                "path": "inline:normalized-prompt-event",
                "digest": sha256_digest(normalized),
            },
            {"role": "knowledge-graph", "path": str(kb_path), "digest": _file_digest(kb_path)},
            {"role": "vocabulary", "path": str(vocab_path), "digest": _file_digest(vocab_path)},
            {"role": "kg-tool", "path": str(kg_path), "digest": _file_digest(kg_path)},
            {"role": "cue-tool", "path": str(cue_path), "digest": _file_digest(cue_path)},
        ]
        outputs = [
            {"role": "route-policy", "path": str(temp / "policy.json"), "digest": _file_digest(temp / "policy.json")},
            {"role": "full-index", "path": str(temp / "index.json"), "digest": _file_digest(temp / "index.json")},
        ]
        manifest = {"inputs": inputs, "outputs": outputs}
        checks: list[tuple[str, str, str, Callable[[], str]]] = [
            ("kb-valid", "quicue.kg-vet", "kg vet .kb", lambda: _run(repo, [str(kg_path), "vet"])),
            (
                "no-dangling-refs",
                "quicue.kg-settle",
                "kg settle .kb",
                lambda: _run(repo, [str(kg_path), "settle"]),
            ),
            (
                "no-generated-input",
                "lattice.runtime-input-scan",
                "reject generated input paths",
                lambda: (
                    "generated inputs absent"
                    if not any("/generated/" in item["path"] for item in inputs)
                    else (_ for _ in ()).throw(ValueError("generated input"))
                ),
            ),
            (
                "no-plugin-cache-input",
                "lattice.runtime-path-scan",
                "reject plugin cache paths",
                lambda: (
                    "plugin cache inputs absent"
                    if not any("/plugins/cache/" in item["path"] for item in inputs)
                    else (_ for _ in ()).throw(ValueError("plugin cache input"))
                ),
            ),
            (
                "no-raw-transcript-input",
                "lattice.runtime-provenance-scan",
                "reject raw transcript provenance",
                lambda: (
                    "normalized prompt-only event admitted"
                    if all(item["role"] != "raw-transcript" for item in inputs)
                    else (_ for _ in ()).throw(ValueError("raw transcript input"))
                ),
            ),
            (
                "transient-projection",
                "lattice.transient-path-scan",
                "require outputs below temp root",
                lambda: (
                    "transient outputs admitted"
                    if all(Path(item["path"]).is_relative_to(temp) for item in outputs)
                    else (_ for _ in ()).throw(ValueError("non-transient output"))
                ),
            ),
        ]
        gates = {
            gate_id: _gate(gate_id, checker, operation, revision, manifest, runner)
            for gate_id, checker, operation, runner in checks
        }
        if any(value["status"] != "pass" for value in gates.values()):
            raise ValueError("a fail-closed context gate did not pass")
        evaluated_at = _now()
        for gate in gates.values():
            gate["evaluatedAt"] = evaluated_at
        packet = {
            "schema": "lattice.context-route-packet.v1",
            "requestId": prompt_context["requestId"],
            "host": "codex",
            "event": "UserPromptSubmit",
            "query": normalized["prompt"],
            "route": prompt_context["route"],
            "confidence": 0.55 if prompt_context["route"] == "default-minimal" else 0.8,
            "authority": False,
            "generated": True,
            "transient": True,
            "evaluatedAt": evaluated_at,
            "index": {"schema": admitted_envelope["schema"], **admitted_envelope["provenance"]},
            "policyDigest": prompt_context["policyDigest"],
            "candidates": state["candidates"],
            "budget": {
                "maxInlineEntities": route_policy["maxInlineEntities"],
                "maxInlineBytes": projection["budget"]["routePacketMaxBytes"],
                "maxResourceHandles": route_policy["maxResourceHandles"],
                "maxAutoReadBytes": route_policy["maxAutoReadBytes"],
                "allowExpensiveReads": route_policy["allowExpensiveReads"],
                "preferMCP": True,
            },
            "selection": prompt_context["selection"],
            "gates": gates,
            "hardExclusions": [
                "raw .kb body injection",
                "generated/codex runtime input",
                "plugin cache runtime input",
                "raw transcript runtime input",
                "parent traversal in selected files",
            ],
            "instruction": prompt_context["instruction"],
        }
        packet["packetDigest"] = sha256_digest(packet)
        admit_context_value(packet, "#RoutePolicyBoundPacket", repo)
        artifact = _audit_artifact(packet)
        gate_summary = {"status": "pass", "evidenceDigest": sha256_digest(packet["gates"])}
        binding = {
            "promptContext": prompt_context,
            "auditPacket": packet,
            "gateSummary": gate_summary,
            "auditArtifact": artifact,
        }
        verify_prompt_context_audit(
            prompt_context,
            packet,
            audit_artifact=artifact,
            gate_summary=gate_summary,
        )
        admit_context_value(binding, "#AuditBoundCodexPromptContext", repo)
        if output_directory is not None:
            written_artifact = _write_audit_artifact(Path(output_directory).resolve(), packet)
            if written_artifact != artifact:
                raise ValueError("written audit artifact does not match the admitted binding")
        return binding


def emit_route_hook(
    event_path: str | Path,
    root: str | Path = ".",
    *,
    kb: str | Path | None = None,
    vocab: str | Path | None = None,
    envelope: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    repo = Path(root).resolve()
    event_file = Path(event_path).resolve()
    event = _normalized_event(json.loads(event_file.read_text(encoding="utf-8")))
    _authority_paths(repo, kb, vocab)
    admitted_envelope = load_full_index_envelope(envelope) if envelope is not None else cached_full_index(repo)[0]
    prompt_context = derive_codex_prompt_context(event, admitted_envelope, repo)
    return {
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": canonical_json(prompt_context).decode(),
        }
    }
