package patterns

idiomFamilies: {
	families: {
		"types-are-values": {
			pillars: [
				"unification",
				"definitions",
				"top-and-bottom",
			]
			rule: "Model schemas and data as values refined by unification."
		}

		"smart-enum-fallback": {
			pillars: [
				"disjunctions",
				"defaults",
				"bounds",
			]
			rule: "Use disjunctions, defaults, and bounds instead of imperative fallback logic."
		}

		"composition-privacy": {
			pillars: [
				"closedness",
				"hidden-and-let",
				"attributes",
			]
			rule: "Compose closed public surfaces from private internal calculation and metadata."
		}

		"data-pipeline": {
			pillars: [
				"comprehensions",
				"projections",
				"constructors",
				"lists",
			]
			rule: "Project new immutable structures from authority data."
		}

		"contract-testing": {
			pillars: [
				"subsumption",
				"negative-fixtures",
				"cycles",
			]
			rule: "Use unification, subsumption, and expected bottom as the test engine."
		}
	}
}
