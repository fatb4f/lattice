# Graph-State Projection

This projection defines the Phase 1 graph-state primitive ontology.

Phase 1 is intentionally domain-neutral. It names stable graph-state entities,
their identifiers, and the source witnesses that justify them. It does not
define runtime adapters, graph algorithms, or operational closedness behavior.

## Phase 1 Surface

The primitive surface lives under `primitives/`:

- identity identifiers for graphs, nodes, edges, objects, refs, and paths
- graph containers for node and edge maps
- target, workspace, stream, fragment, assignment, dependency, conflict,
  projection, context, and producer surface primitives
- a source ledger that separates GitButler, go-git, and Pro Git witness roles

Promotion is exposed from the root package as `closedPhaseOnePromotion` and
closes through `meta.#MakeClosedObligationState`.
