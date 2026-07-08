package primitives

#NodeKind:
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

#NodeFields: {
	id:          #NodeID
	kind:        #NodeKind
	description: #NonEmptyString
	sources:     #SourceRefSet
}

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
	[#NodeID]: #Node
	[ID=#NodeID]: {
		id: ID
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
	edges:       #EdgeMap
})
