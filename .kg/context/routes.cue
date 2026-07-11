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
	maxCandidates: int & >=0 & <=graphRoutingPolicy.ceilings.maxCandidates | *graphRoutingPolicy.budgets.maxCandidates
	maxInlineEntities: int & >=0 & <=3
	maxInlineBytes: int & >=0 & <=defaultTokenBudget.routePacketMaxBytes | *defaultTokenBudget.routePacketMaxBytes
	maxResourceHandles: int & >=0 & <=8 | *8
	maxAutoReadBytes: int & >=0 & <=4096 | *1024
	allowExpensiveReads: bool | *false
	allowedEntities: {
		[#EntityID]: bool
	}
	defaultEntities: [...#EntityID]
	mcpResources: [...#MCPResourceURI]
	files: [...#RepoPath] | *[]
	matchTerms: [...#NonEmptyString] | *[]
})

#RoutePolicyProjection: close({
	schema:  "lattice.route-policy-projection.v1"
	routing: graphRoutingPolicy
	routes:  routePolicy
	budget:  defaultTokenBudget
})

routePolicy: {
	"evidence-gather": #RoutePolicy & {
		matchTerms: ["evidence", "session", "hook", "trace"]
		maxInlineEntities: 2
		maxAutoReadBytes: 4096
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
			"kg://context/summary",
			"codex://drift/findings",
		]
	}

	"promotion-review": #RoutePolicy & {
		matchTerms: ["promotion", "promoted", "status"]
		maxInlineEntities: 1
		maxAutoReadBytes: 4096
		allowedEntities: {
			"project-context": true
		}
		defaultEntities: [
			"project-context",
		]
		mcpResources: [
			"codex://promotion/status/summary",
			"codex://graph-state/phase-one/summary",
			"codex://graph-state/phase-two/summary",
			"codex://drift/findings",
		]
	}

	"graph-state-review": #RoutePolicy & {
		matchTerms: ["graph-state", "phase one", "phase two", "phase 1", "phase 2"]
		maxInlineEntities: 1
		maxAutoReadBytes: 4096
		allowedEntities: {
			"project-context": true
		}
		defaultEntities: [
			"project-context",
		]
		mcpResources: [
			"codex://graph-state/phase-one/summary",
			"codex://graph-state/phase-two/summary",
			"codex://promotion/status/summary",
		]
		files: [
			"projections/graph-state",
			"meta/kernel.cue",
		]
	}

	"kg-maintenance": #RoutePolicy & {
		matchTerms: [".kb", "knowledge graph", "kg maintenance", "kg vet", "kg index", "kg settle"]
		maxInlineEntities: 1
		maxAutoReadBytes: 2048
		allowedEntities: {
			"project-context": true
		}
		defaultEntities: [
			"project-context",
		]
		mcpResources: [
			"kg://context/invariants",
			"kg://index/summary",
		]
		files: [
			".kb",
			".kg/context",
		]
	}

	"resolver-maintenance": #RoutePolicy & {
		matchTerms: ["resolver", "route", "routing", "context selector", "context packet"]
		maxInlineEntities: 1
		maxAutoReadBytes: 2048
		allowedEntities: {
			"project-context": true
		}
		defaultEntities: [
			"project-context",
		]
		mcpResources: [
			"kg://context/summary",
			"codex://surfaces/index",
		]
	}

	"repo-inspection": #RoutePolicy & {
		matchTerms: ["repo", "inspect files", "file inspection", "diff"]
		maxInlineEntities: 1
		maxAutoReadBytes: 2048
		allowedEntities: {
			"project-context": true
		}
		defaultEntities: [
			"project-context",
		]
		mcpResources: [
			"kg://context/summary",
		]
	}

	"default-minimal": #RoutePolicy & {
		maxInlineEntities: 0
		maxAutoReadBytes: 512
		allowedEntities: {}
		defaultEntities: []
		mcpResources: [
			"kg://context/fingerprint",
		]
	}
}
