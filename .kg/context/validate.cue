package context

import "list"

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

#ValidatedContextRoutePacket: #ContextRoutePacket & {
	budget: {
		maxInlineEntities: <=defaultTokenBudget.inlineEntityMax
		maxInlineBytes:    <=defaultTokenBudget.routePacketMaxBytes
		preferMCP:         true
	}
	gates: {
		kbValid:              true
		noDanglingRefs:       true
		noGeneratedInput:     true
		noPluginCacheInput:   true
		noRawTranscriptInput: true
		transientProjection:  true
	}
	generated: true
	authority: false
	transient: true
}

#RoutePolicyBoundPacket: #ValidatedContextRoutePacket & {
	route: #RouteID

	_policy: routePolicy[route]

	budget: {
		maxInlineEntities: <=_policy.maxInlineEntities
	}

	selection: {
		entities: [for entity in selection.entities {
			if _policy.allowedEntities[entity] == true {
				entity
			}
			if _policy.allowedEntities[entity] != true {
				_|_("route packet selects an entity outside routePolicy.allowedEntities")
			}
		}]

		resources: [for resource in selection.resources {
			if list.Contains(_policy.mcpResources, resource) {
				resource
			}
			if !list.Contains(_policy.mcpResources, resource) {
				_|_("route packet selects a resource outside routePolicy.mcpResources")
			}
		}]

		files: [for file in selection.files {
			if list.Contains(_policy.files, file) {
				file
			}
			if !list.Contains(_policy.files, file) {
				_|_("route packet selects a file outside routePolicy.files")
			}
		}]
	}
}
