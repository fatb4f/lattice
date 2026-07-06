package patterns

import meta "github.com/fatb4f/lattice/meta"

#ClosedKernelResource: close({
	id:         =~"^[a-z0-9]+(-[a-z0-9]+)*$"
	path:       string
	role:       string
	visibility: "public" | "internal" | "restricted" | *"internal"
})

#Patterns: {
	"closedness": {

		name:    "Closedness"
		summary: "Close public shapes so unexpected fields become validation failures."
		demonstrates: ["closed structs", "field rejection", "schema boundaries"]
		id:          "closedness"
		family:      "schema"
		status:      "implemented"
		problem:     "Public records need an explicit boundary against accidental widening."
		abstraction: "Closed record boundary"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/closedness.cue -e #Patterns.closedness.positive"], fail: ["cue eval patterns/closedness.cue -e #Patterns.closedness.negative.extraField"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes schema boundary enforcement from CUE-native pattern framing."}

		canonical: {
			id:        "closedness"
			kernelUse: "meta/kernel.cue:#Resource"
			resource:  #ClosedKernelResource
		}

		positive: {
			resource: #ClosedKernelResource & {
				id:         "authority-file"
				path:       "contracts/authority.cue"
				role:       "authority"
				visibility: "internal"
			}
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "closedness"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			extraField: {
				id:    "authority-file"
				path:  "contracts/authority.cue"
				role:  "authority"
				extra: true
			}
		}

	}
}
