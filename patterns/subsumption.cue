package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"subsumption": {

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
