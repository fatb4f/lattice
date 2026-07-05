package codeintelprofile

import profiles "github.com/fatb4f/lattice/profiles"

expectedCodeIntelProfile: profiles.#CodeIntelProfileExpectation & {
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
		"adapter-boundary",
	]

	operatorRules: [
		"Use lattice idioms before inventing local CUE patterns.",
		"Use cue-lsp diagnostics as evidence, not authority.",
		"Prefer exportable witness surfaces and isolated destructive probes.",
		"Keep generated plugin references evidence-only.",
		"Use no-widening checks when comparing source profile and generated projection.",
	]
}

