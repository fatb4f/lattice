package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"map-key-normalization-comprehension": {
			family: "comprehension"
			title:  "Normalize map-key identity with comprehensions"
			problem: "Map-key identity and embedded object identity can diverge without an executable equality proof."
			rule:   "Use comprehensions to bind each map key back into the value and derive stable key sets."

			sourceRefs: [
				"cue-comprehensions",
				"lattice-domain-kernel",
			]

			cueSurface: {
				constructs: [
					"field comprehensions",
					"dynamic fields",
					"map constraints",
				]
				exampleExpr: "#MakeClosedObligationState.out"
			}

			validation: [{
				id:   "closed-state-normalizes"
				mode: "export-passes"
				expr: "_closedState"
			}]
		}
	}
}

_comprehensionInput: {
	services: {
		api: {
			port: 8080
			public: true
		}
		worker: {
			port: 9090
			public: false
		}
	}
}

_comprehensionProjection: {
	publicPorts: [for name, service in _comprehensionInput.services if service.public {
		"\(name):\(service.port)"
	}]
}

cuePillarSpecs: {
	pillars: {
		comprehensions: {
			title:  "Comprehensions"
			class:  "language"
			status: "validated"
			mechanics: [
				"for clauses project maps and lists.",
				"if clauses filter generated values.",
				"Dynamic labels preserve source identity in derived structures.",
			]
			idioms: {
				"filtered-list-projection": {
					title: "Project filtered values from authority data"
					problem: "Hand-written projections drift from the authority map."
					rule: "Derive the projection with a comprehension over the authority value."
					constructs: ["for", "if", "list comprehensions"]
					canonical: {
						expr:  "_comprehensionProjection"
						value: _comprehensionProjection
					}
				}
			}
		}
	}
}
