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

_defaultedMode: {
	mode: "strict" | "permissive" | *"strict"
}

_defaultOverride: _defaultedMode & {
	mode: "permissive"
}

cuePillarSpecs: {
	pillars: {
		defaults: {
			title:  "Defaults"
			class:  "language"
			status: "fixture-backed"
			mechanics: [
				"Defaults mark a preferred value with *.",
				"Concrete values override defaults when still admitted.",
				"Defaults must stay inside the same disjunction as explicit values.",
			]
			idioms: {
				"preferred-value": {
					title: "Use defaults as admitted fallback values"
					problem: "Fallback logic can accept values the schema itself does not admit."
					rule: "Put the default inside the bounded disjunction and let concrete input refine it."
					constructs: ["*", "disjunctions", "concrete override"]
					canonical: {
						expr:  "_defaultedMode"
						value: _defaultedMode
					}
					positive: {
						expr:  "_defaultOverride"
						value: _defaultOverride
					}
					expectedBottom: {
						probeExpr: "_defaultedMode & {mode: \"debug\"}"
						reason:    "debug is not one of the admitted mode values."
					}
				}
			}
		}
	}
}
