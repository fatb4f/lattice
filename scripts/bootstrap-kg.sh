#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$repo_root/.toolchain.env"

cache_root="$repo_root/.cache/quicue-$QUICUE_COMMIT"
checkout="$cache_root/quicue.ca"
bin_dir="$repo_root/.cache/bin"

if [[ ! -d "$checkout/.git" ]]; then
	rm -rf "$cache_root"
	mkdir -p "$cache_root"
	git clone --filter=blob:none --no-checkout "$QUICUE_REPOSITORY" "$checkout"
	git -C "$checkout" checkout --detach "$QUICUE_COMMIT"
fi

[[ "$(git -C "$checkout" rev-parse HEAD)" == "$QUICUE_COMMIT" ]]
[[ "$(sha256sum "$checkout/kg/tools/kg" | awk '{print $1}')" == "$QUICUE_KG_SHA256" ]]

mkdir -p "$bin_dir" "$repo_root/.kb/cue.mod/pkg/quicue.ca"
ln -sfn "$checkout/kg/tools/kg" "$bin_dir/kg"
ln -sfn "../../../../.cache/quicue-$QUICUE_COMMIT/quicue.ca/kg" \
	"$repo_root/.kb/cue.mod/pkg/quicue.ca/kg"

printf 'Pinned quicue-kg %s installed in %s\n' "$QUICUE_COMMIT" "$cache_root"
