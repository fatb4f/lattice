package primitives

#Context: close({
	#TypedNode
	type:      "context"
	workspace: #NodeID
	target?:   #NodeID
	sources:   #SourceRefSet
})

#PhaseOnePrimitiveSurface: close({
	ids: close({
		graph:  #GraphID
		node:   #NodeID
		edge:   #EdgeID
		object: #ObjectID
		ref:    #RefName
		path:   #PathID
	})
	graph:      #Graph
	target:     #Target
	workspace:  #Workspace
	stream:     #Stream
	fragment:   #Fragment
	assignment: #Assignment
	dependency: #Dependency
	conflict:   #Conflict
	projection: #Projection
	context:    #Context
	producer:   #ProducerSurface
	sourceCheck: close({
		ledger: sourceLedgerComplete
		roles:  sourceRolesSeparated
	})
})
