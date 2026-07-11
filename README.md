
## CUE module

This repository now starts with a domain-neutral lattice CUE module:

```text
module: github.com/fatb4f/lattice
package: github.com/fatb4f/lattice/meta
```

The `meta` package owns the reusable kernel:

* `#Resource`, `#Operation`, `#Gate`, and `#Witness`
* `#ObligationState` and `#ClosedObligationState`
* `#MakeClosedObligationState`
* `#StateKeySet`, `#OperationRefKeySet`, and `#NoWideningProof`

Projections should refine the generic vocabularies, then adapt their local names onto the neutral buckets:

```text
resources + operations + gates + witnesses
```

The first downstream projection is the dotfiles Codex contract, which maps artifacts/actions/checks/evidence onto that generic lattice surface.

## Evidence-backed runtime delivery

The locked Python runtime consumes the versioned `kg index --full` envelope while CUE remains the contract and
admission authority:

```sh
uv sync --locked
uv run lattice index build --out /tmp/lattice-index.json
uv run lattice route --envelope /tmp/lattice-index.json --query "knowledge graph context" --out /tmp/route.json
uv run lattice materialize --envelope /tmp/lattice-index.json --route-packet /tmp/route.json --out /tmp/context.json
uv run lattice audit hook --envelope /tmp/lattice-index.json --prompt "knowledge graph context" --out /tmp/hook-audit.json
uv run lattice diagnose --format json --bundle build/diagnostics-review
uv run lattice-mcp
```

`lattice route` exports and admits `graphRoutingPolicy` from `.kg/context/routing.cue` when `--policy` is omitted.
The versioned policy owns ranking weights, allowed metadata, relation propagation, tie-breaking, ceilings, and default
budgets; Python only executes the exported document.

The retained `.kg/mcp/server.js` and Bun package are compatibility launchers
and boundary tests only; Python owns the sole MCP resource implementation.

Indexes and projections are cached under `.cache/lattice` by repository revision, normalized inputs, and tool
identity. The registered Codex hook emits only compact prompt context and does not run diagnostic gates or create audit
artifacts. `lattice audit hook` and `lattice diagnose` own evidence-bearing offline audits; review bundles and the
generated workbook remain non-authoritative.

Use `scripts/validate-fast.sh` for formatting, typing, unit tests, and CUE contract checks without live full-index
work. `scripts/validate-domain.sh` is the integration gate: it creates one shared full-index envelope, reuses it for
diagnostics, and reviews the offline hook audit without executing the registered hook.

## Core generalization

Your **CUE lattice TDD/BDD kernel** applies anywhere the system can be modeled as:

```cue
GivenState ∧ Intent ∧ Rules ∧ Evidence ∧ ExpectedProjection
```

and correctness means:

```cue
unifies    // valid refinement
bottoms   // forbidden state rejected
subsumes  // implementation is within contract
```

So the transferable paradigm is:

> **Replace prose/spec/test drift with constraint-bound graph/state validation.**

The kernel is not limited to software tests. It applies to any domain where you need bounded vocabulary, legal state transitions, negative fixtures, and projection checks.

---

## High-signal paradigm map

| Paradigm                       | CUE lattice role                                  | Main test surface                     |
| ------------------------------ | ------------------------------------------------- | ------------------------------------- |
| **Schema-first development**   | Canonical structural authority                    | Assertions, negative fixtures         |
| **Design by contract**         | Preconditions, postconditions, invariants         | Subsumption, bottom checks            |
| **Model-based testing**        | State graph + transition rules                    | Positive/negative transition fixtures |
| **BDD**                        | Given/When/Then encoded as data                   | Scenario matrices                     |
| **TDD**                        | Tests define admitted shape before implementation | Eval-first fixtures                   |
| **Policy as code**             | Allow/deny constraints                            | Forbidden outputs, required evidence  |
| **Infrastructure as code**     | Desired state + drift rejection                   | Projection + closedness               |
| **CI/CD gates**                | Merge/release admissibility                       | Evidence + status lattice             |
| **Agent workflow control**     | Tool/action/admissible artifact graph             | Required actions, forbidden surfaces  |
| **API/data contracts**         | Producer/consumer compatibility                   | Subsumption, version evolution        |
| **Compiler/codegen pipelines** | AST/IR/projection invariants                      | Lowering correctness                  |
| **Event sourcing**             | Events as state transitions                       | Replay-valid state graph              |
| **Finite state machines**      | Legal state transition matrix                     | Transition bottoming                  |
| **Capability/security models** | Actor/resource/action constraints                 | Capability admission                  |
| **Build systems**              | Inputs/outputs/dependency graph                   | Artifact determinism                  |
| **Supply-chain provenance**    | Evidence graph + artifact lineage                 | Required attestations                 |
| **Ontology/knowledge graphs**  | Node/edge vocabulary + relations                  | Topology validation                   |
| **Typed adapter systems**      | External tools as effect boundaries               | Adapter contract checks               |
| **Config/module systems**      | Layered unification                               | Override admissibility                |
| **Control systems**            | Sensor → controller → actuator constraints        | Stability and gate checks             |

---

## 1. Schema-first / data-contract paradigm

This is the most direct fit.

Instead of saying:

> “This file should contain a valid manifest.”

You encode:

```cue
#Manifest: close({
	id:      #KebabIdentifier
	version: #SemVer
	inputs:  [...#ArtifactRef]
	outputs: [...#ArtifactRef]
})
```

Then your TDD kernel validates:

```cue
positive: #Manifest & validManifest
negative: #Manifest & invalidManifest // should bottom
```

Useful for:

* repo manifests
* API payloads
* JSON/YAML/TOML configs
* generated artifacts
* CLI output contracts
* lockfiles
* registry entries

---

## 2. Design by contract

CUE works well as a **contract surface** because it naturally represents:

| Contract concept | CUE equivalent        |
| ---------------- | --------------------- |
| Precondition     | input constraints     |
| Postcondition    | output constraints    |
| Invariant        | always-unified schema |
| Illegal state    | bottom                |
| Refinement       | unification           |
| Compatibility    | subsumption           |

Example shape:

```cue
#Transition: {
	before: #GraphState
	intent: #Intent
	after:  #GraphState

	// invariant
	after.nodes: [...#Node]

	// postcondition
	after.version: before.version + 1
}
```

This applies to anything with valid/invalid lifecycle movement.

---

## 3. Model-based testing

Your kernel maps very cleanly to model-based testing.

Instead of testing individual examples manually, you define:

```cue
#State
#Operation
#Transition
#Invariant
#Fixture
```

Then generate a matrix:

```cue
for op in operations
for fixture in fixtures
```

CUE becomes the **state-space filter**.

Good fits:

* graph mutations
* workflow engines
* repo state transitions
* package lifecycle
* issue/PR lifecycle
* deployment promotion
* task assignment flows
* document approval flows

---

## 4. BDD without prose ambiguity

Traditional BDD:

```gherkin
Given a repo has a contract
When Codex edits a file
Then it must report evidence
```

CUE BDD:

```cue
#Scenario: {
	given: #RepoState
	when:  #CodexAction
	then:  #ExpectedState
	mustReport: [...#EvidenceRef]
	forbiddenOutputs: [...#ArtifactRef]
}
```

The value is that the “Given/When/Then” becomes executable constraint structure, not prose.

This is especially strong for agent contracts because agents are otherwise prone to interpreting prose loosely.

---

## 5. Policy as code

CUE is strong wherever the main question is:

> “Is this action admitted?”

Example:

```cue
#Action: {
	kind: "edit" | "create" | "delete"
	target: #ArtifactRef
}

#Policy: {
	allowedTargets: [...#ArtifactRef]
	forbiddenTargets: [...#ArtifactRef]
}

#AdmittedAction: #Action & {
	target: =~"^contracts/"
}
```

Useful for:

* allowed mutation surfaces
* forbidden generated files
* CI permissions
* deployment approvals
* agent tool permissions
* security boundary checks
* publication gates

Your current contract work already lives here.

---

## 6. Infrastructure as code / desired-state control

CUE can model the desired state, while Terraform, Ansible, Nix, shell, Kubernetes, or GitHub Actions act as adapters.

Pattern:

```text
CUE authority
   ↓ projection
adapter config
   ↓ actuator
real system
   ↓ evidence
CUE validation
```

Applies to:

* dotfiles
* Kubernetes manifests
* GitHub Actions
* Nix/home-manager
* systemd units
* devcontainers
* package sets
* editor/plugin config
* CI/CD topology

CUE does not need to perform the mutation. It can own the **admission and projection contract**.

---

## 7. Agent workflow control

This is one of the strongest applications.

Agents need bounded surfaces:

```cue
#AgentRun: {
	requiredActions: [...#Action]
	requiredArtifacts: [...#ArtifactRef]
	forbiddenArtifacts: [...#ArtifactRef]
	checks: [...#Check]
	evidence: [...#Evidence]
	witness: #CompletionWitness
}
```

This gives you:

* action admissibility
* artifact authority
* forbidden output gates
* required evidence
* completion witnesses
* tool-call surface constraints
* report template enforcement

That turns agentic work from:

```text
“Please follow these instructions”
```

into:

```text
“Only this graph transition is admissible.”
```

---

## 8. API compatibility and versioning

CUE subsumption is useful for producer/consumer contracts.

Example:

```cue
#ConsumerNeeds: {
	id: string
	status: "ok" | "error"
}

#ProducerOutput: {
	id: string
	status: "ok" | "error" | "pending"
}
```

You can check whether producer output is too wide, too narrow, or compatible.

Useful for:

* API versions
* CLI JSON output
* generated reports
* event payloads
* database export contracts
* schema migration gates

The lattice gives you a clean vocabulary for compatibility:

| Change    | Meaning                   |
| --------- | ------------------------- |
| Narrowing | Usually safer for outputs |
| Widening  | Usually safer for inputs  |
| Bottom    | Incompatible              |
| Subsumes  | Contract-compatible       |

---

## 9. Compiler / codegen / lowering pipelines

CUE is very useful around codegen because codegen is usually a sequence of projections:

```text
Authority schema
  → intermediate representation
  → target-specific projection
  → generated code
  → evidence report
```

CUE can validate:

* source schema shape
* IR completeness
* target capability compatibility
* forbidden target constructs
* generated artifact manifest
* roundtrip metadata
* adapter-specific constraints

For your style, this fits:

```text
CUE authority
→ projected codegen
→ adapter contracts
→ generated repo artifacts
→ witness validation
```

---

## 10. Event sourcing and append-only logs

Event sourcing is another strong fit because each event is a constrained transition.

```cue
#Event: {
	id:   #EventID
	kind: "created" | "assigned" | "closed"
	at:   #Timestamp
}

#ValidReplay: {
	events: [...#Event]
	final:  #State
}
```

Checks:

* illegal event order bottoms
* missing required events bottom
* state after replay must unify
* derived projection must subsume expected view

Good for:

* audit logs
* agent run logs
* CI history
* issue/PR event streams
* contract evolution history

---

## 11. Capability and security models

CUE works well for access control because capability systems are naturally graph-shaped:

```cue
#Capability: {
	actor:    #ActorID
	action:   #ActionKind
	resource: #ResourceID
	scope:    #Scope
}
```

Then admission is:

```cue
#Allowed: #Capability & policy.allow[_]
#Denied:  #Capability & policy.deny[_] // should bottom with allowed
```

Useful for:

* agent permissions
* repo mutation rights
* deployment rights
* tool access
* publication rights
* secret/material boundary checks

---

## 12. Build systems and artifact determinism

CUE can define the expected build graph:

```cue
#BuildStep: {
	inputs:  [...#Artifact]
	outputs: [...#Artifact]
	command: #Command
}
```

Then validate:

* all inputs declared
* all outputs admitted
* no forbidden outputs
* dependency graph closed
* generated files match projection
* evidence exists for each step

This is similar to Bazel/Nix thinking, but CUE can be the **contract and topology authority** rather than the executor.

---

## 13. Ontology / knowledge graph validation

Your lattice kernel also applies to semantic graph work.

```cue
#Node: {
	id:   #Identifier
	kind: "concept" | "artifact" | "claim" | "evidence"
}

#Edge: {
	from: #NodeID
	to:   #NodeID
	kind: "supports" | "contradicts" | "derives" | "dependsOn"
}
```

Checks:

* no dangling refs
* allowed edge types by node kind
* required evidence for claims
* contradiction surfaces
* projection to reports/docs
* authority/evidence separation

This is relevant to semagrams-style work.

---

## 14. Control-theory framing

In control-system terms:

```text
Authority contract = controller law
Input state         = sensor signal
Intent/action       = control input
Adapter/tool        = actuator
Generated artifact  = plant output
Evidence/witness    = feedback
CUE eval            = stability/admissibility check
```

Your kernel generalizes to any system where you need to prevent uncontrolled mutation.

The key control surfaces are:

| Surface    | CUE role                                   |
| ---------- | ------------------------------------------ |
| Sensor     | observed state schema                      |
| Controller | invariant contract                         |
| Actuator   | adapter boundary                           |
| Plant      | external system                            |
| Feedback   | evidence/witness                           |
| Stability  | repeated unification without contradiction |
| Fault      | bottom                                     |

---

## Where the CUE lattice is strongest

Use it when the domain has:

* finite or bounded vocabularies
* structured state
* graph references
* legal/illegal transitions
* required evidence
* generated projections
* compatibility/versioning needs
* adapter boundaries
* CI gates
* agent/tool constraints

The stronger the need for **admission control**, the better CUE fits.

---

## Where it is weaker

CUE is less ideal as the primary tool for:

| Weak area                | Reason                                                          |
| ------------------------ | --------------------------------------------------------------- |
| Heavy algorithms         | CUE is constraint/eval-oriented, not general imperative compute |
| Large randomized search  | Use external generators if needed                               |
| Runtime side effects     | Needs adapters                                                  |
| Stateful services        | CUE should specify, not serve                                   |
| Complex temporal logic   | Possible, but awkward without a model checker                   |
| Performance simulation   | Better handled by specialized tools                             |
| Rich statistical testing | Better handled by Python/Rust/Go/etc.                           |

So the boundary is:

```text
CUE owns admissibility.
Adapters own execution.
Evidence returns to CUE.
```

---

## Condensed answer

The CUE lattice applies to any paradigm that can be reduced to:

```text
bounded vocabulary
+ structured state
+ legal transitions
+ forbidden states
+ generated projections
+ evidence-backed completion
```

The highest-value adjacent paradigms are:

1. **Design by contract**
2. **Model-based testing**
3. **Policy as code**
4. **Agent workflow control**
5. **Infrastructure desired-state validation**
6. **API/data contract compatibility**
7. **Codegen/projection pipelines**
8. **Event-sourced state machines**
9. **Capability/security models**
10. **Knowledge graph validation**

The unifying move is:

```text
imperative test logic
→ declarative admissibility lattice

prose requirements
→ executable constraints

agent instruction chains
→ graph-state transition contracts
```
