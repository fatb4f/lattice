import assert from 'node:assert/strict';
import test from 'node:test';

import { normalizeFullIndex } from './index-response.js';

const provenance = {
  revision: 'abc123',
  inputDigest: 'sha256:123',
  kgVersion: 'kg v1',
  cueVersion: 'cue version v0.17.0',
};

const graph = {
  entities: {
    one: { collection: 'decisions', value: { related: { two: true } } },
    two: { collection: 'insights', value: {} },
  },
  summary: { total: 2 },
};

test('full KG index command failures use the structured invalid-index envelope', () => {
  const result = normalizeFullIndex({ ok: false, output: 'invalid graph' }, provenance);
  const envelope = JSON.parse(result.output);

  assert.equal(result.ok, false);
  assert.equal(envelope.schema, 'lattice.mcp-error.v1');
  assert.equal(envelope.error.code, 'kg_index_invalid');
  assert.equal(envelope.error.details.cause, 'invalid graph');
});

test('malformed full KG index output uses the structured invalid-JSON envelope', () => {
  const result = normalizeFullIndex({ ok: true, output: '{not-json' }, provenance);
  const envelope = JSON.parse(result.output);

  assert.equal(result.ok, false);
  assert.equal(envelope.schema, 'lattice.mcp-error.v1');
  assert.equal(envelope.error.code, 'kg_index_invalid_json');
  assert.match(envelope.error.details.cause, /JSON/);
});

test('full KG indexes are wrapped with provenance and normalized relations', () => {
  const result = normalizeFullIndex({ ok: true, output: JSON.stringify(graph) }, provenance);

  assert.equal(result.ok, true);
  assert.equal(result.value.schema, 'lattice.kg-full-index-envelope.v1');
  assert.equal(result.value.provenance.repositoryRevision, 'abc123');
  assert.deepEqual(result.value.graph.relations, [
    { source: 'one', predicate: 'related', target: 'two' },
  ]);
});

test('missing provenance cannot produce a valid full-index envelope', () => {
  const result = normalizeFullIndex({ ok: true, output: JSON.stringify(graph) });
  const envelope = JSON.parse(result.output);

  assert.equal(result.ok, false);
  assert.equal(envelope.error.code, 'kg_index_provenance_missing');
});

test('dangling relations fail the full index closed', () => {
  const invalidGraph = structuredClone(graph);
  invalidGraph.entities.one.value.related = { missing: true };
  const result = normalizeFullIndex(
    { ok: true, output: JSON.stringify(invalidGraph) },
    provenance,
  );
  const envelope = JSON.parse(result.output);

  assert.equal(result.ok, false);
  assert.equal(envelope.error.code, 'kg_index_dangling_relations');
});
