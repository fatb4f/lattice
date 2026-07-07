package codexdrift

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
