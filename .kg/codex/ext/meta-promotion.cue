package codexdrift

metaPromotionBindings: {
	"graph-state-phase-one": #PromotionBinding & {
		id: "graph-state-phase-one-promotion"
		phase: "graph-state-phase-one"
		description: "Phase 1 closes through meta.#MakeClosedObligationState."
		planSelector: "closedPhaseOnePromotion"
		implementationSelector: "closedPhaseOnePromotion"
	}

	"graph-state-phase-two": #PromotionBinding & {
		id: "graph-state-phase-two-promotion"
		phase: "graph-state-phase-two"
		description: "Phase 2 closes, proves no-widening, and bottoms negative probes."
		planSelector: "closedPhaseTwoPlan"
		implementationSelector: "closedPhaseTwoImplementation"
		noWideningSelector: "phaseTwoNoWidening"
		negativeProbeSelectors: [
			"danglingEdgeNegative.out.probe.proof",
			"illegalEdgeTypeNegative.out.probe.proof",
			"missingAssignmentTargetNegative.out.probe.proof",
			"cyclicDependencyNegative.out.probe.proof",
			"projectionSelectsMissingNodeNegative.out.probe.proof",
			"widenedProducerOutputNegative.out.probe.proof",
		]
	}
}
