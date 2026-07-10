import assert from 'node:assert/strict';
import test from 'node:test';

import { normalizeFullIndex } from './index-response.js';

test('full KG index command failures use the structured invalid-index envelope', () => {
  const result = normalizeFullIndex({ ok: false, output: 'invalid graph' });
  const envelope = JSON.parse(result.output);

  assert.equal(result.ok, false);
  assert.equal(envelope.schema, 'lattice.mcp-error.v1');
  assert.equal(envelope.error.code, 'kg_index_invalid');
  assert.equal(envelope.error.details.cause, 'invalid graph');
});

test('malformed full KG index output uses the structured invalid-JSON envelope', () => {
  const result = normalizeFullIndex({ ok: true, output: '{not-json' });
  const envelope = JSON.parse(result.output);

  assert.equal(result.ok, false);
  assert.equal(envelope.schema, 'lattice.mcp-error.v1');
  assert.equal(envelope.error.code, 'kg_index_invalid_json');
  assert.match(envelope.error.details.cause, /JSON/);
});
