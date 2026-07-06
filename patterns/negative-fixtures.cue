package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"negative-fixtures": {

		name:    "Negative Fixtures"
		summary: "Keep invalid examples exportable while proving failure through a destructive probe."
		demonstrates: ["negative fixtures", "bottom", "probe separation"]
		id:          "negative-fixtures"
		family:      "fixture"
		status:      "implemented"
		problem:     "Invalid examples need to remain exportable while still proving bottom."
		abstraction: "Exportable negative fixture plus destructive probe"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/negative-fixtures.cue -e #Patterns.negative-fixtures.positive"], fail: ["cue eval patterns/negative-fixtures.cue -e #Patterns.negative-fixtures.negative.proof"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes validator fixture pairs and expected-bottom probes."}

		_authority: {
			id: "negative-fixtures"
			resources: {
				"authority-file": {
					path: "contracts/authority.cue"
					role: "authority"
				}
			}
			operations: {}
			gates: {}
			witnesses: {}
		}

		_invalid: {
			id: "negative-fixtures"
			resources: {
				"authority-file": {
					path: "contracts/authority.cue"
					role: "forbidden"
				}
			}
			operations: {}
			gates: {}
			witnesses: {}
		}

		canonical: {
			id:        "negative-fixtures"
			kernelUse: "meta/kernel.cue:#MakeNegativeFixtureSpec"
			spec: (meta.#MakeNegativeFixtureSpec & {in: {
				id:          "negative-fixtures"
				description: "Expected-bottom fixture metadata"
				authority:   _authority
				invalid:     _invalid
			}}).out
		}

		positive: {
			specOnly: canonical.spec
			validation: (meta.#MakeClosedObligationState & {in: _authority}).out
		}

		negative: {
			proof: {
				id:          "negative-fixtures"
				description: "Expected-bottom fixture proof"
				authority:   _authority
				invalid:     _invalid
			}
		}

	}
}
