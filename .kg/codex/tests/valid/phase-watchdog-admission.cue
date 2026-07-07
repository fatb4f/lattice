package codexdrift

blockedPhaseWatchdog: #PhaseWatchdogEvaluation & {
	phase: graphStatePhases["graph-state-phase-one"]
	watchdog: phaseWatchdogs["graph-state-phase-one"]
	findings: [{
		kind:     "policy-violated"
		surface:  "codex-drift-kg"
		severity: "violation"
		response: "block"
		reason:   "Protected graph-state promotion surface changed without review."
		phase:    "graph-state-phase-one"
	}]
	status:     "blocked"
	admissible: false
}

admissiblePhaseWatchdog: #PhaseWatchdogEvaluation & {
	phase: graphStatePhases["graph-state-phase-one"]
	watchdog: phaseWatchdogs["graph-state-phase-one"]
	findings: [{
		kind:     "interface-contract-changed"
		surface:  "codex-drift-kg"
		severity: "warning"
		response: "require-review"
		reason:   "Non-blocking observation remains reviewable."
		phase:    "graph-state-phase-one"
	}]
	status:     "admissible"
	admissible: true
}
