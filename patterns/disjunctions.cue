package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"disjunctions": {

		name:    "Disjunctions"
		summary: "Represent mutually exclusive operation variants as closed disjunctions."
		demonstrates: ["disjunctions", "tagged variants", "closed structs"]
		id:          "disjunctions"
		family:      "variant"
		status:      "implemented"
		problem:     "Operation alternatives need closed variant selection."
		abstraction: "Closed disjunction variant"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/disjunctions.cue -e #Patterns.disjunctions.positive"], fail: ["cue eval patterns/disjunctions.cue -e #Patterns.disjunctions.negative.invalidSelector"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes strategy-like variant selection as closed disjunctions."}

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
