package decisions

import "quicue.ca/kg/core@v0"

graph: {
	"ADR-001": core.#Decision & {
		id:        "ADR-001"
		title:     "Adopt upstream-shaped CUE KG entries through the kg CLI"
		status:    "accepted"
		date:      "2026-07-06"
		context:   "The repository already has a Codex drift KG, but needs the upstream full-example project knowledge shape."
		decision:  "Use the local kg CLI to create and validate .kb entries for decisions, patterns, insights, rejected approaches, and a derived _index."
		rationale: "The CLI owns the upstream module wiring and keeps the local project KG aligned with quicue.ca/kg conventions."
		consequences: [
			"Project knowledge is exported with kg index --full.",
			"The Codex drift KG remains under .kg/codex with a separate authority boundary.",
		]
		related: {"INSIGHT-001": true, "struct-as-set": true}
	}

	"ADR-002": core.#Decision & {
		id:        "ADR-002"
		title:     "Keep agent KG access read-only by default"
		status:    "accepted"
		date:      "2026-07-06"
		context:   "Agents need fast access to KG facts but should not treat derived indexes, MCP output, or generated observations as mutation authority."
		decision:  "Provide a repo-local skill that routes agents through kg vet, kg index, kg query, kg settle, and read-only MCP inspection before editing KG authority."
		rationale: "The CLI and existing MCP policy already model read-only KG access; the skill makes that workflow explicit for future agents."
		consequences: [
			"Agents should run kg vet and kg index before changing .kb entries.",
			"Mutation still happens through ordinary file edits reviewed by repository validation.",
		]
		related: {"INSIGHT-002": true, "adr-as-cue": true}
	}

	"ADR-003": core.#Decision & {
		id:        "ADR-003"
		title:     "Canonicalize project KG directory boundaries"
		status:    "accepted"
		date:      "2026-07-07"
		context:   "The repository has a reusable kg schema package, a repo-local project knowledge graph, and a separate Codex drift-control graph."
		decision:  "Use .kb as the only project knowledge instance directory; reserve .kg/codex for Codex drift controls and treat kg/ as reusable schema and examples."
		rationale: "A single instance directory avoids adapter and documentation drift while preserving the framework-versus-instance split."
		consequences: [
			"Project knowledge entries, indexes, and kg CLI validation remain under .kb.",
			"Codex drift-control surfaces remain under .kg/codex and are not a .kg alias for project knowledge.",
			"Executable adapters must name which graph authority they expose.",
		]
		related: {"ADR-001": true, "ADR-002": true, "REJ-002": true, "REJ-003": true}
	}
}
