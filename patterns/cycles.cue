package patterns

cycleReferences: {
	nodes: {
		api: {
			id:   "api"
			next: nodes.worker.id
		}
		worker: {
			id:   "worker"
			next: nodes.api.id
		}
	}
}

cycleInvalidWitness: close({
	id:          "cyclic-arithmetic-bottom"
	description: "A value cannot be defined as itself plus one."
	probeExpr:   "{x: x + 1}.x"
})

cuePillarSpecs: {
	pillars: {
		cycles: {
			title:  "Cycles"
			class:  "contract"
			status: "validated"
			mechanics: [
				"Reference cycles can model linked authority objects.",
				"Computational cycles that cannot converge bottom.",
				"Cycle probes distinguish reference tracking from invalid recursion.",
			]
			idioms: {
				"reference-cycle-witness": {
					title: "Represent valid reference cycles explicitly"
					problem: "Cycle handling is ambiguous without positive and negative witnesses."
					rule: "Keep reference cycles as data and record invalid cyclic computation as an expected-bottom probe."
					constructs: ["self references", "selector references", "_|_"]
					canonical: {
						expr:  "cycleReferences"
						value: cycleReferences
					}
					expectedBottom: {
						probeExpr: cycleInvalidWitness.probeExpr
						reason:    cycleInvalidWitness.description
					}
				}
			}
		}
	}
}
