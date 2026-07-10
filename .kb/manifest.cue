// Lattice knowledge base manifest.
//
// Directory graph boundaries are semantic routing boundaries. Runtime context
// selection reads this CUE-native graph topology instead of generated resolver
// indexes.
package kg

import "quicue.ca/kg/ext@v0"

kb: ext.#KnowledgeBase & {
	context: project
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
