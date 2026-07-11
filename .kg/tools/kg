#!/usr/bin/env sh
set -eu

usage() {
	printf 'usage: kg hook codex user-prompt-submit --event FILE --kb DIR --vocab FILE --out codex-hook-json [--mode route-packet]\n' >&2
	exit 2
}

[ "$#" -ge 4 ] || usage
[ "$1" = "hook" ] || usage
[ "$2" = "codex" ] || usage
[ "$3" = "user-prompt-submit" ] || usage
shift 3

event=
kb=
vocab=
out=
mode=route-packet

while [ "$#" -gt 0 ]; do
	case "$1" in
	--event)
		[ "$#" -ge 2 ] || usage
		event=$2
		shift 2
		;;
	--kb)
		[ "$#" -ge 2 ] || usage
		kb=$2
		shift 2
		;;
	--vocab)
		[ "$#" -ge 2 ] || usage
		vocab=$2
		shift 2
		;;
	--out)
		[ "$#" -ge 2 ] || usage
		out=$2
		shift 2
		;;
	--mode)
		[ "$#" -ge 2 ] || usage
		mode=$2
		shift 2
		;;
	*)
		usage
		;;
	esac
done

[ -n "$event" ] && [ -f "$event" ] || usage
[ -n "$kb" ] && [ -d "$kb" ] || usage
[ -n "$vocab" ] && [ -f "$vocab" ] || usage
[ "$out" = "codex-hook-json" ] || usage
[ "$mode" = "route-packet" ] || usage

case "$kb" in
*..*) printf 'kg hook: --kb must not contain parent traversal\n' >&2; exit 2 ;;
esac
case "$vocab" in
*..*) printf 'kg hook: --vocab must not contain parent traversal\n' >&2; exit 2 ;;
esac

if ! jq -e 'type == "object"
	and ((keys - ["hook_event_name", "hookEventName", "prompt", "userPrompt", "message"]) | length == 0)
	and ((.hook_event_name // .hookEventName // "UserPromptSubmit") == "UserPromptSubmit")
	and ([.prompt, .userPrompt, .message] | map(select(. != null)) | length == 1)
	and ((.prompt // .userPrompt // .message) | type == "string" and length > 0)' "$event" >/dev/null 2>&1; then
	printf 'kg hook: event is not a closed prompt-event envelope\n' >&2
	exit 2
fi
prompt=$(jq -r '.prompt // .userPrompt // .message' "$event")

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
"$repo_root/scripts/require-toolchain.sh"
kg_bin=${KG_BIN:-$repo_root/.cache/bin/kg}
cue_bin=${CUE_BIN:-$(command -v cue || true)}
case "$kg_bin" in
/*) kg_bin_abs=$kg_bin ;;
*) kg_bin_abs=$(cd "$(dirname "$kg_bin")" && pwd -P)/$(basename "$kg_bin") ;;
esac
self_bin=$repo_root/.kg/tools/kg
self_bin_abs=$(cd "$(dirname "$self_bin")" && pwd -P)/$(basename "$self_bin")
[ "$kg_bin_abs" != "$self_bin_abs" ] || {
	printf 'kg hook: external kg CLI resolves to local shim; refusing recursion\n' >&2
	exit 2
}
kg_bin=$kg_bin_abs

packet_json=$(mktemp "${TMPDIR:-/tmp}/lattice-context-packet.XXXXXX.json")
packet_cue=$(mktemp "${TMPDIR:-/tmp}/lattice-context-packet.XXXXXX.cue")
policy_json=$(mktemp "${TMPDIR:-/tmp}/lattice-route-policy.XXXXXX.json")
index_json=$(mktemp "${TMPDIR:-/tmp}/lattice-full-index.XXXXXX.json")
gate_json=$(mktemp "${TMPDIR:-/tmp}/lattice-gates.XXXXXX.jsonl")
gate_output=$(mktemp "${TMPDIR:-/tmp}/lattice-gate-output.XXXXXX")
manifest_json=$(mktemp "${TMPDIR:-/tmp}/lattice-runtime-manifest.XXXXXX.json")
normalized_event=$(mktemp "${TMPDIR:-/tmp}/lattice-prompt-event.XXXXXX.json")
trap 'rm -f "$packet_json" "$packet_cue" "$policy_json" "$index_json" "$gate_json" "$gate_output" "$manifest_json" "$normalized_event"' EXIT HUP INT TERM

jq -cn --arg prompt "$prompt" '{schema: "lattice.prompt-event.v1", event: "UserPromptSubmit", prompt: $prompt}' >"$normalized_event"

if [ "$kb" != "$repo_root/.kb" ]; then
	printf 'kg hook: this runtime only accepts the repo-local .kb authority\n' >&2
	exit 2
fi

revision=$(git -C "$repo_root" rev-parse HEAD)
canonical_path() {
	if [ -e "$1" ]; then realpath "$1"; else realpath -m "$1"; fi
}
path_digest() {
	if [ -f "$1" ]; then
		sha256sum "$1" | awk '{print "sha256:" $1}'
	elif [ -d "$1" ]; then
		(
			cd "$1"
			find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum
		) | sha256sum | awk '{print "sha256:" $1}'
	else
		printf '%s' "$1" | sha256sum | awk '{print "sha256:" $1}'
	fi
}

event_path=$(canonical_path "$normalized_event")
kb_path=$(canonical_path "$kb")
vocab_path=$(canonical_path "$vocab")
tmp_root=$(canonical_path "${TMPDIR:-/tmp}")
jq -n \
	--arg event "$event_path" --arg event_digest "$(path_digest "$event_path")" \
	--arg kb "$kb_path" --arg kb_digest "$(path_digest "$kb_path")" \
	--arg vocab "$vocab_path" --arg vocab_digest "$(path_digest "$vocab_path")" \
	--arg packet_json "$(canonical_path "$packet_json")" --arg packet_cue "$(canonical_path "$packet_cue")" \
	--arg policy_json "$(canonical_path "$policy_json")" --arg index_json "$(canonical_path "$index_json")" \
	'{inputs: [
		{role: "normalized-prompt-event", path: $event, digest: $event_digest},
		{role: "knowledge-graph", path: $kb, digest: $kb_digest},
		{role: "vocabulary", path: $vocab, digest: $vocab_digest}
	], outputs: [
		{role: "route-packet-json", path: $packet_json},
		{role: "route-packet-cue", path: $packet_cue},
		{role: "route-policy", path: $policy_json},
		{role: "full-index", path: $index_json}
	]}' >"$manifest_json"
input_digest=$(jq -cS '[.inputs[] | {role, digest}]' "$manifest_json" | sha256sum | awk '{print "sha256:" $1}')
execution_manifest_digest=$(sha256sum "$manifest_json" | awk '{print "sha256:" $1}')

run_gate() {
	gate_id=$1
	checker=$2
	policy=$3
	operation=$4
	shift 4
	started_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
	if "$@" >"$gate_output" 2>&1; then
		status=pass
		code=check-passed
		message="Checker completed successfully."
	else
		exit_code=$?
		status=fail
		code=check-failed
		message="Checker exited with status $exit_code."
	fi
	exit_code=${exit_code:-0}
	completed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
	expires_at=$(date -u -d "$completed_at + 300 seconds" +%Y-%m-%dT%H:%M:%SZ)
	result=$(sed -n '1,40p' "$gate_output")
	[ -n "$result" ] || result="checker produced no output; exit status $exit_code"
	digest=$(printf '%s\n%s\n%s\n%s\n%s\n%s\n' "$gate_id" "$checker" "$operation" "$revision" "$execution_manifest_digest" "$exit_code:$result" | sha256sum | awk '{print "sha256:" $1}')
	jq -cn \
		--arg gate_id "$gate_id" --arg checker "$checker" --arg policy "$policy" \
		--arg operation "$operation" --arg started_at "$started_at" --arg completed_at "$completed_at" \
		--arg expires_at "$expires_at" --arg status "$status" --arg code "$code" --arg message "$message" \
		--arg digest "$digest" --arg revision "$revision" --arg input_digest "$input_digest" --arg execution_manifest_digest "$execution_manifest_digest" \
		--arg result "$result" --argjson exit_status "$exit_code" --slurpfile manifest "$manifest_json" \
		'{key: $gate_id, value: {
			gateId: $gate_id, checker: $checker, status: $status, policy: $policy,
			startedAt: $started_at, completedAt: $completed_at, evaluatedAt: $completed_at,
			inputs: ["runtime-manifest:" + $execution_manifest_digest],
			evidence: [{ref: ("inline:" + $digest), digest: $digest,
				observedAt: $completed_at, expiresAt: $expires_at,
				record: {gateId: $gate_id, checker: $checker, operation: $operation,
					repositoryRevision: $revision,
					inputManifest: ($manifest[0] + {inputDigest: $input_digest, executionManifestDigest: $execution_manifest_digest}),
					exitStatus: $exit_status, resultDigest: $digest, result: $result}}],
			diagnostics: [{code: $code, message: $message}]
		}}' >>"$gate_json"
	unset exit_code
}

check_no_generated_input() {
	! jq -e --arg prefix "$(canonical_path "$repo_root/.kg/generated")/" \
		'.inputs[] | select(.path | startswith($prefix))' "$manifest_json" >/dev/null
}

check_no_plugin_cache_input() {
	! jq -e '.inputs[] | select(.path | contains("/plugins/cache/"))' "$manifest_json" >/dev/null
}

check_no_raw_transcript_input() {
	jq -e '([.inputs[] | select(.role == "normalized-prompt-event")] | length) == 1
		and ([.inputs[] | select(.role == "raw-transcript" or .role == "conversation-log")] | length) == 0' "$manifest_json" >/dev/null
	jq -e '.schema == "lattice.prompt-event.v1" and .event == "UserPromptSubmit"
		and (.prompt | type == "string" and length > 0)
		and ((keys | sort) == ["event", "prompt", "schema"])' "$normalized_event" >/dev/null
}

check_transient_projection() {
	jq -e --arg prefix "$tmp_root/" 'all(.outputs[]; .path | startswith($prefix))' "$manifest_json" >/dev/null
}

run_gate kb-valid quicue.kg-vet fail-closed 'kg vet .kb' sh -c 'cd "$1" && "$2" vet' sh "$repo_root" "$kg_bin"
run_gate no-dangling-refs quicue.kg-settle fail-closed 'kg settle .kb' sh -c 'cd "$1" && "$2" settle' sh "$repo_root" "$kg_bin"
run_gate no-generated-input lattice.runtime-input-scan fail-closed 'reject generated input roles and paths' check_no_generated_input
run_gate no-plugin-cache-input lattice.runtime-path-scan fail-closed 'reject plugin-cache input paths' check_no_plugin_cache_input
run_gate no-raw-transcript-input lattice.runtime-provenance-scan fail-closed 'reject raw transcript provenance roles' check_no_raw_transcript_input
run_gate transient-projection lattice.transient-path-scan fail-closed 'require every output beneath canonical temp root' check_transient_projection

if jq -s -e 'all(.[]; .value.status == "pass" or .value.policy == "fail-open")' "$gate_json" >/dev/null; then
	:
else
	printf 'kg hook: a fail-closed context gate did not pass\n' >&2
	exit 1
fi

(cd "$repo_root" && "$kg_bin" index --full) >"$index_json"
"$cue_bin" export "$repo_root/.kg/context" -e '#RoutePolicyProjection' --out json >"$policy_json"

kg_input_digest=$(
	git -C "$repo_root" ls-files -co --exclude-standard -- .kb \
		| LC_ALL=C sort \
		| git -C "$repo_root" hash-object --stdin-paths \
		| sha256sum \
		| awk '{print "sha256:" $1}'
)
kg_version=$(sha256sum "$kg_bin" | awk '{print "sha256:" $1}')
cue_version=$($cue_bin version | sed -n '1p')
evaluated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)

jq -n \
	--arg query "$prompt" \
	--arg revision "$revision" \
	--arg input_digest "$kg_input_digest" \
	--arg kg_version "$kg_version" \
	--arg cue_version "$cue_version" \
	--arg evaluated_at "$evaluated_at" \
	--slurpfile gate_results "$gate_json" \
	--slurpfile projection "$policy_json" \
	--slurpfile full_index "$index_json" \
	'
	($projection[0]) as $projection
	| ($full_index[0]) as $index
	| ($projection.routes) as $routes
	| ($projection.budget) as $budget
	| ($index.entities // {}) as $entities
	| ($gate_results | map({(.key): (.value + {evaluatedAt: $evaluated_at})}) | add) as $gates
	| if (($index.summary.total // -1) < 0 or ($index.summary.total > ($entities | length))) then
		error("full KG index is incomplete")
	  else . end
	| [
		$entities | to_entries[]
		| .key as $source
		| (.value.value.related // {}) | to_entries[]
		| select(.value == true and ($entities[.key] == null))
		| {source: $source, target: .key}
	  ] as $dangling
	| if ($dangling | length) > 0 then error("full KG index has dangling relations") else . end
	|
	def q: $query | ascii_downcase;
	def route:
		if q | test("promotion|promoted|promote|status") then "promotion-review"
		elif q | test("evidence|gather|session|hook output|last run|trace") then "evidence-gather"
		elif q | test("graph-state|phase one|phase two|phase 1|phase 2") then "graph-state-review"
		elif q | test("resolver|route|routing|context selector|context packet") then "resolver-maintenance"
		elif q | test("\\.kb|knowledge graph|kg maintenance|kg vet|kg index|kg settle") then "kg-maintenance"
		elif q | test("repo|inspect files|file inspection|diff") then "repo-inspection"
		else "default-minimal"
		end;
	(route) as $route
	| ($routes[$route]) as $policy
	|
	{
		schema: "lattice.context-route-packet.v1",
		host: "codex",
		event: "UserPromptSubmit",
		query: $query,
		route: $route,
		confidence: (if $route == "default-minimal" then 0.55 else 0.8 end),
		authority: false,
		generated: true,
		transient: true,
		evaluatedAt: $evaluated_at,
		index: {
			schema: "lattice.kg-full-index-envelope.v1",
			repositoryRevision: $revision,
			inputDigest: $input_digest,
			tools: {kg: $kg_version, cue: $cue_version}
		},
		budget: {
			maxInlineEntities: $policy.maxInlineEntities,
			maxInlineBytes: $budget.routePacketMaxBytes,
			maxResourceHandles: $policy.maxResourceHandles,
			maxAutoReadBytes: $policy.maxAutoReadBytes,
			allowExpensiveReads: $policy.allowExpensiveReads,
			preferMCP: $budget.mcpPreferred
		},
		selection: ({
			entities: ([$policy.defaultEntities[] | select($entities[.] != null)][0:$policy.maxInlineEntities]),
			resources: ($policy.mcpResources[0:([($budget.inlineResourceMax), ($policy.maxResourceHandles)] | min)]),
			files: ($policy.files // [])
		}),
		gates: $gates,
		hardExclusions: [
			"raw .kb body injection",
			"generated/codex runtime input",
			"plugin cache runtime input",
			"raw transcript runtime input",
			"parent traversal in selected files"
		],
		instruction: "Use MCP resources for details; do not inline broad KG content."
	}' >"$packet_json"

{
	printf 'package context\n\n_packet: '
	cat "$packet_json"
	printf '\n'
} >"$packet_cue"

"$cue_bin" export "$repo_root/.kg/context"/*.cue "$packet_cue" -e '(_packet & #RoutePolicyBoundPacket)' --out json >/dev/null

jq -cn --slurpfile packet "$packet_json" '{
	hookSpecificOutput: {
		hookEventName: "UserPromptSubmit",
		additionalContext: ($packet[0] | tojson)
	}
}'
