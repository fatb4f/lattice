package kg

import "quicue.ca/kg/core@v0"

r003: core.#Rejected & {
	id:       "REJ-003"
	approach: "Treat .kg as a deprecated alias for the project knowledge graph."
	reason:   "This repository already uses .kg/codex for Codex drift-control authority, so a broad .kg alias would blur the project knowledge and control-plane boundaries."
	date:     "2026-07-07"
	alternative: "Use .kb for project knowledge and keep .kg/codex as the only .kg subtree with KG authority."
	related: {"ADR-003": true, "REJ-002": true}
}
