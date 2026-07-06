package patterns

import domain "github.com/fatb4f/lattice/domain"

#V1: {
	fieldA: string
	...
}

#V2: {
	fieldA: string
	fieldB: int | *0
	...
}

canonical: {
	id:            "subsumption"
	compatibility: #V1 & #V2
}

positive: {
	value: canonical.compatibility & {
		fieldA: "stable"
	}
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "subsumption"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	incompatibleField: #V1 & {
		fieldA: 1
	}
}
