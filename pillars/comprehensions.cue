package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"comprehensions": {

#Services: {
	[string]: {
		port:   int
		public: bool
	}
}

_services: #Services & {
	api: {
		port:   8080
		public: true
	}
	worker: {
		port:   9090
		public: false
	}
}

canonical: {
	id: "comprehensions"
	publicPorts: [for name, service in _services if service.public {
		"\(name):\(service.port)"
	}]
}

positive: {
	publicPorts: canonical.publicPorts & ["api:8080"]
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "comprehensions"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	badServicePort: {
		api: {
			port:   "8080"
			public: true
		}
	}
}

}
}
