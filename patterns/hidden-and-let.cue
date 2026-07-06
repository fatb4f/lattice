package patterns

import domain "github.com/fatb4f/lattice/domain"

_privateSuffix: "internal"

#PublicView: close({
	name: string
	slug: string
})

canonical: {
	id: "hidden-and-let"
	let serviceName = "api"
	view: #PublicView & {
		name: serviceName
		slug: "\(serviceName)-\(_privateSuffix)"
	}
}

positive: {
	view: canonical.view & {
		name: "api"
		slug: "api-internal"
	}
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "hidden-and-let"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	privateConflict: _privateSuffix & "external"
}
