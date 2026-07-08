package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#AssignmentGraph: #TypedGraphState & {
	...

	graph: primitives.#Graph

	assignmentProof: {
		for nodeID, node in graph.nodes if node.type == "assignment" {
			"\(nodeID)-fragment-is-fragment": graph.nodes[node.fragment].type & "fragment"
		}
	}
}
