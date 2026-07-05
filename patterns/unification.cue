package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"constraint-unification": {
			family: "unification"
			title:  "Compose authority by unifying compatible constraints"
			problem: "A profile can drift when schema, fixture, and expected output are checked separately."
			rule:   "Represent each requirement as a constraint and admit only values that unify with every authority layer."

			sourceRefs: [
				"cue-unification",
				"lattice-domain-kernel",
			]

			cueSurface: {
				constructs: [
					"unification",
					"struct constraints",
					"bottom",
				]
				exampleExpr: "_noWideningProof.compatibility"
			}

			validation: [{
				id:   "domain-vets"
				mode: "vet-passes"
				expr: "_closedState"
			}]
		}
	}
}

_unificationSchema: {
	name: string
	tier: "internal" | "public"
}

_unificationData: {
	name: "catalog"
	tier: "internal"
}

_unificationCanonical: _unificationSchema & _unificationData

cuePillarSpecs: {
	pillars: {
		unification: {
			title:  "Unification"
			class:  "language"
			status: "validated"
			mechanics: [
				"Values combine with &.",
				"Compatible constraints refine to a narrower value.",
				"Incompatible constraints produce bottom.",
				"Schema and data are checked by the same operation.",
			]
			idioms: {
				"schema-data-unification": {
					title: "Unify schema and data as values"
					problem: "Separate schema checks can drift from the data they claim to validate."
					rule: "Unify concrete data with the schema value and export the resulting value."
					constructs: ["&", "struct constraints", "enum refinement"]
					canonical: {
						expr:  "_unificationCanonical"
						value: _unificationCanonical
					}
					expectedBottom: {
						probeExpr: "_unificationSchema & {tier: \"external\"}"
						reason:    "external is outside the admitted tier disjunction."
					}
				}
			}
		}
	}
}
