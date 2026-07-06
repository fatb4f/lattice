package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"unification": {

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
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "unification"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	incompatibleTier: {
		name: "suite"
		tier: "external"
	}
}

}
}
