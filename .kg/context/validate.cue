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
	evaluatedAt: #UTCTimestamp
	let E = evaluatedAt
	gates: #ValidatedContextGateResults & {
		[string]: {evaluatedAt: E}
	}
	generated: true
	authority: false
}

#ValidatedContextRoutePacket: #ContextRoutePacket & {
	evaluatedAt: #UTCTimestamp
	let E = evaluatedAt
	budget: {
		maxInlineEntities:   <=defaultTokenBudget.inlineEntityMax
		maxInlineBytes:      <=defaultTokenBudget.routePacketMaxBytes
		maxResourceHandles:  <=defaultTokenBudget.inlineResourceMax
		maxAutoReadBytes:    <=defaultTokenBudget.maxAutoReadBytes
		allowExpensiveReads: defaultTokenBudget.allowExpensiveReads
		preferMCP:           true
	}
	gates: #ValidatedContextRouteGateResults & {
		[string]: {evaluatedAt: E}
	}
	generated: true
	authority: false
	transient: true
}

#RoutePolicyBoundPacket: #ValidatedContextRoutePacket & {
	route: #RouteID

	_policy: routePolicy[route]

	budget: {
		maxInlineEntities:   <=_policy.maxInlineEntities
		maxResourceHandles:  <=_policy.maxResourceHandles
		maxAutoReadBytes:    <=_policy.maxAutoReadBytes
		allowExpensiveReads: _policy.allowExpensiveReads
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
	if len(selection.entities) > budget.maxInlineEntities {
		_|_("route packet entities exceed inline budget")
	}
	if len(selection.resources) > budget.maxResourceHandles {
		_|_("route packet resources exceed handle budget")
	}
}
