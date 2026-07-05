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

_projectionAuthority: {
	resources: {
		"authority-file": {
			path:       "patterns/catalog.cue"
			visibility: "public"
		}
		"internal-proof": {
			path:       "domain/kernel.cue"
			visibility: "internal"
		}
	}
}

_projectionPublicView: {
	resources: [for resourceID, resource in _projectionAuthority.resources if resource.visibility == "public" {
		id:   resourceID
		path: resource.path
	}]
}

cuePillarSpecs: {
	pillars: {
		projections: {
			title:  "Projections"
			class:  "adapter"
			status: "validated"
			mechanics: [
				"Projection values are derived from authority values.",
				"Exported views omit internal calculation fields.",
				"Authority flows one way into reports and adapter surfaces.",
			]
			idioms: {
				"authority-to-public-view": {
					title: "Derive public views from authority data"
					problem: "Manually maintained reports can widen or contradict authority."
					rule: "Compute the report from the authority value and validate the report selector."
					constructs: ["comprehensions", "filtering", "exported views"]
					canonical: {
						expr:  "_projectionPublicView"
						value: _projectionPublicView
					}
				}
			}
		}
	}
}
