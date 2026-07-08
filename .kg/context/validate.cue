package context

#GeneratedArtifactRole:
	"host-registration" |
	"materialization-witness" |
	"validation-report" |
	"debug-trace" |
	"static-export"

#GeneratedArtifact: close({
	path: string & !=""
	role: #GeneratedArtifactRole

	authority:    false
	generated:    true
	runtimeInput: false
})

#ForbiddenRuntimeGeneratedContext: close({
	role:
		"context-index" |
		"resolver-fragments" |
		"prompt-routes" |
		"route-inventory"

	runtimeInput: true
})

#ValidatedContextPacket: #ContextPacket & {
	gates: {
		vocabMapped:         true
		kbValid:             true
		noDanglingRefs:      true
		noGeneratedInput:    true
		noParentTraversal:   true
		transientProjection: true
	}
	generated: true
	authority: false
}
