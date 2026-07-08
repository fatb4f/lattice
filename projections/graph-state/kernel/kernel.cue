package kernel

import primitives "github.com/fatb4f/lattice/projections/graph-state/primitives"

#GraphStateKernel: close({
	graph: primitives.#Graph
	let G = graph

	invariants: close({
		closed: #ClosedGraphState & {graph: G}
		typed:  #TypedGraphState & {graph: G}
	})

	relations: close({
		assignment: #AssignmentGraph & {graph: G}
		dependency: #DependencyGraph & {graph: G}
		conflict:   #ConflictSurface & {graph: G}
		workspace:  #WorkspaceProjection & {graph: G}
		context:    #ContextProjection & {graph: G}
	})

	observations: close({
		producer: #ProducerObservation & {graph: G}
	})
})

#GraphStateProjectionSuite: close({
	graph: primitives.#Graph
	let G = graph

	jsonld: #JSONLDProjection & {graph: G}
})
