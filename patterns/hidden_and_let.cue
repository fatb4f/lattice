package patterns

_hiddenAndLetInput: {
	name: "api"
	port: 8080
}

hiddenAndLetEndpoint: {
	_input: _hiddenAndLetInput
	let address = "\(_input.name):\(_input.port)"

	endpoint: address
}

cuePillarSpecs: {
	pillars: {
		"hidden-and-let": {
			title:  "Hidden Fields And Let"
			class:  "language"
			status: "validated"
			mechanics: [
				"Hidden fields keep internal calculation out of exported data.",
				"let bindings name local derived expressions.",
				"Public output can be composed from private inputs.",
			]
			idioms: {
				"private-calculation-public-output": {
					title: "Use hidden fields and let for internal calculation"
					problem: "Intermediate values often leak into exported adapter surfaces."
					rule: "Keep inputs hidden and expose only the derived public field."
					constructs: ["_hidden fields", "let", "interpolation"]
					canonical: {
						expr:  "hiddenAndLetEndpoint"
						value: hiddenAndLetEndpoint
					}
				}
			}
		}
	}
}
