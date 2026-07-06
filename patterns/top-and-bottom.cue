package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"top-and-bottom": {

		canonical: {
			id:             "top-and-bottom"
			kernelUse:      "meta/kernel.cue:#NegativeFixtureConflictProbe.proof"
			openProofInput: _
		}

		positive: {
			refinedTop: canonical.openProofInput & {
				resource: "generated-file"
				role:     "generated-output"
			}
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "top-and-bottom"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			conflict: {
				left:  meta.#GeneratedOutputResourceRole
				right: "authority"
			}
		}

	}
}
