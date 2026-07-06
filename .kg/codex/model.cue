package codexdrift

#NonEmptyString: string & !=""
#Path:           #NonEmptyString
#KebabID:        #NonEmptyString & =~"^[a-z0-9]+(-[a-z0-9]+)*$"

#ControlSurfaceKind:
	"layout" |
	"authority" |
	"adapter" |
	"controller" |
	"verification" |
	"generated" |
	"interface" |
	"policy"

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

#Severity:
	"info" |
	"warning" |
	"violation" |
	"critical"

#Response:
	"allow" |
	"warn" |
	"require-review" |
	"block"

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

#ControlSurface: close({
	id:          #KebabID
	kind:        #ControlSurfaceKind
	description: #NonEmptyString

	requiredPaths: [...#Path] | *[]
	forbiddenPaths: [...#Path] | *[]
	protectedPaths: [...#Path] | *[]
})

#DriftRule: close({
	id:       #KebabID
	kind:     #DriftKind
	surface:  #KebabID
	severity: #Severity
	response: #Response
	reason:   #NonEmptyString
})

#DriftModel: close({
	schema: "codex-drift-model.v1"

	surfaceIDs?: [...#KebabID]

	surfaces: {
		[#KebabID]: #ControlSurface
	}

	rules: {
		[#KebabID]: #DriftRule
	}
})
