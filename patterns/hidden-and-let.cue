package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"hidden-and-let": {

		name:    "Hidden Fields And Let Bindings"
		summary: "Use hidden values and local bindings for internal proof computations."
		demonstrates: ["hidden fields", "let bindings", "derived proofs"]

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
			kernelUse: "meta/kernel.cue:#ClosedObligationState._createsGeneratedOutputProof"
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
