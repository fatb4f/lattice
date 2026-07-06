package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"top-and-bottom": {

		name:    "Top And Bottom"
		summary: "Use top for open inputs and bottom-producing conflicts for proof failures."
		demonstrates: ["top", "bottom", "conflicts"]
		id:          "top-and-bottom"
		family:      "fixture"
		status:      "implemented"
		problem:     "Open inputs and expected failures need explicit top and bottom examples."
		abstraction: "Top input with bottom conflict probe"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/top-and-bottom.cue -e #Patterns.top-and-bottom.positive"], fail: ["cue eval patterns/top-and-bottom.cue -e #Patterns.top-and-bottom.negative.conflict"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes bottom as proof/failure mechanism."}

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
