package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#ClosedGraphState: {
	...

	graph: primitives.#Graph

	nodeIDs: [for id, _ in graph.nodes {id}]
	edgeIDs: [for id, _ in graph.edges {id}]

	edgeEndpointProof: {
		for edgeID, edge in graph.edges {
			"\(edgeID)-from-exists": graph.nodes[edge.from].id & edge.from
			"\(edgeID)-to-exists":   graph.nodes[edge.to].id & edge.to
		}
	}
}
