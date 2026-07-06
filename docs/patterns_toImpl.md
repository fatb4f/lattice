 Constructor / Builder

  - Implemented:
      - #MakeClosedObligationState
      - #MakeUncheckedNegativeFixture
      - #MakeNegativeFixtureProbeBinding
      - #MakeNegativeFixture
      - #MakeNegativeFixtureCheck
      - #MakeNegativeFixtureSpec

  - Possible variants:
      - #MakeClosedResourceMap
      - #MakeClosedOperationMap
      - #MakeProjection
      - #MakeTransitionResult

  Schema / Data Structures

  - Implemented:
      - #Resource
      - #Operation
      - #Gate
      - #Witness
      - #ResourceMap
      - #OperationMap
      - #GateMap
      - #WitnessMap
      - #ObligationState
      - #ClosedObligationState

  - Possible variants:
      - #PatternEntry
      - #SourceRef
      - #ControlSurface
      - #DriftRule

  Projection / No-Widening

  - Implemented:
      - #NoWideningProof
      - #StateKeySet
      - #OperationRefKeySet

  - Possible variants:
      - #PublicResourceProjection
      - #ProjectionKeySet
      - #NoGeneratedAuthorityProof
      - #ProjectionCompatibilityProof

  Validator / Fixture Pair

  - Implemented:
      - #NegativeFixtureSpec
      - #NegativeFixture
      - #UncheckedNegativeFixture
      - #NegativeFixtureProbeSpec
      - #NegativeFixtureConflictProbe
      - #NegativeFixtureProbeBinding
      - #NegativeFixtureCheck

  - Possible variants:
      - #PositiveFixture
      - #FixtureMatrix
      - #ExpectedFailureProbe
      - #ExportableInvalidExample

  State

  - Implemented:
      - #ObligationState
      - #ClosedObligationState

  - Partial:
      - _createsGeneratedOutputProof

  - Missing/proposed:
      - #StateTransition
      - #TransitionInput
      - #TransitionResult
      - #AllowedOperation
      - #BeforeAfterProof

  Graph / References

  - Implemented:
      - #RefSet
      - #Operation.reads
      - #Operation.writes
      - #Operation.creates
      - #Operation.requiresGates
      - #Operation.requiresWitnesses
      - _createsGeneratedOutputProof

  - Possible variants:
      - #ResourceGraph
      - #OperationGraph
      - #ReachabilityProof
      - #CycleRejectionProbe
      - #DAGProof

  Sorting / Stable Keysets

  - Implemented:
      - #StateKeySet
      - #OperationRefKeySet

  - Uses:
      - list.SortStrings
      - list.Contains

  - Possible variants:
      - #SortedMapKeys
      - #StableKeySetEquality
      - #RequiredCoverageProof

  Closed Boundary

  - Implemented:
      - #Resource
      - #Operation
      - #Gate
      - #Witness
      - #NegativeFixtureSpec
      - #NegativeFixtureProbeBinding
      - #NoWideningProof

  - Possible variants:
      - #ClosedPublicView
      - #ClosedAdapterInput
      - #ClosedGeneratedSnapshot

  Defaults

  - Implemented:
      - #Resource.visibility: #VisibilityTier | *"internal"
      - #Gate.required: bool | *true
      - #Witness.required: bool | *true

  - Possible variants:
      - #DefaultedPolicy
      - #DefaultedProjectionOptions

  Strategy / Variant Selection

  - Weakly implemented:
      - #VisibilityTier
      - #GeneratedOutputResourceRole

  - Not really implemented:
      - #OperationKind is open, not a closed strategy.

  - Possible variants:
      - #OperationVariant
      - #ProjectionMode
      - #ValidationMode

  Adapter

  - Not implemented in meta/kernel.cue.
  - Adjacent implemented pieces:
      - #CueSelectorExpr
      - #NoWideningProof
      - #ClosedObligationState

  - Possible variants:
      - #ToolAdapter
      - #CueExportAdapter
      - #CodeIntelAdapter
      - #JSONSchemaAdapter

  Command

  - Not implemented in meta/kernel.cue.
  - Possible variants:
      - #CueCommand
      - #CueEvalCommand
      - #CueExportCommand
      - #CueVetCommand
      - #CommandFixture

  Selector / Search

  - Partially implemented:
      - #CueSelectorExpr

  - Possible variants:
      - #SelectorRef
      - #SelectorTarget
      - #PathMatch
      - #SelectorCoverageProof

  Release / Version-Gated Feature

  - Implemented in patterns/schema.cue, not meta/kernel.cue:
      - #FeatureMaturity
      - #CueFeatureNote
      - #CueVersionCoverage
      - cueVersionCoverage["v0.17.0"]

  - Possible variants:
      - #ExperimentGate
      - #ReleaseFeatureMatrix
      - #CompatibilityWatchItem
