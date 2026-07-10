package tasks

import "quicue.ca/kg/core@v0"

// #TaskV1 is the stable repository task contract.
#TaskV1: close(core.#Task & {
	schema_version: "lattice.task.v1"
	priority:       core.#Priority
	"@type_tags":  {[string]: true}
	depends_on:     {[string]: true}
	refs:           {[core.#KBRef]: true}
})

Graph: {
	"kg-hook-runtime": #TaskV1 & {
		schema_version: "lattice.task.v1"
		id:          "kg-hook-runtime"
		title:       "Route Codex prompt context through KG hook runtime"
		status:      "active"
		project:     "lattice"
		priority:    "high"
		"@type_tags": {"kg-runtime": true}
		depends_on: {}
		description: "Replace static resolver artifacts with transient context packets selected from the CUE-native .kb graph."
		refs: {
			"ADR-003": true
		}
	}
}
