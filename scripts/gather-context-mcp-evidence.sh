#!/usr/bin/env sh
set -eu

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$repo_root"

stamp=${STAMP:-$(date -u +%Y%m%dT%H%M%SZ)}
out=${OUT:-".codex/evidence/context-mcp-proof-$stamp"}
prompt=${PROMPT:-"Let's test if the kg resolver injects route formatted context from the context:json-ld, and if MCP is wired."}

mkdir -p "$out/route" "$out/drift" "$out/mcp" "$out/repo"

printf '%s\n' "$prompt" >"$out/route/prompt.txt"
git rev-parse HEAD >"$out/repo/head.txt"
git status --short >"$out/repo/status.txt"
git branch --show-current >"$out/repo/branch.txt"
git log -n 5 --oneline --decorate >"$out/repo/recent-commits.txt"

printf '%s\n' "$prompt" \
	| .kg/hooks/codex/user-prompt-submit \
	>"$out/route/user-prompt-submit.json"

jq '{
	schema,
	route,
	confidence,
	budget,
	selection,
	gates,
	hardExclusions
}' "$out/route/user-prompt-submit.json" >"$out/route/route-summary.json"

printf '{"hook_event_name":"UserPromptSubmit","prompt":%s}\n' \
	"$(jq -Rn --arg prompt "$prompt" '$prompt')" \
	| .kg/hooks/codex/user-prompt-submit \
	>"$out/route/user-prompt-submit-envelope.json"

.kg/codex/tools/drift-check --format json --mode full \
	>"$out/drift/drift-full.json"

.kg/codex/tools/drift-check --format json --mode promotion \
	>"$out/drift/drift-promotion.json"

cue export ./.kg/codex/mcp -e mcpResources --out json \
	>"$out/mcp/resources-declared.json"

cue export ./.kg/context -e '#RoutePolicyProjection' --out json \
	>"$out/route/route-policy.json"

cue export ./.kg/context -e selectionPolicy --out json \
	>"$out/route/selection-policy.json" 2>"$out/route/selection-policy.err" || true

cat >"$out/route/route-prompts.tsv" <<'EOF'
promotion-review	Inspect promotion status and targetPackage bindings.
graph-state-review	Review graph-state phase one and phase two contracts.
kg-maintenance	Run kg maintenance with kg vet, kg index, and kg settle.
resolver-maintenance	Check resolver route policy and context packet selection.
repo-inspection	Inspect files and repo diff for this change.
default-minimal	Hello.
EOF

: >"$out/route/all-routes.jsonl"
while IFS='	' read -r expected_route route_prompt; do
	[ -n "$expected_route" ] || continue
	route_file="$out/route/packet-$expected_route.json"
	printf '%s\n' "$route_prompt" \
		| .kg/hooks/codex/user-prompt-submit \
		>"$route_file"
	jq -c --arg expected "$expected_route" '. + {expectedRoute: $expected}' "$route_file" \
		>>"$out/route/all-routes.jsonl"
done <"$out/route/route-prompts.tsv"

abs_out="$repo_root/$out"

(
cd "$repo_root/.kg/mcp"
OUT_DIR="$abs_out" PROMPT_TEXT="$prompt" node --input-type=module <<'EOF'
import { mkdirSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

const repoRoot = resolve(process.cwd(), '../..');
const outDir = process.env.OUT_DIR;
const prompt = process.env.PROMPT_TEXT;
const mcpDir = process.cwd();

mkdirSync(resolve(outDir, 'mcp'), { recursive: true });

function save(name, value) {
  const text = typeof value === 'string' ? value : JSON.stringify(value, null, 2);
  writeFileSync(resolve(outDir, 'mcp', name), `${text.trim()}\n`);
}

function firstText(result) {
  return result?.content?.[0]?.text ?? '{}';
}

function firstResourceText(result) {
  return result?.contents?.[0]?.text ?? '{}';
}

const client = new Client({ name: 'context-mcp-evidence', version: '0.1.0' });
const transport = new StdioClientTransport({
  command: 'bun',
  args: ['server.js'],
  cwd: mcpDir,
});

try {
  await client.connect(transport);

  const tools = await client.listTools();
  save('tools.json', tools);

  const status = await client.callTool({ name: 'kg_status', arguments: {} });
  save('status.json', firstText(status));

  const contextMatch = await client.callTool({
    name: 'kg_context_match',
    arguments: { prompt },
  });
  save('context-match.json', firstText(contextMatch));

  const resources = await client.callTool({
    name: 'kg_query',
    arguments: { expression: 'resources' },
  });
  save('resources.json', firstText(resources));

  const readTargets = [
    'codex://surfaces',
    'codex://drift/findings',
    'codex://graph-state/phase-one',
    'codex://graph-state/phase-two',
    'codex://promotion/status',
    'kg://query/selfContext',
    'kg://index/summary',
    'kg://index/full',
    'kg://entity/project-context',
    'kg://related/project-context',
  ];

  const readSummary = {};
  for (const uri of readTargets) {
    const result = await client.readResource({ uri });
    const resourceText = firstResourceText(result);
    const name = uri.replace(/[^a-zA-Z0-9]+/g, '-').replace(/^-|-$/g, '');
    save(`${name}.json`, resourceText);
    const parsed = JSON.parse(resourceText || '{}');
    readSummary[uri] = {
      bytes: Buffer.byteLength(resourceText),
      schema: parsed.schema ?? 'unknown',
      keys: Object.keys(parsed).slice(0, 12),
    };
  }

  save('resource-read-summary.json', readSummary);
} finally {
  await client.close();
}
EOF
)

jq -e '
	.schema == "lattice.context-route-packet.v1"
	and .budget.preferMCP == true
	and .budget.maxInlineEntities <= 3
	and .budget.maxInlineBytes <= 4096
	and (.selection.entities | length) <= .budget.maxInlineEntities
	and (.hardExclusions | index("raw .kb body injection") != null)
' "$out/route/user-prompt-submit.json" >"$out/route/assert-route-packet.ok"

jq -s -e '
	all(.route == .expectedRoute)
' "$out/route/all-routes.jsonl" >"$out/route/assert-all-routes-classified.ok"

jq -s -e --slurpfile policy "$out/route/route-policy.json" '
	($policy[0].routes) as $routes
	| all(. as $packet |
		(.budget.maxInlineEntities <= $routes[.route].maxInlineEntities)
		and (($packet.selection.entities // []) | all($routes[$packet.route].allowedEntities[.] == true))
	)
' "$out/route/all-routes.jsonl" >"$out/route/assert-all-routes-policy-entities.ok"

jq -s -e --slurpfile policy "$out/route/route-policy.json" '
	($policy[0].routes) as $routes
	| all(. as $packet |
		(($packet.selection.resources // []) | all(. as $resource | ($routes[$packet.route].mcpResources | index($resource) != null)))
		and (($packet.selection.files // []) | all(. as $file | ($routes[$packet.route].files | index($file) != null)))
	)
' "$out/route/all-routes.jsonl" >"$out/route/assert-all-routes-policy-selection.ok"

jq -e '
	has("kg://query/selfContext")
	and has("codex://surfaces")
' "$out/mcp/resources.json" >"$out/mcp/assert-selected-resources-declared.ok"

jq -e '
	.schema == "lattice.context-route-packet.v1"
	and .selection.resources == ["kg://query/selfContext", "codex://surfaces"]
' "$out/mcp/context-match.json" >"$out/mcp/assert-context-match.ok"

jq -e '
	.schema == "lattice-self-context.v1"
' "$out/mcp/kg-query-selfContext.json" >"$out/mcp/assert-self-context-resource.ok"

jq -e '
	has("codex-drift-kg")
	and has("kg-hook-runtime")
	and has("project-knowledge-kg")
' "$out/mcp/codex-surfaces.json" >"$out/mcp/assert-codex-surfaces-resource.ok"

jq -e '
	has("codex://surfaces")
	and has("codex://drift/findings")
	and has("codex://graph-state/phase-one")
	and has("codex://graph-state/phase-two")
	and has("codex://promotion/status")
	and has("kg://query/selfContext")
	and has("kg://index/summary")
	and has("kg://index/full")
	and has("kg://entity/project-context")
	and has("kg://related/project-context")
' "$out/mcp/resource-read-summary.json" >"$out/mcp/assert-all-resource-classes-read.ok"

{
	printf 'Context MCP evidence bundle\n'
	printf '===========================\n\n'
	printf 'created_utc: %s\n' "$stamp"
	printf 'prompt: %s\n' "$prompt"
	printf 'head: %s\n' "$(cat "$out/repo/head.txt")"
	printf 'output: %s\n\n' "$out"
	printf 'files:\n'
	find "$out" -type f | sort | while IFS= read -r file; do
		bytes=$(wc -c <"$file" | tr -d ' ')
		sha=$(sha256sum "$file" | awk '{print $1}')
		printf -- '- path: %s\n  bytes: %s\n  sha256: %s\n' "$file" "$bytes" "$sha"
	done
} >"$out/MANIFEST.txt"

tar -czf "$out.tar.gz" "$out"
printf '%s\n' "$out.tar.gz"
