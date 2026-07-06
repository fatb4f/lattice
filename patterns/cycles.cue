package patterns

import domain "github.com/fatb4f/lattice/domain"

canonical: {
	id: "cycles"
	nodes: {
		api: {
			next: nodes.worker.id
			id:   "api"
		}
		worker: {
			next: nodes.api.id
			id:   "worker"
		}
	}
}

positive: {
	apiNext:    canonical.nodes.api.next & "worker"
	workerNext: canonical.nodes.worker.next & "api"
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "cycles"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	arithmeticCycle: {
		x: x + 1
	}.x
}
