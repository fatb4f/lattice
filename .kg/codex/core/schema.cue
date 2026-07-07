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

#ControlSurfaceKind:
	"layout" |
	"authority" |
	"adapter" |
	"controller" |
	"verification" |
	"generated" |
	"interface" |
	"policy"

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

#CheckFinding: close({
	rule?:    #KebabID
	kind:     #DriftKind
	surface:  #KebabID
	path?:    #Path
	severity: #Severity
	response: #Response
	reason:   #NonEmptyString
})
