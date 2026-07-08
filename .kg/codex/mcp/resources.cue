package codexdrift

mcpResources: {
	"codex://surfaces": {
		uri: "codex://surfaces"
		description: "Full declared Codex KG control surfaces; use only for explicit surface inspection."
		selector: "latticeReference.surfaces"
		readOnly: true
		expensive: true
		defaultInject: false
		autoRead: false
		projection: "full"
	}
	"codex://surfaces/index": {
		uri: "codex://surfaces/index"
		description: "Compact index of declared Codex KG control surfaces."
		selector: "latticeReference.surfaces"
		readOnly: true
		defaultInject: true
		autoRead: true
		maxBytes: 2048
		projection: "index"
	}
	"codex://surface/{id}/summary": {
		uri: "codex://surface/{id}/summary"
		description: "Compact summary for one declared Codex KG control surface."
		selector: "latticeReference.surfaces[id]"
		readOnly: true
		defaultInject: true
		autoRead: true
		maxBytes: 1024
		projection: "template"
	}
	"codex://surface/{id}/paths": {
		uri: "codex://surface/{id}/paths"
		description: "Path arrays for one declared Codex KG control surface."
		selector: "latticeReference.surfaces[id]"
		readOnly: true
		defaultInject: false
		autoRead: false
		projection: "template"
	}
	"codex://surface/{id}/full": {
		uri: "codex://surface/{id}/full"
		description: "Full body for one declared Codex KG control surface."
		selector: "latticeReference.surfaces[id]"
		readOnly: true
		expensive: true
		defaultInject: false
		autoRead: false
		projection: "template"
	}
	"codex://drift/findings": {
		uri: "codex://drift/findings"
		description: "Current drift and promotion-gate findings from the Codex KG watchdog."
		selector: "findings"
		readOnly: true
		defaultInject: true
		autoRead: true
		maxBytes: 4096
	}
	"codex://graph-state/phase-one": {
		uri: "codex://graph-state/phase-one"
		description: "Full Graph-state Phase 1 watchdog status."
		selector: "promotionStatus.phases.\"graph-state-phase-one\""
		readOnly: true
		expensive: true
		defaultInject: false
		autoRead: false
	}
	"codex://graph-state/phase-one/summary": {
		uri: "codex://graph-state/phase-one/summary"
		description: "Compact Graph-state Phase 1 watchdog status summary."
		selector: "promotionStatus.phases.\"graph-state-phase-one\""
		readOnly: true
		defaultInject: true
		autoRead: true
		maxBytes: 1024
	}
	"codex://graph-state/phase-two": {
		uri: "codex://graph-state/phase-two"
		description: "Full Graph-state Phase 2 watchdog status."
		selector: "promotionStatus.phases.\"graph-state-phase-two\""
		readOnly: true
		expensive: true
		defaultInject: false
		autoRead: false
	}
	"codex://graph-state/phase-two/summary": {
		uri: "codex://graph-state/phase-two/summary"
		description: "Compact Graph-state Phase 2 watchdog status summary."
		selector: "promotionStatus.phases.\"graph-state-phase-two\""
		readOnly: true
		defaultInject: true
		autoRead: true
		maxBytes: 1024
	}
	"codex://promotion/status": {
		uri: "codex://promotion/status"
		description: "Full phase promotion status projection."
		selector: "promotionStatus"
		readOnly: true
		expensive: true
		defaultInject: false
		autoRead: false
	}
	"codex://promotion/status/summary": {
		uri: "codex://promotion/status/summary"
		description: "Compact phase promotion status projection."
		selector: "promotionStatus"
		readOnly: true
		defaultInject: true
		autoRead: true
		maxBytes: 2048
	}
	"kg://query/selfContext": {
		uri: "kg://query/selfContext"
		description: "Full project self-context from kg query selfContext; use only for explicit context inspection."
		command: ["kg", "query", "selfContext"]
		readOnly: true
		expensive: true
		defaultInject: false
		autoRead: false
		projection: "full"
	}
	"kg://context/fingerprint": {
		uri: "kg://context/fingerprint"
		description: "Tiny project-context fingerprint for route-safe default classification."
		command: ["kg", "query", "selfContext"]
		readOnly: true
		defaultInject: true
		autoRead: true
		maxBytes: 512
		projection: "fingerprint"
	}
	"kg://context/summary": {
		uri: "kg://context/summary"
		description: "Compact project-context summary for repo inspection."
		command: ["kg", "query", "selfContext"]
		readOnly: true
		defaultInject: true
		autoRead: true
		maxBytes: 2048
		projection: "summary"
	}
	"kg://context/invariants": {
		uri: "kg://context/invariants"
		description: "Project-context invariant statements for KG maintenance."
		command: ["kg", "query", "selfContext"]
		readOnly: true
		defaultInject: true
		autoRead: true
		maxBytes: 2048
		projection: "invariants"
	}
	"kg://context/full": {
		uri: "kg://context/full"
		description: "Full project self-context; explicit expensive context inspection only."
		command: ["kg", "query", "selfContext"]
		readOnly: true
		expensive: true
		defaultInject: false
		autoRead: false
		projection: "full"
	}
	"kg://index/summary": {
		uri: "kg://index/summary"
		description: "Compact KG index summary."
		command: ["kg", "index"]
		readOnly: true
		defaultInject: true
		autoRead: true
		maxBytes: 1024
	}
	"kg://index/full": {
		uri: "kg://index/full"
		description: "Full KG index; use only on explicit KG inspection."
		command: ["kg", "index", "--full"]
		readOnly: true
		expensive: true
		defaultInject: false
		autoRead: false
	}
	"kg://entity/{id}": {
		uri: "kg://entity/{id}"
		description: "Fetch one KG entity by stable ID."
		command: ["kg", "query", "entityByID"]
		readOnly: true
		defaultInject: false
		autoRead: false
		projection: "template"
	}
	"kg://related/{id}": {
		uri: "kg://related/{id}"
		description: "Fetch bounded neighbors for one KG entity."
		command: ["kg", "query", "related"]
		readOnly: true
		defaultInject: false
		autoRead: false
		projection: "template"
	}
}
