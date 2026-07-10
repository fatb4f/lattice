package rejected

import "quicue.ca/kg/core@v0"

Graph: {
	"REJ-001": core.#Rejected & {
		id:          "REJ-001"
		approach:    "Import quicue.ca/kg directly into the root lattice CUE module for the example."
		reason:      "That would couple root validation to a remote module dependency for a small project knowledge example."
		date:        "2026-07-06"
		alternative: "Use kg init so .kb is its own CUE module with the CLI-managed quicue.ca/kg schema link."
		related: {"ADR-001": true}
	}

	"REJ-002": core.#Rejected & {
		id:          "REJ-002"
		approach:    "Place project knowledge entries inside .kg/codex."
		reason:      ".kg/codex owns Codex drift controls, watchdogs, and MCP declarations; mixing project KG entries there would blur authority boundaries."
		date:        "2026-07-06"
		alternative: "Use .kb for project knowledge and keep .kg/codex for drift controls."
		related: {"ADR-002": true}
	}

	"REJ-003": core.#Rejected & {
		id:          "REJ-003"
		approach:    "Treat .kg as a deprecated alias for the project knowledge graph."
		reason:      "This repository already uses .kg/codex for Codex drift-control authority, so a broad .kg alias would blur the project knowledge and control-plane boundaries."
		date:        "2026-07-07"
		alternative: "Use .kb for project knowledge and keep .kg/codex as the only .kg subtree with KG authority."
		related: {"ADR-003": true, "REJ-002": true}
	}
}
