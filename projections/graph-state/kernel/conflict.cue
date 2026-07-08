package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#ConflictSurface: #TypedGraphState & {
	...

	graph: primitives.#Graph

	conflictProof: {
		for nodeID, node in graph.nodes if node.type == "conflict" {
			for participantID, _ in node.participants {
				"\(nodeID)-participant-\(participantID)-exists": graph.nodes[participantID].id & participantID
			}
		}
	}
}
