#!/usr/bin/env sh
set -eu

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
vocab=$repo_root/.kb/cue.mod/pkg/quicue.ca/kg/vocab/context.cue
[ -f "$vocab" ] || vocab=$repo_root/.kg/vocab/context.cue

event_json=$(mktemp "${TMPDIR:-/tmp}/kg-hook.XXXXXX.json")
normalized_event=$(mktemp "${TMPDIR:-/tmp}/kg-hook-normalized.XXXXXX.json")
output_json=$(mktemp "${TMPDIR:-/tmp}/kg-hook-output.XXXXXX.json")
trap 'rm -f "$event_json" "$normalized_event" "$output_json"' EXIT HUP INT TERM
cat >"$event_json"

# Accept the closed upstream Codex UserPromptSubmit command envelope. Protocol
# metadata is validated but discarded: transcript_path is never opened, hashed,
# or admitted as a runtime input.
if jq -e '
	type == "object"
	and ((keys - [
		"agent_id",
		"agent_type",
		"cwd",
		"hook_event_name",
		"model",
		"permission_mode",
		"prompt",
		"session_id",
		"transcript_path",
		"turn_id"
	]) | length == 0)
	and has("cwd")
	and has("hook_event_name")
	and has("model")
	and has("permission_mode")
	and has("prompt")
	and has("session_id")
	and has("transcript_path")
	and has("turn_id")
	and (.hook_event_name == "UserPromptSubmit")
	and (.cwd | type == "string")
	and (.model | type == "string")
	and (.permission_mode == "default"
		or .permission_mode == "acceptEdits"
		or .permission_mode == "plan"
		or .permission_mode == "dontAsk"
		or .permission_mode == "bypassPermissions")
	and (.prompt | type == "string" and length > 0)
	and (.session_id | type == "string")
	and (.transcript_path == null or (.transcript_path | type == "string"))
	and (.turn_id | type == "string")
	and ((has("agent_id") | not) or (.agent_id | type == "string"))
	and ((has("agent_type") | not) or (.agent_type | type == "string"))
' "$event_json" >/dev/null 2>&1; then
	jq -c '{hook_event_name: "UserPromptSubmit", prompt: .prompt}' \
		"$event_json" >"$normalized_event"
# Preserve the closed prompt-only form used by repo-local deterministic fixtures.
elif jq -e '
	type == "object"
	and ((keys | sort) == ["hook_event_name", "prompt"])
	and (.hook_event_name == "UserPromptSubmit")
	and (.prompt | type == "string" and length > 0)
' "$event_json" >/dev/null 2>&1; then
	jq -c '{hook_event_name: "UserPromptSubmit", prompt: .prompt}' \
		"$event_json" >"$normalized_event"
else
	printf 'kg hook: event is not an admitted Codex UserPromptSubmit envelope\n' >&2
	exit 2
fi

"$repo_root/.kg/tools/kg" hook codex user-prompt-submit \
	--event "$normalized_event" \
	--kb "$repo_root/.kb" \
	--vocab "$vocab" \
	--out codex-hook-json \
	--mode route-packet >"$output_json"

cat "$output_json"
