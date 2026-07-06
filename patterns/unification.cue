package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"unification": {

		name:    "Unification"
		summary: "Combine schemas and data to derive a more specific value."
		demonstrates: ["unification", "constraints", "closed structs"]
		id:          "unification"
		family:      "schema"
		status:      "implemented"
		problem:     "Schemas and data need to compose into stricter values without procedural glue."
		abstraction: "Schema-data unification"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/unification.cue -e #Patterns.unification.positive"], fail: ["cue eval patterns/unification.cue -e #Patterns.unification.negative.incompatibleRole"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes unification as the base CUE composition pattern."}

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
