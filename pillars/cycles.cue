package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"cycles": {

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
		expression: "x: x + 1"
	}
}

}
}
