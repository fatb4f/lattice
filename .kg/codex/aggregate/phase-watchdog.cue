package codexdrift

phaseWatchdogs: {
	"graph-state-phase-one": #Watchdog & {
		id:          "graph-state-phase-one-watchdog"
		phase:       "graph-state-phase-one"
		description: "Watch graph-state primitive ontology promotion surfaces."
		watches:     graphStatePhases["graph-state-phase-one"].watchedPaths
		blockingKinds: [
			"missing-required-surface",
			"unexpected-surface",
			"duplicate-authority",
			"policy-violated",
		]
	}

	"graph-state-phase-two": #Watchdog & {
		id:          "graph-state-phase-two-watchdog"
		phase:       "graph-state-phase-two"
		description: "Watch graph-state kernel promotion surfaces."
		watches:     graphStatePhases["graph-state-phase-two"].watchedPaths
		blockingKinds: [
			"missing-required-surface",
			"unexpected-surface",
			"generated-promoted-to-authority",
			"policy-violated",
		]
	}
}

phaseWatchdogStatus: #PhaseWatchdogStatus & {}
phaseFindings:            phaseWatchdogStatus.phaseFindings
phaseWatchdogEvaluations: phaseWatchdogStatus.phaseWatchdogEvaluations
promotionStatus:          phaseWatchdogStatus.promotionStatus

blockingFindings: [...#PhaseFinding]

admissiblePhaseState: promotionStatus
