package codeintelprofilefixtures

invalidMissingPillarCoverage: {
	id:          "invalid-missing-pillar-coverage"
	description: "A projected profile must cover every expected code-intel pillar"
	reason:      "requiredPillars omits attributes"

	snapshot: {
		schema: "factory.plugin-bundle.code-intel.cue-profile.v1"
		id:     "code-intel-cue-profile"
		pillarAuthority: {
			repo:   "fatb4f/lattice"
			module: "github.com/fatb4f/lattice"
			export: "pillars/*.cue"
		}
		providers: validProfileSnapshot.providers
		requiredPillars: [
			"unification",
			"definitions",
			"defaults",
			"disjunctions",
			"comprehensions",
			"closedness",
			"subsumption",
			"negative-fixtures",
			"projections",
			"constructors",
			"top-and-bottom",
			"bounds",
			"hidden-and-let",
			"cycles",
			"lists",
		]
		operatorRules: validProfileSnapshot.operatorRules
	}
}
