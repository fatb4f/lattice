package patterns

import domain "github.com/fatb4f/lattice/domain"

canonical: {
	id:  "top-and-bottom"
	top: _
}

positive: {
	refinedTop: canonical.top & {
		port: 8080
	}
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "top-and-bottom"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	conflict: string & int
}
