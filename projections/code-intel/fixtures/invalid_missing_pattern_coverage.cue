package codeintelprofilefixtures

invalidMissingPatternCoverage: {
	id:          "invalid-missing-pattern-coverage"
	description: "A projected profile must cover every expected code-intel pattern"
	reason:      "requiredPatterns omits attributes"

	snapshot: {
		schema: "factory.plugin-bundle.code-intel.cue-profile.v1"
		id:     "code-intel-cue-profile"
		patternAuthority: {
			repo:   "fatb4f/lattice"
			module: "github.com/fatb4f/lattice"
			export: "patterns/*.cue"
		}
		providers: validProfileSnapshot.providers
		requiredPatterns: [
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
