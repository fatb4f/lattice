package primitives

#LineNumber: int & >=0

#Fragment: close({
	#NodeFields
	kind:    "fragment"
	hunkID:  #NonEmptyString
	path:    #PathID
	header?: #NonEmptyString
	addedLines: [...#LineNumber] | *[]
	removedLines: [...#LineNumber] | *[]
	diff?: #NonEmptyString
})
