package codexdrift

#CodexHookContext: close({
	schema: "codex-drift-context.v1"
	authority: ".kg/codex"
	findingCount: int & >=0
	maxResponse: #Response
	findings: [...#KGFinding]
})
