package control

import "strings"

#NonEmptyString: string & strings.MinRunes(1)
#NonEmptyStringList: [...#NonEmptyString] & [_, ...]
#KebabIdentifier: #NonEmptyString & =~"^[a-z0-9]+(-[a-z0-9]+)*$"

#SensorKind:
	"selector" |
	"projection" |
	"fixture" |
	"evidence" |
	"command-output"

#SensorCoverage:
	"full" |
	"partial" |
	"sentinel"

#ControllerKind:
	"constructor" |
	"validator" |
	"transition" |
	"gate" |
	"adapter"

#ActuatorKind:
	"command" |
	"adapter" |
	"codegen" |
	"mutation" |
	"publication"

#ActuatorEffect:
	"read" |
	"write" |
	"create" |
	"delete" |
	"publish"

#StabilityMode:
	"idempotent" |
	"monotone" |
	"convergent" |
	"bounded" |
	"unchecked"

#TechniqueStatus:
	"implemented" |
	"planned" |
	"deferred"

#PatternFamily:
	"adapter" |
	"bounds" |
	"constructor" |
	"default" |
	"fixture" |
	"graph" |
	"keyset" |
	"projection" |
	"schema" |
	"selector" |
	"state" |
	"variant"

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

#FixtureControl: close({
	positive: close({
		input:  _
		expect: "accepted"
	})
	negative: close({
		input:      _
		expect:     "bottom"
		errorClass: #NonEmptyString
	})
})

#PatternRef: close({
	id:     #KebabIdentifier
	family: #PatternFamily
})

#TechniqueEntry: close({
	id:          #KebabIdentifier
	name:        #NonEmptyString
	status:      #TechniqueStatus
	summary:     #NonEmptyString
	patternRef:  #PatternRef
	technique:   #NonEmptyString
	derivesFrom: #NonEmptyStringList
	control:     #ControlSurface
	checks?: close({
		pass?: #NonEmptyStringList
		fail?: #NonEmptyStringList
	})
})

#TechniqueMap: {
	[string]: #TechniqueEntry
}

#Techniques: #TechniqueMap
