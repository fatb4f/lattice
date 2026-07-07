package codexdrift

#NonEmptyString: string & !=""

#MCPEntry: close({
	name?: #NonEmptyString
	uri?: #NonEmptyString
	description: #NonEmptyString
	selector?: #NonEmptyString
	readOnly?: bool
})

#ReadOnlyMCPTool: #MCPEntry & {
	name:     #NonEmptyString
	readOnly: true
}

#MCPPolicy: close({
	mode: "read-only"
	mutationToolsAllowed: false
	resources: {
		[#NonEmptyString]: #MCPEntry
	}
	tools: {
		[#NonEmptyString]: #ReadOnlyMCPTool
	}
	prompts: {
		[#NonEmptyString]: #MCPEntry
	}
})
