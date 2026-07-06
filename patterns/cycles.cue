package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"cycles": {

		name:    "Cycles"
		summary: "Use references for valid graph relationships and isolate invalid cyclic expressions as probes."
		demonstrates: ["references", "cycles", "bottom"]
		id:          "cycles"
		family:      "graph"
		status:      "partial"
		problem:     "Reference graphs need valid cross-links while invalid cycles remain isolated probes."
		abstraction: "Graph reference and cycle-rejection probe"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/cycles.cue -e #Patterns.cycles.positive"], fail: ["cue eval patterns/cycles.cue -e #Patterns.cycles.negative.arithmeticCycle.expression.x"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes graph algorithms and cycle rejection into executable CUE probes."}

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
