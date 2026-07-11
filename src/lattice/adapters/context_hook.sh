#!/usr/bin/env sh
set -eu

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

case "${1:-}" in
	hook)
		exec uv run --project "$repo_root" --locked lattice "$@" --root "$repo_root"
		;;
	diagnose)
		shift
		exec uv run --project "$repo_root" --locked lattice diagnose --root "$repo_root" "$@"
		;;
	*)
		kg_bin=${KG_BIN:-"$repo_root/.cache/bin/kg"}
		exec "$kg_bin" "$@"
		;;
esac
