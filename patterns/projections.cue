package patterns

import domain "github.com/fatb4f/lattice/domain"

_authority: {
	id: "projections"
	resources: {
		"authority-file": {
			path:       "patterns/projections.cue"
			role:       "authority"
			visibility: "public"
		}
		"internal-proof": {
			path:       "domain/kernel.cue"
			role:       "authority"
			visibility: "internal"
		}
	}
	operations: {}
	gates: {}
	witnesses: {}
}

_closedAuthority: (domain.#MakeClosedObligationState & {in: _authority}).out

canonical: {
	id: "projections"
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
	validation: domain.#NoWideningProof & {
		authority: _closedAuthority
		target:    _closedAuthority
	}
}

negative: {
	widenedProjection: domain.#NoWideningProof & {
		authority: _closedAuthority
		target: (domain.#MakeClosedObligationState & {in: _authority & {
			resources: {
				"extra-file": {
					path: "generated/extra.json"
					role: "authority"
				}
			}
		}}).out
	}
}
