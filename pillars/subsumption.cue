package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"subsumption": {

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
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "subsumption"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	incompatibleField: {
		fieldA: 1
	}
}

}
}
