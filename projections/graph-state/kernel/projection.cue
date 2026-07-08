package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#ProjectionSelectionClosure: #TypedGraphState & {
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
			if node.target != _|_ {
				"\(nodeID)-target-is-target": graph.nodes[node.target].type & "target"
			}
		}
	}
}

#WorkspaceProjection: #ProjectionSelectionClosure & {
	...

	graph: primitives.#Graph

	workspaceProof: {
		for nodeID, node in graph.nodes if node.type == "workspace" {
			if node.target != _|_ {
				"\(nodeID)-target-is-target": graph.nodes[node.target].type & "target"
			}
			for streamID, _ in node.streams {
				"\(nodeID)-stream-\(streamID)-is-stream": graph.nodes[streamID].type & "stream"
			}
		}
	}
}
