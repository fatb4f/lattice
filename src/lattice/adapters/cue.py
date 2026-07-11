"""CUE-owned admission for serialized runtime packets."""

from __future__ import annotations

import json
import os
import subprocess
from collections.abc import Mapping
from pathlib import Path
from typing import Any


def export_context_value(selector: str, root: str | Path = ".", *, timeout: float = 20.0) -> dict[str, Any]:
    """Export one concrete CUE-owned context value as JSON."""
    repo = Path(root).resolve()
    contracts = sorted((repo / ".kg" / "context").glob("*.cue"))
    if not contracts:
        raise ValueError("CUE context contracts are unavailable")
    try:
        completed = subprocess.run(
            [
                os.environ.get("CUE_BIN", "cue"),
                "export",
                *[str(path) for path in contracts],
                "-e",
                selector,
                "--out",
                "json",
            ],
            cwd=repo,
            check=True,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        detail = getattr(exc, "stderr", None) or getattr(exc, "stdout", None) or str(exc)
        raise ValueError(f"CUE could not export {selector}: {detail.strip()}") from exc
    value = json.loads(completed.stdout)
    if not isinstance(value, dict):
        raise ValueError(f"CUE export {selector} must be an object")
    return value


def admit_context_value(
    value: Mapping[str, Any], selector: str, root: str | Path = ".", *, timeout: float = 20.0
) -> None:
    repo = Path(root).resolve()
    contracts = sorted((repo / ".kg" / "context").glob("*.cue"))
    if not contracts:
        raise ValueError("CUE context contracts are unavailable")
    try:
        subprocess.run(
            [
                os.environ.get("CUE_BIN", "cue"),
                "vet",
                *(str(path) for path in contracts),
                "json:",
                "-",
                "-d",
                selector,
            ],
            cwd=repo,
            check=True,
            capture_output=True,
            input=json.dumps(value, sort_keys=True, separators=(",", ":")),
            text=True,
            timeout=timeout,
        )
    except (OSError, subprocess.SubprocessError) as exc:
        detail = getattr(exc, "stderr", None) or getattr(exc, "stdout", None) or str(exc)
        raise ValueError(f"CUE rejected {selector}: {detail.strip()}") from exc
