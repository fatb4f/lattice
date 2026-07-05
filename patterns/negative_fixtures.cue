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

_negativeFixtureSchema: close({
	id:   #KebabIdentifier
	mode: "strict" | "permissive"
})

_negativeFixturePositive: _negativeFixtureSchema & {
	id:   "strict-case"
	mode: "strict"
}

negativeFixtureWitness: close({
	id:          "invalid-mode-bottom"
	description: "A mode outside the bounded disjunction must bottom."
	probeExpr:   "_negativeFixtureSchema & {id: \"invalid-mode\", mode: \"debug\"}"
})

cuePillarSpecs: {
	pillars: {
		"negative-fixtures": {
			title:  "Negative Fixtures"
			class:  "contract"
			status: "validated"
			mechanics: [
				"Invalid examples are represented as named probes.",
				"Expected failure is part of the contract, not an external note.",
				"Bottom witnesses prove rejection behavior.",
			]
			idioms: {
				"expected-bottom-witness": {
					title: "Record invalid cases as expected-bottom probes"
					problem: "Invalid behavior is easy to describe but hard to regression-test without a selector."
					rule: "Name the invalid expression and require it to bottom in validation."
					constructs: ["_|_", "negative fixtures", "bounded disjunctions"]
					positive: {
						expr:  "_negativeFixturePositive"
						value: _negativeFixturePositive
					}
					expectedBottom: {
						probeExpr: negativeFixtureWitness.probeExpr
						reason:    negativeFixtureWitness.description
					}
				}
			}
		}
	}
}
