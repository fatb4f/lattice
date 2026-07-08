package primitives

#Dependency: close({
	#NodeFields
	kind:        "dependency"
	predecessor: #NodeID
	successor:   #NodeID
	constraints: close({
		apply?:         bool
		mergeConflict?: bool
	})
})
