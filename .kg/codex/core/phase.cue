package codexdrift

#Phase: close({
	id:          #PhaseID
	status:      #PhaseStatus | *"planned"
	description: #NonEmptyString
	watchedPaths: [...#Path]
})
