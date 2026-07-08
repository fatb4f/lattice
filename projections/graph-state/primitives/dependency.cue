package primitives

#Dependency: close({
	#TypedNode
	type:        "dependency"
	predecessor: #NodeID
	successor:   #NodeID
	constraints: close({
		apply?:         bool
		mergeConflict?: bool
	})
})
