package codeintelprofile

import profiles "github.com/fatb4f/lattice/profiles"

#CodeIntelProfileSnapshot: profiles.#CodeIntelProfileExpectation

#InvalidProfileFixture: close({
	id:          profiles.#KebabIdentifier
	description: profiles.#NonEmptyString
	reason:      profiles.#NonEmptyString
	snapshot:    _
})

