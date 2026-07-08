package primitives

#Workspace: close({
	#TypedNode
	type:    "workspace"
	target?: #NodeID
	streams: #NodeRefSet | *{}
	paths: {
		[#PathID]: true
	} | *{}
})
