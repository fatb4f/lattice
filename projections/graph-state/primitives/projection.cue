package primitives

#Projection: close({
	#TypedNode
	type:        "projection"
	description: #NonEmptyString
	selects: close({
		nodes: #NodeRefSet | *{}
		edges: #EdgeRefSet | *{}
	})
	target?: #NodeID
})
