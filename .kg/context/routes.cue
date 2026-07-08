package context

#RouteID:
	"evidence-gather" |
	"promotion-review" |
	"graph-state-review" |
	"kg-maintenance" |
	"resolver-maintenance" |
	"repo-inspection" |
	"default-minimal"

#EntityID: string & !=""
#MCPResourceURI: string & =~"^(kg|codex)://"
#RepoPath: string & !="" & !~"(^/|\\.\\.)"

#RoutePolicy: close({
	maxInlineEntities: int & >=0 & <=3
	allowedEntities: {
		[#EntityID]: bool
	}
	defaultEntities: [...#EntityID]
	mcpResources: [...#MCPResourceURI]
	files?: [...#RepoPath]
})

routePolicy: {
	"evidence-gather": #RoutePolicy & {
		maxInlineEntities: 2
		allowedEntities: {
			"ADR-002": true
			"ADR-003": true
			"INSIGHT-002": true
			"REJ-002": true
			"REJ-003": true
			"project-context": true
		}
		defaultEntities: [
			"project-context",
			"INSIGHT-002",
		]
		mcpResources: [
			"kg://entity/project-context",
			"kg://query/selfContext",
			"codex://drift/findings",
		]
	}

	"promotion-review": #RoutePolicy & {
		maxInlineEntities: 1
		allowedEntities: {
			"project-context": true
		}
		defaultEntities: [
			"project-context",
		]
		mcpResources: [
			"codex://promotion/status",
			"codex://graph-state/phase-one",
			"codex://graph-state/phase-two",
			"codex://drift/findings",
		]
	}

	"graph-state-review": #RoutePolicy & {
		maxInlineEntities: 1
		allowedEntities: {
			"project-context": true
		}
		defaultEntities: [
			"project-context",
		]
		mcpResources: [
			"codex://graph-state/phase-one",
			"codex://graph-state/phase-two",
			"codex://promotion/status",
		]
		files: [
			"projections/graph-state",
			"meta/kernel.cue",
		]
	}

	"kg-maintenance": #RoutePolicy & {
		maxInlineEntities: 1
		allowedEntities: {
			"project-context": true
		}
		defaultEntities: [
			"project-context",
		]
		mcpResources: [
			"kg://query/selfContext",
			"kg://index/summary",
		]
		files: [
			".kb",
			".kg/context",
		]
	}

	"resolver-maintenance": #RoutePolicy & {
		maxInlineEntities: 1
		allowedEntities: {
			"project-context": true
		}
		defaultEntities: [
			"project-context",
		]
		mcpResources: [
			"kg://query/selfContext",
			"codex://surfaces",
		]
	}

	"repo-inspection": #RoutePolicy & {
		maxInlineEntities: 1
		allowedEntities: {
			"project-context": true
		}
		defaultEntities: [
			"project-context",
		]
		mcpResources: [
			"kg://query/selfContext",
		]
	}

	"default-minimal": #RoutePolicy & {
		maxInlineEntities: 0
		allowedEntities: {}
		defaultEntities: []
		mcpResources: [
			"kg://query/selfContext",
		]
	}
}
