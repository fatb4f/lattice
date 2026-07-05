package idioms

import "strings"

#NonEmptyString: string & strings.MinRunes(1)
#KebabIdentifier: #NonEmptyString & =~"^[a-z0-9]+(-[a-z0-9]+)*$"

#SourceKind:
	"local-kernel" |
	"local-doc" |
	"official-doc" |
	"example-corpus" |
	"tutorial" |
	"projection-substrate"

#SourceID:
	"lattice-domain-kernel" |
	"lattice-domain-negative-fixture" |
	"lattice-readme-projection-kernel" |
	"cue-bottom-semantics" |
	"cue-definitions" |
	"cue-unification" |
	"cue-defaults" |
	"cue-disjunctions" |
	"cue-comprehensions" |
	"cue-closedness" |
	"cue-subsume" |
	"cue-tool-commands" |
	"cue-by-example" |
	"cuetorials-useful-patterns" |
	"apercue-projection-patterns"

#SourceRef: close({
	id:    #SourceID
	kind:  #SourceKind
	title: #NonEmptyString
	ref:   #NonEmptyString
})

#SourceRefMap: {
	[ID= !~"^[a-z0-9]+(-[a-z0-9]+)*$"]: {
		_invalidMapKey: ID & #KebabIdentifier
	}
	[string]: #SourceRef
	[ID=string]: {
		id: ID
	}
}

cueIdiomSources: close({
	schema: "fatb4f.lattice.cue-idiom-sources.v1"
	sources: #SourceRefMap & {
		"lattice-domain-kernel": {
			kind:  "local-kernel"
			title: "Lattice domain obligation kernel"
			ref:   "domain/kernel.cue"
		}
		"lattice-domain-negative-fixture": {
			kind:  "local-kernel"
			title: "Lattice negative fixture proof split"
			ref:   "domain/kernel.cue"
		}
		"lattice-readme-projection-kernel": {
			kind:  "local-doc"
			title: "Lattice README projection and validation framing"
			ref:   "README.md"
		}
		"cue-bottom-semantics": {
			kind:  "official-doc"
			title: "CUE bottom semantics"
			ref:   "https://cuelang.org/docs/concept/the-logic-of-cue/"
		}
		"cue-definitions": {
			kind:  "official-doc"
			title: "CUE definitions"
			ref:   "https://cuelang.org/docs/tour/basics/definitions/"
		}
		"cue-unification": {
			kind:  "official-doc"
			title: "CUE unification"
			ref:   "https://cuelang.org/docs/concept/the-logic-of-cue/"
		}
		"cue-defaults": {
			kind:  "official-doc"
			title: "CUE defaults"
			ref:   "https://cuelang.org/docs/tour/types/defaults/"
		}
		"cue-disjunctions": {
			kind:  "official-doc"
			title: "CUE disjunctions"
			ref:   "https://cuelang.org/docs/tour/types/disjunctions/"
		}
		"cue-comprehensions": {
			kind:  "official-doc"
			title: "CUE comprehensions"
			ref:   "https://cuelang.org/docs/tour/expressions/comprehensions/"
		}
		"cue-closedness": {
			kind:  "official-doc"
			title: "CUE closed structs"
			ref:   "https://cuelang.org/docs/tour/types/closed/"
		}
		"cue-subsume": {
			kind:  "official-doc"
			title: "CUE subsumption"
			ref:   "https://cuelang.org/docs/reference/command/cue-help-vet/"
		}
		"cue-tool-commands": {
			kind:  "official-doc"
			title: "CUE command tasks"
			ref:   "https://cuelang.org/docs/concept/using-the-cue-command-line/"
		}
		"cue-by-example": {
			kind:  "example-corpus"
			title: "CUE by Example"
			ref:   "https://github.com/cue-labs/cue-by-example"
		}
		"cuetorials-useful-patterns": {
			kind:  "tutorial"
			title: "Cuetorials useful patterns"
			ref:   "https://cuetorials.com/patterns/"
		}
		"apercue-projection-patterns": {
			kind:  "projection-substrate"
			title: "Apercue projection patterns"
			ref:   "https://github.com/quicue/apercue"
		}
	}
})
