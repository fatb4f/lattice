package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"fixture-matrix": {
			family:         "fixture"
			pillarClass:    "lattice-contract-pillars"
			coverageStatus: "captured"
			title:  "Use fixture matrices to prove accepted and rejected states"
			problem: "Single examples do not show whether contract boundaries reject the right failures."
			rule:   "Keep exportable fixture metadata separate from destructive probes and validation reports."
			sourceRefs: ["lattice-domain-negative-fixture", "lattice-readme-projection-kernel"]
			cueSurface: {
				constructs: ["fixtures", "negative probes", "feedback reports"]
				exampleExpr: "codeIntelProfileFeedbackReport"
			}
			validation: [{
				id:   "fixture-matrix-exports"
				mode: "export-passes"
				expr: "cueIdiomCatalog"
			}]
		}
		"validation-report-surface": {
			family:         "validation"
			pillarClass:    "lattice-contract-pillars"
			coverageStatus: "captured"
			title:  "Export validation reports as evidence"
			problem: "A validation pass is hard to reuse unless its coverage and boundary checks are exported."
			rule:   "Derive a concrete report that records accepted status, missing coverage, and authority-boundary checks."
			sourceRefs: ["lattice-readme-projection-kernel", "cue-tool-commands"]
			cueSurface: {
				constructs: ["reports", "derived fields", "export selectors"]
				exampleExpr: "codeIntelProfileFeedbackReport"
			}
			validation: [{
				id:   "validation-report-exports"
				mode: "export-passes"
				expr: "cueIdiomCatalog"
			}]
		}
	}
}
