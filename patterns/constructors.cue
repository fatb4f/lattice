package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"closed-state-constructor": {
			family: "constructor"
			title:  "Use constructor definitions to close and normalize partial input"
			problem: "Input fixtures are convenient when partial, but validation needs stable IDs, defaults, and derived proof fields."
			rule:   "Expose a #Make-style constructor with an input shape and a fully constrained output shape."

			sourceRefs: [
				"lattice-domain-kernel",
				"cue-definitions",
			]

			cueSurface: {
				constructs: [
					"definitions",
					"let bindings",
					"field comprehensions",
					"unification",
				]
				exampleExpr: "#MakeClosedObligationState.out"
			}

			validation: [
				{
					id:   "closed-state-exports"
					mode: "export-passes"
					expr: "_closedState"
				},
			]
		}
	}
}

