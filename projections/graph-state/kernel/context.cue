package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#ContextProjection: #TypedGraphState & {
	...

	graph: primitives.#Graph

	contextProof: {
		for nodeID, node in graph.nodes if node.type == "context" {
			"\(nodeID)-workspace-is-workspace": graph.nodes[node.workspace].type & "workspace"
		}
	}
}
