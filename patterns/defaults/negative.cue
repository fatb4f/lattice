package defaultsfixtures

defaultsNegativeCase: close({
	id:          "invalid-default-visibility-bottom"
	description: "A defaulted visibility value outside the enum should bottom."
	probeExpr:   "#DefaultedVisibility & {id: \"invalid-default\", visibility: \"external\"}"
})
