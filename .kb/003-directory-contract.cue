package kg

import "quicue.ca/kg/core@v0"

d003: core.#Decision & {
	id:     "ADR-003"
	title:  "Canonicalize project KG directory boundaries"
	status: "accepted"
	date:   "2026-07-07"

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
