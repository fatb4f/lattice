package pillars

import meta "github.com/fatb4f/lattice/meta"

#ClosedKernelResource: close({
	id:         =~"^[a-z0-9]+(-[a-z0-9]+)*$"
	path:       string
	role:       string
	visibility: "public" | "internal" | "restricted" | *"internal"
})

#Pillars: {
	"closedness": {

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
