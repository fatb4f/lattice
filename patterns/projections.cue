package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"projections": {

		name:    "Projections"
		summary: "Project a public view from closed authority while preserving no-widening checks."
		demonstrates: ["projections", "filters", "no widening"]

		_authority: {
			id: "projections"
			resources: {
				"authority-file": {
					path:       "patterns/projections.cue"
					role:       "authority"
					visibility: "public"
				}
				"internal-proof": {
					path:       "meta/kernel.cue"
					role:       "authority"
					visibility: "internal"
				}
			}
			operations: {}
			gates: {}
			witnesses: {}
		}

		_closedAuthority: (meta.#MakeClosedObligationState & {in: _authority}).out

		canonical: {
			id:        "projections"
			kernelUse: "meta/kernel.cue:#NoWideningProof"
			publicResources: [for resourceID, resource in _closedAuthority.resources if resource.visibility == "public" {
				id:   resourceID
				path: resource.path
			}]
		}

		positive: {
			publicResources: canonical.publicResources & [{
				id:   "authority-file"
				path: "patterns/projections.cue"
			}]
			validation: meta.#NoWideningProof & {
				authority: _closedAuthority
				target:    _closedAuthority
			}
		}

		negative: {
			widenedProjection: {
				resources: {
					"extra-file": {
						path: "generated/extra.json"
						role: "authority"
					}
				}
			}
		}

	}
}
