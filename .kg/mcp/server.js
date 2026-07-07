import { execFileSync } from 'node:child_process';
import { existsSync, readdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';

const serverDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(serverDir, '../..');
const kgDir = resolve(repoRoot, '.kg/codex');
const driftCheck = resolve(kgDir, 'tools/drift-check');
const topLevelCueFiles = [
  'model.cue',
  'reference.cue',
  'checks.cue',
  'kg.cue',
  'policy.cue',
].map((file) => resolve(kgDir, file));

function cueFiles(roleDir) {
  const dir = resolve(kgDir, roleDir);
  return readdirSync(dir)
    .filter((file) => file.endsWith('.cue'))
    .sort()
    .map((file) => resolve(dir, file));
}

const mcpCueFiles = cueFiles('mcp');
const aggregateCueFiles = cueFiles('aggregate');

const expressions = {
  surfaces: 'latticeReference.surfaces',
  policy: 'mcpPolicy',
  resources: 'mcpResources',
  tools: 'mcpTools',
  prompts: 'mcpPrompts',
  promotionStatus: 'promotionStatus',
  phaseOne: 'promotionStatus.phases."graph-state-phase-one"',
  phaseTwo: 'promotionStatus.phases."graph-state-phase-two"',
};

const resourceExpressions = {
  'codex://surfaces': expressions.surfaces,
  'codex://drift/findings': 'drift-findings',
  'codex://graph-state/phase-one': expressions.phaseOne,
  'codex://graph-state/phase-two': expressions.phaseTwo,
  'codex://promotion/status': expressions.promotionStatus,
};

function run(command, args, options = {}) {
  try {
    const output = execFileSync(command, args, {
      cwd: options.cwd || repoRoot,
      timeout: options.timeout || 15000,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    }).trim();

    return { ok: true, output: output || '{}'};
  } catch (error) {
    const output = (error.stderr || error.stdout || error.message || '').toString().trim();
    return { ok: false, output };
  }
}

function exportCue(expression, out = 'json') {
  let files = topLevelCueFiles;
  if (
    expression === expressions.policy ||
    expression === expressions.resources ||
    expression === expressions.tools ||
    expression === expressions.prompts
  ) {
    files = mcpCueFiles;
  } else if (
    expression === expressions.promotionStatus ||
    expression === expressions.phaseOne ||
    expression === expressions.phaseTwo
  ) {
    files = aggregateCueFiles;
  }

  return run('cue', ['export', ...files, '-e', expression, '--out', out]);
}

function driftFindings(mode = 'full') {
  return run(driftCheck, ['--format', 'json', '--mode', mode], { timeout: 20000 });
}

function content(result) {
  return {
    content: [{ type: 'text', text: result.output || '{}' }],
    isError: !result.ok,
  };
}

function text(value) {
  return {
    content: [{ type: 'text', text: value }],
  };
}

const server = new McpServer(
  {
    name: 'lattice-kg',
    version: '0.1.0',
  },
  {
    instructions: [
      'Read-only Codex KG server for this lattice repository.',
      'Use it to inspect declared surfaces, drift findings, and phase promotion status.',
      'The server does not mutate repository files.',
    ].join(' '),
  },
);

server.tool(
  'kg_status',
  'Show whether the lattice Codex KG and drift tooling are available.',
  {},
  async () => {
    const checks = {
      repoRoot,
      kgDir,
      kgDirExists: existsSync(kgDir),
      driftCheckExists: existsSync(driftCheck),
      cuePolicy: exportCue(expressions.policy).ok,
    };

    return text(JSON.stringify(checks, null, 2));
  },
);

server.tool(
  'kg_query',
  'Evaluate an allowed read-only Codex KG CUE expression and return JSON.',
  {
    expression: z
      .enum(Object.keys(expressions))
      .default('policy')
      .describe('Named expression to evaluate.'),
  },
  async ({ expression }) => content(exportCue(expressions[expression])),
);

server.tool(
  'kg_drift_scan',
  'Scan repository and patch facts for Codex KG drift findings.',
  {
    mode: z.enum(['full', 'repo', 'patch']).default('full').describe('Drift scan scope.'),
  },
  async ({ mode }) => content(driftFindings(mode)),
);

server.tool(
  'kg_phase_status',
  'Read graph-state phase watchdog status.',
  {
    phase: z.enum(['all', 'phase-one', 'phase-two']).default('all').describe('Phase status scope.'),
  },
  async ({ phase }) => {
    if (phase === 'phase-one') return content(exportCue(expressions.phaseOne));
    if (phase === 'phase-two') return content(exportCue(expressions.phaseTwo));
    return content(exportCue(expressions.promotionStatus));
  },
);

server.tool(
  'kg_surface_explain',
  'Read declared Codex KG control surfaces.',
  {},
  async () => content(exportCue(expressions.surfaces)),
);

server.tool(
  'kg_mcp_policy',
  'Read the declared MCP read-only policy, resources, tools, and prompts.',
  {},
  async () => content(exportCue(expressions.policy)),
);

server.tool(
  'kg_vet',
  'Validate the lattice Codex KG CUE package.',
  {},
  async () => {
    const result = run('cue', ['vet', ...topLevelCueFiles]);
    if (result.ok) return text('OK: .kg/codex CUE package is valid');
    return content(result);
  },
);

for (const [uri, expression] of Object.entries(resourceExpressions)) {
  server.resource(uri, uri, async () => {
    const result = expression === 'drift-findings' ? driftFindings() : exportCue(expression);
    return {
      contents: [
        {
          uri,
          mimeType: 'application/json',
          text: result.output || '{}',
        },
      ],
    };
  });
}

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('lattice-kg MCP server running');
}

main().catch((error) => {
  console.error('Fatal:', error);
  process.exit(1);
});
