package insights

import "quicue.ca/kg/core@v0"

graph: {
	"INSIGHT-001": core.#Insight & {
		id:        "INSIGHT-001"
		statement: "CUE unification can be both the schema validator and the KG federation mechanism."
		evidence: [
			"The upstream full example indexes decisions, insights, rejected approaches, and patterns through one CUE value.",
			"The local kg CLI validates .kb entries and exports a derived _index without a database.",
		]
		method:      "cross_reference"
		confidence:  "high"
		discovered:  "2026-07-06"
		implication: "The repo-local KG can stay zero-infrastructure and still be queryable by agents."
		action_items: ["Keep kg index --full exportable through the validator."]
		related: {"ADR-001": true}
	}

	"INSIGHT-002": core.#Insight & {
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
}
