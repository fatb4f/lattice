package primitives

#ProducerSurface: close({
	#TypedNode
	type: "producer"
	name: #NonEmptyString
	inputs: close({
		nodes: #NodeRefSet | *{}
		edges: #EdgeRefSet | *{}
	})
	outputs: close({
		nodes: #NodeRefSet | *{}
		edges: #EdgeRefSet | *{}
	})
	authority: bool | *false
})
