package kg

import "quicue.ca/kg/core@v0"

d001: core.#Decision & {
	id:     "ADR-001"
	title:  "Adopt upstream-shaped CUE KG entries through the kg CLI"
	status: "accepted"
	date:   "2026-07-06"

	context:   "The repository already has a Codex drift KG, but needs the upstream full-example project knowledge shape."
	decision:  "Use the local kg CLI to create and validate .kb entries for decisions, patterns, insights, rejected approaches, and a derived _index."
	rationale: "The CLI owns the upstream module wiring and keeps the local project KG aligned with quicue.ca/kg conventions."
	consequences: [
		"Project knowledge is exported with kg index --full.",
		"The Codex drift KG remains under .kg/codex with a separate authority boundary.",
	]
	related: {"INSIGHT-001": true, "struct-as-set": true}
}
