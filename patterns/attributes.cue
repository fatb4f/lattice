package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"attributes": {

		name:    "Attributes"
		summary: "Attach command-line tags to fields that tooling can select or populate."
		demonstrates: ["attributes", "field tags", "tool parameters"]

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
