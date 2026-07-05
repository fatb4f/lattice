package disjunctionsfixtures

disjunctionsNegativeCase: close({
	id:          "missing-export-selector-bottom"
	description: "An export command branch without selector should bottom."
	probeExpr:   "#CommandBranch & {kind: \"export\", package: \"./exports\"}"
})
