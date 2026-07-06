package patterns

import domain "github.com/fatb4f/lattice/domain"

#Service: {
	name: string
	tier: "internal" | "public"
}

_data: {
	name: "suite"
	tier: "internal"
}

canonical: {
	id:      "unification"
	service: #Service & _data
}

positive: {
	service: canonical.service & {
		name: "suite"
		tier: "internal"
	}
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "unification"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	incompatibleTier: #Service & {
		name: "suite"
		tier: "external"
	}
}
