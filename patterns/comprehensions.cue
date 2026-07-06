package patterns

import domain "github.com/fatb4f/lattice/domain"

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
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "comprehensions"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	badServicePort: #Services & {
		api: {
			port:   "8080"
			public: true
		}
	}
}
