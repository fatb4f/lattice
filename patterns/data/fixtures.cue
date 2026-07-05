package datafixtures

import profiles "github.com/fatb4f/lattice/profiles"

#ProfileSnapshotEvidence: close({
	source:       "json" | "yaml" | "cue"
	authority:    false
	evidenceOnly: true
	payload:      profiles.#CodeIntelProfileExpectation
})

jsonProfileEvidence: #ProfileSnapshotEvidence & {
	source:       "json"
	authority:    false
	evidenceOnly: true
	payload: {
		schema: "factory.plugin-bundle.code-intel.cue-profile.v1"
		id:     "code-intel-cue-profile"
		idiomAuthority: {
			repo:   "fatb4f/lattice"
			module: "github.com/fatb4f/lattice"
			export: "cueIdiomCatalog"
		}
		providers: cueLsp: {
			id:           "cue-lsp"
			authority:    false
			evidenceOnly: true
			diagnostics:  true
			format:       true
		}
		requiredIdiomFamilies: ["unification"]
		operatorRules: ["Validate imported data before treating it as evidence."]
	}
}

dataIngestionFixtureReport: close({
	schema: "fatb4f.lattice.pattern-fixtures.data-ingestion.v1"
	fixtures: {
		sourceIsExternalData: jsonProfileEvidence.source == "json"
		evidenceOnly:        jsonProfileEvidence.evidenceOnly == true
		notAuthority:        jsonProfileEvidence.authority == false
		payloadValidated:     jsonProfileEvidence.payload.schema == "factory.plugin-bundle.code-intel.cue-profile.v1"
	}
	accepted: fixtures.sourceIsExternalData &&
		fixtures.evidenceOnly &&
		fixtures.notAuthority &&
		fixtures.payloadValidated
})

