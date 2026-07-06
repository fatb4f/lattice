package patterns

import (
	"list"

	meta "github.com/fatb4f/lattice/meta"
)

#Patterns: {
	"lists": {

		name:    "Lists"
		summary: "Extract and compare stable key lists from maps."
		demonstrates: ["lists", "standard library sorting", "key sets"]
		id:          "lists"
		family:      "keyset"
		status:      "implemented"
		problem:     "Map-derived sets need stable ordering for comparison."
		abstraction: "Sorted keyset extraction"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/lists.cue -e #Patterns.lists.positive"], fail: ["cue eval patterns/lists.cue -e #Patterns.lists.negative.badTuple"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes sorting and stable projection checks."}

		#NonEmptyKeyList: [...string] & [_, ...]
		#AuthorityKeyTuple: ["authority-file", "generated-file"]

		_resources: {
			"generated-file": {}
			"authority-file": {}
		}

		canonical: {
			id:        "lists"
			kernelUse: "meta/kernel.cue:#StateKeySet"
			keys: #NonEmptyKeyList & list.SortStrings([for key, _ in _resources {key}])
			tuple: #AuthorityKeyTuple
		}

		positive: {
			keys: canonical.keys & ["authority-file", "generated-file"]
			tuple: #AuthorityKeyTuple & ["authority-file", "generated-file"]
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "lists"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			emptyCommands: []
			badTuple: ["generated-file", "authority-file"]
		}

	}
}
