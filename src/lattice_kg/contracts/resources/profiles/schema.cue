package profiles

import "strings"

#NonEmptyString: string & strings.MinRunes(1)

#ProfileManifest: close({
	schema:          "lattice.profile-manifest.v1"
	protocolVersion: "lattice.registry.v1"
	profiles: [close({
		id:              #NonEmptyString
		version:         #NonEmptyString
		protocolVersion: "lattice.registry.v1"
		resource:        #NonEmptyString
		digest:          =~"^sha256:[0-9a-f]{64}$"
	}), ...]
})
