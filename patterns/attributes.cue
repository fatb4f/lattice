package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"attributes": {

		name:    "Attributes"
		summary: "Attach command-line tags to fields that tooling can select or populate."
		demonstrates: ["attributes", "field tags", "tool parameters"]
		id:          "attributes"
		family:      "selector"
		status:      "partial"
		problem:     "Tool-facing fields need stable selector and tag metadata without becoming authority."
		abstraction: "Tagged selector record"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/attributes.cue -e #Patterns.attributes.canonical"], fail: ["cue eval patterns/attributes.cue -e #Patterns.attributes.negative.invalidKind"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes selector and command-surface tagging from pattern framing."}

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
