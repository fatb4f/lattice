package domain

import (
	"list"
	"strings"
)

// Primitive constraints shared by domain profiles.
#NonEmptyString: string & strings.MinRunes(1)
#NonEmptyStringList: [...#NonEmptyString] & [_, ...]
#KebabIdentifier: #NonEmptyString & =~"^[a-z0-9]+(-[a-z0-9]+)*$"
#CueSelectorExpr: #NonEmptyString & =~"^[_#A-Za-z][_A-Za-z0-9]*(\\.[_A-Za-z][_A-Za-z0-9]*)*$"

#KebabMapKeyGuard: {
	[ID= !~"^[a-z0-9]+(-[a-z0-9]+)*$"]: {
		_invalidMapKey: ID & #KebabIdentifier
	}
}

#RefSet: {
	[ID= !~"^[a-z0-9]+(-[a-z0-9]+)*$"]: {
		_invalidMapKey: ID & #KebabIdentifier
	}
	[string]: true
}

// Domain profiles refine these vocabularies with bounded enums.
#ResourceRole:                #NonEmptyString
#OperationKind:               #NonEmptyString
#GeneratedOutputResourceRole: "generated-output"

#VisibilityTier:
	"public" |
	"internal" |
	"restricted"

// Domain-neutral graph kernel.
#Resource: close({
	[F= !~"^(id|path|role|visibility)$"]: {
		_invalidField: F & =~"^(id|path|role|visibility)$"
	}

	id:         #KebabIdentifier
	path:       #NonEmptyString
	role:       #ResourceRole
	visibility: #VisibilityTier | *"internal"
})

#Operation: close({
	[F= !~"^(id|kind|description|reads|writes|creates|requiresGates|requiresWitnesses)$"]: {
		_invalidField: F & =~"^(id|kind|description|reads|writes|creates|requiresGates|requiresWitnesses)$"
	}

	id:          #KebabIdentifier
	kind:        #OperationKind
	description: #NonEmptyString

	reads:   #RefSet
	writes:  #RefSet
	creates: #RefSet

	requiresGates:     #RefSet
	requiresWitnesses: #RefSet
})

#Gate: close({
	[F= !~"^(id|description|required)$"]: {
		_invalidField: F & =~"^(id|description|required)$"
	}

	id:          #KebabIdentifier
	description: #NonEmptyString
	required:    bool | *true
})

#Witness: close({
	[F= !~"^(id|description|required)$"]: {
		_invalidField: F & =~"^(id|description|required)$"
	}

	id:          #KebabIdentifier
	description: #NonEmptyString
	required:    bool | *true
})

#ResourceMap: {
	[ID= !~"^[a-z0-9]+(-[a-z0-9]+)*$"]: {
		_invalidMapKey: ID & #KebabIdentifier
	}
	[string]: #Resource
	[ID=string]: {
		id: ID
	}
}

#OperationMap: {
	[ID= !~"^[a-z0-9]+(-[a-z0-9]+)*$"]: {
		_invalidMapKey: ID & #KebabIdentifier
	}
	[string]: #Operation
	[ID=string]: {
		id: ID
	}
}

#GateMap: {
	[ID= !~"^[a-z0-9]+(-[a-z0-9]+)*$"]: {
		_invalidMapKey: ID & #KebabIdentifier
	}
	[string]: #Gate
	[ID=string]: {
		id: ID
	}
}

#WitnessMap: {
	[ID= !~"^[a-z0-9]+(-[a-z0-9]+)*$"]: {
		_invalidMapKey: ID & #KebabIdentifier
	}
	[string]: #Witness
	[ID=string]: {
		id: ID
	}
}

#ObligationState: {
	[F= !~"^(id|resources|operations|gates|witnesses)$"]: {
		_invalidField: F & =~"^(id|resources|operations|gates|witnesses)$"
	}

	id: #KebabIdentifier

	resources:  #ResourceMap
	operations: #OperationMap
	gates:      #GateMap
	witnesses:  #WitnessMap
}

#ClosedObligationState: {
	[F= !~"^(id|resources|operations|gates|witnesses)$"]: {
		_invalidField: F & =~"^(id|resources|operations|gates|witnesses)$"
	}

	id: #KebabIdentifier

	resources:  #ResourceMap
	operations: #OperationMap
	gates:      #GateMap
	witnesses:  #WitnessMap

	_createsGeneratedOutputProof: {
		for operationID, operation in operations {
			for resourceID, _ in operation.creates {
				"\(operationID)-creates-\(resourceID)-exists": list.Contains(list.SortStrings([for key, _ in resources {key}]), resourceID) & true
				"\(operationID)-creates-\(resourceID)-role": resources[resourceID] & {
					role: #GeneratedOutputResourceRole
				}
			}
		}
	}
}

#MakeClosedObligationState: {
	in: #ObligationState
	out: #ClosedObligationState & {
		id: in.id

		resources: {
			for resourceID, resource in in.resources {
				"\(resourceID)": resource & {
					id: resourceID
				}
			}
		}

		operations: {
			for operationID, operation in in.operations {
				"\(operationID)": operation & {
					id: operationID
				}
			}
		}

		gates: {
			for gateID, gate in in.gates {
				"\(gateID)": gate & {
					id: gateID
				}
			}
		}

		witnesses: {
			for witnessID, witness in in.witnesses {
				"\(witnessID)": witness & {
					id: witnessID
				}
			}
		}
	}
}

#StateKeySet: close({
	state: #ClosedObligationState

	resources: list.SortStrings([for key, _ in state.resources {key}])
	operations: list.SortStrings([for key, _ in state.operations {key}])
	gates: list.SortStrings([for key, _ in state.gates {key}])
	witnesses: list.SortStrings([for key, _ in state.witnesses {key}])
})

#OperationRefKeySet: close({
	operation: #Operation

	reads: list.SortStrings([for key, _ in operation.reads {key}])
	writes: list.SortStrings([for key, _ in operation.writes {key}])
	creates: list.SortStrings([for key, _ in operation.creates {key}])
	requiresGates: list.SortStrings([for key, _ in operation.requiresGates {key}])
	requiresWitnesses: list.SortStrings([for key, _ in operation.requiresWitnesses {key}])
})

#NoWideningProof: close({
	authority: #ClosedObligationState
	target:    #ClosedObligationState

	authorityKeys: (#StateKeySet & {state: authority})
	targetKeys: (#StateKeySet & {state: target})

	keyEquality: {
		resources:  authorityKeys.resources & targetKeys.resources
		operations: authorityKeys.operations & targetKeys.operations
		gates:      authorityKeys.gates & targetKeys.gates
		witnesses:  authorityKeys.witnesses & targetKeys.witnesses
	}

	operationRefEquality: {
		for operationID, _ in authority.operations {
			"\(operationID)": {
				authorityRefs: (#OperationRefKeySet & {operation: authority.operations[operationID]})
				targetRefs: (#OperationRefKeySet & {operation: target.operations[operationID]})

				reads:             authorityRefs.reads & targetRefs.reads
				writes:            authorityRefs.writes & targetRefs.writes
				creates:           authorityRefs.creates & targetRefs.creates
				requiresGates:     authorityRefs.requiresGates & targetRefs.requiresGates
				requiresWitnesses: authorityRefs.requiresWitnesses & targetRefs.requiresWitnesses
			}
		}
	}

	compatibility: authority & target
})

#NegativeFixtureSpec: close({
	id:          #KebabIdentifier
	description: #NonEmptyString
	polarity:    "negative"

	authority: #ClosedObligationState
	invalid:   #ClosedObligationState

	proofStatus: "requiresDestructiveProbe"
})

#NegativeFixture:          #NegativeFixtureSpec
#UncheckedNegativeFixture: #NegativeFixtureSpec

#NegativeFixtureProbeSpec: {
	authority: #ClosedObligationState
	invalid:   #ClosedObligationState
	...
}

#NegativeFixtureConflictProbe: #NegativeFixtureProbeSpec & {
	authority: #ClosedObligationState
	invalid:   #ClosedObligationState

	proof: authority & invalid
}

#NegativeFixtureProbeBinding: close({
	fixture: #NegativeFixtureSpec
	probe: #NegativeFixtureConflictProbe & {
		authority: fixture.authority
		invalid:   fixture.invalid
	}
})

#NegativeFixtureCheck: #NegativeFixtureProbeBinding

#MakeUncheckedNegativeFixture: {
	in: close({
		id:          #KebabIdentifier
		description: #NonEmptyString
		authority:   #ObligationState
		invalid:     #ObligationState
	})
	let closedAuthority = (#MakeClosedObligationState & {"in": in.authority}).out
	let closedInvalid = (#MakeClosedObligationState & {"in": in.invalid}).out
	out: #NegativeFixtureSpec & {
		id:          in.id
		description: in.description
		polarity:    "negative"
		authority:   closedAuthority
		invalid:     closedInvalid
		proofStatus: "requiresDestructiveProbe"
	}
}

#MakeNegativeFixtureSpec: #MakeUncheckedNegativeFixture

#MakeNegativeFixtureProbeBinding: {
	in: close({
		id:          #KebabIdentifier
		description: #NonEmptyString
		authority:   #ObligationState
		invalid:     #ObligationState
	})
	let builtFixture = (#MakeUncheckedNegativeFixture & {
		"in": in
	}).out
	out: #NegativeFixtureProbeBinding & {
		fixture: builtFixture
		probe: {
			authority: builtFixture.authority
			invalid:   builtFixture.invalid
		}
	}
}

#MakeNegativeFixture: #MakeNegativeFixtureProbeBinding

#MakeNegativeFixtureCheck: #MakeNegativeFixtureProbeBinding
