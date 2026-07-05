package packagesfixtures

import (
	patterns "github.com/fatb4f/lattice/patterns"
	profiles "github.com/fatb4f/lattice/profiles"
)

packageBoundaryFixture: close({
	module: "github.com/fatb4f/lattice"
	imports: {
		parentPackage: "github.com/fatb4f/lattice/patterns"
		localPackage:  "github.com/fatb4f/lattice/profiles"
	}
	exports: {
		catalogSchema: patterns.cueIdiomCatalog.schema
		profileSchema: profiles.#CodeIntelProfileExpectation.schema
	}
})

packagesFixtureReport: close({
	schema: "fatb4f.lattice.pattern-fixtures.packages.v1"
	fixtures: {
		parentPackageImported: packageBoundaryFixture.exports.catalogSchema == "fatb4f.lattice.cue-idiom-catalog.v1"
		localPackageImported:  packageBoundaryFixture.exports.profileSchema == "factory.plugin-bundle.code-intel.cue-profile.v1"
	}
	accepted: fixtures.parentPackageImported && fixtures.localPackageImported
})

