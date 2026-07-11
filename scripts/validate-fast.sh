#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir/.."

uv sync --locked
uv run lattice diagnostics runtime-surface --root .
uv run ruff check src tests
uv run pyright
uv run pytest -m "not integration"
cue vet ./.kg/context/*.cue
cue vet ./.kg/diagnostics/*.cue
