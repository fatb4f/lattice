# Patterns To Implement

This is a promotion backlog, not a flat dump of everything that could live in
`patterns/`. Each candidate is distilled to the idiomatic CUE primitives it
teaches, the reusable pattern it should become, and the placement it should be
promoted to.

Repository shape:

```text
meta/kernel.cue
  = small reusable proof kernel

patterns/
  = executable pattern catalogue:
    problem -> abstraction -> fixtures -> validation -> promotion rule

profiles/
  = domain/profile mappings:
    control, codex, dotfiles, semagrams, delivery, adapters, etc.

sources/
  = reference/source registry, not authority-bearing implementation
```

## Promotion Contract

Every accepted pattern should satisfy this catalogue shape before it is treated
as implemented:

```cue
#PatternEntry: close({
	id:      #KebabIdentifier
	name:    #NonEmptyString
	family:  #PatternFamily
	status:  "implemented" | "partial" | "planned" | "deferred"
	problem: #NonEmptyString
	rule:    #NonEmptyString

	abstraction: _
	canonical:   _
	positive:    _
	negative:    _

	checks: {
		pass?: [...#CueSelectorExpr]
		fail?: [...#CueSelectorExpr]
	}

	promotion: close({
		target: "meta-kernel" | "patterns" | "profile" | "adapter" | "deferred"
		reason: #NonEmptyString
	})
})
```

## Control Profile Track

Closed-loop feedback is a parallel profile, not part of the base pattern entry.
`patterns/` stays focused on pure idiomatic CUE. `profiles/control/` catalogs
techniques for generating closed-loop feedback from those idiomatic patterns.

The profile-level overlay is:

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
		invariants:  [...#NonEmptyString]
	})

	sensors: [string]: close({
		kind:     "selector" | "projection" | "fixture" | "evidence" | "command-output"
		target:   #NonEmptyString
		coverage: "full" | "partial" | "sentinel"
	})

	controller: close({
		kind:       "constructor" | "validator" | "transition" | "gate" | "adapter"
		policyRef:  #NonEmptyString
		errorModes: [...#NonEmptyString]
	})

	actuators?: [string]: close({
		kind:   "command" | "adapter" | "codegen" | "mutation" | "publication"
		target: #NonEmptyString
		effect: "read" | "write" | "create" | "delete" | "publish"
	})

	feedback: close({
		errorSignal: #NonEmptyString
		proofRef:    #NonEmptyString
		stability:   "idempotent" | "monotone" | "convergent" | "bounded" | "unchecked"
	})
})
```

Each control technique references a pattern and explains how to derive:

- plant: what system or state is being controlled
- setpoint: the desired authority contract or invariant
- sensors: selectors, projections, fixtures, evidence, or command output
- controller: constructor, validator, transition, gate, or adapter policy
- actuators: optional command, adapter, codegen, mutation, or publication effects
- feedback: error signal, proof reference, and stability claim

Every mature pattern should eventually have a control-profile technique that can
explain it as:

```text
authority state
  -> projection / adapter / transition
  -> observed output
  -> proof / fixture / evidence
  -> admissibility decision
```

This keeps the idiom catalogue simple while still making closed-loop feedback a
first-class engineering track.

Canonical families:

```cue
#PatternFamily:
	"schema" |
	"constructor" |
	"closed-boundary" |
	"projection-safety" |
	"fixture-harness" |
	"state-transition" |
	"reference-graph" |
	"adapter-contract" |
	"command-contract" |
	"selector-coverage" |
	"version-gate" |
	"evidence-stream"
```

## Current Fit

The kernel foundations are real. `meta/kernel.cue` already owns the reusable
surface for `#Resource`, `#Operation`, `#Gate`, `#Witness`, map/state layers,
`#ObligationState`, `#ClosedObligationState`, `#MakeClosedObligationState`,
keyset helpers, `_operationRefProof`, and `#NoWideningProof`.

The next gap is promotion discipline: every pattern needs a problem, reusable
abstraction, canonical fixture, positive fixture, negative fixture, validation
selectors, and promotion rule.

## Merge Rules

Collapse overlapping candidates before implementation:

- `Projection / No-Widening` + `Sorting / Stable Keysets` + `Closed Boundary`
  -> `projection-safety`.
- `Validator / Fixture Pair` + `Negative Fixture` + `Expected Failure Probe` +
  `Generated Assertion Matrix` -> `fixture-harness`.
- `Graph / References` + `Typed Resource Graph` + `Graph Analysis` +
  `Reachability / Cycle / DAG proof` -> `reference-graph`.
- `Adapter` + `Command` + `Provider Binding` + `Execution Plan` ->
  `adapter-contract` and `command-contract`.
- `State` + `State Transition` + `Trace Closure` + `Configuration Trace` ->
  `state-transition` and later trace patterns.

## P0 - Implement Now

### Constructor / Builder

- Family: `constructor`.
- Decision: keep.
- Placement: `patterns/constructors.cue`, with stable pieces factored into
  `meta/kernel.cue` only when reused by multiple pattern families.
- Idiomatic CUE primitives: definitions, unification, parameter structs, hidden
  helper fields, comprehensions, `close`, and bottom-producing probes.
- Pattern: define `#MakeX` constructors that accept narrow input contracts and
  produce closed, checked outputs with derived evidence.
- Implemented variants: `#MakeClosedObligationState`,
  `#MakeUncheckedNegativeFixture`, `#MakeNegativeFixtureProbeBinding`,
  `#MakeNegativeFixture`, `#MakeNegativeFixtureCheck`,
  `#MakeNegativeFixtureSpec`.
- Next variants: `#MakeClosedResourceMap`, `#MakeClosedOperationMap`,
  `#MakeProjection`.

### Schema / Data Structures

- Family: `schema`.
- Decision: keep.
- Placement: `meta/kernel.cue` for generic closed records; `patterns/` for
  catalogue entries and domain-neutral examples.
- Idiomatic CUE primitives: definitions, closed structs, typed maps, required
  fields, optional fields, disjunctions, defaults, and reusable field schemas.
- Pattern: define authority-bearing records as small closed contracts, then
  compose them into maps and states.
- Implemented variants: `#Resource`, `#Operation`, `#Gate`, `#Witness`,
  `#ResourceMap`, `#OperationMap`, `#GateMap`, `#WitnessMap`,
  `#ObligationState`, `#ClosedObligationState`.
- Next variants: strengthen `#PatternEntry`, `#SourceRef`, `#DriftRule`.

### Projection / No-Widening

- Family: `projection-safety`.
- Decision: keep.
- Placement: `patterns/projections.cue`; keep only generic key/ref proof
  helpers in `meta/kernel.cue`.
- Idiomatic CUE primitives: field selection, map comprehensions, key-set proofs,
  list sorting, equality constraints, closed projections, and conflict probes.
- Pattern: derive public or generated views from authority data and prove the
  derived view does not introduce new authority, keys, or refs.
- Implemented variants: `#NoWideningProof`, `#StateKeySet`,
  `#OperationRefKeySet`.
- Next variants: `#ProjectionKeySet`, `#PublicResourceProjection`,
  `#NoGeneratedAuthorityProof`, `#ProjectionCompatibilityProof`.

### Validator / Fixture Pair

- Family: `fixture-harness`.
- Decision: keep.
- Placement: `patterns/fixtures.cue` and `patterns/checks.cue`.
- Idiomatic CUE primitives: positive examples, negative examples, bottom checks,
  probe bindings, selectors, fixtures as data, and executable validation specs.
- Pattern: document every rule with a canonical valid example, a positive
  accepted fixture, and a negative rejected fixture.
- Implemented variants: `#NegativeFixtureSpec`, `#NegativeFixture`,
  `#UncheckedNegativeFixture`, `#NegativeFixtureProbeSpec`,
  `#NegativeFixtureConflictProbe`, `#NegativeFixtureProbeBinding`,
  `#NegativeFixtureCheck`.
- Next variants: `#PositiveFixture`, `#FixtureMatrix`,
  `#ExpectedFailureProbe`, `#ExportableInvalidExample`, `#CommandFixture`.

### Closed Boundary

- Family: `projection-safety`.
- Decision: keep.
- Placement: `patterns/closedness.cue` and projection handoff checks.
- Idiomatic CUE primitives: `close`, closed definitions, closed generated
  snapshots, explicit adapter inputs, and extra-field probes.
- Pattern: close authority boundaries at every adapter, projection, and export
  handoff so generated data cannot silently widen the model.
- Implemented variants: `#Resource`, `#Operation`, `#Gate`, `#Witness`,
  `#NegativeFixtureSpec`, `#NegativeFixtureProbeBinding`,
  `#NoWideningProof`.
- Next variants: `#ClosedPublicView`, `#ClosedAdapterInput`,
  `#ClosedGeneratedSnapshot`.

### Sorting / Stable Keysets

- Family: `projection-safety`.
- Decision: keep.
- Placement: shared helper in `meta/kernel.cue` when generic; pattern examples in
  `patterns/projections.cue`.
- Idiomatic CUE primitives: `list.SortStrings`, `list.Contains`,
  map-to-list comprehensions, deterministic key lists, and key-set equality.
- Pattern: normalize unordered maps into stable key sets before comparing,
  projecting, or checking coverage.
- Implemented variants: `#StateKeySet`, `#OperationRefKeySet`.
- Next variants: `#SortedMapKeys`, `#StableKeySetEquality`,
  `#RequiredCoverageProof`.

### Command

- Family: `command-contract`.
- Decision: promote.
- Placement: `patterns/commands.cue` or `patterns/adapters/commands.cue`.
- Idiomatic CUE primitives: command records, argument lists, environment maps,
  expected outputs, fixture-backed checks, and adapter-specific projections.
- Pattern: represent `cue vet`, `cue eval`, `cue export`, and similar
  invocations as declarative data with declared inputs, outputs, gates, and
  generated artifacts.
- Next variants: `#CueCommand`, `#CueEvalCommand`, `#CueExportCommand`,
  `#CueVetCommand`, `#CommandFixture`.

### Adapter

- Family: `adapter-contract`.
- Decision: promote.
- Placement: `patterns/adapters/`.
- Idiomatic CUE primitives: input/output contracts, selector expressions,
  projection proofs, closed adapter inputs, command bindings, and compatibility
  checks.
- Pattern: place every external tool behind a typed adapter contract that states
  what it can read, write, generate, and prove.
- Adjacent implemented variants: `#CueSelectorExpr`, `#NoWideningProof`,
  `#ClosedObligationState`.
- Next variants: `#ToolAdapter`, `#CueExportAdapter`, `#CodeIntelAdapter`,
  `#JSONSchemaAdapter`, `#AdapterCommandPlan`, `#AdapterEvidence`.

### Selector / Search

- Family: `selector-coverage`.
- Decision: promote.
- Placement: `patterns/selectors.cue`.
- Idiomatic CUE primitives: selector strings, path fields, target refs,
  match constraints, coverage proofs, and negative missing-target probes.
- Pattern: make every query or selector an addressable contract with a declared
  target and proof of coverage.
- Partial variants: `#CueSelectorExpr`.
- Next variants: `#SelectorTarget`, `#SelectorRef`, `#PathMatch`,
  `#SelectorCoverageProof`.

### State Transition

- Family: `state-transition`.
- Decision: promote.
- Placement: `patterns/state_transitions.cue`; promote only the primitive once it
  is reused across graph, command, and evidence patterns.
- Idiomatic CUE primitives: closed records, lifecycle status disjunctions,
  transition inputs, transition results, operation refs, before/after proofs.
- Pattern: model mutation as explicit before/after transition data, not implicit
  state replacement.
- Implemented variants: `#ObligationState`, `#ClosedObligationState`.
- Partial variants: `_operationRefProof`.
- Next variants: `#TransitionInput`, `#StateTransition`,
  `#TransitionResult`, `#BeforeAfterProof`, `#AllowedOperation`.

## P1 - Implement After P0

### Typed Resource Graph

- Family: `reference-graph`.
- Decision: implement after selector, projection, and fixture contracts.
- Placement: `patterns/graph/typed_resource.cue`.
- Idiomatic CUE primitives: node records, type-set lists, dependency sets, keyed
  resource maps, membership checks, and provider matching constraints.
- Pattern: give graph validation a concrete resource-level input model where
  nodes declare types and dependencies explicitly.
- Variants: `#TypedResource`, `#TypeSet`, `#DependencySet`, `#ResourceGraph`.

### Graph Analysis

- Family: `reference-graph`.
- Decision: implement after typed graph.
- Placement: `patterns/graph/analysis.cue`.
- Idiomatic CUE primitives: typed nodes, dependency edges, graph projections,
  reachability sets, cycle probes, critical-path derivations, and diff records.
- Pattern: turn resource refs into an analyzable dependency graph that supports
  impact, reachability, critical path, cycle rejection, and topology diff checks.
- Variants: `#DependencyGraph`, `#ImpactQuery`, `#BlastRadius`,
  `#CriticalPath`, `#CycleRejectionProof`, `#GraphDiff`.

### Provider / Adapter Binding

- Family: `adapter-contract`.
- Decision: implement after adapter and command contracts exist.
- Placement: `patterns/adapters/provider_binding.cue`.
- Idiomatic CUE primitives: type sets, provider maps, overlap constraints,
  command templates, resolved actions, and adapter command plans.
- Pattern: bind external providers to resources by declared type overlap and
  resolve actions at compile time.
- Variants: `#ProviderBinding`, `#TypeOverlapMatch`, `#ActionDef`,
  `#ResolvedAction`, `#AdapterCommandPlan`.

### Static Projection Surface

- Family: `projection-safety`.
- Decision: implement after projection safety.
- Placement: `patterns/projections/static_surface.cue`.
- Idiomatic CUE primitives: export targets, projection endpoints, generated
  response maps, no-widening checks, and build-output fixtures.
- Pattern: expose static JSON-LD, API, wiki, OpenAPI, or dashboard surfaces as
  precomputed projections with bounded authority.
- Variants: `#StaticExportSurface`, `#ProjectionEndpoint`,
  `#PrecomputedResponseSet`, `#ExportMatrix`.

### Role-Scoped Views

- Family: `projection-safety`.
- Decision: implement after static projection surface.
- Placement: `patterns/projections/role_view.cue`.
- Idiomatic CUE primitives: visibility fields, role enums, projection filters,
  read-only views, publication surfaces, and no-authority proofs.
- Pattern: generate audience-specific read views without promoting those views
  into source authority.
- Variants: `#RoleView`, `#VisibilityProjection`, `#PublicationSurface`,
  `#ReadOnlyProjection`.

### External Spec Coverage Matrix

- Family: `version-gate`.
- Decision: implement after pattern catalogue contract.
- Placement: `patterns/coverage/spec_matrix.cue`.
- Idiomatic CUE primitives: spec-keyed maps, coverage-depth enums, status
  fields, source refs, projection refs, and required-coverage proofs.
- Pattern: track how deeply each external spec is represented and which
  projection or pattern proves that coverage.
- Variants: `#SpecCoverage`, `#SpecProjection`, `#CoverageDepth`,
  `#ExternalVocabularyProjection`.

### Release / Version-Gated Feature

- Family: `version-gate`.
- Decision: keep.
- Placement: `patterns/schema.cue`, then `patterns/coverage/`.
- Idiomatic CUE primitives: version-keyed maps, feature records, status
  disjunctions, experimental gates, compatibility notes, and watch items.
- Pattern: record language and toolchain features as versioned contracts so
  patterns depend on features explicitly.
- Implemented variants: `#FeatureMaturity`, `#CueFeatureNote`,
  `#CueVersionCoverage`, `cueVersionCoverage["v0.17.0"]`.
- Next variants: `#ExperimentGate`, `#ReleaseFeatureMatrix`,
  `#CompatibilityWatchItem`.

## P2 - Theory-Backed Families

### Domain Product / Solver Cooperation

- Family: `schema`.
- Decision: keep as design target; do not implement first.
- Placement: deferred pattern family, later feeding `meta/kernel.cue` only if it
  becomes a reusable proof primitive.
- Idiomatic CUE primitives: ordered domain records, component maps, product
  composition, meet-like unification, admissibility checks, and projection proofs.
- Pattern: compose CUE, compiler, LSP, VCS, replay, scope, and evidence domains
  into one product contract admitted only when every domain agrees.
- Variants: `#DomainProduct`, `#DomainComponent`, `#AdmissibilityProduct`,
  `#CooperatingSolverProof`.

### Trace Closure / Collecting Semantics

- Family: `state-transition`.
- Decision: implement only after `#StateTransition` and `#ReplayProof`.
- Placement: later `patterns/traces/`.
- Idiomatic CUE primitives: ordered trace lists, step schemas, list
  comprehensions, closure operators as derived fields, replay fixtures, and
  accepted/rejected trace probes.
- Pattern: validate lifecycle behavior by collecting observations into a trace
  and proving replay reaches the same closed acceptance state.
- Variants: `#Trace`, `#TraceStep`, `#TraceClosure`, `#TraceAcceptance`,
  `#ReplayProof`.

### Configuration Traces / Dynamic Architecture

- Family: `state-transition`.
- Decision: later; depends on graph state and transition trace.
- Placement: later `patterns/traces/` or domain profile.
- Idiomatic CUE primitives: graph states, transition traces, topology refs,
  temporal assertions, report projections, and graph consistency proofs.
- Pattern: express changing topology as configuration states with assertions at
  each step and across generated reports.
- Variants: `#ConfigurationTrace`, `#TopologyState`, `#TopologyAssertion`,
  `#GraphStateProof`, `#ReportGraphConsistencyProof`.

### Symbolic Approximation

- Family: `adapter-contract`.
- Decision: relevant to Semagrams lowering; implement under adapter/lowering
  profile after adapter contracts are stable.
- Placement: `profiles/semagrams/` or `patterns/adapters/lowering.cue`.
- Idiomatic CUE primitives: partial values, constraints as IR, lowering adapters,
  projection boundaries, evidence records, and compatibility proofs.
- Pattern: use CUE as symbolic approximation that can be analyzed, lowered, and
  exported while preserving source authority.
- Variants: `#SymbolicApproximation`, `#ContractIR`, `#LoweringAdapter`,
  `#AdapterEvidence`.

### Information Order / Definedness

- Family: `state-transition`.
- Decision: good kernel extension, but wait until status semantics are needed.
- Placement: deferred; possible future `meta/kernel.cue` primitive.
- Idiomatic CUE primitives: status enums, lattice-like state records,
  bottom/error states, progress order fields, acceptance states, and monotone
  refinement checks.
- Pattern: distinguish absent, unknown, partial, accepted, rejected, and bottom
  states with explicit information and progress ordering.
- Variants: `#InformationState`, `#DefinednessOrder`, `#ProgressOrder`,
  `#AcceptanceState`.

### Monotone Evidence

- Family: `evidence-stream`.
- Decision: strong for reports and monitor loops; P2/P3.
- Placement: `patterns/evidence/` after fixture, command, and adapter evidence
  contracts exist.
- Idiomatic CUE primitives: append-only lists, keyed evidence maps, timestamped
  observations, monotone refinements, convergence proofs, and repeated-run
  fixtures.
- Pattern: accept new observations only when they refine or extend evidence
  without invalidating previous accepted facts.
- Variants: `#EvidenceStream`, `#MonotoneObservation`, `#AppendOnlyEvidence`,
  `#ConvergenceProof`.

### Security Lattice Extension

- Family: `evidence-stream`.
- Decision: defer until publication and secrets become first-class.
- Placement: later profile or publication policy package.
- Idiomatic CUE primitives: visibility tiers, policy maps, publication surfaces,
  secret refs, role views, and dynamic tier extension constraints.
- Pattern: model visibility and publication authority as an extensible lattice
  when evidence, reports, secrets, and access control require it.
- Variants: `#SecurityTier`, `#PublicationSurface`,
  `#EvidenceVisibilityPolicy`.

### Bilattice / Four-Valued Logic

- Family: `evidence-stream`.
- Decision: defer; useful for conflicting evidence, not base kernel.
- Placement: later evidence profile.
- Idiomatic CUE primitives: truth-state enums, knowledge-state enums,
  contradiction records, conflict probes, and acceptance policies for unknown or
  inconsistent evidence.
- Pattern: represent unknown, contradiction, both, and neither as operational
  states when evidence disagreement needs semantics.
- Variants: `#TruthState`, `#KnowledgeState`, `#ContradictionProof`.

## P3 - Domain Profiles

KubeVela and Timoni candidates are useful case studies, but they should not
pollute `meta/kernel.cue`. They promote into `profiles/` or adapters once P0/P1
contracts exist.

### Application Delivery Workflow

- Family: `state-transition`.
- Decision: domain profile.
- Placement: `profiles/delivery/`.
- Idiomatic CUE primitives: step records, ordered lists, command bindings,
  lifecycle gates, graph-derived order, and transition results.
- Pattern: model render, orchestrate, and deploy as an explicit workflow contract
  with validation gates at each step.
- Variants: `#DeliveryWorkflow`, `#WorkflowStep`, `#RenderStep`, `#DeployStep`,
  `#WorkflowGate`.

### Application Model / Component Traits

- Family: `schema`.
- Decision: domain profile.
- Placement: `profiles/oam/` or `profiles/delivery/`.
- Idiomatic CUE primitives: component definitions, trait overlays, policy maps,
  placement constraints, defaults, and closed composed application views.
- Pattern: represent applications as components plus composable traits and
  policies, keeping operational concerns separate from base resource shape.
- Variants: `#Application`, `#Component`, `#Trait`, `#Policy`,
  `#PlacementPolicy`.

### Progressive Rollout

- Family: `state-transition`.
- Decision: domain profile.
- Placement: `profiles/delivery/rollout.cue`.
- Idiomatic CUE primitives: staged step lists, status enums, promotion gates,
  verification refs, rollout strategies, and before/after state proofs.
- Pattern: encode canary, blue-green, and staged rollout semantics as state
  transitions gated by verification.
- Variants: `#RolloutPlan`, `#CanaryStep`, `#BlueGreenPlan`,
  `#VerificationGate`, `#PromotionGate`.

### Multi-Cluster Placement

- Family: `reference-graph`.
- Decision: domain profile.
- Placement: `profiles/delivery/placement.cue`.
- Idiomatic CUE primitives: target maps, environment records, placement rules,
  topology constraints, selector refs, and compatibility checks.
- Pattern: bind deployable resources to clusters, clouds, or environments using
  explicit placement policy and topology-aware validation.
- Variants: `#ClusterTarget`, `#PlacementRule`, `#EnvironmentTarget`,
  `#MultiClusterPlan`.

### Module / Package Contract

- Family: `schema`.
- Decision: domain profile.
- Placement: `profiles/modules/`.
- Idiomatic CUE primitives: module definitions, semantic-version constraints,
  artifact refs, signed artifact metadata, schema boundaries, and source refs.
- Pattern: treat reusable CUE modules as versioned, typed, signed package
  contracts with explicit distribution boundaries.
- Variants: `#Module`, `#ModuleSchema`, `#ModuleArtifact`,
  `#SemanticVersion`, `#SignedArtifact`.

### Instance / Release

- Family: `state-transition`.
- Decision: domain profile.
- Placement: `profiles/releases/`.
- Idiomatic CUE primitives: instance records, release state, install/upgrade
  plans, rollback plans, transition inputs, and lifecycle result proofs.
- Pattern: separate reusable module authority from concrete installed state and
  model install, upgrade, uninstall, and rollback as explicit release actions.
- Variants: `#Instance`, `#Release`, `#InstallPlan`, `#UpgradePlan`,
  `#UninstallPlan`, `#RollbackPlan`.

### Bundle Composition

- Family: `schema`.
- Decision: domain profile.
- Placement: `profiles/bundles/`.
- Idiomatic CUE primitives: module refs, config maps, list/map comprehensions,
  runtime input records, projection boundaries, and closed bundle outputs.
- Pattern: compose multiple modules and configurations into a deployable unit
  without collapsing each module's authority boundary.
- Variants: `#Bundle`, `#BundleModuleRef`, `#BundleConfig`,
  `#BundleRuntimeInput`.

### Environment / Runtime Values

- Family: `closed-boundary`.
- Decision: domain profile.
- Placement: `profiles/runtime/`.
- Idiomatic CUE primitives: environment configs, runtime value refs, secret refs,
  late-bound inputs, hidden fields, and public/private projection boundaries.
- Pattern: distinguish compile-time authority from late-bound runtime inputs and
  secret-bearing surfaces.
- Variants: `#EnvironmentConfig`, `#RuntimeValue`, `#SecretRef`,
  `#ConfigSource`, `#LateBoundInput`.

### CRD Schema Import / External Schema Adapter

- Family: `adapter-contract`.
- Decision: adapter/profile, not kernel.
- Placement: `profiles/kubernetes/` or `adapters/crd/`.
- Idiomatic CUE primitives: imported schema records, adapter inputs, custom
  resource templates, schema compatibility proofs, closed projections, and
  invalid-schema probes.
- Pattern: import external CRD schemas through an adapter that proves
  compatibility before custom resources are admitted into application contracts.
- Variants: `#ExternalSchemaImport`, `#CRDSchemaAdapter`,
  `#CustomResourceTemplate`, `#SchemaCompatibilityProof`.

### Supply Chain / Addon Catalog

- Family: `schema`.
- Decision: domain profile.
- Placement: `profiles/supply-chain/`.
- Idiomatic CUE primitives: catalog maps, capability records, addon refs,
  binding constraints, provider refs, version/status fields, and coverage checks.
- Pattern: model reusable platform capabilities as catalog entries that can be
  bound to applications or environments under explicit compatibility rules.
- Variants: `#Addon`, `#Capability`, `#CatalogEntry`, `#CapabilityBinding`.

## High-Signal Next Set

Implement these first:

1. `#PositiveFixture`
2. `#FixtureMatrix`
3. `#ProjectionKeySet`
4. `#ClosedPublicView`
5. `#NoGeneratedAuthorityProof`
6. `#CueCommand`
7. `#ToolAdapter`
8. `#SelectorTarget`
9. `#SelectorCoverageProof`
10. `#StateTransition`

This gives the repository a control loop:

```text
authority state
  -> constructor
  -> closed state
  -> projection
  -> no-widening proof
  -> fixture matrix
  -> command plan
  -> adapter evidence
  -> completion/report projection
```

## Kernel Boundary

Keep `meta/kernel.cue` small:

- identifiers
- closed records
- ref sets
- resource, operation, gate, witness
- state maps
- closed state constructor
- keyset helpers
- no-widening proof
- positive and negative fixture primitives
- transition primitive, once stable

Keep domain specifics out of `meta/kernel.cue`:

- KubeVela
- Timoni
- CRDs
- OpenAPI
- JSON Schema encoder details
- Codex-specific action kinds
- dotfiles-specific roles
- Semagrams-specific lowering terms
- provider-specific command templates
