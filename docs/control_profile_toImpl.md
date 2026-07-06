# Control Profile To Implement

Closed-loop feedback is a profile overlay, not canonical pattern authority.
`patterns/` stays focused on executable idiomatic CUE. `profiles/control/`
catalogs techniques for generating closed-loop feedback from those idioms.

The executable schema authority is `profiles/control/schema.cue`. In particular,
`setpoint.invariants` and `controller.errorModes` are non-empty lists.

## Control Surface Shape

```cue
#ControlSurface: close({
	id: #KebabIdentifier

	plant: close({
		kind:        #NonEmptyString
		stateRef:    #NonEmptyString
		boundaryRef: #NonEmptyString
	})

	setpoint: close({
		contractRef: #NonEmptyString
		invariants:  #NonEmptyStringList
	})

	sensors: {
		[string]: close({
			kind:     #SensorKind
			target:   #NonEmptyString
			coverage: #SensorCoverage
		})
	}

	controller: close({
		kind:       #ControllerKind
		policyRef:  #NonEmptyString
		errorModes: #NonEmptyStringList
	})

	actuators?: {
		[string]: close({
			kind:   #ActuatorKind
			target: #NonEmptyString
			effect: #ActuatorEffect
		})
	}

	feedback: close({
		errorSignal: #NonEmptyString
		proofRef:    #NonEmptyString
		stability:   #StabilityMode
	})
})
```

Each control technique references a pattern and explains how to derive plant,
setpoint, sensors, controller, optional actuators, and feedback from executable
pattern evidence.

```text
authority state
  -> projection / adapter / transition
  -> observed output
  -> proof / fixture / evidence
  -> admissibility decision
```
