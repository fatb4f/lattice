package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"map-key-normalization-comprehension": {
			family: "comprehension"
			title:  "Normalize map-key identity with comprehensions"
			problem: "Map-key identity and embedded object identity can diverge without an executable equality proof."
			rule:   "Use comprehensions to bind each map key back into the value and derive stable key sets."

			sourceRefs: [
				"cue-comprehensions",
				"lattice-domain-kernel",
			]

			cueSurface: {
				constructs: [
					"field comprehensions",
					"dynamic fields",
					"map constraints",
				]
				exampleExpr: "#MakeClosedObligationState.out"
			}

			validation: [{
				id:   "closed-state-normalizes"
				mode: "export-passes"
				expr: "_closedState"
			}]
		}
	}
}

