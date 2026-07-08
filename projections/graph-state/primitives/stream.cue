package primitives

#Stream: close({
	#TypedNode
	type:      "stream"
	sourceRef: #RefName
	upstream?: #RefName
	order?:    int & >=0
	heads: [...#ObjectID] | *[]
})
