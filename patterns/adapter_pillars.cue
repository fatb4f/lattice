package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"external-data-as-input": {
			family:         "data-ingestion"
			pillarClass:    "adapter-projection-pillars"
			coverageStatus: "seed"
			title:  "Treat JSON and YAML as input evidence"
			problem: "Imported data can accidentally become authority when it is not routed through a local schema."
			rule:   "Validate imported data against local CUE authority before using it in reports or feedback."
			sourceRefs: ["cue-tool-commands", "lattice-readme-projection-kernel"]
			cueSurface: {
				constructs: ["cue vet", "data import", "schema validation"]
				exampleExpr: "profileSnapshot"
			}
			validation: [{
				id:   "data-ingestion-exports"
				mode: "export-passes"
				expr: "cueIdiomCatalog"
			}]
		}
		"cue-cli-recipe": {
			family:         "tooling"
			pillarClass:    "adapter-projection-pillars"
			coverageStatus: "partial"
			title:  "Record CUE CLI recipes as reusable validation idioms"
			problem: "Validation behavior drifts when command invocations live only in shell history or prose."
			rule:   "Catalog the selector, command mode, and expected pass or bottom behavior for each recipe."
			sourceRefs: ["cue-tool-commands", "cuetorials-useful-patterns"]
			cueSurface: {
				constructs: ["cue vet", "cue export", "cue eval", "selectors"]
				exampleExpr: "codeIntelProfileFeedbackReport"
			}
			validation: [{
				id:   "tooling-recipe-exports"
				mode: "export-passes"
				expr: "cueIdiomCatalog"
			}]
		}
	}
}

