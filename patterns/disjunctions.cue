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

_disjunctionCommand:
	close({
		kind:   "vet"
		target: string
	}) |
	close({
		kind:     "export"
		target:   string
		selector: string
	})

_disjunctionExport: _disjunctionCommand & {
	kind:     "export"
	target:   "./patterns"
	selector: "cueIdiomCatalog"
}

cuePillarSpecs: {
	pillars: {
		disjunctions: {
			title:  "Disjunctions"
			class:  "language"
			status: "fixture-backed"
			mechanics: [
				"Disjunctions bound scalar vocabularies.",
				"Struct branches model tagged unions.",
				"Invalid branches bottom when required fields are absent.",
			]
			idioms: {
				"tagged-command-union": {
					title: "Model command variants as a tagged union"
					problem: "Open command maps allow selectors and targets to appear on the wrong branch."
					rule: "Use a kind field to select a closed branch with branch-specific required fields."
					constructs: ["|", "close", "tagged union"]
					canonical: {
						expr:  "_disjunctionExport"
						value: _disjunctionExport
					}
					positive: {
						expr:  "_disjunctionExport"
						value: _disjunctionExport
					}
					expectedBottom: {
						probeExpr: "_disjunctionCommand & {kind: \"export\", target: \"./patterns\"}"
						reason:    "The export branch requires selector."
					}
				}
			}
		}
	}
}
