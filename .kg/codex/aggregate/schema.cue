package codexdrift

import "list"

#NonEmptyString: string & !=""
#Path:           #NonEmptyString
#KebabID:        #NonEmptyString & =~"^[a-z0-9]+(-[a-z0-9]+)*$"

#PhaseID:
	"graph-state-phase-one" |
	"graph-state-phase-two"

#PhaseStatus:
	"planned" |
	"in-progress" |
	"blocked" |
	"admissible" |
	"promoted"

#DriftKind:
	"missing-required-surface" |
	"unexpected-surface" |
	"duplicate-authority" |
	"authority-moved" |
	"adapter-boundary-crossed" |
	"controller-bypassed" |
	"verification-weakened" |
	"generated-promoted-to-authority" |
	"interface-contract-changed" |
	"policy-violated"

#Phase: close({
	id:          #PhaseID
	status:      #PhaseStatus | *"planned"
	description: #NonEmptyString
	watchedPaths: [...#Path]
})

#PromotionBinding: close({
	id:            #KebabID
	phase:         #PhaseID
	authority:     "meta/kernel.cue"
	description:   #NonEmptyString
	targetPackage: #NonEmptyString

	planSelector:           #NonEmptyString
	implementationSelector: #NonEmptyString
	noWideningSelector?:    #NonEmptyString
	negativeProbeSelectors: [...#NonEmptyString] | *[]
})

#Watchdog: close({
	id:          #KebabID
	phase:       #PhaseID
	description: #NonEmptyString
	watches: [...#Path]
	blockingKinds: [...#DriftKind]
})

#KGFinding: close({
	rule?:    #KebabID
	kind:     #DriftKind
	surface:  #KebabID
	path?:    #Path
	severity: "info" | "warning" | "violation" | "critical"
	response: "allow" | "warn" | "require-review" | "block"
	reason:   #NonEmptyString
	phase?:   #PhaseID
})

#PhaseFinding: close({
	rule?:    #KebabID
	kind:     #DriftKind
	surface:  #KebabID
	path:     #Path
	severity: "info" | "warning" | "violation" | "critical"
	response: "allow" | "warn" | "require-review" | "block"
	reason:   #NonEmptyString
	phase:    #PhaseID
})

#PhaseWatchdogEvaluation: close({
	let Phase = phase

	phase: #Phase
	watchdog: #Watchdog & {phase: Phase.id}
	findings: [...#PhaseFinding & {phase: Phase.id}] | *[]

	blockingFindings: [
		for finding in findings
		if list.Contains(watchdog.blockingKinds, finding.kind) == true {
			finding
		},
	]

	admissible: len(blockingFindings) == 0
	status:     "admissible" | "blocked"
	if len(blockingFindings) == 0 {
		status: "admissible"
	}
	if len(blockingFindings) > 0 {
		status: "blocked"
	}
})

#PhaseWatchdogStatus: close({
	let Findings = findings

	findings: [...#KGFinding & {path: #Path}] | *[]

	phaseFindings: {
		"graph-state-phase-one": (#PhaseFindings & {phaseID: "graph-state-phase-one", findings: Findings}).output
		"graph-state-phase-two": (#PhaseFindings & {phaseID: "graph-state-phase-two", findings: Findings}).output
	}

	phaseWatchdogEvaluations: {
		"graph-state-phase-one": #PhaseWatchdogEvaluation & {
			phase:    graphStatePhases["graph-state-phase-one"]
			watchdog: phaseWatchdogs["graph-state-phase-one"]
			findings: phaseFindings["graph-state-phase-one"]
		}
		"graph-state-phase-two": #PhaseWatchdogEvaluation & {
			phase:    graphStatePhases["graph-state-phase-two"]
			watchdog: phaseWatchdogs["graph-state-phase-two"]
			findings: phaseFindings["graph-state-phase-two"]
		}
	}

	promotionStatus: {
		schema: "codex-phase-promotion-status.v1"
		phases: {
			"graph-state-phase-one": {
				phase:      graphStatePhases["graph-state-phase-one"]
				promotion:  metaPromotionBindings["graph-state-phase-one"]
				watchdog:   phaseWatchdogs["graph-state-phase-one"]
				evaluation: phaseWatchdogEvaluations["graph-state-phase-one"]
			}
			"graph-state-phase-two": {
				phase:      graphStatePhases["graph-state-phase-two"]
				promotion:  metaPromotionBindings["graph-state-phase-two"]
				watchdog:   phaseWatchdogs["graph-state-phase-two"]
				evaluation: phaseWatchdogEvaluations["graph-state-phase-two"]
			}
		}
	}
})

#PhaseFindings: close({
	phaseID: #PhaseID
	findings: [...#KGFinding & {path: #Path}] | *[]

	output: [
		for finding in findings
		for watchedPath in graphStatePhases[phaseID].watchedPaths
		if (#PathMatches & {path: finding.path, pattern: watchedPath}).matches == true {
			kind:     finding.kind
			surface:  finding.surface
			path:     finding.path
			severity: finding.severity
			response: finding.response
			reason:   finding.reason
			phase:    phaseID
		},
	]
})

graphStatePhases: {
	"graph-state-phase-one": #Phase & {
		id:          "graph-state-phase-one"
		status:      "promoted"
		description: "Graph-state primitive ontology phase."
		watchedPaths: [
			"docs/graph-state-promotion-plan.md",
			"meta/kernel.cue",
			"projections/graph-state/README.md",
			"projections/graph-state/primitives",
			"projections/graph-state/promotion",
		]
	}

	"graph-state-phase-two": #Phase & {
		id:          "graph-state-phase-two"
		status:      "planned"
		description: "Graph-state operational kernel phase."
		watchedPaths: [
			"docs/graph-state-promotion-plan.md",
			"meta/kernel.cue",
			"projections/graph-state/kernel",
			"projections/graph-state/fixtures",
			"projections/graph-state/promotion",
			"generated/codex/graph-state",
		]
	}
}

metaPromotionBindings: {
	"graph-state-phase-one": #PromotionBinding & {
		id:                     "graph-state-phase-one-promotion"
		phase:                  "graph-state-phase-one"
		description:            "Phase 1 closes through meta.#MakeClosedObligationState."
		targetPackage:          "projections/graph-state"
		planSelector:           "closedPhaseOnePromotion"
		implementationSelector: "closedPhaseOnePromotion"
	}

	"graph-state-phase-two": #PromotionBinding & {
		id:                     "graph-state-phase-two-promotion"
		phase:                  "graph-state-phase-two"
		description:            "Phase 2 closes, proves no-widening, and bottoms negative probes."
		targetPackage:          "meta"
		planSelector:           "closedPhaseTwoPlan"
		implementationSelector: "closedPhaseTwoImplementation"
		noWideningSelector:     "phaseTwoNoWidening"
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
