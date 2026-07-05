package patterns

#CuePillarExpectation: close({
	id:             #KebabIdentifier
	pillarClass:    #CuePillarClass
	family:         #CueIdiomFamily
	coverageStatus: #CoverageStatus
	rationale:      #NonEmptyString
	surface:        #CuePillarSurface
})

#CuePillarSurface: close({
	dir:              #KebabIdentifier
	requiresReadme:   true | *true
	requiresPattern:  bool | *false
	requiresPositive: bool | *false
	requiresNegative: bool | *false
	requiresReport:   bool | *false
})

#CuePillarExpectationMap: {
	[ID= !~"^[a-z0-9]+(-[a-z0-9]+)*$"]: {
		_invalidMapKey: ID & #KebabIdentifier
	}
	[string]: #CuePillarExpectation
	[ID=string]: {
		id: ID
	}
}

cuePillarExpectations: close({
	schema: "fatb4f.lattice.cue-pillar-expectations.v1"
	pillars: #CuePillarExpectationMap & {
		"constraints": {
			pillarClass:    "cue-language-pillars"
			family:         "constraint"
			coverageStatus: "partial"
			rationale:      "Basic string constraints exist; numeric and structural constraint recipes need more coverage."
			surface: dir: "constraints"
		}
		"unification": {
			pillarClass:    "cue-language-pillars"
			family:         "unification"
			coverageStatus: "captured"
			rationale:      "The lattice kernel already uses unification as composition and proof."
			surface: {
				dir:             "unification"
				requiresPattern: true
			}
		}
		"bottom": {
			pillarClass:    "cue-language-pillars"
			family:         "bottom"
			coverageStatus: "captured"
			rationale:      "Negative fixtures model bottom as an explicit failure witness."
			surface: {
				dir:             "bottom"
				requiresPattern: true
			}
		}
		"closedness": {
			pillarClass:    "cue-language-pillars"
			family:         "closedness"
			coverageStatus: "partial"
			rationale:      "Closed authority surfaces exist; open-versus-closed contrast recipes are now seeded."
			surface: dir: "closedness"
		}
		"defaults": {
			pillarClass:    "cue-language-pillars"
			family:         "default"
			coverageStatus: "partial"
			rationale:      "Default visibility and required flags exist; standalone default recipes are now seeded."
			surface: {
				dir:              "defaults"
				requiresPositive: true
				requiresNegative: true
			}
		}
		"disjunctions": {
			pillarClass:    "cue-language-pillars"
			family:         "disjunction"
			coverageStatus: "partial"
			rationale:      "Enum disjunctions exist; tagged union and invalid branch recipes are now seeded."
			surface: {
				dir:              "disjunctions"
				requiresPositive: true
				requiresNegative: true
			}
		}
		"lists": {
			pillarClass:    "cue-language-pillars"
			family:         "list"
			coverageStatus: "partial"
			rationale:      "Non-empty and key projection list patterns exist; uniqueness and tuple recipes need expansion."
			surface: dir: "lists"
		}
		"strings": {
			pillarClass:    "cue-language-pillars"
			family:         "string"
			coverageStatus: "partial"
			rationale:      "Regex and interpolation patterns exist; semver and namespaced ID recipes need expansion."
			surface: dir: "strings"
		}
		"numbers": {
			pillarClass:    "cue-language-pillars"
			family:         "number"
			coverageStatus: "seed"
			rationale:      "Numeric constraints are not central to the lattice kernel, so only a seed recipe exists."
			surface: dir: "numbers"
		}
		"packages": {
			pillarClass:    "cue-language-pillars"
			family:         "package"
			coverageStatus: "seed"
			rationale:      "Package/module boundaries are now represented as an explicit idiom surface."
			surface: {
				dir:              "packages"
				requiresPositive: true
				requiresNegative: true
			}
		}
		"stdlib": {
			pillarClass:    "cue-language-pillars"
			family:         "stdlib"
			coverageStatus: "partial"
			rationale:      "Current kernel uses list and strings; more stdlib recipes can be added incrementally."
			surface: dir: "stdlib"
		}
		"data-ingestion": {
			pillarClass:    "adapter-projection-pillars"
			family:         "data-ingestion"
			coverageStatus: "seed"
			rationale:      "External JSON/YAML/data validation is represented as evidence input, not authority."
			surface: {
				dir:              "data"
				requiresPositive: true
				requiresNegative: true
			}
		}
		"tooling": {
			pillarClass:    "adapter-projection-pillars"
			family:         "tooling"
			coverageStatus: "partial"
			rationale:      "CLI commands are modeled as validation recipes; executable tool tasks remain future work."
			surface: {
				dir:              "tooling"
				requiresPositive: true
				requiresNegative: true
			}
		}
		"adapters": {
			pillarClass:    "adapter-projection-pillars"
			family:         "adapter-boundary"
			coverageStatus: "partial"
			rationale:      "Adapter boundaries are represented as evidence-only surfaces."
			surface: dir: "adapters"
		}
		"fixtures": {
			pillarClass:    "lattice-contract-pillars"
			family:         "fixture"
			coverageStatus: "captured"
			rationale:      "Positive and negative validation fixtures are a core lattice contract idiom."
			surface: {
				dir:             "fixtures"
				requiresPattern: true
			}
		}
	}
})
