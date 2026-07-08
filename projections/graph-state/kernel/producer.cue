package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#ProducerObservation: #TypedGraphState & {
	...

	graph: primitives.#Graph

	producerProof: {
		for nodeID, node in graph.nodes if node.type == "producer" {
			for inputNodeID, _ in node.inputs.nodes {
				"\(nodeID)-input-node-\(inputNodeID)-exists": graph.nodes[inputNodeID].id & inputNodeID
			}
			for inputEdgeID, _ in node.inputs.edges {
				"\(nodeID)-input-edge-\(inputEdgeID)-exists": graph.edges[inputEdgeID].id & inputEdgeID
			}
			for outputNodeID, _ in node.outputs.nodes {
				"\(nodeID)-output-node-\(outputNodeID)-exists": graph.nodes[outputNodeID].id & outputNodeID
			}
			for outputEdgeID, _ in node.outputs.edges {
				"\(nodeID)-output-edge-\(outputEdgeID)-exists": graph.edges[outputEdgeID].id & outputEdgeID
			}
		}
	}
}
