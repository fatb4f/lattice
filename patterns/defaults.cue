package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"defaults": {

		name:    "Defaults"
		summary: "Provide default values while still allowing explicit refinement."
		demonstrates: ["defaults", "disjunctions", "refinement"]
		id:          "defaults"
		family:      "default"
		status:      "implemented"
		problem:     "Policy fields need defaults without blocking explicit refinement."
		abstraction: "Defaulted policy field"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/defaults.cue -e #Patterns.defaults.positive"], fail: ["cue eval patterns/defaults.cue -e #Patterns.defaults.negative.invalidRequired"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes defaults and overrides as reusable CUE pattern material."}

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
