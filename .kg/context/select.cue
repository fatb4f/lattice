package context

#SelectionPolicy: close({
	sourceAuthority: ".kb"
	graphBoundary:   "directory"
	selector:        "kg-native-context-json-ld"
	graphSource:     "kg index --full"
	graphProjection: "jsonld"
	vocabSource:     ".kb/cue.mod/pkg/quicue.ca/kg/vocab/context.cue"
	vocabFallback:   ".kg/vocab/context.cue"
	forbiddenRuntimeInputs: [
		"resolver-fragments.json",
		"prompt-routes.json",
		"context-index.json",
		"route-inventory.json",
	]
})

selectionPolicy: #SelectionPolicy
