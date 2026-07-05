package codeintelprofilefixtures

invalidMissingIdiomCoverage: {
	id:          "invalid-missing-idiom-coverage"
	description: "A projected profile must cover every expected code-intel idiom family"
	reason:      "requiredIdiomFamilies omits adapter-boundary"

	snapshot: {
		schema: "factory.plugin-bundle.code-intel.cue-profile.v1"
		id:     "code-intel-cue-profile"
		idiomAuthority: {
			repo:   "fatb4f/lattice"
			module: "github.com/fatb4f/lattice"
			export: "cueIdiomCatalog"
		}
		providers: validProfileSnapshot.providers
		requiredIdiomFamilies: [
			"unification",
			"definition",
			"default",
			"disjunction",
			"comprehension",
			"closedness",
			"subsumption",
			"negative-fixture",
			"projection",
			"constructor",
			"tool-command",
		]
		operatorRules: validProfileSnapshot.operatorRules
	}
}
