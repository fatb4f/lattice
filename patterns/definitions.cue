package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"definitions": {

		name:    "Definitions"
		summary: "Define reusable schema terms for resource-like records."
		demonstrates: ["definitions", "closed structs", "enums"]
		id:          "definitions"
		family:      "schema"
		status:      "implemented"
		problem:     "Repeated record shapes need named reusable schema definitions."
		abstraction: "Named closed resource definition"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/definitions.cue -e #Patterns.definitions.positive"], fail: ["cue eval patterns/definitions.cue -e #Patterns.definitions.negative.invalidRole"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes reusable CUE data-structure definitions."}

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
