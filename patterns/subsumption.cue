package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"no-widening-subsumption": {
			family: "subsumption"
			title:  "Reject projections that widen authority"
			problem: "Generated projections can look compatible while adding resources or references not present in authority."
			rule:   "Compare authority and target key sets, reference sets, and compatibility before accepting a projection."

			sourceRefs: [
				"cue-subsume",
				"lattice-domain-kernel",
			]

			cueSurface: {
				constructs: [
					"subsumption",
					"unification",
					"list sorting",
					"key-set equality",
				]
				exampleExpr: "#NoWideningProof"
			}

			validation: [{
				id:   "no-widening-proof-exports"
				mode: "no-widening"
				expr: "_noWideningProof"
			}]
		}
	}
}

#SubsumptionV1API: {
	fieldA: string
	...
}

#SubsumptionV2API: {
	fieldA: string
	fieldB: int | *0
	...
}

_subsumptionCompatibility: #SubsumptionV1API & #SubsumptionV2API

subsumptionCompatibilityFixture: _subsumptionCompatibility & {
	fieldA: "stable"
}

cuePillarSpecs: {
	pillars: {
		subsumption: {
			title:  "Subsumption"
			class:  "contract"
			status: "validated"
			mechanics: [
				"Compatibility is represented as an explicit witness.",
				"A narrower value can satisfy an older wider surface.",
				"Validation selectors make the compatibility check reviewable.",
			]
			idioms: {
				"compatibility-witness": {
					title: "Expose compatibility as a named value"
					problem: "Compatibility claims are ambiguous when they live only in prose."
					rule: "Unify the old and new surfaces in a named witness and validate that selector."
					constructs: ["unification", "open structs", "compatibility witness"]
					canonical: {
						expr:  "subsumptionCompatibilityFixture"
						value: subsumptionCompatibilityFixture
					}
				}
			}
		}
	}
}
