package kg

import "quicue.ca/kg/core@v0"

d002: core.#Decision & {
	id:     "ADR-002"
	title:  "Keep agent KG access read-only by default"
	status: "accepted"
	date:   "2026-07-06"

	context:   "Agents need fast access to KG facts but should not treat derived indexes, MCP output, or generated observations as mutation authority."
	decision:  "Provide a repo-local skill that routes agents through kg vet, kg index, kg query, kg settle, and read-only MCP inspection before editing KG authority."
	rationale: "The CLI and existing MCP policy already model read-only KG access; the skill makes that workflow explicit for future agents."
	consequences: [
		"Agents should run kg vet and kg index before changing .kb entries.",
		"Mutation still happens through ordinary file edits reviewed by repository validation.",
	]
	related: {"INSIGHT-002": true, "adr-as-cue": true}
}
