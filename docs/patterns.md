
## Direct answer

**Not really.** I do not find a mature, canonical **“Refactoring.Guru for CUE”** or **“TheAlgorithms/CUE”** equivalent.

## Local shape

`pillars/` is the executable pillar suite. One file is one pillar, and each file
exposes `canonical`, `positive`, and `negative` witnesses under `#Pillars`.

What exists is closer to:

| Need                                   | Existing closest match                                            | Gap                                                                            |
| -------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Refactoring.Guru-style pattern catalog | `cue-labs/cue-by-example`, Cuetorials “Useful Patterns”, CUE docs | Not a full catalog of named CUE architectural patterns                         |
| GoF design patterns in CUE             | No direct equivalent found                                        | GoF patterns are runtime/OOP patterns; CUE is a constraint/evaluation language |
| TheAlgorithms/CUE                      | No official TheAlgorithms CUE repo found                          | CUE is not ideal for imperative algorithm collections                          |
| CUE-native algorithm/pattern corpus    | Small/specific projects like `apercue`                            | Domain-specific, not a general educational corpus                              |

Refactoring.Guru has language-specific GoF examples, for example its Go repo states that it contains examples for all classic GoF design patterns. ([GitHub][1]) TheAlgorithms has many language repositories, but its current organization repository list shows languages like Dart, Nim, Fortran, Zig, Python, Go, JavaScript, Mojo, Ruby, C#, C++, Kotlin, Julia, PHP, Lua, TypeScript, Scala, Swift, and C; I did not find a CUE repository in that listing. ([GitHub][2])

## Closest useful CUE resources

### 1. `cue-labs/cue-by-example`

This is probably the nearest “example corpus” in spirit. It describes itself as examples of real-world CUE use with third-party tools, services, and systems. ([GitHub][3])

### 2. Cuetorials “Useful Patterns”

Cuetorials has a “Useful Patterns” section; for example, its scripts/tasks page explains CUE’s task layer over `tools/flow` for non-hermetic operations. ([Cuetorials][4])

### 3. Official CUE concept docs

The official “Logic of CUE” page is important because CUE patterns are mostly not object patterns; they are **unification, subsumption, incompleteness, bottom, disjunction, defaults, and comprehensions**. ([CUE][5])

### 4. `quicue/apercue`

This is a concrete, pattern-heavy CUE project rather than a tutorial corpus. Its README describes compile-time W3C linked data from typed dependency graphs, using CUE comprehensions and unification to produce JSON-LD, SHACL, SKOS, OWL-Time, and other projections via `cue export`. ([GitHub][6]) It also has a `patterns/` directory with graph analysis, validation, lifecycle, provenance, policy, catalog, ontology, taxonomy, visualization, and related CUE pattern definitions. ([GitHub][6])

## Why a direct port is the wrong shape

### Refactoring.Guru → CUE

GoF patterns mostly solve **runtime object collaboration** problems:

* Factory
* Builder
* Adapter
* Strategy
* Observer
* Visitor
* Command
* State
* Chain of Responsibility

CUE does not primarily model mutable runtime objects. A CUE-native pattern catalog would instead organize around **constraint graph construction**:

| GoF-ish name      | CUE-native equivalent                                 |
| ----------------- | ----------------------------------------------------- |
| Factory / Builder | `#Make` constructors                                  |
| Adapter           | Projection schema: CUE → JSON/YAML/OpenAPI/tool input |
| Strategy          | Closed disjunction selected by a concrete tag         |
| Template Method   | Base schema unified with specialization               |
| Composite         | Recursive structs / graph nodes                       |
| Visitor           | Projection over structural variants                   |
| Command           | `cue cmd` task schema                                 |
| State             | Valid state graph + transition constraints            |
| Observer          | Event log / evidence projection                       |
| Validator         | Positive fixture + negative fixture pair              |

### TheAlgorithms → CUE

A CUE version should not try to implement “bubble sort in CUE” as if CUE were Python or Go.

A better equivalent would be:

| TheAlgorithms category | CUE-suitable version                                                       |
| ---------------------- | -------------------------------------------------------------------------- |
| Sorting                | Ordering constraints, uniqueness, stable projection checks                 |
| Graph algorithms       | DAG validation, reachability encoding, topological layers, cycle rejection |
| Search                 | selector/path matching, reference resolution                               |
| Dynamic programming    | usually poor fit unless bounded and static                                 |
| Cryptography           | poor fit; use adapters                                                     |
| Data structures        | schema shapes, maps, tagged unions, recursive types                        |
| Testing algorithms     | positive fixtures, negative fixtures, subsumption tests                    |

So the CUE equivalent is less **“algorithms implemented in CUE”** and more:

> **“Constraint algorithms, graph-state proofs, projection patterns, and validation kernels expressed in CUE.”**

## A good missing OSS project shape

A useful repo could be:

```text
cue-patterns/
  patterns/
    constructors/
    adapters/
    projections/
    disjunctions/
    comprehensions/
    negative-fixtures/
    subsumption/
    open-closed/
    graph-state/
    eval-matrices/
  algorithms/
    graph/
      dag.cue
      cycle_rejection.cue
      topo_layers.cue
      reachability.cue
    schema/
      normalization.cue
      uniqueness.cue
      selector_matching.cue
    testing/
      fixture_matrix.cue
      bottom_probes.cue
      exportable_witnesses.cue
  examples/
  tests/
  docs/
```

Minimal contract schema:

```cue
#CuePattern: {
	id:          =~"^[a-z0-9]+(-[a-z0-9]+)*$"
	family:      "constructor" | "adapter" | "projection" | "disjunction" | "comprehension" | "negativeFixture" | "subsumption" | "graphState"
	intent:      string & !=""
	problem:     string & !=""
	forces:      [...string]
	solution:    string & !=""
	whenToUse:   [...string]
	whenNotToUse: [...string]
	files: {
		schema: string
		fixture?: string
		probe?: string
		export?: string
	}
	checks: [...{
		id: string
		mode: "evalPasses" | "evalBottoms" | "exportPasses" | "subsumes"
		expr: string
	}]
}
```

## Best framing

The missing CUE version should probably be called something like:

* **CUE Patterns**
* **CUE by Constraint**
* **The Constraints**
* **CUE Pattern Atlas**
* **CUE Lattice Patterns**
* **CUE Validation Kernels**

The strongest angle is not “design patterns in CUE”; it is:

> **A catalog of reusable CUE constraint, projection, fixture, and graph-state validation patterns.**

[1]: https://github.com/RefactoringGuru/design-patterns-go "GitHub - RefactoringGuru/design-patterns-go · GitHub"
[2]: https://github.com/orgs/TheAlgorithms/repositories "TheAlgorithms repositories · GitHub"
[3]: https://github.com/cue-labs/cue-by-example "GitHub - cue-labs/cue-by-example · GitHub"
[4]: https://cuetorials.com/patterns/scripts-and-tasks/ "Scripts & Tasks | Useful Patterns | Cuetorials"
[5]: https://cuelang.org/docs/concept/the-logic-of-cue/ "The Logic of CUE | CUE"
[6]: https://github.com/quicue/apercue "GitHub - quicue/apercue: Compile-time W3C linked data from typed dependency graphs · GitHub"
