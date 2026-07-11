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
uv run lattice index build --no-cache --out "$out/route/full-index.json"

emit_audit_packet() {
	packet_prompt=$1
	packet_output=$2
	context_output=$3
	uv run lattice audit hook \
		--envelope "$out/route/full-index.json" \
		--prompt "$packet_prompt" \
		--out "$packet_output" \
		--context-out "$context_output"
}

emit_audit_packet "$prompt" \
	"$out/route/user-prompt-submit.json" \
	"$out/route/user-prompt-context.json"

jq '{
	schema,
	route,
	confidence,
	budget,
	selection,
	gates,
	hardExclusions
}' "$out/route/user-prompt-submit.json" >"$out/route/route-summary.json"

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
	route_context="$out/route/context-$expected_route.json"
	emit_audit_packet "$route_prompt" "$route_file" "$route_context"
	jq -c --arg expected "$expected_route" '. + {expectedRoute: $expected}' "$route_file" \
		>>"$out/route/all-routes.jsonl"
done <"$out/route/route-prompts.tsv"

case "$out" in
/*) abs_out=$out ;;
*) abs_out="$repo_root/$out" ;;
esac

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
  save('tools.json', { tools: (tools.tools ?? []).map((tool) => tool.name).sort() });

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
  save('resources.json', Object.keys(JSON.parse(firstText(resources) || '{}')).sort());

  const readTargets = [
    'codex://surfaces/index',
    'codex://surface/codex-drift-kg/summary',
    'codex://drift/findings',
    'codex://graph-state/phase-one/summary',
    'codex://graph-state/phase-two/summary',
    'codex://promotion/status/summary',
    'kg://context/fingerprint',
    'kg://context/summary',
    'kg://context/invariants',
    'kg://index/summary',
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
	index("kg://context/fingerprint") != null
	and index("kg://context/summary") != null
	and index("kg://context/invariants") != null
	and index("kg://query/selfContext") != null
	and index("codex://surfaces/index") != null
	and index("codex://surfaces") != null
	and index("codex://promotion/status/summary") != null
' "$out/mcp/resources.json" >"$out/mcp/assert-selected-resources-declared.ok"

jq -e '
	.schema == "lattice.context-route-packet.v1"
	and .selection.resources == ["kg://context/summary", "codex://surfaces/index"]
' "$out/mcp/context-match.json" >"$out/mcp/assert-context-match.ok"

jq -e '
	.schema == "lattice-self-context-summary.v1"
' "$out/mcp/kg-context-summary.json" >"$out/mcp/assert-self-context-resource.ok"

jq -e '
	.schema == "codex-surfaces-index.v1"
	and (.surfaces | any(.id == "codex-drift-kg"))
	and (.surfaces | any(.id == "kg-hook-runtime"))
	and (.surfaces | any(.id == "project-knowledge-kg"))
' "$out/mcp/codex-surfaces-index.json" >"$out/mcp/assert-codex-surfaces-resource.ok"

jq -e '
	has("codex://surfaces/index")
	and has("codex://surface/codex-drift-kg/summary")
	and has("codex://drift/findings")
	and has("codex://graph-state/phase-one/summary")
	and has("codex://graph-state/phase-two/summary")
	and has("codex://promotion/status/summary")
	and has("kg://context/fingerprint")
	and has("kg://context/summary")
	and has("kg://context/invariants")
	and has("kg://index/summary")
' "$out/mcp/resource-read-summary.json" >"$out/mcp/assert-all-resource-classes-read.ok"

OUT_DIR="$abs_out" node --input-type=module <<'EOF'
import { readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { basename, join, relative } from 'node:path';

const outDir = process.env.OUT_DIR;
const generated = new Set(['MANIFEST.txt', 'token-stats.json', 'token-summary.tsv']);

function walk(dir) {
  return readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) return walk(path);
    if (generated.has(basename(path))) return [];
    return [path];
  });
}

function estimateTokens(text) {
  const compact = text.trim();
  if (!compact) return 0;
  const wordish = compact.match(/[A-Za-z0-9_]+|[^\sA-Za-z0-9_]/g)?.length ?? 0;
  return Math.max(wordish, Math.ceil(Buffer.byteLength(compact, 'utf8') / 4));
}

function sectionFor(path) {
  return relative(outDir, path).split('/')[0] || 'root';
}

const files = walk(outDir).sort();
const perFile = files.map((path) => {
  const text = readFileSync(path, 'utf8');
  const rel = relative(outDir, path);
  return {
    path: rel,
    section: sectionFor(path),
    bytes: statSync(path).size,
    chars: [...text].length,
    lines: text.length === 0 ? 0 : text.split(/\n/).length - (text.endsWith('\n') ? 1 : 0),
    words: text.trim() ? text.trim().split(/\s+/).length : 0,
    estimatedTokens: estimateTokens(text),
  };
});

const bySection = {};
for (const item of perFile) {
  bySection[item.section] ??= { files: 0, bytes: 0, chars: 0, lines: 0, words: 0, estimatedTokens: 0 };
  const section = bySection[item.section];
  section.files += 1;
  section.bytes += item.bytes;
  section.chars += item.chars;
  section.lines += item.lines;
  section.words += item.words;
  section.estimatedTokens += item.estimatedTokens;
}

const routePackets = perFile
  .filter((item) => item.path.startsWith('route/packet-') && item.path.endsWith('.json'))
  .map((item) => ({ route: item.path.slice('route/packet-'.length, -'.json'.length), ...item }));

const totals = perFile.reduce(
  (acc, item) => ({
    files: acc.files + 1,
    bytes: acc.bytes + item.bytes,
    chars: acc.chars + item.chars,
    lines: acc.lines + item.lines,
    words: acc.words + item.words,
    estimatedTokens: acc.estimatedTokens + item.estimatedTokens,
  }),
  { files: 0, bytes: 0, chars: 0, lines: 0, words: 0, estimatedTokens: 0 },
);

const stats = {
  schema: 'lattice.context-mcp-evidence-token-stats.v1',
  estimator: {
    kind: 'repo-local-heuristic',
    rule: 'max(regex token-like segments, ceil(utf8 bytes / 4))',
  },
  totals,
  bySection,
  routePackets,
  files: perFile,
};

writeFileSync(join(outDir, 'token-stats.json'), `${JSON.stringify(stats, null, 2)}\n`);
writeFileSync(
  join(outDir, 'token-summary.tsv'),
  [
    'section\tfiles\tbytes\tchars\tlines\twords\testimatedTokens',
    ...Object.entries(bySection)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([section, value]) => [
        section,
        value.files,
        value.bytes,
        value.chars,
        value.lines,
        value.words,
        value.estimatedTokens,
      ].join('\t')),
    ['total', totals.files, totals.bytes, totals.chars, totals.lines, totals.words, totals.estimatedTokens].join('\t'),
  ].join('\n') + '\n',
);
EOF

jq -e '
	.schema == "lattice.context-mcp-evidence-token-stats.v1"
	and .totals.estimatedTokens > 0
	and (.routePackets | length) == 6
	and (.bySection.route.estimatedTokens > 0)
	and (.bySection.mcp.estimatedTokens > 0)
' "$out/token-stats.json" >"$out/assert-token-stats.ok"

{
	printf 'Context MCP evidence bundle\n'
	printf '===========================\n\n'
	printf 'created_utc: %s\n' "$stamp"
	printf 'prompt: %s\n' "$prompt"
	printf 'head: %s\n' "$(cat "$out/repo/head.txt")"
	printf 'estimated_tokens: %s\n' "$(jq -r '.totals.estimatedTokens' "$out/token-stats.json")"
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
