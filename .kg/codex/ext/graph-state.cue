package codexdrift

graphStatePhases: {
	"graph-state-phase-one": #Phase & {
		id:          "graph-state-phase-one"
		status:      "promoted"
		description: "Graph-state primitive ontology phase."
		watchedPaths: [
			"docs/graph-state-promotion-plan.md",
			"meta/kernel.cue",
			"projections/graph-state/README.md",
			"projections/graph-state/primitives",
			"projections/graph-state/promotion",
		]
	}

	"graph-state-phase-two": #Phase & {
		id:          "graph-state-phase-two"
		description: "Graph-state operational kernel phase."
		watchedPaths: [
			"docs/graph-state-promotion-plan.md",
			"meta/kernel.cue",
			"projections/graph-state/kernel",
			"projections/graph-state/fixtures",
			"projections/graph-state/promotion",
			"generated/codex/graph-state",
		]
	}
}
