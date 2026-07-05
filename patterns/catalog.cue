package patterns

import (
	"strings"

	idioms "github.com/fatb4f/lattice/idioms"
)

#NonEmptyString: string & strings.MinRunes(1)
#KebabIdentifier: #NonEmptyString & =~"^[a-z0-9]+(-[a-z0-9]+)*$"
#CueSelectorExpr: #NonEmptyString & =~"^[_#A-Za-z][_A-Za-z0-9]*(\\.[_A-Za-z][_A-Za-z0-9]*)*$"

#CueIdiomFamily:
	"unification" |
	"definition" |
	"default" |
	"disjunction" |
	"comprehension" |
	"closedness" |
	"subsumption" |
	"negative-fixture" |
	"projection" |
	"constructor" |
	"tool-command" |
	"adapter-boundary"

#ValidationMode:
	"vet-passes" |
	"export-passes" |
	"eval-bottoms" |
	"subsumes" |
	"no-widening"

#CueIdiom: close({
	id:      #KebabIdentifier
	family:  #CueIdiomFamily
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

