"""Execute the authoritative ``kg index --full`` adapter boundary."""

from __future__ import annotations

import hashlib
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any

from lattice.rag.cache import ArtifactCache, cache_key

from .full_index import FullIndexError, normalize_full_index


def _run(command: list[str], root: Path, timeout: float) -> str:
    try:
        completed = subprocess.run(
            command,
            cwd=root,
            check=True,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        output = getattr(exc, "stderr", None) or getattr(exc, "stdout", None) or str(exc)
        raise FullIndexError("kg_index_command_failed", "Full-index command failed", {"cause": output}) from exc
    return completed.stdout.strip()


def resolve_external_kg(root: str | Path = ".") -> Path:
    repo = Path(root).resolve()
    configured = os.environ.get("KG_BIN")
    candidates = [configured] if configured else [str(repo / ".cache" / "bin" / "kg"), "kg"]
    candidate: str | None = None
    for requested in candidates:
        if not requested:
            continue
        resolved_candidate = shutil.which(requested) if "/" not in requested else requested
        if resolved_candidate and Path(resolved_candidate).is_file():
            candidate = resolved_candidate
            break
    if not candidate:
        raise FullIndexError("kg_index_toolchain_unsupported", "The external kg CLI is unavailable")
    resolved = Path(candidate).resolve()
    local_shim = (repo / ".kg" / "tools" / "kg").resolve()
    if resolved == local_shim:
        raise FullIndexError("kg_index_toolchain_unsupported", "The kg CLI resolves to the local dispatch shim")
    return resolved


def _tree_digest(root: Path, directory: str = ".kb") -> str:
    try:
        digest = hashlib.sha256()
        base = root / directory
        if not base.is_dir():
            raise FullIndexError("kg_index_provenance_unavailable", f"Missing authority directory: {directory}")
        for path in sorted(item for item in base.rglob("*") if item.is_file() or item.is_symlink()):
            relative = path.relative_to(root).as_posix().encode()
            digest.update(relative)
            digest.update(b"\0")
            if path.is_symlink():
                digest.update(os.readlink(path).encode())
            else:
                digest.update(path.read_bytes())
            digest.update(b"\0")
        return "sha256:" + digest.hexdigest()
    except OSError as exc:
        raise FullIndexError(
            "kg_index_provenance_unavailable",
            f"Could not digest authority directory: {directory}",
            {"cause": str(exc)},
        ) from exc


def _file_digest(path: Path) -> str:
    try:
        return "sha256:" + hashlib.sha256(path.read_bytes()).hexdigest()
    except OSError as exc:
        raise FullIndexError(
            "kg_index_provenance_unavailable", "Could not digest the KG executable", {"cause": str(exc)}
        ) from exc


def full_index_provenance(
    repo: Path, timeout: float = 20.0, *, kg: Path | None = None
) -> tuple[Path, dict[str, str]]:
    kg = kg or resolve_external_kg(repo)
    revision = _run(["git", "rev-parse", "HEAD"], repo, timeout)
    cue_version = _run([os.environ.get("CUE_BIN", "cue"), "version"], repo, timeout).splitlines()[0]
    return kg, {
        "revision": revision,
        "inputDigest": _tree_digest(repo),
        "policyDigest": _tree_digest(repo, ".kg/context"),
        "kgVersion": _file_digest(kg),
        "cueVersion": cue_version,
    }


def execute_full_index(
    root: str | Path = ".", timeout: float = 20.0, *, kg: Path | None = None
) -> dict[str, Any]:
    """Run one bounded full-index export and return its validated envelope."""
    repo = Path(root).resolve()
    kg_path, provenance = full_index_provenance(repo, timeout, kg=kg)
    graph = _run([str(kg_path), "index", "--full"], repo, timeout)
    return normalize_full_index(graph, provenance)


def cached_full_index(
    root: str | Path = ".",
    cache_root: str | Path = ".cache/lattice",
    timeout: float = 20.0,
) -> tuple[dict[str, Any], bool]:
    """Reuse an index only when revision, source digest, and tool identities match."""
    repo = Path(root).resolve()
    kg, provenance = full_index_provenance(repo, timeout)
    key = cache_key(
        "full-index",
        provenance["revision"],
        {"inputDigest": provenance["inputDigest"], "policyDigest": provenance["policyDigest"]},
        {"kg": provenance["kgVersion"], "cue": provenance["cueVersion"]},
    )
    cache_path = Path(cache_root)
    if not cache_path.is_absolute():
        cache_path = repo / cache_path
    cache = ArtifactCache(cache_path)

    def produce() -> dict[str, Any]:
        return normalize_full_index(_run([str(kg), "index", "--full"], repo, timeout), provenance)

    artifact, hit = cache.get_or_compute("full-index", key, produce)
    from .full_index import load_full_index_envelope

    admitted = load_full_index_envelope(artifact)
    expected = {
        "repositoryRevision": provenance["revision"],
        "inputDigest": provenance["inputDigest"],
        "policyDigest": provenance["policyDigest"],
        "tools": {"kg": provenance["kgVersion"], "cue": provenance["cueVersion"]},
    }
    if admitted["provenance"] != expected:
        if hit:
            cache.put("full-index", key, produce())
            refreshed = cache.get("full-index", key)
            if refreshed is None:
                raise FullIndexError("kg_index_stale", "Refreshed full index is unavailable")
            admitted = load_full_index_envelope(refreshed)
            hit = False
        if admitted["provenance"] != expected:
            raise FullIndexError("kg_index_stale", "Cached full index does not match its cache address")
    return admitted, hit
