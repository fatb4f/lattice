function errorOutput(code, message, details = {}) {
  return {
    ok: false,
    output: JSON.stringify({
      schema: 'lattice.mcp-error.v1',
      error: { code, message, details },
    }, null, 2),
  };
}

export function normalizeFullIndex(result) {
  if (!result.ok) {
    return errorOutput(
      'kg_index_invalid',
      'Unable to produce the validated full KG index',
      { cause: result.output },
    );
  }

  try {
    return { ok: true, value: JSON.parse(result.output || '{}') };
  } catch (error) {
    return errorOutput(
      'kg_index_invalid_json',
      'The full KG index was not valid JSON',
      { cause: error.message },
    );
  }
}
