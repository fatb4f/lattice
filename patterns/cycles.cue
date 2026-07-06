package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"cycles": {

		canonical: {
			id:        "cycles"
			kernelUse: "meta/kernel.cue:#ClosedObligationState._operationRefProof"
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
