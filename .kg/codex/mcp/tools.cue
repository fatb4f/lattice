package codexdrift

mcpTools: {
	"codex.drift.scan": {
		name: "codex.drift.scan"
		description: "Scan repository and patch facts for drift findings."
		readOnly: true
	}
	"codex.phase.status": {
		name: "codex.phase.status"
		description: "Read graph-state phase watchdog status."
		readOnly: true
	}
	"codex.promotion.check": {
		name: "codex.promotion.check"
		description: "Read promotion checks derived from meta/kernel.cue bindings."
		readOnly: true
	}
	"codex.surface.explain": {
		name: "codex.surface.explain"
		description: "Explain a declared Codex KG control surface."
		readOnly: true
	}
	kg_context_match: {
		name: "kg_context_match"
		description: "Return the JSON-LD project KG context packet that UserPromptSubmit would inject for a prompt."
		readOnly: true
	}
}
