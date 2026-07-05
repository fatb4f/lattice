package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"exportable-negative-fixture": {
			family: "negative-fixture"
			title:  "Separate exportable negative fixture specs from destructive probes"
			problem: "A deliberate bottoming proof cannot live inside an exported data contract."
			rule:   "Keep fixture metadata exportable and place the actual bottom-producing proof behind a probe expression."

			sourceRefs: [
				"lattice-domain-negative-fixture",
				"cue-bottom-semantics",
			]

			cueSurface: {
				constructs: [
					"_|_",
					"unification",
					"hidden fields",
					"definitions",
				]
				exampleExpr: "_negativeFixtureConflictBinding.probe.proof"
			}

			validation: [
				{
					id:   "spec-exports"
					mode: "export-passes"
					expr: "_negativeFixtureSpecOnly"
				},
				{
					id:   "probe-bottoms"
					mode: "eval-bottoms"
					expr: "_negativeFixtureConflictBinding.probe.proof"
				},
			]
		}
	}
}

