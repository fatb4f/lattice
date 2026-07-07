package codexdrift

mcpResources: {
	"codex://surfaces": {
		uri: "codex://surfaces"
		description: "Declared Codex KG control surfaces."
		selector: "latticeReference.surfaces"
		readOnly: true
	}
	"codex://drift/findings": {
		uri: "codex://drift/findings"
		description: "Current drift findings from the Codex KG watchdog."
		selector: "findings"
		readOnly: true
	}
	"codex://graph-state/phase-one": {
		uri: "codex://graph-state/phase-one"
		description: "Graph-state Phase 1 watchdog status."
		selector: "promotionStatus.phases.\"graph-state-phase-one\""
		readOnly: true
	}
	"codex://graph-state/phase-two": {
		uri: "codex://graph-state/phase-two"
		description: "Graph-state Phase 2 watchdog status."
		selector: "promotionStatus.phases.\"graph-state-phase-two\""
		readOnly: true
	}
	"codex://promotion/status": {
		uri: "codex://promotion/status"
		description: "Phase promotion status projection."
		selector: "promotionStatus"
		readOnly: true
	}
}
