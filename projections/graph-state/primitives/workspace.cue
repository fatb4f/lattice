package primitives

#Workspace: close({
	#NodeFields
	kind:    "workspace"
	target?: #NodeID
	streams: #NodeRefSet | *{}
	paths: {
		[#PathID]: true
	} | *{}
})
