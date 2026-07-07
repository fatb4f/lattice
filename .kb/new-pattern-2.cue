package kg

import "quicue.ca/kg/core@v0"

comprehension_index: core.#Pattern & {
	name:     "Comprehension-Derived Index"
	category: "cue"
	problem:  "Manually maintained summary views drift from source entries."
	solution: "Compute summary, status, and confidence views with CUE comprehensions."
	context:  "Use for KG aggregate views and drift-control inventories."
	example:  ".kb/index.cue derives summary, by_status, and by_confidence."
	used_in: {lattice: true}
	related: {"adr-as-cue": true}
}
