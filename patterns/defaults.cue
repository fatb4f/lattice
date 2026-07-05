package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"defaulted-internal-visibility": {
			family: "default"
			title:  "Default optional policy fields without widening accepted values"
			problem: "Callers should not have to repeat common policy values, but defaults must not hide invalid states."
			rule:   "Use defaults for admitted values only, then prove the constructed output remains closed."

			sourceRefs: [
				"cue-defaults",
				"lattice-domain-kernel",
			]

			cueSurface: {
				constructs: [
					"defaults",
					"closed structs",
					"constructors",
				]
				exampleExpr: "_closedState.resources.\"authority-file\".visibility"
			}

			validation: [{
				id:   "default-exports"
				mode: "export-passes"
				expr: "_closedState"
			}]
		}
	}
}

