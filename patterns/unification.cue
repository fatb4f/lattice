package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"unification": {

		#KernelResource: close({
			id:   =~"^[a-z0-9]+(-[a-z0-9]+)*$"
			path: string
			role: "authority" | "generated-output"
		})

		_authorityInput: {
			path: "contracts/authority.cue"
			role: "authority"
		}

		canonical: {
			id:        "unification"
			kernelUse: "meta/kernel.cue:#MakeClosedObligationState"
			resource: #KernelResource & _authorityInput & {
				id: "authority-file"
			}
		}

		positive: {
			resource: canonical.resource & {
				id:   "authority-file"
				path: "contracts/authority.cue"
				role: "authority"
			}
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "unification"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			incompatibleRole: {
				id:   "authority-file"
				path: "contracts/authority.cue"
				role: "forbidden"
			}
		}

	}
}
