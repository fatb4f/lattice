package codeintelprofile

import projections "github.com/fatb4f/lattice/projections"

#CodeIntelProfileSnapshot: projections.#CodeIntelProfileExpectation

#InvalidProfileFixture: close({
	id:          projections.#KebabIdentifier
	description: projections.#NonEmptyString
	reason:      projections.#NonEmptyString
	snapshot:    _
})

