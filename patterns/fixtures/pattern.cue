package fixturepatterns

#PatternFixture: close({
	id:       =~"^[a-z0-9]+(-[a-z0-9]+)*$"
	selector: string
	expect:   "passes" | "bottoms"
})

positiveFixture: #PatternFixture & {
	id:       "catalog-export-passes"
	selector: "cueIdiomCatalog"
	expect:   "passes"
}

negativeFixture: #PatternFixture & {
	id:       "negative-proof-bottoms"
	selector: "_negativeFixtureConflictBinding.probe.proof"
	expect:   "bottoms"
}
