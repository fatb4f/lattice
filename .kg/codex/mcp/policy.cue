package codexdrift

mcpPolicy: #MCPPolicy & {
	mode: "read-only"
	mutationToolsAllowed: false
	resources: mcpResources
	tools: mcpTools
	prompts: mcpPrompts
}
