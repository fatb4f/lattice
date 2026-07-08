package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#DependencyGraph: #TypedGraphState & {
	...

	graph: primitives.#Graph

	dependencyProof: {
		for nodeID, node in graph.nodes if node.type == "dependency" {
			"\(nodeID)-predecessor-is-fragment": graph.nodes[node.predecessor].type & "fragment"
			"\(nodeID)-successor-is-fragment":   graph.nodes[node.successor].type & "fragment"
		}
	}
}
