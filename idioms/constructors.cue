package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"constructors": {

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
