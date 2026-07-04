package domain

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
