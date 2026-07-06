package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"cycles": {

		name:    "Cycles"
		summary: "Use references for valid graph relationships and isolate invalid cyclic expressions as probes."
		demonstrates: ["references", "cycles", "bottom"]

		canonical: {
			id:        "cycles"
			kernelUse: "meta/kernel.cue:#ClosedObligationState._createsGeneratedOutputProof"
			operationGraph: {
				"inspect-operation": {
					creates: {
						"generated-file": true
					}
					generatedRole: resources["generated-file"].role
				}
				resources: {
					"generated-file": {
						role: "generated-output"
					}
				}
			}
		}

		positive: {
			generatedRole: canonical.operationGraph["inspect-operation"].generatedRole & "generated-output"
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "cycles"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			arithmeticCycle: {
				expression: {
					x: x + 1
				}
			}
		}

	}
}
