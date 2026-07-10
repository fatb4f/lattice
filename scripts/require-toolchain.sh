#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$repo_root/.toolchain.env"

cue_bin="${CUE_BIN:-$(command -v cue || true)}"
kg_bin="${KG_BIN:-$repo_root/.cache/bin/kg}"

[[ -x "$cue_bin" ]] || { printf 'pinned CUE executable is unavailable\n' >&2; exit 1; }
[[ -x "$kg_bin" ]] || { printf 'pinned kg executable is unavailable; run scripts/bootstrap-kg.sh\n' >&2; exit 1; }

actual_cue_version="$($cue_bin version | awk 'NR == 1 {sub(/^v/, "", $3); print $3}')"
[[ "$actual_cue_version" == "$CUE_VERSION" ]] || {
	printf 'CUE %s required, found %s\n' "$CUE_VERSION" "$actual_cue_version" >&2
	exit 1
}

actual_kg_sha="$(sha256sum "$(realpath "$kg_bin")" | awk '{print $1}')"
[[ "$actual_kg_sha" == "$QUICUE_KG_SHA256" ]] || {
	printf 'kg executable does not match pinned quicue commit %s\n' "$QUICUE_COMMIT" >&2
	exit 1
}

schema_target="$(realpath "$repo_root/.kb/cue.mod/pkg/quicue.ca/kg")"
expected_target="$repo_root/.cache/quicue-$QUICUE_COMMIT/quicue.ca/kg"
[[ "$schema_target" == "$expected_target" ]] || {
	printf 'quicue schema link is not pinned to %s\n' "$QUICUE_COMMIT" >&2
	exit 1
}
