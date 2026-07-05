package patterns

import "strings"

#BoundedPort: int & >=1 & <=65535
#BoundedIdentifier: string & strings.MinRunes(3) & =~"^[a-z][a-z0-9-]*$"

boundedService: close({
	id:   #BoundedIdentifier
	port: #BoundedPort
}) & {
	id:   "api"
	port: 8080
}

cuePillarSpecs: {
	pillars: {
		bounds: {
			title:  "Bounds"
			class:  "language"
			status: "validated"
			mechanics: [
				"Numeric comparisons constrain scalar domains.",
				"Regular expressions constrain string shape.",
				"Standard library predicates can constrain structural size.",
			]
			idioms: {
				"bounded-scalar-domain": {
					title: "Constrain scalar domains with bounds"
					problem: "Shape-valid values can still carry impossible ports, names, or limits."
					rule: "Combine primitive types with numeric, regex, and length bounds."
					constructs: [">=", "<=", "=~", "strings.MinRunes"]
					canonical: {
						expr:  "boundedService"
						value: boundedService
					}
					expectedBottom: {
						probeExpr: "#BoundedPort & 70000"
						reason:    "70000 exceeds the admitted port range."
					}
				}
			}
		}
	}
}
