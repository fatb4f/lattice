package kg

import "quicue.ca/kg/core@v0"

r001: core.#Rejected & {
	id:       "REJ-001"
	approach: "Import quicue.ca/kg directly into the root lattice CUE module for the example."
	reason:   "That would couple root validation to a remote module dependency for a small project knowledge example."
	date:     "2026-07-06"
	alternative: "Use kg init so .kb is its own CUE module with the CLI-managed quicue.ca/kg schema link."
	related: {"ADR-001": true}
}
