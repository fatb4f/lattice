package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"disjunctions": {

		#KernelOperationIntent:
			close({
				kind: "inspect"
				reads: {[string]: true}
			}) |
			close({
				kind: "generate"
				creates: {[string]: true}
			})

		canonical: {
			id:        "disjunctions"
			kernelUse: "meta/kernel.cue:#Operation.kind"
			intent:    #KernelOperationIntent
		}

		positive: {
			intent: #KernelOperationIntent & {
				kind: "generate"
				creates: {
					"generated-file": true
				}
			}
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "disjunctions"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			invalidSelector: {
				kind: "generate"
				reads: {"authority-file": true}
				target: "generated-file"
			}
		}

	}
}
