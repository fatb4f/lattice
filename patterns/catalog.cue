package patterns

import (
	"strings"

	idioms "github.com/fatb4f/lattice/idioms"
)

#NonEmptyString: string & strings.MinRunes(1)
#KebabIdentifier: #NonEmptyString & =~"^[a-z0-9]+(-[a-z0-9]+)*$"
#CueSelectorExpr: #NonEmptyString & =~"^[_#A-Za-z][_A-Za-z0-9]*(\\.[_A-Za-z][_A-Za-z0-9]*)*$"

#CueIdiomFamily:
	"constraint" |
	"unification" |
	"definition" |
	"default" |
	"disjunction" |
	"top-and-bottom" |
	"bounds" |
	"embedding" |
	"comprehension" |
	"closedness" |
	"hidden-and-let" |
	"cycle" |
	"bottom" |
	"subsumption" |
	"fixture" |
	"negative-fixture" |
	"validation" |
	"projection" |
	"constructor" |
	"attribute" |
	"tool-command" |
	"adapter-boundary" |
	"list" |
	"string" |
	"number" |
	"package" |
	"stdlib" |
	"data-ingestion" |
	"tooling"

#CuePillarClass:
	"cue-language-pillars" |
	"lattice-contract-pillars" |
	"adapter-projection-pillars"

#CoverageStatus:
	"missing" |
	"partial" |
	"seed" |
	"captured"

#ValidationMode:
	"vet-passes" |
	"export-passes" |
	"eval-bottoms" |
	"subsumes" |
	"no-widening"

#PillarID:
	"unification" |
	"definitions" |
	"defaults" |
	"disjunctions" |
	"comprehensions" |
	"closedness" |
	"subsumption" |
	"negative-fixtures" |
	"projections" |
	"constructors" |
	"top-and-bottom" |
	"bounds" |
	"hidden-and-let" |
	"cycles" |
	"lists" |
	"attributes"

#PillarSpecClass:
	"language" |
	"contract" |
	"adapter"

#PillarSpecStatus:
	"doc-only" |
	"fixture-backed" |
	"validated"

#CueValueWitness: close({
	expr:  #NonEmptyString
	value: _
})

#CueBottomWitness: close({
	probeExpr: #NonEmptyString
	reason:    #NonEmptyString
})

#ExecutableIdiomSpec: close({
	title:      #NonEmptyString
	problem:    #NonEmptyString
	rule:       #NonEmptyString
	constructs: [...#NonEmptyString] & [_, ...]

	canonical?:      #CueValueWitness
	positive?:       #CueValueWitness
	negative?:       #CueValueWitness
	expectedBottom?: #CueBottomWitness
})

#ExecutableIdiomSpecMap: {
	[ID= !~"^[a-z0-9]+(-[a-z0-9]+)*$"]: {
		_invalidMapKey: ID & #KebabIdentifier
	}
	[string]: #ExecutableIdiomSpec
}

#PillarSpec: close({
	id:        #PillarID
	title:     #NonEmptyString
	class:     #PillarSpecClass
	status:    #PillarSpecStatus
	mechanics: [...#NonEmptyString] & [_, ...]
	idioms:    #ExecutableIdiomSpecMap
})

#PillarSpecMap: {
	[ID= !~"^[a-z0-9]+(-[a-z0-9]+)*$"]: {
		_invalidMapKey: ID & #KebabIdentifier
	}
	[string]: #PillarSpec
	[ID=string]: {
		id: ID
	}
}

#IdiomFamilyID:
	"types-are-values" |
	"smart-enum-fallback" |
	"composition-privacy" |
	"data-pipeline" |
	"contract-testing"

#IdiomFamilySpec: close({
	id:      #IdiomFamilyID
	pillars: [...#PillarID] & [_, ...]
	rule:    #NonEmptyString
})

#IdiomFamilySpecMap: {
	[ID= !~"^[a-z0-9]+(-[a-z0-9]+)*$"]: {
		_invalidMapKey: ID & #KebabIdentifier
	}
	[string]: #IdiomFamilySpec
	[ID=string]: {
		id: ID
	}
}

#CueIdiom: close({
	id:      #KebabIdentifier
	family:  #CueIdiomFamily
	pillarClass: #CuePillarClass | *"lattice-contract-pillars"
	coverageStatus: #CoverageStatus | *"seed"
	title:   #NonEmptyString
	problem: #NonEmptyString
	rule:    #NonEmptyString

	uses:         [...#KebabIdentifier] | *[]
	antiPatterns: [...#NonEmptyString] | *[]

	sourceRefs: [...idioms.#SourceID] & [_, ...]

	cueSurface: close({
		constructs: [...#NonEmptyString] & [_, ...]
		exampleExpr?: #NonEmptyString
	})

	validation: [...close({
		id:   #KebabIdentifier
		mode: #ValidationMode
		expr: #CueSelectorExpr
	})]
})

#CueIdiomMap: {
	[ID= !~"^[a-z0-9]+(-[a-z0-9]+)*$"]: {
		_invalidMapKey: ID & #KebabIdentifier
	}
	[string]: #CueIdiom
	[ID=string]: {
		id: ID
	}
}

#CueIdiomCatalog: close({
	schema: "fatb4f.lattice.cue-idiom-catalog.v1"
	idioms: #CueIdiomMap
})

cuePillarSpecs: close({
	schema:  "fatb4f.lattice.cue-pillar-specs.v1"
	pillars: #PillarSpecMap
})

idiomFamilies: close({
	schema:   "fatb4f.lattice.cue-idiom-families.v1"
	families: #IdiomFamilySpecMap
})
