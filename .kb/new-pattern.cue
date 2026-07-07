package kg

import "quicue.ca/kg/core@v0"

struct_as_set: core.#Pattern & {
	name:     "Struct-as-Set"
	category: "cue"
	problem:  "List-valued membership fields admit duplicates and make drift checks harder to unify."
	solution: "Represent membership and relationships as {[string]: true} sets."
	context:  "Use for related entries, used-in fields, and required-path membership."
	example:  "KG decisions, patterns, insights, and rejected approaches use related structs."
	used_in: {lattice: true}
	related: {"comprehension-index": true}
}
