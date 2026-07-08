// Lattice knowledge base manifest.
//
// Directory graph boundaries are semantic routing boundaries. Runtime context
// selection reads this CUE-native graph topology instead of generated resolver
// indexes.
package kg

import "quicue.ca/kg/ext@v0"

_projectContext: ext.#Context & {
	"@id":       "https://github.com/fatb4f/lattice"
	name:        "lattice"
	description: "CUE lattice patterns, validation profiles, graph-state projections, and Codex KG hook controls."
	module:      "github.com/fatb4f/lattice"
	repo:        "https://github.com/fatb4f/lattice"
	status:      "active"
	cue_version: "v0.17.0"
	kb_directory: ".kb"
}

kb: ext.#KnowledgeBase & {
	context: _projectContext
	graphs: {
		decisions: ext.#DecisionsGraph
		patterns:  ext.#PatternsGraph
		insights:  ext.#InsightsGraph
		rejected:  ext.#RejectedGraph
		tasks:     ext.#TasksGraph
		workspace: ext.#WorkspaceGraph
		sources: {
			"@type":      "kg:Graph"
			kg_type:      "ext.#SourceFile"
			semantic:     "prov:Entity"
			description:  "Source references and external documents used as evidence by the project knowledge graph."
			directory:    "sources"
			package_name: "sources"
			status:       "active"
		}
	}
}
