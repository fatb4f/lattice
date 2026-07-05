@if(negativeproof)

package domain

_invalidState: {
	id: "valid-state"

	resources: {
		"authority-file": {
			path: "contracts/authority.cue"
			role: "forbidden"
		}
		"generated-file": {
			path: "generated/assertions.json"
			role: "generated-output"
		}
	}

	operations: {}
	gates: {}
	witnesses: {}
}

_negativeFixtureConflictBinding: (#MakeNegativeFixture & {
	in: {
		id:          "negative-conflict"
		description: "Negative fixture derives paired destructive probe input"
		authority:   _validState
		invalid:     _invalidState
	}
}).out
