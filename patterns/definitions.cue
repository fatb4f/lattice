package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"hidden-definition-authority": {
			family: "definition"
			title:  "Keep reusable authority in definitions"
			problem: "Exported data and reusable schemas need different visibility and stability."
			rule:   "Use definitions for reusable constraints and expose only intentional values as exported data."

			sourceRefs: [
				"cue-definitions",
				"lattice-domain-kernel",
			]

			cueSurface: {
				constructs: [
					"definitions",
					"hidden fields",
					"exported values",
				]
				exampleExpr: "#ClosedObligationState"
			}

			validation: [{
				id:   "domain-definitions-vet"
				mode: "vet-passes"
				expr: "#ClosedObligationState"
			}]
		}
	}
}

