package codexdrift

#Watchdog: close({
	id:          #KebabID
	phase:       #PhaseID
	description: #NonEmptyString
	watches:     [...#Path]
	blockingKinds: [...#DriftKind]
})
