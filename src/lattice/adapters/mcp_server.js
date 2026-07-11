// Compatibility launcher only. Python owns all MCP resource behavior.
import { spawnSync } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const uv = process.env.UV_BIN || 'uv';
const result = spawnSync(uv, [
  'run',
  '--project',
  repoRoot,
  '--locked',
  'lattice-mcp',
  ...process.argv.slice(2),
], {
  env: process.env,
  stdio: 'inherit',
});

if (result.error) throw result.error;
process.exitCode = result.status ?? 1;
