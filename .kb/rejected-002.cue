package kg

import "quicue.ca/kg/core@v0"

r002: core.#Rejected & {
	id:       "REJ-002"
	approach: "Place project knowledge entries inside .kg/codex."
	reason:   ".kg/codex owns Codex drift controls, watchdogs, and MCP declarations; mixing project KG entries there would blur authority boundaries."
	date:     "2026-07-06"
	alternative: "Use .kb for project knowledge and keep .kg/codex for drift controls."
	related: {"ADR-002": true}
}
