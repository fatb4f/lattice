package kg

import "quicue.ca/kg/core@v0"

i002: core.#Insight & {
	id:        "INSIGHT-002"
	statement: "The Codex drift KG and upstream-shaped project KG serve different roles."
	evidence: [
		".kg/codex declares watchdog and MCP control surfaces.",
		".kb declares project knowledge entries and derived indexes through the kg CLI.",
	]
	method:      "observation"
	confidence:  "medium"
	discovered:  "2026-07-06"
	implication: "Agents should query both surfaces, but should not merge their authority boundaries."
	related: {"ADR-002": true}
}
