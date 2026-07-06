package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"constructors": {

#MakeService: {
	in: {
		name: string
		port: int | *80
	}
	out: close({
		name: in.name
		port: in.port
	})
}

canonical: {
	id: "constructors"
	service: (#MakeService & {in: {
		name: "api"
	}}).out
}

positive: {
	service: canonical.service & {
		name: "api"
		port: 80
	}
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "constructors"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	badPort: {
		name: "api"
		port: "80"
	}
}

}
}
