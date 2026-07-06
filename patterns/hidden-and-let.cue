package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"hidden-and-let": {

		name:    "Hidden Fields And Let Bindings"
		summary: "Use hidden values and local bindings for internal proof computations."
		demonstrates: ["hidden fields", "let bindings", "derived proofs"]
		id:          "hidden-and-let"
		family:      "graph"
		status:      "implemented"
		problem:     "Internal proof calculations need names without widening public output."
		abstraction: "Hidden constant with local let-bound proof"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/hidden-and-let.cue -e #Patterns.hidden-and-let.positive"], fail: ["cue eval patterns/hidden-and-let.cue -e #Patterns.hidden-and-let.negative.privateConflict"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes graph-state proof internals and derived validation fields."}

		_generatedRole: "generated-output"

		#CreateProof: {
			operation: {
				creates: {[string]: true}
			}
			resources: {
				[string]: {
					role: string
				}
			}
			let createdID = "generated-file"
			proof: resources[createdID].role & _generatedRole
		}

		canonical: {
			id:        "hidden-and-let"
			kernelUse: "meta/kernel.cue:#ClosedObligationState._operationRefProof"
			proof: #CreateProof & {
				operation: {
					creates: {"generated-file": true}
				}
				resources: {
					"generated-file": {
						role: "generated-output"
					}
				}
			}
		}

		positive: {
			proof: canonical.proof.proof & "generated-output"
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "hidden-and-let"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			privateConflict: "authority"
		}

	}
}
