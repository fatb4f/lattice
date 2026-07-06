package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"hidden-and-let": {

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
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "hidden-and-let"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	privateConflict: "external"
}

}
}
