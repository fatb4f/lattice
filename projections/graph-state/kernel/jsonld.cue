package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#JSONLDNode: close({
	"@id":   string
	"@type": string
	label:   string
})

#JSONLDEdge: close({
	"@id":      string
	"@type":    string
	source:     close({"@id": string})
	target:     close({"@id": string})
	predicate:  string
	label:      string
})

#JSONLDProjection: #TypedGraphState & {
	...

	graph: primitives.#Graph

	"@context": {
		"@vocab":   "https://kg.quicue.ca/graph-state#"
		id:         "@id"
		type:       "@type"
		label:      "https://www.w3.org/2000/01/rdf-schema#label"
		source:     close({"@type": "@id"})
		target:     close({"@type": "@id"})
		predicate:  "https://kg.quicue.ca/graph-state#predicate"
		graphState: "https://kg.quicue.ca/graph-state#"
	}

	"@graph": [
		for nodeID, node in graph.nodes {
			#JSONLDNode & {
				"@id":   nodeID
				"@type": "graphState:\(node.type)"
				label:   node.description
			}
		},
		for edgeID, edge in graph.edges {
			#JSONLDEdge & {
				"@id":      edgeID
				"@type":    "graphState:edge"
				source:     {"@id": edge.from}
				target:     {"@id": edge.to}
				predicate:  "graphState:\(edge.kind)"
				label:      edge.description
			}
		},
	]
}
