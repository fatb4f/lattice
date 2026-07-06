package patterns

import domain "github.com/fatb4f/lattice/domain"

#ResourceRef: {
	id:   =~"^[a-z][a-z0-9-]*$"
	role: "authority" | "projection"
}

canonical: {
	id:       "definitions"
	resource: #ResourceRef
}

positive: {
	resource: #ResourceRef & {
		id:   "authority-file"
		role: "authority"
	}
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "definitions"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	invalidRole: #ResourceRef & {
		id:   "authority-file"
		role: "generated"
	}
}
