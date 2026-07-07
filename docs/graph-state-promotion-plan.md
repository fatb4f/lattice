# Graph-State Promotion Plan

## Purpose

This plan defines how graph-state work promotes through the existing
`meta/kernel.cue` admission surface.

The promotion contract is intentionally derived from the actual meta kernel.
Brainstorm labels such as `source-ledger-complete` or `closedness-proven` may be
used as projection-owned gates, but the meta kernel only proves the structural
obligations it defines.

## Kernel-Derived Promotion Rules

Every graph-state phase must expose a promotion contract as a
`meta.#ObligationState` and close it through `meta.#MakeClosedObligationState`.

The meta kernel proves these obligations:

- state IDs, resource keys, operation keys, gate keys, and witness keys are
  kebab-case identifiers
- every operation `reads` reference points to a declared resource
- every operation `writes` reference points to a declared resource
- every operation `creates` reference points to a declared resource
- every created resource has role `generated-output`
- every `requiresGates` reference points to a declared gate
- every `requiresWitnesses` reference points to a declared witness
- keyed IDs are injected from map keys by the constructor

Projection-specific gates prove only what the projection defines in CUE. The
meta kernel admits those gates and proves that operations reference declared
gate IDs; it does not prove the semantic meaning of those gates by itself.

## Phase 1: Graph-State Primitives

### Objective

Define the domain-neutral graph-state ontology.

Phase 1 answers:

```text
What are the primitive entities of graph-state?
What stable identifiers do they use?
What nouns are justified by source witnesses?
What belongs in the universal graph-state model vs downstream narrowing?
```

Phase 1 must not implement graph behavior, adapters, or runtime integration.

### Source Witness Roles

Phase 1 uses implementation and documentation surfaces as ontology evidence:

| Source | Role |
| --- | --- |
| GitButler Rust crates | primary state and intent witness |
| go-git | Git storage and substrate witness |
| Pro Git | conceptual witness for object database, refs, and three trees |

GitButler `Stack` supports the `Stream` primitive. Relevant observed fields
include stable identity, source ref name, upstream, order, workspace membership,
and heads.

GitButler `HunkAssignment` supports the `Fragment` and `Assignment` primitives.
Relevant observed fields include hunk identity, optional hunk header, path,
optional stack assignment, branch ref target, added and removed line numbers,
and diff data.

GitButler hunk dependency surfaces support the `Dependency` primitive by
modeling patch dependency in terms of apply and merge-conflict constraints.

go-git supports storage primitives such as commit, tree, blob, tag, ref, and
worktree.

### Deliverables

```text
projections/graph-state/
  README.md

  primitives/
    sources.cue
    identity.cue
    graph.cue
    target.cue
    workspace.cue
    stream.cue
    fragment.cue
    assignment.cue
    dependency.cue
    conflict.cue
    projection.cue
    context.cue
    producer.cue
```

### Required Primitive Surface

```text
#GraphID
#NodeID
#EdgeID
#ObjectID
#RefName
#PathID

#Node
#Edge
#Graph
#NodeMap
#EdgeMap

#Target
#Workspace
#Stream
#Fragment
#Assignment
#Dependency
#Conflict
#Projection
#Context
#ProducerSurface
```

### Phase 1 Promotion Contract

Phase 1 promotes through a closed `meta.#ObligationState`.

Required resources:

```text
graph-state-readme
primitives-source-ledger
primitive-identity
primitive-graph
primitive-target
primitive-workspace
primitive-stream
primitive-fragment
primitive-assignment
primitive-dependency
primitive-conflict
primitive-projection
primitive-context
primitive-producer
phase-one-summary
```

`phase-one-summary` is a generated output resource. All primitive files and the
source ledger are authority resources.

Required operations:

```text
collect-ontology-witnesses
define-primitive-vocabulary
classify-source-roles
publish-phase-one-summary
```

Required projection-owned gates:

```text
primitive-files-declared
source-ledger-complete
ontology-only
source-roles-separated
no-adapter-implementation
```

Required witnesses:

```text
gitbutler-stack-witness
gitbutler-hunk-assignment-witness
gitbutler-hunk-dependency-witness
go-git-storage-witness
pro-git-conceptual-witness
source-ledger-witness
```

The closed promotion contract proves reference closure across these resources,
operations, gates, and witnesses. The graph-state projection must separately
define checks that give semantic force to gates such as `ontology-only` and
`source-ledger-complete`.

## Phase 2: Graph-State Kernel

### Objective

Compose the graph-state primitives with the local CUE pattern suite to make the
model operational.

Phase 2 answers:

```text
How do graph-state primitives behave under the lattice?
What closes?
What bottoms?
What projects?
What subsumes?
What counts as an admissible graph-state observation?
```

### Deliverables

```text
projections/graph-state/
  kernel/
    kernel.cue
    closedness.cue
    typing.cue
    assignment.cue
    dependency.cue
    conflict.cue
    projection.cue
    context.cue
    producer.cue
    jsonld.cue
    fixtures.cue

  fixtures/
    positive/
      closed-graph.cue
      typed-graph.cue
      stream-fragment-assignment.cue
      workspace-projection.cue
      dependency-graph.cue
      context-projection.cue

    negative/
      dangling-edge.cue
      illegal-edge-type.cue
      missing-assignment-target.cue
      cyclic-dependency.cue
      projection-selects-missing-node.cue
      widened-producer-output.cue
```

### Required Kernel Surface

```text
#ClosedGraphState
#TypedGraphState
#AssignmentGraph
#DependencyGraph
#ConflictSurface
#WorkspaceProjection
#ContextProjection
#ProducerObservation
#JSONLDProjection
#GraphStateKernel
```

### Phase 2 Promotion Contract

Phase 2 promotes through three layers.

First, the phase plan and implementation must each close as a
`meta.#ObligationState`.

Required resources:

```text
graph-state-kernel
closedness-kernel
typing-kernel
assignment-kernel
dependency-kernel
conflict-kernel
projection-kernel
context-kernel
producer-kernel
jsonld-kernel
positive-fixtures
negative-fixtures
generated-validation-report
```

`generated-validation-report` is a generated output resource.

Required operations:

```text
compose-kernel
validate-positive-fixtures
bind-negative-fixtures
project-jsonld-shape
emit-validation-report
```

Required projection-owned gates:

```text
closedness-checks-pass
typing-checks-pass
assignment-checks-pass
dependency-checks-pass
projection-checks-pass
negative-fixture-probes-bottom
producer-contract-admitted
```

Required witnesses:

```text
closed-graph-witness
typed-edge-witness
fragment-assignment-witness
dependency-witness
projection-witness
negative-fixture-witness
jsonld-projection-witness
```

Second, Phase 2 must pass `meta.#NoWideningProof` between the closed plan and
the closed implementation:

```cue
phaseTwoNoWidening: meta.#NoWideningProof & {
	authority: closedPhaseTwoPlan
	target:    closedPhaseTwoImplementation
}
```

This proves:

- resource key equality
- operation key equality
- gate key equality
- witness key equality
- operation `reads` reference-set equality
- operation `writes` reference-set equality
- operation `creates` reference-set equality
- operation `requiresGates` reference-set equality
- operation `requiresWitnesses` reference-set equality
- compatibility through `authority & target`

Third, Phase 2 negative fixtures must use the meta negative-fixture probe
surface. `meta.#MakeNegativeFixture` binds `.out.probe.proof`; promotion must
evaluate that selector as an expected failure.

Required negative fixtures:

```text
dangling-edge
illegal-edge-type
missing-assignment-target
cyclic-dependency
projection-selects-missing-node
widened-producer-output
```

## Example Promotion Shape

```cue
package graphstate

import meta "github.com/fatb4f/lattice/meta"

phaseOnePromotion: meta.#ObligationState & {
	id: "graph-state-phase-one-primitives"

	resources: {
		"primitive-identity": {
			path: "projections/graph-state/primitives/identity.cue"
			role: "authority"
			visibility: "public"
		}
		"primitive-graph": {
			path: "projections/graph-state/primitives/graph.cue"
			role: "authority"
			visibility: "public"
		}
		"phase-one-summary": {
			path: "projections/graph-state/reports/phase-one.md"
			role: "generated-output"
			visibility: "public"
		}
	}

	operations: {
		"define-primitive-vocabulary": {
			kind: "create"
			description: "Define graph-state primitive ontology."
			reads: {}
			writes: {
				"primitive-identity": true
				"primitive-graph": true
			}
			creates: {}
			requiresGates: {
				"ontology-only": true
			}
			requiresWitnesses: {
				"gitbutler-stack-witness": true
				"gitbutler-hunk-assignment-witness": true
			}
		}
		"publish-phase-one-summary": {
			kind: "report"
			description: "Publish Phase 1 primitive ontology summary."
			reads: {
				"primitive-identity": true
				"primitive-graph": true
			}
			writes: {}
			creates: {
				"phase-one-summary": true
			}
			requiresGates: {
				"source-ledger-complete": true
			}
			requiresWitnesses: {
				"source-ledger-witness": true
			}
		}
	}

	gates: {
		"ontology-only": {
			description: "Primitive files define ontology only, not kernel behavior."
		}
		"source-ledger-complete": {
			description: "Every primitive has at least one source witness."
		}
	}

	witnesses: {
		"gitbutler-stack-witness": {
			description: "GitButler Stack supports the stream primitive."
		}
		"gitbutler-hunk-assignment-witness": {
			description: "GitButler HunkAssignment supports fragment and assignment primitives."
		}
		"source-ledger-witness": {
			description: "Primitive source ledger maps source witnesses to ontology primitives."
		}
	}
}

closedPhaseOnePromotion: (meta.#MakeClosedObligationState & {
	in: phaseOnePromotion
}).out
```

## Promotion Rule

```text
No graph-state deliverable promotes unless its phase obligation state closes
through meta.#MakeClosedObligationState.

No semantic graph-state gate promotes unless graph-state CUE defines and
validates that semantic check.

No Phase 2 implementation promotes unless meta.#NoWideningProof succeeds
between the closed plan and closed implementation.

No Phase 2 negative fixture promotes unless meta.#MakeNegativeFixture exposes a
probe and CI verifies .out.probe.proof bottoms.
```
