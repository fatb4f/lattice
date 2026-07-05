package toolingfixtures

#CueCommandKind: "vet" | "export" | "eval"

#CueCliRecipe:
	close({
		id:      =~"^[a-z0-9]+(-[a-z0-9]+)*$"
		command: "vet"
		target:  string
		expect: "passes" | "bottoms"
	}) |
	close({
		id:       =~"^[a-z0-9]+(-[a-z0-9]+)*$"
		command:  "export"
		target:   string
		selector: string
		expect:   "passes" | "bottoms"
	}) |
	close({
		id:       =~"^[a-z0-9]+(-[a-z0-9]+)*$"
		command:  "eval"
		target:   string
		selector: string
		expect:   "passes" | "bottoms"
	})

vetRecipe: #CueCliRecipe & {
	id:      "vet-patterns"
	command: "vet"
	target:  "./patterns"
	expect:  "passes"
}

exportRecipe: #CueCliRecipe & {
	id:       "export-idiom-catalog"
	command:  "export"
	target:   "./exports"
	selector: "cueIdiomCatalog"
	expect:   "passes"
}

expectedFailureRecipe: #CueCliRecipe & {
	id:       "negative-fixture-probe"
	command:  "export"
	target:   "./domain"
	selector: "_negativeFixtureConflictBinding.probe.proof"
	expect:   "bottoms"
}

toolingFixtureReport: close({
	schema: "fatb4f.lattice.pattern-fixtures.tooling.v1"
	fixtures: {
		vetRecipeAccepted:       vetRecipe.command == "vet"
		exportRecipeHasSelector: exportRecipe.selector == "cueIdiomCatalog"
		expectedFailureBottom:   expectedFailureRecipe.expect == "bottoms"
	}
	accepted: fixtures.vetRecipeAccepted &&
		fixtures.exportRecipeHasSelector &&
		fixtures.expectedFailureBottom
})
