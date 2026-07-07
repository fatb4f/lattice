package codexdrift

phaseWatchdogs: {
	"graph-state-phase-one": #Watchdog & {
		id: "graph-state-phase-one-watchdog"
		phase: "graph-state-phase-one"
		description: "Watch graph-state primitive ontology promotion surfaces."
		watches: graphStatePhases["graph-state-phase-one"].watchedPaths
		blockingKinds: [
			"missing-required-surface",
			"unexpected-surface",
			"duplicate-authority",
			"policy-violated",
		]
	}

	"graph-state-phase-two": #Watchdog & {
		id: "graph-state-phase-two-watchdog"
		phase: "graph-state-phase-two"
		description: "Watch graph-state kernel promotion surfaces."
		watches: graphStatePhases["graph-state-phase-two"].watchedPaths
		blockingKinds: [
			"missing-required-surface",
			"unexpected-surface",
			"generated-promoted-to-authority",
			"policy-violated",
		]
	}
}

promotionStatus: {
	schema: "codex-phase-promotion-status.v1"
	phases: {
		"graph-state-phase-one": {
			phase: graphStatePhases["graph-state-phase-one"]
			promotion: metaPromotionBindings["graph-state-phase-one"]
			watchdog: phaseWatchdogs["graph-state-phase-one"]
			evaluation: phaseWatchdogEvaluations["graph-state-phase-one"]
		}
		"graph-state-phase-two": {
			phase: graphStatePhases["graph-state-phase-two"]
			promotion: metaPromotionBindings["graph-state-phase-two"]
			watchdog: phaseWatchdogs["graph-state-phase-two"]
			evaluation: phaseWatchdogEvaluations["graph-state-phase-two"]
		}
	}
}

phaseWatchdogEvaluations: {
	"graph-state-phase-one": #PhaseWatchdogEvaluation & {
		phase: graphStatePhases["graph-state-phase-one"]
		watchdog: phaseWatchdogs["graph-state-phase-one"]
		findings: []
	}

	"graph-state-phase-two": #PhaseWatchdogEvaluation & {
		phase: graphStatePhases["graph-state-phase-two"]
		watchdog: phaseWatchdogs["graph-state-phase-two"]
		findings: []
	}
}

blockingFindings: [...#KGFinding]

admissiblePhaseState: promotionStatus
