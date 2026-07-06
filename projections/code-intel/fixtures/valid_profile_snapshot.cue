package codeintelprofilefixtures

import projections "github.com/fatb4f/lattice/projections"

validProfileSnapshot: projections.#CodeIntelProfileExpectation & {
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
		"attributes",
	]

	operatorRules: [
		"Use lattice pillar files before inventing local CUE patterns.",
		"Use cue-lsp diagnostics as evidence, not authority.",
		"Prefer exportable witness surfaces and isolated destructive probes.",
		"Keep generated plugin references evidence-only.",
		"Use no-widening checks when comparing source profile and generated projection.",
	]
}
