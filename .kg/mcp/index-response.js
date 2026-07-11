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
    graph.summary.total > entityIDs.size
  ) {
    return invalid('kg_index_incomplete', 'The full KG index entity inventory is incomplete', {
      declaredTotal: graph.summary?.total,
      entityCount: entityIDs.size,
    });
  }

  const relations = [];
  const dangling = [];
  for (const [source, record] of Object.entries(graph.entities)) {
    if (!record?.collection || !record?.value || typeof record.value !== 'object') {
      return invalid('kg_index_incomplete', 'A full KG index entity is missing its type or value', {
        id: source,
      });
    }
    for (const [target, selected] of Object.entries(record.value.related || {})) {
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

  relations.sort((left, right) =>
    `${left.source}\0${left.predicate}\0${left.target}`.localeCompare(
      `${right.source}\0${right.predicate}\0${right.target}`,
    ));
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

    const required = ['revision', 'inputDigest', 'kgVersion', 'cueVersion'];
    const missing = required.filter((field) => !provenance[field]);
    if (missing.length > 0) {
      return invalid('kg_index_provenance_missing', 'The full KG index provenance is incomplete', {
        missing,
      });
    }

    return {
      ok: true,
      value: {
        schema: INDEX_SCHEMA,
        provenance: {
          repositoryRevision: provenance.revision,
          inputDigest: provenance.inputDigest,
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
