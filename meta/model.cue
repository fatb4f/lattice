package meta

_validState: {
	id: "valid-state"

	resources: {
		"authority-file": {
			path: "contracts/authority.cue"
			role: "authority"
		}
		"generated-file": {
			path: "generated/assertions.json"
			role: "generated-output"
		}
	}

	operations: {
		"inspect-operation": {
			kind:        "inspect"
			description: "Inspect authority and generate assertions"
			reads: {
				"authority-file": true
			}
			writes: {}
			creates: {
				"generated-file": true
			}
			requiresGates: {
				"cue-vet": true
			}
			requiresWitnesses: {
				"inspection-report": true
			}
		}
	}

	gates: {
		"cue-vet": {
			description: "Run CUE validation"
		}
	}

	witnesses: {
		"inspection-report": {
			description: "Recorded validation evidence"
		}
	}
}

_closedState: (#MakeClosedObligationState & {in: _validState}).out

_noWideningProof: #NoWideningProof & {
	authority: _closedState
	target:    _closedState
}

_uncheckedNegativeFixtureAllowsNonConflict: (#MakeUncheckedNegativeFixture & {
	in: {
		id:          "unchecked-negative-non-conflict"
		description: "Unchecked negative spec can export without proving bottom"
		authority:   _validState
		invalid:     _validState
	}
}).out

_negativeFixtureCheckedNonConflict: (#MakeNegativeFixture & {
	in: {
		id:          "negative-non-conflict-control"
		description: "Checked negative fixture exposes destructive proof"
		authority:   _validState
		invalid:     _validState
	}
}).out

_negativeFixtureCheckedProof: _negativeFixtureCheckedNonConflict.probe.proof

_negativeFixtureSpecOnly: (#MakeNegativeFixtureSpec & {
	in: {
		id:          "negative-spec-only"
		description: "Spec-only negative fixture does not expose probe"
		authority:   _validState
		invalid:     _validState
	}
}).out
