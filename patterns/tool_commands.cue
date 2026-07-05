package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"tool-command-evidence-boundary": {
			family: "tool-command"
			title:  "Treat tool command output as evidence, not authority"
			problem: "Commands and adapters observe or project state, but their outputs can drift from source contracts."
			rule:   "Route command output into evidence fixtures and validate it against local CUE authority before promotion."

			sourceRefs: [
				"cue-tool-commands",
				"lattice-readme-projection-kernel",
			]

			cueSurface: {
				constructs: [
					"tool commands",
					"evidence fixtures",
					"projection validation",
				]
				exampleExpr: "cueIdiomCatalog"
			}

			validation: [{
				id:   "catalog-exposes-tool-boundary"
				mode: "export-passes"
				expr: "cueIdiomCatalog"
			}]
		}
	}
}
