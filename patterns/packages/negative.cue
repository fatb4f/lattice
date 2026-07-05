package packagesfixtures

packagesNegativeCase: close({
	id:          "missing-profile-schema-bottom"
	description: "A package-boundary fixture without the imported profile schema should bottom."
	probeExpr:   "packageBoundaryFixture & {exports: {profileSchema: _|_}}"
})
