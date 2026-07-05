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

#DefinitionBackedResource: {
	id:   #KebabIdentifier
	role: "authority" | "projection"
}

definitionBackedResource: #DefinitionBackedResource & {
	id:   "authority-file"
	role: "authority"
}

cuePillarSpecs: {
	pillars: {
		definitions: {
			title:  "Definitions"
			class:  "language"
			status: "validated"
			mechanics: [
				"Definitions are reusable constraints.",
				"Definition names are not emitted as regular data.",
				"Exported values choose which definition-backed surfaces become public.",
			]
			idioms: {
				"definition-boundary": {
					title: "Keep reusable authority behind a definition"
					problem: "Reusable constraints become harder to audit when copied into every value."
					rule: "Name the reusable shape as a definition and expose only concrete values that unify with it."
					constructs: ["# definitions", "constraint reuse", "exported values"]
					canonical: {
						expr:  "definitionBackedResource"
						value: definitionBackedResource
					}
					positive: {
						expr:  "definitionBackedResource"
						value: definitionBackedResource
					}
				}
			}
		}
	}
}
