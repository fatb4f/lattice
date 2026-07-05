package disjunctionsfixtures

#ScalarEnum: "vet" | "export" | "eval"

#CommandBranch:
	close({
		kind:    "vet"
		package: string
	}) |
	close({
		kind:     "export"
		package:  string
		selector: string
	}) |
	close({
		kind: "eval"
		expr: string
	})

#DefaultBranch: close({
	mode: "strict" | "permissive" | *"strict"
})

scalarEnum: #ScalarEnum & "vet"

taggedUnionVet: #CommandBranch & {
	kind:    "vet"
	package: "./patterns"
}

taggedUnionExport: #CommandBranch & {
	kind:     "export"
	package:  "./exports"
	selector: "cueIdiomCatalog"
}

defaultBranch: #DefaultBranch & {}

invalidBranchFixture: close({
	id:          "invalid-branch-bottom"
	description: "A command branch with kind export but no selector should bottom when unified with #CommandBranch."
	probeExpr:   "#CommandBranch & {kind: \"export\", package: \"./exports\"}"
})

disjunctionsFixtureReport: close({
	schema: "fatb4f.lattice.pattern-fixtures.disjunctions.v1"
	fixtures: {
		scalarEnumAccepted:  scalarEnum == "vet"
		vetBranchAccepted:   taggedUnionVet.kind == "vet"
		exportBranchAccepted: taggedUnionExport.selector == "cueIdiomCatalog"
		defaultBranchApplied: defaultBranch.mode == "strict"
		invalidBranchListed: invalidBranchFixture.id == "invalid-branch-bottom"
	}
	accepted: fixtures.scalarEnumAccepted &&
		fixtures.vetBranchAccepted &&
		fixtures.exportBranchAccepted &&
		fixtures.defaultBranchApplied &&
		fixtures.invalidBranchListed
})
