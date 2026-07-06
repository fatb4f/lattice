# Patterns To Implement

Each candidate below is distilled into the idiomatic CUE primitives it should
teach and the reusable pattern it should become. The names under implemented,
partial, weak, and proposed variants are the implementation vocabulary to map
into `patterns/` and `meta/kernel.cue`.

## Kernel-Level Patterns

### Constructor / Builder

- Idiomatic CUE primitives: definitions, unification, parameter structs, hidden
  helper fields, comprehensions, `close`, and bottom-producing negative probes.
- Pattern: define `#MakeX` constructors that accept a narrow input contract and
  produce a closed, checked output with derived evidence.
- Implemented variants: `#MakeClosedObligationState`,
  `#MakeUncheckedNegativeFixture`, `#MakeNegativeFixtureProbeBinding`,
  `#MakeNegativeFixture`, `#MakeNegativeFixtureCheck`,
  `#MakeNegativeFixtureSpec`.
- Proposed variants: `#MakeClosedResourceMap`, `#MakeClosedOperationMap`,
  `#MakeProjection`, `#MakeTransitionResult`.

### Schema / Data Structures

- Idiomatic CUE primitives: definitions, closed structs, typed maps, required
  fields, optional fields, disjunctions, defaults, and reusable field schemas.
- Pattern: define authority-bearing records as small closed contracts, then
  compose them into maps and states instead of relying on untyped free-form data.
- Implemented variants: `#Resource`, `#Operation`, `#Gate`, `#Witness`,
  `#ResourceMap`, `#OperationMap`, `#GateMap`, `#WitnessMap`,
  `#ObligationState`, `#ClosedObligationState`.
- Proposed variants: `#PatternEntry`, `#SourceRef`, `#ControlSurface`,
  `#DriftRule`.

### Projection / No-Widening

- Idiomatic CUE primitives: field selection, map comprehensions, key-set proofs,
  list sorting, equality constraints, closed projections, and conflict probes.
- Pattern: derive public or generated views from authority data and prove the
  derived view does not introduce authority, keys, or refs that were not present
  upstream.
- Implemented variants: `#NoWideningProof`, `#StateKeySet`,
  `#OperationRefKeySet`.
- Proposed variants: `#PublicResourceProjection`, `#ProjectionKeySet`,
  `#NoGeneratedAuthorityProof`, `#ProjectionCompatibilityProof`.

### Validator / Fixture Pair

- Idiomatic CUE primitives: positive examples, negative examples, bottom checks,
  probe bindings, selectors, fixtures as data, and executable validation specs.
- Pattern: pair each rule with an accepted fixture and a rejected fixture so the
  rule is documented by executable CUE rather than prose only.
- Implemented variants: `#NegativeFixtureSpec`, `#NegativeFixture`,
  `#UncheckedNegativeFixture`, `#NegativeFixtureProbeSpec`,
  `#NegativeFixtureConflictProbe`, `#NegativeFixtureProbeBinding`,
  `#NegativeFixtureCheck`.
- Proposed variants: `#PositiveFixture`, `#FixtureMatrix`,
  `#ExpectedFailureProbe`, `#ExportableInvalidExample`.

### State

- Idiomatic CUE primitives: closed records, status disjunctions, lifecycle fields,
  derived fields, transition inputs, transition results, and before/after proofs.
- Pattern: model lifecycle state as a closed contract and express mutation as
  explicit transition data instead of implicit state replacement.
- Implemented variants: `#ObligationState`, `#ClosedObligationState`.
- Partial variants: `_operationRefProof`.
- Proposed variants: `#StateTransition`, `#TransitionInput`,
  `#TransitionResult`, `#AllowedOperation`, `#BeforeAfterProof`.

### Graph / References

- Idiomatic CUE primitives: ref sets, keyed maps, comprehensions over refs,
  membership constraints, sorted key sets, and negative missing-ref probes.
- Pattern: treat refs as first-class graph edges and prove that every operation
  edge resolves to an allowed resource, gate, witness, or generated output.
- Implemented variants: `#RefSet`, `#Operation.reads`, `#Operation.writes`,
  `#Operation.creates`, `#Operation.requiresGates`,
  `#Operation.requiresWitnesses`, `_operationRefProof`.
- Proposed variants: `#ResourceGraph`, `#OperationGraph`,
  `#ReachabilityProof`, `#CycleRejectionProbe`, `#DAGProof`.

### Sorting / Stable Keysets

- Idiomatic CUE primitives: `list.SortStrings`, `list.Contains`,
  map-to-list comprehensions, deterministic key lists, and key-set equality.
- Pattern: normalize unordered maps into stable key sets before comparing,
  projecting, or checking coverage.
- Implemented variants: `#StateKeySet`, `#OperationRefKeySet`.
- Proposed variants: `#SortedMapKeys`, `#StableKeySetEquality`,
  `#RequiredCoverageProof`.

### Closed Boundary

- Idiomatic CUE primitives: `close`, closed definitions, closed generated
  snapshots, explicit adapter inputs, and bottom-producing extra-field probes.
- Pattern: close the authority boundary at every handoff so generated or
  adapter-owned data cannot silently widen the model.
- Implemented variants: `#Resource`, `#Operation`, `#Gate`, `#Witness`,
  `#NegativeFixtureSpec`, `#NegativeFixtureProbeBinding`,
  `#NoWideningProof`.
- Proposed variants: `#ClosedPublicView`, `#ClosedAdapterInput`,
  `#ClosedGeneratedSnapshot`.

### Defaults

- Idiomatic CUE primitives: default markers, disjunctions, closed enums, required
  fields with default values, and fixture checks for default materialization.
- Pattern: encode policy defaults at the schema boundary while keeping the
  accepted value space explicit.
- Implemented variants: `#Resource.visibility: #VisibilityTier | *"internal"`,
  `#Gate.required: bool | *true`, `#Witness.required: bool | *true`.
- Proposed variants: `#DefaultedPolicy`, `#DefaultedProjectionOptions`.

### Strategy / Variant Selection

- Idiomatic CUE primitives: closed disjunctions, open extension points, tagged
  unions, defaults, and explicit experimental gates.
- Pattern: model variant selection as data with bounded choices, not as ad hoc
  strings hidden in operation bodies.
- Weak variants: `#VisibilityTier`, `#GeneratedOutputResourceRole`.
- Gap: `#OperationKind` is open and is not yet a closed strategy.
- Proposed variants: `#OperationVariant`, `#ProjectionMode`,
  `#ValidationMode`.

### Adapter

- Idiomatic CUE primitives: input/output contracts, selector expressions,
  projection proofs, closed adapter inputs, command bindings, and compatibility
  checks.
- Pattern: place every external tool behind a typed adapter contract that states
  what it can read, write, generate, and prove.
- Adjacent implemented variants: `#CueSelectorExpr`, `#NoWideningProof`,
  `#ClosedObligationState`.
- Proposed variants: `#ToolAdapter`, `#CueExportAdapter`,
  `#CodeIntelAdapter`, `#JSONSchemaAdapter`.

### Command

- Idiomatic CUE primitives: command records, argument lists, environment maps,
  expected outputs, fixture-backed checks, and adapter-specific projections.
- Pattern: represent invocations as declarative data so validation can reason
  about inputs, outputs, gates, and generated artifacts before execution.
- Proposed variants: `#CueCommand`, `#CueEvalCommand`, `#CueExportCommand`,
  `#CueVetCommand`, `#CommandFixture`.

### Selector / Search

- Idiomatic CUE primitives: selector strings, path fields, target refs,
  match constraints, coverage proofs, and negative missing-target probes.
- Pattern: make every query or selector an addressable contract with a declared
  target and proof of coverage.
- Partial variants: `#CueSelectorExpr`.
- Proposed variants: `#SelectorRef`, `#SelectorTarget`, `#PathMatch`,
  `#SelectorCoverageProof`.

### Release / Version-Gated Feature

- Idiomatic CUE primitives: version-keyed maps, feature records, status
  disjunctions, experimental gates, compatibility notes, and watch items.
- Pattern: record language and toolchain features as versioned contracts so
  patterns can depend on features explicitly.
- Implemented variants in `patterns/schema.cue`: `#FeatureMaturity`,
  `#CueFeatureNote`, `#CueVersionCoverage`,
  `cueVersionCoverage["v0.17.0"]`.
- Proposed variants: `#ExperimentGate`, `#ReleaseFeatureMatrix`,
  `#CompatibilityWatchItem`.

## Theory-Derived Patterns

### Domain Product / Solver Cooperation

- Idiomatic CUE primitives: ordered domain records, component maps, product
  composition, meet-like unification, admissibility checks, and projection proofs.
- Pattern: compose CUE, compiler, LSP, VCS, replay, scope, and evidence domains
  into one product contract that admits a state only when every participating
  domain agrees.
- Source concepts: abstract domains as ordered structures; solver cooperation as
  domain/product composition.
- Proposed variants: `#DomainProduct`, `#DomainComponent`,
  `#AdmissibilityProduct`, `#CooperatingSolverProof`.

### Trace Closure / Collecting Semantics

- Idiomatic CUE primitives: ordered trace lists, step schemas, list
  comprehensions, closure operators as derived fields, replay fixtures, and
  accepted/rejected trace probes.
- Pattern: validate lifecycle behavior by collecting all constraint observations
  into a trace and proving that replay reaches the same closed acceptance state.
- Source concepts: closure operators over sequences of constraints; collecting
  semantics over constraint traces.
- Proposed variants: `#Trace`, `#TraceStep`, `#TraceClosure`,
  `#TraceAcceptance`, `#ReplayProof`.

### Configuration Traces / Dynamic Architecture

- Idiomatic CUE primitives: graph states, transition traces, topology refs,
  temporal assertions, report projections, and graph consistency proofs.
- Pattern: express changing topology as a sequence of configuration states with
  assertions that must hold at each step and across generated reports.
- Source concepts: configuration traces; trace assertions over changing
  topology.
- Proposed variants: `#ConfigurationTrace`, `#TopologyState`,
  `#TopologyAssertion`, `#GraphStateProof`, `#ReportGraphConsistencyProof`.

### Symbolic Approximation

- Idiomatic CUE primitives: partial values, constraints as IR, lowering adapters,
  projection boundaries, evidence records, and compatibility proofs.
- Pattern: use CUE as a symbolic approximation language that can be analyzed,
  lowered, and exported while preserving the original contract authority.
- Source concept: symbolic approximation language as both abstraction and
  analyzable input.
- Proposed variants: `#SymbolicApproximation`, `#ContractIR`,
  `#LoweringAdapter`, `#AdapterEvidence`.

### Information Order / Definedness

- Idiomatic CUE primitives: status enums, lattice-like state records,
  bottom/error states, progress order fields, acceptance states, and monotone
  refinement checks.
- Pattern: distinguish absent, unknown, partial, accepted, rejected, and bottom
  states with explicit information and progress ordering.
- Source concepts: information order; definedness and progress order.
- Proposed variants: `#InformationState`, `#DefinednessOrder`,
  `#ProgressOrder`, `#AcceptanceState`.

### Monotone Evidence

- Idiomatic CUE primitives: append-only lists, keyed evidence maps, timestamped
  observations, monotone refinements, convergence proofs, and repeated-run
  fixtures.
- Pattern: accept new observations only when they refine or extend evidence
  without invalidating previous accepted facts.
- Source concepts: logical monotonicity; monotone streaming order; LVars, CRDT,
  and Datalog lineage.
- Proposed variants: `#EvidenceStream`, `#MonotoneObservation`,
  `#AppendOnlyEvidence`, `#ConvergenceProof`.

### Security Lattice Extension

- Idiomatic CUE primitives: visibility tiers, policy maps, publication surfaces,
  secret refs, role views, and dynamic tier extension constraints.
- Pattern: model visibility and publication authority as an extensible lattice
  once evidence, reports, secrets, and access control become first-class.
- Source concept: dynamically extensible security lattices.
- Deferred variants: `#SecurityTier`, `#PublicationSurface`,
  `#EvidenceVisibilityPolicy`.

### Bilattice / Four-Valued Logic

- Idiomatic CUE primitives: truth-state enums, knowledge-state enums,
  contradiction records, conflict probes, and acceptance policies for unknown or
  inconsistent evidence.
- Pattern: represent unknown, contradiction, both, and neither as operational
  states when evidence disagreement needs more than prose labels.
- Source concept: Belnap-style four-valued logic.
- Deferred variants: `#TruthState`, `#KnowledgeState`,
  `#ContradictionProof`.

## Quicue / Apercue-Derived Patterns

### Graph Analysis

- Idiomatic CUE primitives: typed nodes, dependency edges, graph projections,
  reachability sets, cycle probes, critical-path derivations, and diff records.
- Pattern: turn resource refs into an analyzable dependency graph that supports
  impact, reachability, critical path, cycle rejection, and topology diff checks.
- Source concepts: apercue `#Graph`, `#CriticalPath`, `#CycleDetector`,
  `#ConnectedComponents`, `#GraphDiff`; quicue.ca `#InfraGraph`,
  `#ImpactQuery`, `#BlastRadius`, `#SinglePointsOfFailure`.
- Proposed variants: `#DependencyGraph`, `#ImpactQuery`, `#BlastRadius`,
  `#CriticalPath`, `#CycleRejectionProof`, `#GraphDiff`.

### Provider / Adapter Binding

- Idiomatic CUE primitives: type sets, provider maps, overlap constraints,
  command templates, resolved actions, and adapter command plans.
- Pattern: bind external providers to resources by declared type overlap and
  resolve actions at compile time.
- Source concepts: resource `@type` sets; provider matching by type overlap;
  compile-time command template resolution.
- Proposed variants: `#ProviderBinding`, `#TypeOverlapMatch`, `#ActionDef`,
  `#ResolvedAction`, `#AdapterCommandPlan`.

### Static Projection Surface

- Idiomatic CUE primitives: export targets, projection endpoints, generated
  response maps, no-widening checks, and build-output fixtures.
- Pattern: expose static JSON-LD, API, wiki, OpenAPI, or dashboard surfaces as
  precomputed projections with bounded authority.
- Source concepts: precomputed static read surfaces from `cue export`; no
  runtime query engine for static publication.
- Proposed variants: `#StaticExportSurface`, `#ProjectionEndpoint`,
  `#PrecomputedResponseSet`, `#ExportMatrix`.

### External Spec Coverage Matrix

- Idiomatic CUE primitives: spec-keyed maps, coverage-depth enums, status
  fields, source refs, projection refs, and required-coverage proofs.
- Pattern: track how deeply each external spec is represented and which
  projection or pattern proves that coverage.
- Source concepts: W3C-style coverage table with spec, pattern, depth, and
  status; projection depth values such as full, partial, vocabulary, structural.
- Proposed variants: `#SpecCoverage`, `#SpecProjection`, `#CoverageDepth`,
  `#ExternalVocabularyProjection`.

### Typed Resource Graph

- Idiomatic CUE primitives: node records, type-set lists, dependency sets, keyed
  resource maps, membership checks, and provider matching constraints.
- Pattern: give graph validation a concrete resource-level input model where
  nodes declare types and dependencies explicitly.
- Source concepts: resource nodes with `@type` sets; `depends_on` as dependency
  set.
- Proposed variants: `#TypedResource`, `#TypeSet`, `#DependencySet`,
  `#ResourceGraph`.

### Execution / Deployment Plan

- Idiomatic CUE primitives: ordered step lists, graph-derived ordering, rollback
  lists, gate refs, provider-resolved commands, and satisfied-gate proofs.
- Pattern: derive executable lifecycle plans from graph order, operation refs,
  adapter commands, and explicit gates.
- Source concepts: deployment order; rollback sequence; gates;
  provider-resolved commands.
- Proposed variants: `#DeploymentPlan`, `#RollbackPlan`, `#ExecutionLayer`,
  `#GateSatisfiedProof`.

### Self-Modeling / Self-Charter

- Idiomatic CUE primitives: repository graph records, maturity gates, authority
  maps, evidence refs, generated validation reports, and drift checks.
- Pattern: model the repository's own authority, maturity gates, and evidence
  graph as data that can validate itself.
- Source concepts: project models its own graph and development phases;
  self-validation report.
- Proposed variants: `#SelfModel`, `#ProjectCharter`, `#MaturityGate`,
  `#SelfValidationReport`.

### Role-Scoped Views

- Idiomatic CUE primitives: visibility fields, role enums, projection filters,
  read-only views, publication surfaces, and no-authority proofs.
- Pattern: generate audience-specific read views without promoting those
  generated views into source authority.
- Source concepts: role-scoped views; read-only publication surfaces;
  Hydra/API-style linked data views.
- Proposed variants: `#RoleView`, `#VisibilityProjection`,
  `#PublicationSurface`, `#ReadOnlyProjection`.

## KubeVela / Timoni-Derived Patterns

### Application Delivery Workflow

- Idiomatic CUE primitives: step records, ordered lists, command bindings,
  lifecycle gates, graph-derived order, and transition results.
- Pattern: model render, orchestrate, and deploy as an explicit workflow contract
  with validation gates at each step.
- Source concepts: KubeVela render, orchestrate, deploy workflow; workflow steps
  programmable with CUE.
- Proposed variants: `#DeliveryWorkflow`, `#WorkflowStep`, `#RenderStep`,
  `#DeployStep`, `#WorkflowGate`.

### Application Model / Component Traits

- Idiomatic CUE primitives: component definitions, trait overlays, policy maps,
  placement constraints, defaults, and closed composed application views.
- Pattern: represent applications as components plus composable traits and
  policies, keeping operational concerns separate from base resource shape.
- Source concepts: Open Application Model-style components; traits and
  operational policies layered onto components.
- Proposed variants: `#Application`, `#Component`, `#Trait`, `#Policy`,
  `#PlacementPolicy`.

### Progressive Rollout

- Idiomatic CUE primitives: staged step lists, status enums, promotion gates,
  verification refs, rollout strategies, and before/after state proofs.
- Pattern: encode canary, blue-green, and staged rollout semantics as state
  transitions gated by continuous verification.
- Source concepts: canary rollout; blue-green rollout; staged promotion;
  continuous verification.
- Proposed variants: `#RolloutPlan`, `#CanaryStep`, `#BlueGreenPlan`,
  `#VerificationGate`, `#PromotionGate`.

### Multi-Cluster Placement

- Idiomatic CUE primitives: target maps, environment records, placement rules,
  topology constraints, selector refs, and compatibility checks.
- Pattern: bind deployable resources to clusters, clouds, or environments using
  explicit placement policy and topology-aware validation.
- Source concepts: placement across clusters, clouds, and environments;
  environment-specific targets.
- Proposed variants: `#ClusterTarget`, `#PlacementRule`,
  `#EnvironmentTarget`, `#MultiClusterPlan`.

### Module / Package Contract

- Idiomatic CUE primitives: module definitions, semantic-version constraints,
  artifact refs, signed artifact metadata, schema boundaries, and source refs.
- Pattern: treat reusable CUE modules as versioned, typed, signed package
  contracts with explicit distribution boundaries.
- Source concepts: Timoni module as typed CUE application definition; OCI
  artifact distribution; semantic versions; signed modules.
- Proposed variants: `#Module`, `#ModuleSchema`, `#ModuleArtifact`,
  `#SemanticVersion`, `#SignedArtifact`.

### Instance / Release

- Idiomatic CUE primitives: instance records, release state, install/upgrade
  plans, rollback plans, transition inputs, and lifecycle result proofs.
- Pattern: separate reusable module authority from concrete installed state and
  model install, upgrade, uninstall, and rollback as explicit release actions.
- Source concepts: Timoni instance as app instantiation; release lifecycle over
  deployed workloads.
- Proposed variants: `#Instance`, `#Release`, `#InstallPlan`,
  `#UpgradePlan`, `#UninstallPlan`, `#RollbackPlan`.

### Bundle Composition

- Idiomatic CUE primitives: module refs, config maps, list/map comprehensions,
  runtime input records, projection boundaries, and closed bundle outputs.
- Pattern: compose multiple modules and configurations into a deployable unit
  without collapsing each module's authority boundary.
- Source concept: Timoni bundle as deployable unit composed from multiple modules
  and configurations.
- Proposed variants: `#Bundle`, `#BundleModuleRef`, `#BundleConfig`,
  `#BundleRuntimeInput`.

### Environment / Runtime Values

- Idiomatic CUE primitives: environment configs, runtime value refs, secret refs,
  late-bound inputs, hidden fields, and public/private projection boundaries.
- Pattern: distinguish compile-time authority from late-bound runtime inputs and
  secret-bearing surfaces.
- Source concepts: environment-specific config; runtime-loaded values during
  install or upgrade; secret and config references.
- Proposed variants: `#EnvironmentConfig`, `#RuntimeValue`, `#SecretRef`,
  `#ConfigSource`, `#LateBoundInput`.

### CRD Schema Import / External Schema Adapter

- Idiomatic CUE primitives: imported schema records, adapter inputs, custom
  resource templates, schema compatibility proofs, closed projections, and
  invalid-schema probes.
- Pattern: import external CRD schemas through an adapter that proves compatibility
  before custom resources are admitted into application contracts.
- Source concepts: import Kubernetes CRD schemas; incorporate custom resources
  into typed app deployments.
- Proposed variants: `#ExternalSchemaImport`, `#CRDSchemaAdapter`,
  `#CustomResourceTemplate`, `#SchemaCompatibilityProof`.

### Supply Chain / Addon Catalog

- Idiomatic CUE primitives: catalog maps, capability records, addon refs,
  binding constraints, provider refs, version/status fields, and coverage checks.
- Pattern: model reusable platform capabilities as catalog entries that can be
  bound to applications or environments under explicit compatibility rules.
- Source concepts: reusable addons; platform capabilities; capability catalogs.
- Proposed variants: `#Addon`, `#Capability`, `#CatalogEntry`,
  `#CapabilityBinding`.
