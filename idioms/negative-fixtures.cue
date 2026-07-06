package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"negative-fixtures": {

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
