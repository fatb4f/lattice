package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"constraint-unification": {
			family: "unification"
			title:  "Compose authority by unifying compatible constraints"
			problem: "A profile can drift when schema, fixture, and expected output are checked separately."
			rule:   "Represent each requirement as a constraint and admit only values that unify with every authority layer."

			sourceRefs: [
				"cue-unification",
				"lattice-domain-kernel",
			]

			cueSurface: {
				constructs: [
					"unification",
					"struct constraints",
					"bottom",
				]
				exampleExpr: "_noWideningProof.compatibility"
			}

			validation: [{
				id:   "domain-vets"
				mode: "vet-passes"
				expr: "_closedState"
			}]
		}
	}
}

