package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"definitions": {

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
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "definitions"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	invalidRole: {
		id:   "authority-file"
		role: "generated"
	}
}

}
}
