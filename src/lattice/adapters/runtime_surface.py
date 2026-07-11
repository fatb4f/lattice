"""Repository gate for the P1 Python runtime boundary."""

from __future__ import annotations

from pathlib import Path

LEGACY_KG_RUNTIME = frozenset(
    {
        ".kg/codex/tools/drift-check",
        ".kg/codex/tools/drift-facts",
        ".kg/codex/tools/drift-hook",
        ".kg/codex/tools/promotion-facts",
        ".kg/mcp/bun.lock",
        ".kg/mcp/package.json",
        ".kg/mcp/server.test.js",
    }
)
KG_WRAPPERS = {
    ".kg/hooks/codex/user-prompt-submit": """#!/usr/bin/env sh
set -eu

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
exec sh "$repo_root/src/lattice/adapters/codex_hook.sh" "$@"
""",
    ".kg/tools/kg": """#!/usr/bin/env sh
set -eu

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
exec sh "$repo_root/src/lattice/adapters/context_hook.sh" "$@"
""",
    ".kg/mcp/index-response.js": """// Compatibility bridge for Bun consumers and tests.
export * from '../../src/lattice/adapters/index_response.js';
""",
    ".kg/mcp/server.js": """// Compatibility bridge; the implementation is owned by the lattice package.
import '../../src/lattice/adapters/mcp_server.js';
""",
}
PACKAGE_SOURCE_SUFFIXES = frozenset({".py", ".js", ".sh"})
PACKAGE_DATA_PATHS = frozenset(
    {
        "profiles/control/profile.cue",
        "profiles/manifest.json",
        "rag/contracts/resources/profiles/schema.cue",
        "rag/contracts/resources/registry/schema.cue",
    }
)


def _is_exact_wrapper(path: Path, expected: str) -> bool:
    return path.read_text(encoding="utf-8").replace("\r\n", "\n") == expected


def runtime_surface_violations(root: Path) -> list[str]:
    violations: list[str] = []
    kg = root / ".kg"
    if kg.exists():
        for path in sorted(item for item in kg.rglob("*") if item.is_file() and "node_modules" not in item.parts):
            relative = path.relative_to(root).as_posix()
            if relative in LEGACY_KG_RUNTIME or path.suffix in {".cue", ".md"}:
                continue
            if relative in KG_WRAPPERS and _is_exact_wrapper(path, KG_WRAPPERS[relative]):
                continue
            violations.append(f"unadmitted file beneath .kg: {relative}")
    package = root / "src" / "lattice"
    if package.exists():
        for path in sorted(item for item in package.rglob("*") if item.is_file()):
            relative = path.relative_to(package).as_posix()
            if "__pycache__" in path.parts:
                continue
            if path.suffix not in PACKAGE_SOURCE_SUFFIXES and relative not in PACKAGE_DATA_PATHS:
                violations.append(f"unadmitted non-source file beneath src/lattice: {path.relative_to(root)}")
    return violations
