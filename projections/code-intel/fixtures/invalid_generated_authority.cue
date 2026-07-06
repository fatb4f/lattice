package codeintelprofilefixtures

invalidGeneratedAuthority: {
	id:          "invalid-generated-authority"
	description: "cue-lsp must remain evidence-only and cannot become an authority provider"
	reason:      "providers.cueLsp.authority is true"

	snapshot: {
		schema: "factory.plugin-bundle.code-intel.cue-profile.v1"
		id:     "code-intel-cue-profile"
		pillarAuthority: {
			repo:   "fatb4f/lattice"
			module: "github.com/fatb4f/lattice"
			export: "pillars/*.cue"
		}
		providers: cueLsp: {
			id:           "cue-lsp"
			authority:    true
			evidenceOnly: true
			diagnostics:  true
			format:       true
		}
		requiredPillars: validProfileSnapshot.requiredPillars
		operatorRules:   validProfileSnapshot.operatorRules
	}
}
