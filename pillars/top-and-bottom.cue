package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"top-and-bottom": {

canonical: {
	id:  "top-and-bottom"
	top: _
}

positive: {
	refinedTop: canonical.top & {
		port: 8080
	}
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "top-and-bottom"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	conflict: {
		left:  "string"
		right: "int"
	}
}

}
}
