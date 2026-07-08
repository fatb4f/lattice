package primitives

#ProducerSurface: close({
	#NodeFields
	kind: "producer"
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
