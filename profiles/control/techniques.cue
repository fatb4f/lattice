package control

#Techniques: {
	"constructor-normalization-loop": {
		id:      "constructor-normalization-loop"
		name:    "Constructor Normalization Loop"
		status:  "implemented"
		summary: "Treat a constructor as the controller that drives open input toward a closed output."
		patternRef: {
			id:     "constructors"
			family: "constructor"
		}
		technique: "Use a #MakeX constructor as the controller, inspect the closed output as the sensor reading, and treat bottom as the error signal."
		derivesFrom: [
			"patterns/constructors.cue",
			"meta/kernel.cue:#MakeClosedObligationState",
		]
		control: {
			id: "constructor-normalization-control"
			plant: {
				kind:        "open input data"
				stateRef:    "patterns/constructors.cue:#Patterns.constructors.canonical"
				boundaryRef: "meta/kernel.cue:#ObligationState"
			}
			setpoint: {
				contractRef: "meta/kernel.cue:#ClosedObligationState"
				invariants: [
					"constructor output is closed",
					"derived resource ids match map keys",
				]
			}
			sensors: {
				"closed-output": {
					kind:     "projection"
					target:   "constructor output"
					coverage: "full"
				}
			}
			controller: {
				kind:      "constructor"
				policyRef: "meta/kernel.cue:#MakeClosedObligationState"
				errorModes: [
					"invalid input type",
					"unresolved operation reference",
				]
			}
			feedback: {
				errorSignal: "bottom from constructor unification failure"
				proofRef:    "scripts/validate-domain.sh:constructor negative fixture"
				stability:   "idempotent"
			}
		}
		checks: {
			pass: ["cue eval patterns/constructors.cue -e #Patterns.constructors.positive"]
			fail: ["cue eval patterns/constructors.cue -e '(#Patterns[\"constructors\"].#MakeResource & {in: #Patterns[\"constructors\"].negative.badResource}).out'"]
		}
	}

	"projection-observer-loop": {
		id:      "projection-observer-loop"
		name:    "Projection Observer Loop"
		status:  "implemented"
		summary: "Treat a projection as a bounded observer that cannot acquire authority."
		patternRef: {
			id:     "projections"
			family: "projection"
		}
		technique: "Compare authority and projected key/ref sets, then reject widened generated views as feedback errors."
		derivesFrom: [
			"patterns/projections.cue",
			"meta/kernel.cue:#NoWideningProof",
		]
		control: {
			id: "projection-observer-control"
			plant: {
				kind:        "authority graph"
				stateRef:    "patterns/projections.cue:#Patterns.projections._closedAuthority"
				boundaryRef: "meta/kernel.cue:#NoWideningProof"
			}
			setpoint: {
				contractRef: "authority key/ref set"
				invariants: [
					"projection does not add authority resources",
					"projection does not add operation refs",
				]
			}
			sensors: {
				"authority-keyset": {
					kind:     "projection"
					target:   "meta/kernel.cue:#StateKeySet"
					coverage: "full"
				}
				"target-keyset": {
					kind:     "projection"
					target:   "meta/kernel.cue:#StateKeySet"
					coverage: "full"
				}
			}
			controller: {
				kind:      "validator"
				policyRef: "meta/kernel.cue:#NoWideningProof"
				errorModes: [
					"keyset widening",
					"refset widening",
					"incompatible projected state",
				]
			}
			actuators: {
				"public-export": {
					kind:   "publication"
					target: "generated projection surface"
					effect: "publish"
				}
			}
			feedback: {
				errorSignal: "key/ref mismatch or compatibility conflict"
				proofRef:    "meta/kernel.cue:#NoWideningProof"
				stability:   "monotone"
			}
		}
		checks: {
			pass: ["cue eval patterns/projections.cue -e #Patterns.projections.positive"]
			fail: ["cue eval patterns/projections.cue -e '(meta.#NoWideningProof & {authority: #Patterns[\"projections\"]._closedAuthority, target: (meta.#MakeClosedObligationState & {in: #Patterns[\"projections\"]._authority & #Patterns[\"projections\"].negative.widenedProjection}).out})'"]
		}
	}

	"fixture-error-signal-loop": {
		id:      "fixture-error-signal-loop"
		name:    "Fixture Error Signal Loop"
		status:  "implemented"
		summary: "Treat fixture pairs as sensors that confirm accepted and rejected controller behavior."
		patternRef: {
			id:     "negative-fixtures"
			family: "fixture"
		}
		technique: "Use positive fixtures as accepted observations and negative fixtures as expected-bottom error signals."
		derivesFrom: [
			"patterns/negative-fixtures.cue",
			"meta/kernel.cue:#MakeNegativeFixture",
		]
		control: {
			id: "fixture-error-signal-control"
			plant: {
				kind:        "validation rule"
				stateRef:    "patterns/negative-fixtures.cue:#Patterns.negative-fixtures.fixtures"
				boundaryRef: "meta/kernel.cue:#NegativeFixtureSpec"
			}
			setpoint: {
				contractRef: "fixture acceptance contract"
				invariants: [
					"positive fixture evaluates",
					"negative fixture bottoms at the expected probe",
				]
			}
			sensors: {
				"positive-probe": {
					kind:     "fixture"
					target:   "accepted fixture"
					coverage: "sentinel"
				}
				"negative-probe": {
					kind:     "fixture"
					target:   "expected bottom fixture"
					coverage: "sentinel"
				}
			}
			controller: {
				kind:      "validator"
				policyRef: "meta/kernel.cue:#MakeNegativeFixture"
				errorModes: [
					"positive fixture rejected",
					"negative fixture accepted",
				]
			}
			feedback: {
				errorSignal: "unexpected pass/fail fixture result"
				proofRef:    "scripts/validate-domain.sh:negative fixture probes"
				stability:   "bounded"
			}
		}
		checks: {
			pass: ["cue eval patterns/negative-fixtures.cue -e #Patterns.negative-fixtures.positive"]
			fail: ["cue eval patterns/negative-fixtures.cue -e '(meta.#MakeNegativeFixture & {in: #Patterns[\"negative-fixtures\"].negative.proof}).out.probe.proof'"]
		}
	}
}
