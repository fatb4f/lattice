package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"bounded-vocabulary-disjunction": {
			family: "disjunction"
			title:  "Bound vocabularies with closed disjunctions"
			problem: "Open string fields let projections invent roles, states, or validation modes."
			rule:   "Use disjunctions for stable vocabularies and refine them only at owned profile boundaries."

			sourceRefs: [
				"cue-disjunctions",
				"lattice-domain-kernel",
			]

			cueSurface: {
				constructs: [
					"disjunctions",
					"string literals",
					"schema refinement",
				]
				exampleExpr: "#CueIdiomFamily"
			}

			validation: [{
				id:   "catalog-vocabulary-exports"
				mode: "export-passes"
				expr: "cueIdiomCatalog"
			}]
		}
	}
}

