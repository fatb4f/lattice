package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"closed-contract-surface": {
			family: "closedness"
			title:  "Close authority surfaces against stray fields"
			problem: "Unrecognized fields can silently become authority if contracts remain open."
			rule:   "Use closed schemas or explicit invalid-field guards on authority surfaces."

			sourceRefs: [
				"cue-closedness",
				"lattice-domain-kernel",
			]

			cueSurface: {
				constructs: [
					"close",
					"field guards",
					"bottom",
				]
				exampleExpr: "#Resource"
			}

			validation: [{
				id:   "closed-domain-vets"
				mode: "vet-passes"
				expr: "_closedState"
			}]
		}
	}
}

_closedSurface: close({
	id:   #KebabIdentifier
	role: "authority" | "projection"
})

_closedSurfacePositive: _closedSurface & {
	id:   "closed-authority"
	role: "authority"
}

cuePillarSpecs: {
	pillars: {
		closedness: {
			title:  "Closedness"
			class:  "language"
			status: "validated"
			mechanics: [
				"Open structs admit additional fields.",
				"close() rejects fields outside the declared surface.",
				"Closed authority surfaces prevent typo-driven widening.",
			]
			idioms: {
				"closed-authority-surface": {
					title: "Close public authority surfaces"
					problem: "Unexpected fields can become unreviewed authority."
					rule: "Use close() for the public contract and keep extension points explicit."
					constructs: ["close", "closed structs", "field rejection"]
					canonical: {
						expr:  "_closedSurfacePositive"
						value: _closedSurfacePositive
					}
					positive: {
						expr:  "_closedSurfacePositive"
						value: _closedSurfacePositive
					}
					expectedBottom: {
						probeExpr: "_closedSurface & {id: \"closed-authority\", role: \"authority\", typo: true}"
						reason:    "The closed surface does not admit typo."
					}
				}
			}
		}
	}
}
