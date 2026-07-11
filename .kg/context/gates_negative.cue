package context

_negativeGateFixtures: {
	fail: #GateResult & {
		gateId: "negative-fail"
		checker: "fixture"
		status: "fail"
		policy: "fail-closed"
		startedAt: "2026-01-01T00:00:00Z"
		completedAt: "2026-01-01T00:00:01Z"
		evaluatedAt: "2026-01-01T00:00:01Z"
		inputs: ["fixture:failure"]
		evidence: []
		diagnostics: [{code: "check-failed", message: "The checker rejected its input."}]
	}
	skipped: #GateResult & {
		gateId: "negative-skipped"
		checker: "fixture"
		status: "skipped"
		policy: "fail-open"
		startedAt: "2026-01-01T00:00:00Z"
		completedAt: "2026-01-01T00:00:00Z"
		evaluatedAt: "2026-01-01T00:00:00Z"
		inputs: ["fixture:disabled"]
		evidence: []
		diagnostics: [{code: "check-skipped", message: "Policy disabled the checker."}]
	}
	unsupported: #GateResult & {
		gateId: "negative-unsupported"
		checker: "fixture"
		status: "unsupported"
		policy: "fail-open"
		startedAt: "2026-01-01T00:00:00Z"
		completedAt: "2026-01-01T00:00:00Z"
		evaluatedAt: "2026-01-01T00:00:00Z"
		inputs: ["fixture:platform"]
		evidence: []
		diagnostics: [{code: "checker-unsupported", message: "The checker is unavailable on this platform."}]
	}
	indeterminate: #GateResult & {
		gateId: "negative-indeterminate"
		checker: "fixture"
		status: "indeterminate"
		policy: "fail-closed"
		startedAt: "2026-01-01T00:00:00Z"
		completedAt: "2026-01-01T00:00:00Z"
		evaluatedAt: "2026-01-01T00:00:00Z"
		inputs: ["fixture:missing-evidence"]
		evidence: []
		diagnostics: [{code: "evidence-missing", message: "No evidence was produced."}]
	}
}
