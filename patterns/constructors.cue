package patterns

import domain "github.com/fatb4f/lattice/domain"

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
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "constructors"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	badPort: (#MakeService & {in: {
		name: "api"
		port: "80"
	}}).out
}
