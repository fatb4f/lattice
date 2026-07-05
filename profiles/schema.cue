package profiles

import (
	"strings"

	patterns "github.com/fatb4f/lattice/patterns"
)

#NonEmptyString: string & strings.MinRunes(1)
#KebabIdentifier: #NonEmptyString & =~"^[a-z0-9]+(-[a-z0-9]+)*$"

#LatticeIdiomAuthority: close({
	repo:   "fatb4f/lattice"
	module: "github.com/fatb4f/lattice"
	export: "cueIdiomCatalog"
})

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

	idiomAuthority: #LatticeIdiomAuthority
	providers:      #CodeIntelProviders

	requiredIdiomFamilies: [...patterns.#CueIdiomFamily] & [_, ...]
	operatorRules: [...#NonEmptyString] & [_, ...]
})

