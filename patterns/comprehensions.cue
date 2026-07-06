package patterns

import meta "github.com/fatb4f/lattice/meta"

#Patterns: {
	"comprehensions": {

		name:    "Comprehensions"
		summary: "Derive normalized maps from input registries by iterating over keys and values."
		demonstrates: ["comprehensions", "derived fields", "keyed maps"]
		id:          "comprehensions"
		family:      "constructor"
		status:      "implemented"
		problem:     "Input registries need normalized derived maps without hand-copying keys."
		abstraction: "Map comprehension normalization"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/comprehensions.cue -e #Patterns.comprehensions.positive"], fail: ["cue eval patterns/comprehensions.cue -e #Patterns.comprehensions.negative.badServicePort"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes registry transforms and derived key maps."}

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
