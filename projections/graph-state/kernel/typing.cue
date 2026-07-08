package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#TypedGraphState: #ClosedGraphState & {
	...

	graph: primitives.#Graph

	typedNodeProof: {
		if graph.typedNodes != _|_ {
			for nodeType, nodes in graph.typedNodes {
				for nodeID, typedNode in nodes {
					"\(nodeType)-\(nodeID)-exists": graph.nodes[nodeID].id & nodeID
					"\(nodeType)-\(nodeID)-type":   graph.nodes[nodeID].type & typedNode.type & nodeType
				}
			}
		}
	}
}
