package codexdrift

import "list"

#PromotionGateFinding: #KGFinding & {
	surface: "codex-drift-kg" | "meta-kernel"
}

#PromotionSelectorCheck: close({
	selector: #NonEmptyString
	ok:       bool
	error?:   string
})

#PromotionNegativeProbeCheck: close({
	selector: #NonEmptyString
	bottoms:  bool
	error?:   string
})

#PromotionGateFacts: close({
	schema: "codex-promotion-facts.v1"
	phases: {
		[#PhaseID]: close({
			phase:         #PhaseID
			targetPackage: #NonEmptyString
			selectorResults: close({
				plan:           #PromotionSelectorCheck
				implementation: #PromotionSelectorCheck
				noWidening?:    #PromotionSelectorCheck
				negativeProbes: [...#PromotionNegativeProbeCheck]
			})
		})
	}
})

#PromotionGateEvaluation: close({
	let Phase = phase

	phase: #PhaseID
	binding: #PromotionBinding & {phase: Phase}

	selectorResults: close({
		plan:           #PromotionSelectorCheck
		implementation: #PromotionSelectorCheck
		noWidening?:    #PromotionSelectorCheck
		negativeProbes: [...#PromotionNegativeProbeCheck]
	})

	findings: [...#KGFinding]
	admissible: bool
	response:   #Response
})

#PromotionGateStatus: close({
	let Facts = facts
	let Findings = findings

	facts: #PromotionGateFacts

	findings: [
		for phaseID, phaseFacts in Facts.phases
		if phaseFacts.selectorResults.plan.ok == false {
			kind:     "verification-weakened"
			surface:  "meta-kernel"
			severity: "critical"
			response: "block"
			reason:   "Promotion plan selector does not export from the meta authority."
			phase:    phaseID
		},
		for phaseID, phaseFacts in Facts.phases
		if phaseFacts.selectorResults.implementation.ok == false {
			kind:     "verification-weakened"
			surface:  "meta-kernel"
			severity: "critical"
			response: "block"
			reason:   "Promotion implementation selector does not export from the meta authority."
			phase:    phaseID
		},
		for phaseID, phaseFacts in Facts.phases
		if phaseFacts.selectorResults.noWidening != _|_ {
			if phaseFacts.selectorResults.noWidening.ok == false {
				kind:     "verification-weakened"
				surface:  "meta-kernel"
				severity: "critical"
				response: "block"
				reason:   "Promotion no-widening selector does not export from the meta authority."
				phase:    phaseID
			}
		},
		for phaseID, phaseFacts in Facts.phases
		for probe in phaseFacts.selectorResults.negativeProbes
		if probe.bottoms == false {
			kind:     "verification-weakened"
			surface:  "meta-kernel"
			severity: "critical"
			response: "block"
			reason:   "Promotion negative probe does not bottom."
			phase:    phaseID
		},
	]

	evaluations: {
		for phaseID, promotionBinding in metaPromotionBindings {
			"\(phaseID)": #PromotionGateEvaluation & {
				phase:           phaseID
				binding:         promotionBinding
				selectorResults: Facts.phases[phaseID].selectorResults
				findings: [
					for finding in Findings
					if finding.phase == phaseID {
						finding
					},
				]
				admissible: len(findings) == 0
				if len(findings) == 0 {
					response: "allow"
				}
				if len(findings) > 0 {
					response: "block"
				}
			}
		}
	}
})

#FullDriftGate: close({
	let Model = model
	let Facts = facts
	let Drift = drift
	let Promotion = promotion

	schema: "codex-drift-kg.v1"
	model:  #DriftModel
	facts: close({
		repo:      #ObservedRepo
		patch:     #ObservedPatch
		promotion: #PromotionGateFacts
		selfContext: #SelfContextFacts | *{
			schema: "lattice-self-context.v1"
			surfaces: {}
			invariants: {}
		}
	})

	drift: (#FullDriftKG & {
		schema: "codex-drift-kg.v1"
		model:  Model
		facts: {
			repo:        Facts.repo
			patch:       Facts.patch
			selfContext: Facts.selfContext
		}
	})

	promotion: (#PromotionGateStatus & {
		facts: Facts.promotion
	})

	findings: list.Concat([
		[for finding in Drift.findings {finding}],
		[for finding in Promotion.findings {finding}],
	])
})
