package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"top-and-bottom": {

		name:    "Top And Bottom"
		summary: "Use top for open inputs and bottom-producing conflicts for proof failures."
		demonstrates: ["top", "bottom", "conflicts"]

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
