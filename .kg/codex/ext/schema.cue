package codexdrift

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

#Response:
	"allow" |
	"warn" |
	"require-review" |
	"block"

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

#ObservedChange: close({
	path:   #Path
	action: "added" | "modified" | "deleted" | "renamed" | "unknown"
	from?:  #Path
})

#ObservedRepo: close({
	filesByPath: close({
		[#Path]: true
	})
})

#ObservedPatch: close({
	base?: #NonEmptyString
	head?: #NonEmptyString
	changes: [...#ObservedChange]
})

#CheckFinding: close({
	rule?:    #KebabID
	kind:     #DriftKind
	surface:  #KebabID
	path?:    #Path
	severity: "info" | "warning" | "violation" | "critical"
	response: #Response
	reason:   #NonEmptyString
})

#KGFinding: #CheckFinding & {
	phase?: #PhaseID
}

#Phase: close({
	id:          #PhaseID
	status:      #PhaseStatus | *"planned"
	description: #NonEmptyString
	watchedPaths: [...#Path]
})

#PromotionBinding: close({
	id:          #KebabID
	phase:       #PhaseID
	authority:   "meta/kernel.cue"
	description: #NonEmptyString

	planSelector:           #NonEmptyString
	implementationSelector: #NonEmptyString
	noWideningSelector?:    #NonEmptyString
	negativeProbeSelectors: [...#NonEmptyString] | *[]
})
