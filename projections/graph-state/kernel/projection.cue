package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#WorkspaceProjection: #TypedGraphState & {
	...

	graph: primitives.#Graph

	projectionProof: {
		for nodeID, node in graph.nodes if node.type == "projection" {
			for selectedNodeID, _ in node.selects.nodes {
				"\(nodeID)-selects-node-\(selectedNodeID)-exists": graph.nodes[selectedNodeID].id & selectedNodeID
			}
			for selectedEdgeID, _ in node.selects.edges {
				"\(nodeID)-selects-edge-\(selectedEdgeID)-exists": graph.edges[selectedEdgeID].id & selectedEdgeID
			}
		}
	}
}
