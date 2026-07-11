#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
cd "$repo_root"

hook=.kg/hooks/codex/user-prompt-submit

expect_failure() {
	local payload=$1
	if printf '%s\n' "$payload" | "$hook" >/dev/null 2>&1; then
		printf 'expected Codex hook envelope rejection, but input passed\n' >&2
		return 1
	fi
}

valid_event=$(jq -cn \
	--arg cwd "$repo_root" \
	'{
		agent_id: "fixture-agent",
		agent_type: "codex",
		cwd: $cwd,
		hook_event_name: "UserPromptSubmit",
		model: "gpt-5.6",
		permission_mode: "default",
		prompt: "project knowledge graph context",
		session_id: "fixture-session",
		transcript_path: "/path/that/must/not/be-read/transcript.jsonl",
		turn_id: "fixture-turn"
	}')

hook_output=$(printf '%s\n' "$valid_event" | "$hook")
printf '%s\n' "$hook_output" |
	jq -e '
		.hookSpecificOutput.hookEventName == "UserPromptSubmit"
		and (.hookSpecificOutput.additionalContext | fromjson
			| .schema == "lattice.context-route-packet.v1"
			and .event == "UserPromptSubmit"
			and .query == "project knowledge graph context"
			and (.gates["no-raw-transcript-input"].status == "pass"))
		and (tostring | contains("transcript_path") | not)
	' >/dev/null

expect_failure "$(printf '%s\n' "$valid_event" | jq -c '.unexpected = true')"
expect_failure "$(printf '%s\n' "$valid_event" | jq -c '.permission_mode = "unknown"')"
expect_failure "$(printf '%s\n' "$valid_event" | jq -c '.prompt = [{role: "user", content: "raw"}]')"
expect_failure "$(printf '%s\n' "$valid_event" | jq -c 'del(.turn_id)')"
expect_failure 'user: raw transcript'

# The prompt-only envelope remains admitted solely for deterministic repo-local
# fixtures; it normalizes to the same internal event shape.
printf '%s\n' '{"hook_event_name":"UserPromptSubmit","prompt":"project knowledge graph context"}' |
	"$hook" |
	jq -e '.hookSpecificOutput.hookEventName == "UserPromptSubmit"' >/dev/null
