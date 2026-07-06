package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"constructors": {

		name:    "Constructors"
		summary: "Model reusable builders with explicit input and normalized output fields."
		demonstrates: ["definitions", "unification", "normalization"]
		id:          "constructors"
		family:      "constructor"
		status:      "implemented"
		problem:     "Reusable builders need explicit input and normalized closed output."
		abstraction: "Input-output constructor definition"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/constructors.cue -e #Patterns.constructors.positive"], fail: ["cue eval patterns/constructors.cue -e #Patterns.constructors.negative.badResource"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes constructor and builder shape from CUE-native pattern mapping."}

		#MakeResource: {
			in: {
				id:   =~"^[a-z0-9]+(-[a-z0-9]+)*$"
				path: string
				role: "authority" | "generated-output"
			}
			out: close({
				id:         in.id
				path:       in.path
				role:       in.role
				visibility: "internal" | *"internal"
			})
		}

		canonical: {
			id:        "constructors"
			kernelUse: "meta/kernel.cue:#MakeClosedObligationState"
			resource: (#MakeResource & {in: {
				id:   "authority-file"
				path: "contracts/authority.cue"
				role: "authority"
			}}).out
		}

		positive: {
			resource: canonical.resource & {
				id:         "authority-file"
				path:       "contracts/authority.cue"
				role:       "authority"
				visibility: "internal"
			}
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "constructors"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			badResource: {
				id:   "authority-file"
				path: 80
				role: "authority"
			}
		}

	}
}
