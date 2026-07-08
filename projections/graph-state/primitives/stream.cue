package primitives

#Stream: close({
	#NodeFields
	kind:      "stream"
	sourceRef: #RefName
	upstream?: #RefName
	order?:    int & >=0
	heads: [...#ObjectID] | *[]
})
