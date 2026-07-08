package primitives

#NodeType:
	"target" |
	"workspace" |
	"stream" |
	"fragment" |
	"assignment" |
	"dependency" |
	"conflict" |
	"projection" |
	"context" |
	"producer"

#EdgeKind:
	"contains" |
	"targets" |
	"assigns" |
	"depends-on" |
	"conflicts-with" |
	"projects" |
	"produces" |
	"observes"

#TypedNode: close({
	id:          #NodeID
	type:        #NodeType
	description: #NonEmptyString
	sources:     #SourceRefSet
})

#Node:
	#Target |
	#Workspace |
	#Stream |
	#Fragment |
	#Assignment |
	#Dependency |
	#Conflict |
	#Projection |
	#Context |
	#ProducerSurface

#Edge: close({
	id:          #EdgeID
	kind:        #EdgeKind
	from:        #NodeID
	to:          #NodeID
	description: #NonEmptyString
	sources:     #SourceRefSet
})

#NodeMap: {
	[ID=#NodeID]: #Node & {
		id: ID
	}
}

#NodesByType: {
	target: {
		[#NodeID]: #Target
	}
	workspace: {
		[#NodeID]: #Workspace
	}
	stream: {
		[#NodeID]: #Stream
	}
	fragment: {
		[#NodeID]: #Fragment
	}
	assignment: {
		[#NodeID]: #Assignment
	}
	dependency: {
		[#NodeID]: #Dependency
	}
	conflict: {
		[#NodeID]: #Conflict
	}
	projection: {
		[#NodeID]: #Projection
	}
	context: {
		[#NodeID]: #Context
	}
	producer: {
		[#NodeID]: #ProducerSurface
	}
}

#EdgeMap: {
	[#EdgeID]: #Edge
	[ID=#EdgeID]: {
		id: ID
	}
}

#Graph: close({
	id:          #GraphID
	description: #NonEmptyString
	nodes:       #NodeMap
	typedNodes?: #NodesByType
	edges:       #EdgeMap
})
