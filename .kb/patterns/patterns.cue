package patterns

import "quicue.ca/kg/core@v0"

graph: {
	"struct-as-set": core.#Pattern & {
		name:     "Struct-as-Set"
		category: "cue"
		problem:  "List-valued membership fields admit duplicates and make drift checks harder to unify."
		solution: "Represent membership and relationships as {[string]: true} sets."
		context:  "Use for related entries, used-in fields, and required-path membership."
		example:  "KG decisions, patterns, insights, and rejected approaches use related structs."
		used_in: {lattice: true}
		related: {"comprehension-index": true}
	}

	"adr-as-cue": core.#Pattern & {
		name:     "ADR as CUE Struct"
		category: "knowledge"
		problem:  "Markdown-only decisions are not type-checked or queryable by repo validators."
		solution: "Encode decisions as CUE structs with required context, decision, rationale, and consequences."
		context:  "Use for repository architecture choices that should participate in KG indexes."
		used_in: {lattice: true}
		related: {"struct-as-set": true}
	}

	"comprehension-index": core.#Pattern & {
		name:     "Comprehension-Derived Index"
		category: "cue"
		problem:  "Manually maintained summary views drift from source entries."
		solution: "Compute summary, status, and confidence views with CUE comprehensions."
		context:  "Use for KG aggregate views and drift-control inventories."
		example:  ".kb/index.cue derives summary, by_status, and by_confidence."
		used_in: {lattice: true}
		related: {"adr-as-cue": true}
	}
}
