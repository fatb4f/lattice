function errorOutput(code, message, details = {}) {
  return {
    ok: false,
    output: JSON.stringify({
      schema: 'lattice.mcp-error.v1',
      error: { code, message, details },
    }, null, 2),
  };
}

const INDEX_SCHEMA = 'lattice.kg-full-index-envelope.v1';

function invalid(code, message, details = {}) {
  return errorOutput(code, message, details);
}

export function validateFullIndex(graph) {
  if (!graph || typeof graph !== 'object' || Array.isArray(graph)) {
    return invalid('kg_index_incomplete', 'The full KG index must be a JSON object');
  }

  if (!graph.entities || typeof graph.entities !== 'object' || Array.isArray(graph.entities)) {
    return invalid('kg_index_incomplete', 'The full KG index does not contain a typed entity inventory');
  }

  const entityIDs = new Set(Object.keys(graph.entities));
  if (
    entityIDs.size === 0 ||
    typeof graph.summary?.total !== 'number' ||
    !Number.isInteger(graph.summary.total) ||
    graph.summary.total !== Object.values(graph.entities)
      .filter((record) => record?.collection !== 'context').length
  ) {
    return invalid('kg_index_incomplete', 'The full KG index entity inventory is incomplete', {
      declaredTotal: graph.summary?.total,
      entityCount: entityIDs.size,
    });
  }

  const relations = [];
  const dangling = [];
  for (const [source, record] of Object.entries(graph.entities)) {
    if (
      !record ||
      typeof record !== 'object' ||
      Array.isArray(record) ||
      !record.collection ||
      !record.value ||
      typeof record.value !== 'object' ||
      Array.isArray(record.value)
    ) {
      return invalid('kg_index_incomplete', 'A full KG index entity is missing its type or value', {
        id: source,
      });
    }
    const related = Object.hasOwn(record.value, 'related') ? record.value.related : {};
    if (!related || typeof related !== 'object' || Array.isArray(related)) {
      return invalid('kg_index_incomplete', 'An entity related field must be an object', { id: source });
    }
    for (const [target, selected] of Object.entries(related)) {
      if (selected !== true) continue;
      const relation = { source, predicate: 'related', target };
      relations.push(relation);
      if (!entityIDs.has(target)) dangling.push(relation);
    }
  }

  if (dangling.length > 0) {
    return invalid('kg_index_dangling_relations', 'The full KG index contains dangling relations', {
      relations: dangling,
    });
  }

  const ordinal = (left, right) => {
    const leftPoints = Array.from(left, (value) => value.codePointAt(0));
    const rightPoints = Array.from(right, (value) => value.codePointAt(0));
    for (let index = 0; index < Math.min(leftPoints.length, rightPoints.length); index += 1) {
      if (leftPoints[index] !== rightPoints[index]) return leftPoints[index] < rightPoints[index] ? -1 : 1;
    }
    return leftPoints.length === rightPoints.length ? 0 : leftPoints.length < rightPoints.length ? -1 : 1;
  };
  relations.sort((left, right) => {
    for (const field of ['source', 'predicate', 'target']) {
      const compared = ordinal(left[field], right[field]);
      if (compared !== 0) return compared;
    }
    return 0;
  });
  return { ok: true, relations };
}

export function normalizeFullIndex(result, provenance = {}) {
  if (!result.ok) {
    return errorOutput(
      'kg_index_invalid',
      'Unable to produce the validated full KG index',
      { cause: result.output },
    );
  }

  try {
    const graph = JSON.parse(result.output || '{}');
    const validation = validateFullIndex(graph);
    if (!validation.ok) return validation;

    const required = ['revision', 'inputDigest', 'policyDigest', 'kgVersion', 'cueVersion'];
    const missing = required.filter((field) => !provenance[field]);
    if (missing.length > 0) {
      return invalid('kg_index_provenance_missing', 'The full KG index provenance is incomplete', {
        missing,
      });
    }
    if (
      !/^sha256:[0-9a-f]{64}$/.test(provenance.inputDigest) ||
      !/^sha256:[0-9a-f]{64}$/.test(provenance.policyDigest) ||
      !/^sha256:[0-9a-f]{64}$/.test(provenance.kgVersion)
    ) {
      return invalid('kg_index_provenance_invalid', 'Full-index provenance digests are invalid');
    }

    return {
      ok: true,
      value: {
        schema: INDEX_SCHEMA,
        provenance: {
          repositoryRevision: provenance.revision,
          inputDigest: provenance.inputDigest,
          policyDigest: provenance.policyDigest,
          tools: {
            kg: provenance.kgVersion,
            cue: provenance.cueVersion,
          },
        },
        graph: {
          ...graph,
          relations: validation.relations,
        },
      },
    };
  } catch (error) {
    return errorOutput(
      'kg_index_invalid_json',
      'The full KG index was not valid JSON',
      { cause: error.message },
    );
  }
}
