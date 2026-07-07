---
name: kg-agent
description: Use the repo-local quicue kg CLI to inspect, validate, index, query, and safely update the .kb knowledge graph. Trigger for requests about KG entries, ADRs, patterns, insights, rejected approaches, upstream quicue kg shape, kg index/query/settle/graph output, or agent workflows that need project knowledge before editing.
---

# KG Agent

## Workflow

1. Work from the repository root.
2. Use the `kg` CLI as the primary interface for `.kb`:
   - `kg vet` before trusting or after editing entries.
   - `kg index --full` for the full project KG.
   - `kg index` for summary counts.
   - `kg query '<cue expression>'` for focused reads.
   - `kg settle` for referential integrity and coverage.
   - `kg graph --json` or `kg graph --dot` for relationship views.
3. Treat `.kb` as the project knowledge graph and `.kg/codex` as the Codex drift-control KG. Do not merge their authority boundaries.
4. When adding entries, prefer `kg add decision`, `kg add pattern`, `kg add insight`, or `kg add rejected`, then edit the generated CUE file.
5. Keep `.kb/index.cue` as the CLI `_index` aggregate; update it when adding new entries so `kg index --full` sees them.
6. Run `./scripts/validate-domain.sh` after KG changes when repository drift surfaces or validation coverage may be affected.

## Editing Rules

- Preserve the CLI-managed `.kb/cue.mod` module shape.
- Do not edit `.kb/cue.mod/pkg` symlink targets by hand.
- Use struct-as-set links: `related: {"ADR-001": true}`.
- Keep IDs stable: `ADR-###`, `INSIGHT-###`, and `REJ-###`.
- Avoid TODO placeholders in committed `.kb` entries; `kg vet --strict` reports them.

## Useful Queries

```bash
kg query decisions
kg query insights
kg query patterns
kg query rejected
kg query _index.by_status.accepted
kg query _index.by_confidence.high
```
