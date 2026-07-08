package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#PositiveFixture: close({
	id:          =~"^[a-z0-9]+(-[a-z0-9]+)*$"
	description: string & !=""
	graph:       primitives.#Graph
})

#NegativeFixture: close({
	id:          =~"^[a-z0-9]+(-[a-z0-9]+)*$"
	description: string & !=""
	invalid:     _
})
