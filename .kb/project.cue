package kg

import "quicue.ca/kg/ext@v0"

project: ext.#Context & {
	"@id":       "https://github.com/fatb4f/lattice"
	name:        "lattice"
	description: "CUE lattice patterns, validation profiles, and Codex KG drift controls."
	module:      "github.com/fatb4f/lattice"
	status:      "active"
	cue_version: "v0.17.0"
	kb_directory: ".kb"
}
