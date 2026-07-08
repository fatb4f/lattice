package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#PositiveFixture: close({
	id:          =~"^[a-z0-9]+(-[a-z0-9]+)*$"
	description: string & !=""
	graph:       primitives.#Graph
})

#NegativeFixture: close({
	id:          =~"^[a-z0-9]+(-[a-z0-9]+)*$"
	description: string & !=""
	invalid:     _
})

_phaseTwoPositiveGraph: primitives.#Graph & {
	id:          "phase-two-positive"
	description: "Concrete graph-state kernel fixture"
	nodes: {
		"target-a": {
			id:          "target-a"
			type:        "target"
			description: "Target node"
			sources:     {}
			ref:         "refs/heads/main"
		}
		"workspace-a": {
			id:          "workspace-a"
			type:        "workspace"
			description: "Workspace node"
			sources:     {}
			target:      "target-a"
			streams: {
				"stream-a": true
			}
			paths: {
				"src/main.go": true
			}
		}
		"stream-a": {
			id:          "stream-a"
			type:        "stream"
			description: "Stream node"
			sources:     {}
			sourceRef:   "refs/heads/feature"
		}
		"fragment-a": {
			id:          "fragment-a"
			type:        "fragment"
			description: "First fragment"
			sources:     {}
			hunkID:      "hunk-a"
			path:        "src/main.go"
		}
		"fragment-b": {
			id:          "fragment-b"
			type:        "fragment"
			description: "Second fragment"
			sources:     {}
			hunkID:      "hunk-b"
			path:        "src/main.go"
		}
		"assignment-a": {
			id:          "assignment-a"
			type:        "assignment"
			description: "Assignment node"
			sources:     {}
			fragment:    "fragment-a"
			stream:      "stream-a"
			branchRef:   "refs/heads/feature"
		}
		"dependency-a": {
			id:          "dependency-a"
			type:        "dependency"
			description: "Dependency node"
			sources:     {}
			predecessor: "fragment-a"
			successor:   "fragment-b"
			constraints: {}
		}
		"conflict-a": {
			id:          "conflict-a"
			type:        "conflict"
			description: "Conflict node"
			sources:     {}
			participants: {
				"fragment-a": true
				"fragment-b": true
			}
			reason: "overlap"
		}
		"projection-a": {
			id:          "projection-a"
			type:        "projection"
			description: "Projection node"
			sources:     {}
			selects: {
				nodes: {
					"fragment-a": true
				}
				edges: {
					"edge-dependency": true
				}
			}
			target: "target-a"
		}
		"context-a": {
			id:          "context-a"
			type:        "context"
			description: "Context node"
			sources:     {}
			workspace:   "workspace-a"
			target:      "target-a"
		}
		"producer-a": {
			id:          "producer-a"
			type:        "producer"
			description: "Producer node"
			sources:     {}
			name:        "fixture-producer"
			inputs: {
				nodes: {
					"fragment-a": true
				}
				edges: {
					"edge-assignment": true
				}
			}
			outputs: {
				nodes: {
					"projection-a": true
				}
				edges: {
					"edge-projection": true
				}
			}
		}
	}
	typedNodes: {
		target: {
			"target-a": nodes["target-a"]
		}
		workspace: {
			"workspace-a": nodes["workspace-a"]
		}
		stream: {
			"stream-a": nodes["stream-a"]
		}
		fragment: {
			"fragment-a": nodes["fragment-a"]
			"fragment-b": nodes["fragment-b"]
		}
		assignment: {
			"assignment-a": nodes["assignment-a"]
		}
		dependency: {
			"dependency-a": nodes["dependency-a"]
		}
		conflict: {
			"conflict-a": nodes["conflict-a"]
		}
		projection: {
			"projection-a": nodes["projection-a"]
		}
		context: {
			"context-a": nodes["context-a"]
		}
		producer: {
			"producer-a": nodes["producer-a"]
		}
	}
	edges: {
		"edge-assignment": {
			id:          "edge-assignment"
			kind:        "assigns"
			from:        "assignment-a"
			to:          "fragment-a"
			description: "Assignment edge"
			sources:     {}
		}
		"edge-dependency": {
			id:          "edge-dependency"
			kind:        "depends-on"
			from:        "fragment-b"
			to:          "fragment-a"
			description: "Dependency edge"
			sources:     {}
		}
		"edge-projection": {
			id:          "edge-projection"
			kind:        "projects"
			from:        "projection-a"
			to:          "target-a"
			description: "Projection edge"
			sources:     {}
		}
	}
}

phaseTwoPositiveFixture: #PositiveFixture & {
	id:          "phase-two-positive"
	description: "Positive fixture for the Phase 2 graph-state kernel"
	graph:       _phaseTwoPositiveGraph
}

phaseTwoPositiveKernel: #GraphStateKernel & {
	graph: _phaseTwoPositiveGraph
}

phaseTwoPositiveTypedNodeIndex: #TypedNodeIndexProjection & {
	graph: _phaseTwoPositiveGraph
}

phaseTwoPositiveProjectionSuite: #GraphStateProjectionSuite & {
	graph: _phaseTwoPositiveGraph
}
