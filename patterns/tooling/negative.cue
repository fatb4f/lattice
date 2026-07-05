package toolingfixtures

toolingNegativeCase: close({
	id:          "export-command-without-selector-bottom"
	description: "An export recipe without a selector should bottom."
	probeExpr:   "#CueCliRecipe & {id: \"missing-selector\", command: \"export\", target: \"./exports\", expect: \"passes\"}"
})
