package projections

import "strings"

#NonEmptyString:  string & strings.MinRunes(1)
#KebabIdentifier: #NonEmptyString & =~"^[a-z0-9]+(-[a-z0-9]+)*$"

#LatticePillarAuthority: close({
	repo:   "fatb4f/lattice"
	module: "github.com/fatb4f/lattice"
	export: "pillars/*.cue"
})

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

#EvidenceProvider: close({
	id:           #KebabIdentifier
	authority:    false
	evidenceOnly: true
	diagnostics?: bool
	format?:      bool
})

#CodeIntelProviders: close({
	cueLsp: #EvidenceProvider & {
		id:          "cue-lsp"
		diagnostics: true
		format:      true
	}
})

#CodeIntelProfileExpectation: close({
	schema: "factory.plugin-bundle.code-intel.cue-profile.v1"
	id:     "code-intel-cue-profile"

	pillarAuthority: #LatticePillarAuthority
	providers:      #CodeIntelProviders

	requiredPillars: [...#PillarID] & [_, ...]
	operatorRules: [...#NonEmptyString] & [_, ...]
})
