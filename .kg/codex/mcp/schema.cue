package codexdrift

#NonEmptyString: string & !=""

#MCPEntry: close({
	name?: #NonEmptyString
	uri?: #NonEmptyString
	description: #NonEmptyString
	selector?: #NonEmptyString
	command?: [...#NonEmptyString]
	readOnly?: bool
	expensive?: bool
	defaultInject?: bool
	autoRead?: bool
	maxBytes?: int & >=0
	projection?: "index" | "summary" | "fingerprint" | "invariants" | "full" | "template"
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
