package patterns

import "strings"

#NonEmptyString: string & strings.MinRunes(1)
#NonEmptyStringList: [...#NonEmptyString] & [_, ...]

#CheckSet: {
	pass?: #NonEmptyStringList
	fail?: #NonEmptyStringList
}

#FeatureMaturity:
	"stable" |
	"experimental" |
	"watch"

#CueFeatureNote: {
	name:      #NonEmptyString
	maturity:  #FeatureMaturity
	guidance:  #NonEmptyString
	sourceRef: #NonEmptyString
}

#CueVersionCoverage: {
	version: #NonEmptyString
	features: {
		[string]: #CueFeatureNote
	}
}

#PatternEntry: {
	name:         #NonEmptyString
	summary:      #NonEmptyString
	demonstrates: #NonEmptyStringList

	canonical: _
	positive:  _
	negative:  _

	checks?: #CheckSet
	uses?:   #NonEmptyStringList
	notes?:  #NonEmptyStringList

	...
}

#PatternMap: {
	[string]: #PatternEntry
}

#Patterns: #PatternMap

cueVersionCoverage: {
	"v0.17.0": #CueVersionCoverage & {
		version: "v0.17.0"
		features: {
			module_replace: {
				name:      "Module replacement"
				maturity:  "stable"
				guidance:  "Use now for local module substitution and adapter development."
				sourceRef: "cue-release-v0-17-0"
			}
			comprehension_fix: {
				name:      "Comprehension evaluation fix"
				maturity:  "stable"
				guidance:  "Rely on this to reduce surprising incomplete-value and cycle failures in comprehension-heavy patterns."
				sourceRef: "cue-release-v0-17-0"
			}
			list_syntax: {
				name:      "List syntax cleanup"
				maturity:  "stable"
				guidance:  "Prefer the cleaner generated CUE list syntax when emitting or formatting examples."
				sourceRef: "cue-release-v0-17-0"
			}
			shortcircuit: {
				name:      "Short-circuit operators"
				maturity:  "experimental"
				guidance:  "Gate explicitly; do not use in baseline patterns without an experiment note."
				sourceRef: "cue-release-v0-17-0"
			}
			cue_lsp: {
				name:      "cue lsp improvements"
				maturity:  "stable"
				guidance:  "Use as the baseline for organize-imports, navigation, and editor diagnostics evidence."
				sourceRef: "cue-release-v0-17-0"
			}
			jsonschema_encoder: {
				name:      "JSON Schema encoder changes"
				maturity:  "watch"
				guidance:  "Watch generated-name changes when comparing JSON Schema output or generated fixtures."
				sourceRef: "cue-release-v0-17-0"
			}
			go_api_fs_loading: {
				name:      "Go API fs loading"
				maturity:  "stable"
				guidance:  "Use for embedded adapters and test harnesses that load CUE from virtual file systems."
				sourceRef: "cue-release-v0-17-0"
			}
		}
	}
}
