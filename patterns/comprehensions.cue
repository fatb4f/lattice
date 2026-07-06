package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"comprehensions": {

		#ResourceInputs: {
			[string]: {
				path: string
				role: "authority" | "generated-output"
			}
		}

		_resources: #ResourceInputs & {
			"authority-file": {
				path: "contracts/authority.cue"
				role: "authority"
			}
			"generated-file": {
				path: "generated/assertions.json"
				role: "generated-output"
			}
		}

		canonical: {
			id:        "comprehensions"
			kernelUse: "meta/kernel.cue:#MakeClosedObligationState.resources"
			closedResources: {
				for resourceID, resource in _resources {
					"\(resourceID)": resource & {
						id: resourceID
					}
				}
			}
		}

		positive: {
			closedResources: canonical.closedResources & {
				"authority-file": {
					id:   "authority-file"
					path: "contracts/authority.cue"
					role: "authority"
				}
			}
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "comprehensions"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			badServicePort: {
				"authority-file": {
					path: 404
					role: "authority"
				}
			}
		}

	}
}
