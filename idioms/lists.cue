package pillars

import (
	"list"

	meta "github.com/fatb4f/lattice/meta"
)

#Pillars: {
	"lists": {

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
