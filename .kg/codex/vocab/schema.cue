package codexdrift

#NonEmptyString: string & !=""
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
