package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"defaults": {

		#KernelGatePolicy: close({
			id:          =~"^[a-z0-9]+(-[a-z0-9]+)*$"
			description: string
			required:    bool | *true
		})

		canonical: {
			id:        "defaults"
			kernelUse: "meta/kernel.cue:#Gate"
			gate:      #KernelGatePolicy
		}

		positive: {
			explicit: {
				gate: #KernelGatePolicy & {
					id:          "cue-vet"
					description: "Run CUE validation"
					required:    false
				}
			}
			implicit: {
				gate: #KernelGatePolicy & {
					id:          "cue-vet"
					description: "Run CUE validation"
				}
			}
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "defaults"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			invalidRequired: {
				id:          "cue-vet"
				description: "Run CUE validation"
				required:    "true"
			}
		}

	}
}
