import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, lstatSync, readFileSync, readlinkSync, readdirSync, realpathSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { McpServer, ResourceTemplate } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';

import { normalizeFullIndex } from './index_response.js';

const serverDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(serverDir, '../../..');
const kgDir = resolve(repoRoot, '.kg/codex');
const driftCheck = resolve(kgDir, 'tools/drift-check');
const contextHook = resolve(repoRoot, '.kg/hooks/codex/user-prompt-submit');
const localKgShim = resolve(repoRoot, '.kg/tools/kg');
const toolchainGate = resolve(repoRoot, 'scripts/require-toolchain.sh');
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
  'codex://surfaces/index': 'surfaces-index',
  'codex://drift/findings': 'gate-findings',
  'codex://graph-state/phase-one': expressions.phaseOne,
  'codex://graph-state/phase-one/summary': 'phase-one-summary',
  'codex://graph-state/phase-two': expressions.phaseTwo,
  'codex://graph-state/phase-two/summary': 'phase-two-summary',
  'codex://promotion/status': expressions.promotionStatus,
  'codex://promotion/status/summary': 'promotion-summary',
};

const kgResourceCommands = {
  'kg://query/selfContext': ['query', 'selfContext'],
  'kg://context/full': ['query', 'selfContext'],
  'kg://index/summary': ['index'],
  'kg://index/full': ['index', '--full'],
};

const kgContextProjections = new Set([
  'kg://context/fingerprint',
  'kg://context/summary',
  'kg://context/invariants',
]);

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
  const configured = process.env.KG_BIN || resolve(repoRoot, '.cache/bin/kg');
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

  const gate = run('bash', [toolchainGate]);
  if (!gate.ok) return errorOutput('toolchain_invalid', gate.output);
  return run(process.env.CUE_BIN || 'cue', ['export', ...files, '-e', expression, '--out', out]);
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
  const gate = run('bash', [toolchainGate]);
  if (!gate.ok) return errorOutput('toolchain_invalid', gate.output);
  const kg = resolveExternalKg();
  if (!kg.ok) return { ok: false, output: kg.error };
  return run(kg.path, args, { timeout: options.timeout || 20000 });
}

function fullIndex() {
  const kg = resolveExternalKg();
  if (!kg.ok) return errorOutput('kg_index_toolchain_unsupported', kg.error);

  const revision = run('git', ['rev-parse', 'HEAD']);
  const cueVersion = run(process.env.CUE_BIN || 'cue', ['version']);
  const inputs = run('git', ['ls-files', '-co', '--exclude-standard', '--', '.kb']);
  if (!revision.ok || !cueVersion.ok || !inputs.ok) {
    return errorOutput(
      'kg_index_provenance_unavailable',
      'Unable to determine full-index provenance',
      { revision: revision.output, cue: cueVersion.output, inputs: inputs.output },
    );
  }

  const digest = createHash('sha256');
  for (const path of inputs.output.split('\n').filter(Boolean).sort()) {
    const absolute = resolve(repoRoot, path);
    digest.update(path);
    digest.update('\0');
    const stat = lstatSync(absolute);
    digest.update(stat.isSymbolicLink() ? readlinkSync(absolute) : readFileSync(absolute));
    digest.update('\0');
  }
  const kgDigest = createHash('sha256').update(readFileSync(kg.path)).digest('hex');

  return normalizeFullIndex(
    kgCommand(['index', '--full'], { timeout: 30000 }),
    {
      revision: revision.output,
      inputDigest: `sha256:${digest.digest('hex')}`,
      kgVersion: `sha256:${kgDigest}`,
      cueVersion: cueVersion.output.split('\n')[0],
    },
  );
}

function parseJSONResult(result, label) {
  if (!result.ok) return result;

  try {
    return { ok: true, value: JSON.parse(result.output || '{}') };
  } catch (error) {
    return { ok: false, output: `failed to parse ${label}: ${error.message}` };
  }
}

function jsonOutput(value) {
  return {
    ok: true,
    output: JSON.stringify(value, null, 2),
  };
}

function errorOutput(code, message, details = {}) {
  return {
    ok: false,
    output: JSON.stringify({
      schema: 'lattice.mcp-error.v1',
      error: { code, message, details },
    }, null, 2),
  };
}

function surfaceIndex() {
  const result = parseJSONResult(exportCue(expressions.surfaces), 'codex surfaces');
  if (!result.ok) return result;

  const surfaces = Object.entries(result.value || {}).map(([id, surface]) => ({
    id,
    kind: surface.kind,
  }));

  return jsonOutput({
    schema: 'codex-surfaces-index.v1',
    count: surfaces.length,
    surfaces,
  });
}

function surfaceProjection(id, projection) {
  const result = parseJSONResult(exportCue(expressions.surfaces), 'codex surfaces');
  if (!result.ok) return result;

  const surface = result.value?.[id];
  if (!surface) return { ok: false, output: `Codex surface not found: ${id}` };

  if (projection === 'summary') {
    return jsonOutput({
      schema: 'codex-surface-summary.v1',
      id,
      kind: surface.kind,
      role: surface.role,
      path: surface.path,
      description: surface.description,
      reads: surface.reads,
      forbids: surface.forbids,
    });
  }

  if (projection === 'paths') {
    return jsonOutput({
      schema: 'codex-surface-paths.v1',
      id,
      path: surface.path,
      requiredPaths: surface.requiredPaths || [],
      forbiddenPaths: surface.forbiddenPaths || [],
      protectedPaths: surface.protectedPaths || [],
      watchedPaths: surface.watchedPaths || [],
    });
  }

  return jsonOutput({
    schema: 'codex-surface-full.v1',
    id,
    surface,
  });
}

function summarizePhase(id, status) {
  const findings = status?.evaluation?.findings || status?.findings || [];
  const blockingFindings = status?.evaluation?.blockingFindings || status?.blockingFindings || [];
  return {
    id,
    status: status?.phase?.status,
    description: status?.phase?.description,
    watchedPathCount: status?.phase?.watchedPaths?.length || 0,
    findingCount: findings.length,
    blockingFindingCount: blockingFindings.length,
    blockingKinds: [...new Set(blockingFindings.map((finding) => finding.kind).filter(Boolean))].sort(),
  };
}

function promotionSummary(scope) {
  const result = parseJSONResult(phaseStatus('all'), 'promotion status');
  if (!result.ok) return result;

  const phases = result.value?.phases || {};
  if (scope) {
    return jsonOutput({
      schema: 'codex-phase-status-summary.v1',
      phase: summarizePhase(scope, phases[scope]),
    });
  }

  return jsonOutput({
    schema: 'codex-promotion-status-summary.v1',
    phases: Object.fromEntries(
      Object.entries(phases).map(([id, status]) => [id, summarizePhase(id, status)]),
    ),
  });
}

function selfContextProjection(projection) {
  const result = parseJSONResult(kgCommand(['query', 'selfContext']), 'kg query selfContext');
  if (!result.ok) return result;

  const context = result.value || {};
  const surfaces = context.surfaces || {};
  const invariants = context.invariants || {};

  if (projection === 'fingerprint') {
    return jsonOutput({
      schema: 'lattice-self-context-fingerprint.v1',
      authority: context.authority,
      surfaceCount: Object.keys(surfaces).length,
      invariantCount: Object.keys(invariants).length,
    });
  }

  if (projection === 'summary') {
    return jsonOutput({
      schema: 'lattice-self-context-summary.v1',
      surfaces: Object.fromEntries(
        Object.entries(surfaces).map(([id, surface]) => [
          id,
          {
            role: surface.role,
            path: surface.path,
          },
        ]),
      ),
      invariantIDs: Object.keys(invariants),
    });
  }

  return jsonOutput({
    schema: 'lattice-self-context-invariants.v1',
    authority: context.authority,
    invariants: Object.fromEntries(
      Object.entries(invariants).map(([id, invariant]) => [
        id,
        {
          statement: invariant.statement,
          enforcedBy: invariant.enforcedBy,
        },
      ]),
    ),
  });
}

function entityByID(id) {
  const index = fullIndex();
  if (!index.ok) return index;

  const record = index.value?.graph?.entities?.[id];
  if (record) {
    return jsonOutput({
      schema: 'lattice.kg-entity.v1',
      index: index.value.provenance,
      id,
      collection: record.collection,
      entity: record.value,
    });
  }

  return errorOutput('kg_entity_not_found', `KG entity not found: ${id}`, { id });
}

function relatedEntities(id) {
  const index = fullIndex();
  if (!index.ok) return index;

  const entity = index.value?.graph?.entities?.[id];
  if (!entity) return errorOutput('kg_entity_not_found', `KG entity not found: ${id}`, { id });

  const relatedIDs = index.value.graph.relations
    .filter((relation) => relation.source === id)
    .map((relation) => relation.target)
    .slice(0, 8);

  const related = relatedIDs.map((relatedID) => {
    const record = index.value.graph.entities[relatedID];
    return { id: relatedID, collection: record.collection, entity: record.value };
  });

  return {
    ok: true,
    output: JSON.stringify({
      schema: 'lattice.kg-related.v1',
      index: index.value.provenance,
      id,
      related,
    }, null, 2),
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
    const gate = run('bash', [toolchainGate]);
    if (!gate.ok) return content(errorOutput('toolchain_invalid', gate.output));
    const result = run(process.env.CUE_BIN || 'cue', ['vet', ...topLevelCueFiles]);
    if (result.ok) return text('OK: .kg/codex Codex drift KG CUE package is valid');
    return content(result);
  },
);

for (const [uri, expression] of Object.entries(resourceExpressions)) {
  server.resource(uri, uri, async () => {
    let result;
    if (expression === 'gate-findings') {
      result = driftFindings('gate');
    } else if (expression === 'surfaces-index') {
      result = surfaceIndex();
    } else if (expression === 'promotion-summary') {
      result = promotionSummary();
    } else if (expression === 'phase-one-summary') {
      result = promotionSummary('graph-state-phase-one');
    } else if (expression === 'phase-two-summary') {
      result = promotionSummary('graph-state-phase-two');
    } else {
      result = queryExpression(expression);
    }
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

for (const uri of kgContextProjections) {
  server.resource(uri, uri, async () => {
    const result = selfContextProjection(uri.split('/').at(-1));
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
    const result = uri === 'kg://index/full'
      ? (() => {
          const index = fullIndex();
          return index.ok ? jsonOutput(index.value) : index;
        })()
      : kgCommand(args, { timeout: 20000 });
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

for (const projection of ['summary', 'paths', 'full']) {
  const template = `codex://surface/{id}/${projection}`;
  server.resource(
    template,
    new ResourceTemplate(template, { list: undefined }),
    async (uri, variables) => {
      const id = String(variables.id || '');
      const result = surfaceProjection(id, projection);
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
}

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('lattice-codex-kg MCP server running');
}

main().catch((error) => {
  console.error('Fatal:', error);
  process.exit(1);
});
