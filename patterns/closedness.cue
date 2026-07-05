package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"closed-contract-surface": {
			family: "closedness"
			title:  "Close authority surfaces against stray fields"
			problem: "Unrecognized fields can silently become authority if contracts remain open."
			rule:   "Use closed schemas or explicit invalid-field guards on authority surfaces."

			sourceRefs: [
				"cue-closedness",
				"lattice-domain-kernel",
			]

			cueSurface: {
				constructs: [
					"close",
					"field guards",
					"bottom",
				]
				exampleExpr: "#Resource"
			}

			validation: [{
				id:   "closed-domain-vets"
				mode: "vet-passes"
				expr: "_closedState"
			}]
		}
	}
}

