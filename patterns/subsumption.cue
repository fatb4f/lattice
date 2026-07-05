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

