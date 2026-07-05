package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"authority-to-projection": {
			family: "projection"
			title:  "Project authority into generated evidence without reversing ownership"
			problem: "Generated reports and operator views are useful evidence, but become unsafe if treated as source authority."
			rule:   "Model projections as one-way exports from local authority graphs into generated evidence or operator surfaces."

			sourceRefs: [
				"lattice-readme-projection-kernel",
				"apercue-projection-patterns",
			]

			cueSurface: {
				constructs: [
					"comprehensions",
					"unification",
					"definitions",
					"closed structs",
				]
				exampleExpr: "cueIdiomCatalog"
			}

			validation: [
				{
					id:   "catalog-exports"
					mode: "export-passes"
					expr: "cueIdiomCatalog"
				},
			]
		}
		"adapter-evidence-boundary": {
			family: "adapter-boundary"
			title:  "Keep adapters outside source authority"
			problem: "Adapters and generated overlays can observe, format, or project authority, but cannot define it."
			rule:   "Declare adapter outputs evidence-only and validate them against owned contracts before use."

			sourceRefs: [
				"lattice-readme-projection-kernel",
				"apercue-projection-patterns",
			]

			cueSurface: {
				constructs: [
					"closed structs",
					"evidence fixtures",
					"authority references",
				]
				exampleExpr: "cueIdiomCatalog"
			}

			validation: [{
				id:   "adapter-boundary-exports"
				mode: "export-passes"
				expr: "cueIdiomCatalog"
			}]
		}
	}
}
