import { execFileSync } from 'node:child_process';
import { existsSync, readdirSync, realpathSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { McpServer, ResourceTemplate } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';

const serverDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(serverDir, '../..');
const kgDir = resolve(repoRoot, '.kg/codex');
const driftCheck = resolve(kgDir, 'tools/drift-check');
const contextHook = resolve(repoRoot, '.kg/hooks/codex/user-prompt-submit');
const localKgShim = resolve(repoRoot, '.kg/tools/kg');
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
  'codex://drift/findings': 'gate-findings',
  'codex://graph-state/phase-one': expressions.phaseOne,
  'codex://graph-state/phase-two': expressions.phaseTwo,
  'codex://promotion/status': expressions.promotionStatus,
};

const kgResourceCommands = {
  'kg://query/selfContext': ['query', 'selfContext'],
  'kg://index/summary': ['index'],
  'kg://index/full': ['index', '--full'],
};

function resolveExecutable(command) {
  if (command.includes('/')) return resolve(repoRoot, command);

  for (const dir of (process.env.PATH || '').split(':')) {
    if (!dir) continue;
    const candidate = resolve(dir, command);
    if (existsSync(candidate)) return candidate;
  }

  return '';
}

function resolveExternalKg() {
  const configured = process.env.KG_BIN || 'kg';
  const resolved = resolveExecutable(configured);
  if (!resolved) {
    return { ok: false, error: `external kg CLI not found: ${configured}` };
  }

  const resolvedReal = realpathSync(resolved);
  const localReal = existsSync(localKgShim) ? realpathSync(localKgShim) : localKgShim;
  if (resolvedReal === localReal) {
    return { ok: false, error: 'external kg CLI resolves to local shim; refusing recursion' };
  }

  return { ok: true, path: resolvedReal };
}

function run(command, args, options = {}) {
  try {
    const output = execFileSync(command, args, {
      cwd: options.cwd || repoRoot,
      timeout: options.timeout || 15000,
      encoding: 'utf8',
      input: options.input,
      stdio: [options.input === undefined ? 'ignore' : 'pipe', 'pipe', 'pipe'],
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

function phaseStatus(phase = 'all') {
  if (phase === 'phase-one') {
    return run(
      driftCheck,
      ['--format', 'json', '--mode', 'phase', '--phase', 'graph-state-phase-one'],
      { timeout: 20000 },
    );
  }

  if (phase === 'phase-two') {
    return run(
      driftCheck,
      ['--format', 'json', '--mode', 'phase', '--phase', 'graph-state-phase-two'],
      { timeout: 20000 },
    );
  }

  return run(driftCheck, ['--format', 'json', '--mode', 'phase'], { timeout: 20000 });
}

function contextMatch(prompt) {
  const event = JSON.stringify({
    hook_event_name: 'UserPromptSubmit',
    prompt,
  });
  const result = run('sh', [contextHook], { input: event, timeout: 20000 });
  if (!result.ok) return result;

  try {
    const hookEnvelope = JSON.parse(result.output);
    const packet = JSON.parse(hookEnvelope.hookSpecificOutput?.additionalContext || '{}');
    return { ok: true, output: JSON.stringify(packet, null, 2) };
  } catch (error) {
    return { ok: false, output: `failed to parse context hook output: ${error.message}` };
  }
}

function kgCommand(args, options = {}) {
  const kg = resolveExternalKg();
  if (!kg.ok) return { ok: false, output: kg.error };
  return run(kg.path, args, { timeout: options.timeout || 20000 });
}

function fullIndex() {
  const result = kgCommand(['index', '--full'], { timeout: 30000 });
  if (!result.ok) return result;

  try {
    return { ok: true, value: JSON.parse(result.output || '{}') };
  } catch (error) {
    return { ok: false, output: `failed to parse kg index --full: ${error.message}` };
  }
}

function entityByID(id) {
  if (id === 'project-context') return kgCommand(['query', 'selfContext']);

  const index = fullIndex();
  if (!index.ok) return index;

  const collections = ['decisions', 'insights', 'rejected', 'patterns'];
  for (const collection of collections) {
    const entity = index.value?.[collection]?.[id];
    if (entity) {
      return {
        ok: true,
        output: JSON.stringify({ id, collection, entity }, null, 2),
      };
    }
  }

  return { ok: false, output: `KG entity not found: ${id}` };
}

function relatedEntities(id) {
  const entityResult = entityByID(id);
  if (!entityResult.ok) return entityResult;

  if (id === 'project-context') {
    return {
      ok: true,
      output: JSON.stringify({ id, related: [] }, null, 2),
    };
  }

  const index = fullIndex();
  if (!index.ok) return index;

  let entity;
  for (const collection of ['decisions', 'insights', 'rejected', 'patterns']) {
    entity = index.value?.[collection]?.[id];
    if (entity) break;
  }

  const relatedIDs = Object.entries(entity?.related || {})
    .filter(([, selected]) => selected === true)
    .map(([relatedID]) => relatedID)
    .slice(0, 8);

  const related = relatedIDs
    .map((relatedID) => {
      const result = entityByID(relatedID);
      if (!result.ok) return { id: relatedID, error: result.output };
      return JSON.parse(result.output);
    });

  return {
    ok: true,
    output: JSON.stringify({ id, related }, null, 2),
  };
}

function queryExpression(expression) {
  if (expression === expressions.phaseOne) return phaseStatus('phase-one');
  if (expression === expressions.phaseTwo) return phaseStatus('phase-two');
  if (expression === expressions.promotionStatus) return phaseStatus('all');
  return exportCue(expression);
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
    name: 'lattice-codex-kg',
    version: '0.1.0',
  },
  {
    instructions: [
      'Read-only Codex drift KG server for this lattice repository.',
      'Use it to inspect declared surfaces, drift findings, phase promotion status, and targeted project KG reads.',
      'It exposes .kg/codex control resources and bounded read-only .kb resources, and does not mutate repository files.',
    ].join(' '),
  },
);

server.tool(
  'kg_status',
  'Show whether the lattice Codex drift KG and drift tooling are available.',
  {},
  async () => {
    const checks = {
      repoRoot,
      kgDir,
      kgDirExists: existsSync(kgDir),
      driftCheckExists: existsSync(driftCheck),
      contextHookExists: existsSync(contextHook),
      cuePolicy: exportCue(expressions.policy).ok,
      kg: resolveExternalKg(),
    };

    return text(JSON.stringify(checks, null, 2));
  },
);

server.tool(
  'kg_query',
  'Evaluate an allowed read-only Codex drift KG CUE expression and return JSON.',
  {
    expression: z
      .enum(Object.keys(expressions))
      .default('policy')
      .describe('Named expression to evaluate.'),
  },
  async ({ expression }) => content(queryExpression(expressions[expression])),
);

server.tool(
  'kg_drift_scan',
  'Scan Codex KG drift findings by scope.',
  {
    mode: z
      .enum(['full', 'repo', 'patch', 'phase', 'promotion', 'gate'])
      .default('full')
      .describe('Drift scan scope.'),
  },
  async ({ mode }) => content(driftFindings(mode)),
);

server.tool(
  'kg_phase_status',
  'Read graph-state phase watchdog status.',
  {
    phase: z.enum(['all', 'phase-one', 'phase-two']).default('all').describe('Phase status scope.'),
  },
  async ({ phase }) => content(phaseStatus(phase)),
);

server.tool(
  'kg_surface_explain',
  'Read declared Codex drift KG control surfaces.',
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
  'kg_context_match',
  'Return the bounded route packet that UserPromptSubmit would inject for a prompt.',
  {
    prompt: z.string().min(1).describe('Prompt text to match against the repo-local .kb project KG.'),
  },
  async ({ prompt }) => content(contextMatch(prompt)),
);

server.tool(
  'kg_vet',
  'Validate the lattice Codex drift KG CUE package.',
  {},
  async () => {
    const result = run('cue', ['vet', ...topLevelCueFiles]);
    if (result.ok) return text('OK: .kg/codex Codex drift KG CUE package is valid');
    return content(result);
  },
);

for (const [uri, expression] of Object.entries(resourceExpressions)) {
  server.resource(uri, uri, async () => {
    const result = expression === 'gate-findings' ? driftFindings('gate') : queryExpression(expression);
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

for (const [uri, args] of Object.entries(kgResourceCommands)) {
  server.resource(uri, uri, async () => {
    const result = kgCommand(args, { timeout: uri === 'kg://index/full' ? 30000 : 20000 });
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

server.resource(
  'kg://entity/{id}',
  new ResourceTemplate('kg://entity/{id}', { list: undefined }),
  async (uri, variables) => {
    const id = String(variables.id || '');
    const result = entityByID(id);
    return {
      contents: [
        {
          uri: uri.href,
          mimeType: 'application/json',
          text: result.output || '{}',
        },
      ],
    };
  },
);

server.resource(
  'kg://related/{id}',
  new ResourceTemplate('kg://related/{id}', { list: undefined }),
  async (uri, variables) => {
    const id = String(variables.id || '');
    const result = relatedEntities(id);
    return {
      contents: [
        {
          uri: uri.href,
          mimeType: 'application/json',
          text: result.output || '{}',
        },
      ],
    };
  },
);

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('lattice-codex-kg MCP server running');
}

main().catch((error) => {
  console.error('Fatal:', error);
  process.exit(1);
});
