package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"attributes": {

		#TaggedKernelSelector: {
			selector: string @tag(selector)
			path:     string @tag(path)
		}

		canonical: {
			id:        "attributes"
			kernelUse: "meta/kernel.cue:#CueSelectorExpr"
			selector:  #TaggedKernelSelector
		}

		positive: {
			selector: #TaggedKernelSelector & {
				selector: "#ClosedObligationState"
				path:     "meta/kernel.cue"
			}
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "attributes"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			invalidKind: {
				selector: 1
				path:     "meta/kernel.cue"
			}
		}

	}
}
