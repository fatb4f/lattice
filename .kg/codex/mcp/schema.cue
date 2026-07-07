package codexdrift

#NonEmptyString: string & !=""

#MCPEntry: close({
	name?: #NonEmptyString
	uri?: #NonEmptyString
	description: #NonEmptyString
	selector?: #NonEmptyString
	readOnly?: bool
})
