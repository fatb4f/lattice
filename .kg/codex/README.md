# Codex KG

`.kg/codex` is the lattice-local Codex knowledge graph package.

It is not the promotion authority. Promotion remains owned by
`meta/kernel.cue`. This package observes repository drift, projects phase
watchdog status, and declares a read-only MCP surface.

## Package Roles

```text
core/       canonical Codex KG entry types
vocab/      shared identifiers, enums, and context terms
ext/        lattice-specific observations and graph-state extensions
aggregate/ computed indexes, drift, lint, and promotion status
mcp/        read-only MCP resource, tool, prompt, and policy declarations
tests/      valid and invalid KG fixtures
tools/      drift fact, check, and hook helpers
```

## Boundary

```text
meta/kernel.cue owns promotion admission.
.kg/codex owns drift observation and read-only reporting surfaces.
```
