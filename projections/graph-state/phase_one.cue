package graphstate

import (
	meta "github.com/fatb4f/lattice/meta"
	primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"
)

_primitiveSurface: primitives.#PhaseOnePrimitiveSurface

phaseOneSemanticChecks: {
	primitiveFilesDeclared:  true
	sourceLedgerComplete:    primitives.sourceLedgerComplete
	ontologyOnly:            true
	sourceRolesSeparated:    primitives.sourceRolesSeparated
	noAdapterImplementation: true
}

phaseOnePromotion: meta.#ObligationState & {
	id: "graph-state-phase-one-primitives"

	resources: {
		"graph-state-readme": {
			path:       "projections/graph-state/README.md"
			role:       "authority"
			visibility: "public"
		}
		"primitives-source-ledger": {
			path:       "projections/graph-state/primitives/sources.cue"
			role:       "authority"
			visibility: "public"
		}
		"primitive-identity": {
			path:       "projections/graph-state/primitives/identity.cue"
			role:       "authority"
			visibility: "public"
		}
		"primitive-graph": {
			path:       "projections/graph-state/primitives/graph.cue"
			role:       "authority"
			visibility: "public"
		}
		"primitive-target": {
			path:       "projections/graph-state/primitives/target.cue"
			role:       "authority"
			visibility: "public"
		}
		"primitive-workspace": {
			path:       "projections/graph-state/primitives/workspace.cue"
			role:       "authority"
			visibility: "public"
		}
		"primitive-stream": {
			path:       "projections/graph-state/primitives/stream.cue"
			role:       "authority"
			visibility: "public"
		}
		"primitive-fragment": {
			path:       "projections/graph-state/primitives/fragment.cue"
			role:       "authority"
			visibility: "public"
		}
		"primitive-assignment": {
			path:       "projections/graph-state/primitives/assignment.cue"
			role:       "authority"
			visibility: "public"
		}
		"primitive-dependency": {
			path:       "projections/graph-state/primitives/dependency.cue"
			role:       "authority"
			visibility: "public"
		}
		"primitive-conflict": {
			path:       "projections/graph-state/primitives/conflict.cue"
			role:       "authority"
			visibility: "public"
		}
		"primitive-projection": {
			path:       "projections/graph-state/primitives/projection.cue"
			role:       "authority"
			visibility: "public"
		}
		"primitive-context": {
			path:       "projections/graph-state/primitives/context.cue"
			role:       "authority"
			visibility: "public"
		}
		"primitive-producer": {
			path:       "projections/graph-state/primitives/producer.cue"
			role:       "authority"
			visibility: "public"
		}
		"phase-one-summary": {
			path:       "generated/codex/graph-state/phase-one-summary.json"
			role:       "generated-output"
			visibility: "public"
		}
	}

	operations: {
		"collect-ontology-witnesses": {
			kind:        "collect"
			description: "Collect source witnesses for Phase 1 primitive ontology."
			reads: {
				"graph-state-readme": true
			}
			writes: {
				"primitives-source-ledger": true
			}
			creates: {}
			requiresGates: {
				"source-roles-separated":    true
				"no-adapter-implementation": true
			}
			requiresWitnesses: {
				"gitbutler-stack-witness":           true
				"gitbutler-hunk-assignment-witness": true
				"gitbutler-hunk-dependency-witness": true
				"go-git-storage-witness":            true
				"pro-git-conceptual-witness":        true
			}
		}
		"define-primitive-vocabulary": {
			kind:        "define"
			description: "Define domain-neutral graph-state primitive vocabulary."
			reads: {
				"primitives-source-ledger": true
			}
			writes: {
				"primitive-identity":   true
				"primitive-graph":      true
				"primitive-target":     true
				"primitive-workspace":  true
				"primitive-stream":     true
				"primitive-fragment":   true
				"primitive-assignment": true
				"primitive-dependency": true
				"primitive-conflict":   true
				"primitive-projection": true
				"primitive-context":    true
				"primitive-producer":   true
			}
			creates: {}
			requiresGates: {
				"primitive-files-declared": true
				"ontology-only":            true
			}
			requiresWitnesses: {
				"source-ledger-witness": true
			}
		}
		"classify-source-roles": {
			kind:        "classify"
			description: "Classify witness roles without promoting downstream narrowing."
			reads: {
				"primitives-source-ledger": true
			}
			writes: {}
			creates: {}
			requiresGates: {
				"source-ledger-complete": true
				"source-roles-separated": true
			}
			requiresWitnesses: {
				"source-ledger-witness": true
			}
		}
		"publish-phase-one-summary": {
			kind:        "report"
			description: "Emit a generated summary of the Phase 1 primitive ontology."
			reads: {
				"graph-state-readme":       true
				"primitives-source-ledger": true
				"primitive-identity":       true
				"primitive-graph":          true
				"primitive-target":         true
				"primitive-workspace":      true
				"primitive-stream":         true
				"primitive-fragment":       true
				"primitive-assignment":     true
				"primitive-dependency":     true
				"primitive-conflict":       true
				"primitive-projection":     true
				"primitive-context":        true
				"primitive-producer":       true
			}
			writes: {}
			creates: {
				"phase-one-summary": true
			}
			requiresGates: {
				"source-ledger-complete": true
				"ontology-only":          true
			}
			requiresWitnesses: {
				"source-ledger-witness": true
			}
		}
	}

	gates: {
		"primitive-files-declared": {
			description: "All Phase 1 primitive files are declared as authority resources."
		}
		"source-ledger-complete": {
			description: "Every Phase 1 primitive has at least one source witness."
		}
		"ontology-only": {
			description: "Primitive files define ontology only, not graph behavior or runtime integration."
		}
		"source-roles-separated": {
			description: "GitButler, go-git, and Pro Git witnesses keep distinct evidence roles."
		}
		"no-adapter-implementation": {
			description: "Phase 1 contains no adapter implementation or runtime integration."
		}
	}

	witnesses: {
		"gitbutler-stack-witness": {
			description: "GitButler Stack supports the stream primitive."
		}
		"gitbutler-hunk-assignment-witness": {
			description: "GitButler HunkAssignment supports fragment and assignment primitives."
		}
		"gitbutler-hunk-dependency-witness": {
			description: "GitButler hunk dependency surfaces support dependency and conflict primitives."
		}
		"go-git-storage-witness": {
			description: "go-git supports Git storage and substrate primitives."
		}
		"pro-git-conceptual-witness": {
			description: "Pro Git supports object database, refs, and three-tree conceptual vocabulary."
		}
		"source-ledger-witness": {
			description: "The source ledger maps source witnesses to ontology primitives."
		}
	}
}

closedPhaseOnePromotion: (meta.#MakeClosedObligationState & {
	in: phaseOnePromotion
}).out
