package context

#SelectionPolicy: close({
	sourceAuthority: ".kb"
	graphBoundary:   "directory"
	selector:        "route-packet"
	graphSource:     "kg index"
	graphProjection: "mcp-resource-uris"
	vocabSource:     ".kb/cue.mod/pkg/quicue.ca/kg/vocab/context.cue"
	vocabFallback:   ".kg/vocab/context.cue"
	authorityInputs: [
		".codex/skills/kg-agent/SKILL.md",
		".kb",
		".kg/hooks",
		".kg/codex",
		"meta/kernel.cue",
		"projections/graph-state",
	]
	nonAuthorityInputs: [
		"~/.local/share/codex/plugins/cache/dotfiles",
		"generated resolver JSON from plugin cache",
		"transient context packets",
		"MCP/tool outputs",
		"raw transcripts",
	]
	forbiddenRuntimeInputs: [
		"resolver-fragments.json",
		"prompt-routes.json",
		"context-index.json",
		"route-inventory.json",
	]
	tokenBudget: #TokenBudget
	routes: {
		[#RouteID]: #RoutePolicy
	}
})

selectionPolicy: #SelectionPolicy & {
	tokenBudget: defaultTokenBudget
	routes:      routePolicy
}
