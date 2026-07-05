package bottompatterns

#ClosedCommand: close({
	kind:   "vet" | "export"
	target: string
})

validCommand: #ClosedCommand & {
	kind:   "vet"
	target: "./patterns"
}

bottomProbeFixture: close({
	id:          "closed-command-extra-field-bottom"
	description: "Adding an undeclared field to a closed command should bottom."
	probeExpr:   "#ClosedCommand & {kind: \"vet\", target: \"./patterns\", extra: true}"
})
