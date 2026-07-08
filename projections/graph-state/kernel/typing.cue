package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#TypedGraphState: #ClosedGraphState & {
	...

	graph: primitives.#Graph

	nodeTypeProof: {
		for nodeID, node in graph.nodes {
			"\(nodeID)-has-type": node.type & primitives.#NodeType
		}
	}
}

#TypedNodeIndexProjection: #TypedGraphState & {
	...

	graph: primitives.#Graph & {
		typedNodes: primitives.#NodesByType
	}

	typedNodeIndexProof: {
		for nodeType, nodes in graph.typedNodes {
			for nodeID, typedNode in nodes {
				"\(nodeType)-\(nodeID)-exists": graph.nodes[nodeID].id & nodeID
				"\(nodeType)-\(nodeID)-type":   graph.nodes[nodeID].type & typedNode.type & nodeType
			}
		}

		for nodeID, node in graph.nodes {
			"\(nodeID)-indexed": graph.typedNodes[node.type][nodeID].id & nodeID
		}
	}
}
