package sources

import "strings"

#NonEmptyString:  string & strings.MinRunes(1)
#KebabIdentifier: #NonEmptyString & =~"^[a-z0-9]+(-[a-z0-9]+)*$"

#SourceKind:
	"local-kernel" |
	"local-doc" |
	"official-doc" |
	"example-corpus" |
	"tutorial" |
	"projection-substrate"

#SourceID:
	"lattice-meta-kernel" |
	"lattice-meta-negative-fixture" |
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
	"cue-modules" |
	"cue-packages" |
	"cue-imports" |
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

cuePatternSources: close({
	schema: "fatb4f.lattice.cue-pattern-sources.v1"
	sources: #SourceRefMap & {
		"lattice-meta-kernel": {
			kind:  "local-kernel"
			title: "Lattice meta obligation kernel"
			ref:   "meta/kernel.cue"
		}
		"lattice-meta-negative-fixture": {
			kind:  "local-kernel"
			title: "Lattice negative fixture proof split"
			ref:   "meta/kernel.cue"
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
		"cue-modules": {
			kind:  "official-doc"
			title: "CUE modules"
			ref:   "https://cuelang.org/docs/reference/modules/"
		}
		"cue-packages": {
			kind:  "official-doc"
			title: "CUE packages"
			ref:   "https://cuelang.org/docs/concept/modules-packages-instances/"
		}
		"cue-imports": {
			kind:  "official-doc"
			title: "CUE imports and standard library"
			ref:   "https://pkg.go.dev/cuelang.org/go/pkg"
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
