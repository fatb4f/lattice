package kg

import "quicue.ca/kg/core@v0"

adr_as_cue: core.#Pattern & {
	name:     "ADR as CUE Struct"
	category: "knowledge"
	problem:  "Markdown-only decisions are not type-checked or queryable by repo validators."
	solution: "Encode decisions as CUE structs with required context, decision, rationale, and consequences."
	context:  "Use for repository architecture choices that should participate in KG indexes."
	used_in: {lattice: true}
	related: {"struct-as-set": true}
}
