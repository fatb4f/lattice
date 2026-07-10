package kg

import "quicue.ca/kg/ext@v0"

project: ext.#Context & {
	"@id":       "https://github.com/fatb4f/lattice"
	name:        "lattice"
	description: "CUE lattice patterns, validation profiles, graph-state projections, and Codex KG hook controls."
	module:      "github.com/fatb4f/lattice"
	repo:        "https://github.com/fatb4f/lattice"
	status:      "active"
	cue_version: "v0.17.0"
	kb_directory: ".kb"
}
