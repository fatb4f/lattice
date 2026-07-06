package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"subsumption": {

		name:    "Subsumption"
		summary: "Check compatibility between authority and projected resource shapes."
		demonstrates: ["subsumption", "compatibility", "refinement"]
		id:          "subsumption"
		family:      "projection"
		status:      "implemented"
		problem:     "Authority and projected shapes need compatibility checks."
		abstraction: "Authority-target compatibility proof"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/subsumption.cue -e #Patterns.subsumption.positive"], fail: ["cue eval patterns/subsumption.cue -e #Patterns.subsumption.negative.incompatibleField"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes subsumption tests and projection compatibility."}

		#AuthorityResource: {
			id:   string
			path: string
			role: "authority" | "generated-output"
			...
		}

		#ProjectedResource: {
			id:         string
			path:       string
			role:       "authority" | "generated-output"
			visibility: "public" | "internal" | *"internal"
			...
		}

		canonical: {
			id:            "subsumption"
			kernelUse:     "meta/kernel.cue:#NoWideningProof.compatibility"
			compatibility: #AuthorityResource & #ProjectedResource
		}

		positive: {
			value: canonical.compatibility & {
				id:   "authority-file"
				path: "contracts/authority.cue"
				role: "authority"
			}
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "subsumption"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			incompatibleField: {
				id:   "authority-file"
				path: "contracts/authority.cue"
				role: "forbidden"
			}
		}

	}
}
