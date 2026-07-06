package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"definitions": {

		#KernelResourceRef: close({
			id:         =~"^[a-z0-9]+(-[a-z0-9]+)*$"
			path:       string
			role:       "authority" | "projection" | "generated-output"
			visibility: "public" | "internal" | "restricted" | *"internal"
		})

		canonical: {
			id:        "definitions"
			kernelUse: "meta/kernel.cue:#Resource"
			resource:  #KernelResourceRef
		}

		positive: {
			resource: #KernelResourceRef & {
				id:         "authority-file"
				path:       "contracts/authority.cue"
				role:       "authority"
				visibility: "internal"
			}
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "definitions"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			invalidRole: {
				id:   "authority-file"
				path: "contracts/authority.cue"
				role: "runtime-cache"
			}
		}

	}
}
