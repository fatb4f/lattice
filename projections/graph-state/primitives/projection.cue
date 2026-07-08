package primitives

#Projection: close({
	#NodeFields
	kind:        "projection"
	description: #NonEmptyString
	selects: close({
		nodes: #NodeRefSet | *{}
		edges: #EdgeRefSet | *{}
	})
	target?: #NodeID
})
