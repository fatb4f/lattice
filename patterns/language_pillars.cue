package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"constraint-as-type": {
			family:         "constraint"
			pillarClass:    "cue-language-pillars"
			coverageStatus: "partial"
			title:  "Use constraints as reusable type surfaces"
			problem: "Repeating primitive constraints makes validation weaker and harder to audit."
			rule:   "Name primitive constraints and reuse them in closed schemas, maps, and constructors."
			sourceRefs: ["cue-definitions", "lattice-domain-kernel"]
			cueSurface: {
				constructs: ["definitions", "type constraints", "regular expressions"]
				exampleExpr: "#KebabIdentifier"
			}
			validation: [{
				id:   "catalog-constraint-exports"
				mode: "export-passes"
				expr: "cueIdiomCatalog"
			}]
		}
		"bottom-as-failure-witness": {
			family:         "bottom"
			pillarClass:    "cue-language-pillars"
			coverageStatus: "captured"
			title:  "Use bottom as an explicit failure witness"
			problem: "Negative behavior is easy to describe in prose but hard to prove unless it bottoms."
			rule:   "Represent forbidden states as expressions that must evaluate to bottom under a destructive probe."
			sourceRefs: ["cue-bottom-semantics", "lattice-domain-negative-fixture"]
			cueSurface: {
				constructs: ["_|_", "unification", "negative fixtures"]
				exampleExpr: "_negativeFixtureConflictBinding.probe.proof"
			}
			validation: [{
				id:   "negative-probe-bottoms"
				mode: "eval-bottoms"
				expr: "_negativeFixtureConflictBinding.probe.proof"
			}]
		}
		"schema-layer-extension": {
			family:         "embedding"
			pillarClass:    "cue-language-pillars"
			coverageStatus: "seed"
			title:  "Layer base schemas into specialized contracts"
			problem: "Copying fields from base contracts into specializations creates drift."
			rule:   "Compose a base schema with a narrower layer through unification."
			sourceRefs: ["cue-unification", "cue-definitions"]
			cueSurface: {
				constructs: ["definitions", "unification", "schema layering"]
				exampleExpr: "#CodeIntelProfileSnapshot"
			}
			validation: [{
				id:   "profile-layer-vets"
				mode: "vet-passes"
				expr: "cueIdiomCatalog"
			}]
		}
		"open-closed-contrast": {
			family:         "closedness"
			pillarClass:    "cue-language-pillars"
			coverageStatus: "partial"
			title:  "Show open and closed struct behavior explicitly"
			problem: "Closedness is hard to reason about without contrasting accepted extra fields and rejected extra fields."
			rule:   "Document open input surfaces separately from closed authority surfaces."
			sourceRefs: ["cue-closedness", "lattice-domain-kernel"]
			cueSurface: {
				constructs: ["open structs", "close", "invalid-field guards"]
				exampleExpr: "#ClosedObligationState"
			}
			validation: [{
				id:   "closedness-vets"
				mode: "vet-passes"
				expr: "cueIdiomCatalog"
			}]
		}
		"non-empty-list": {
			family:         "list"
			pillarClass:    "cue-language-pillars"
			coverageStatus: "partial"
			title:  "Constrain lists to contain at least one item"
			problem: "Empty validation lists often pass shape checks while carrying no evidence."
			rule:   "Unify list element constraints with tuple lower bounds such as [_, ...]."
			sourceRefs: ["cue-definitions", "lattice-domain-kernel"]
			cueSurface: {
				constructs: ["lists", "ellipsis", "tuple lower bound"]
				exampleExpr: "#NonEmptyStringList"
			}
			validation: [{
				id:   "list-constraint-vets"
				mode: "vet-passes"
				expr: "cueIdiomCatalog"
			}]
		}
		"regex-string-identifier": {
			family:         "string"
			pillarClass:    "cue-language-pillars"
			coverageStatus: "partial"
			title:  "Constrain strings with named regex-backed identifiers"
			problem: "Unbounded strings let keys, IDs, paths, and selectors drift independently."
			rule:   "Name regex-backed string constraints and use them in both map keys and embedded IDs."
			sourceRefs: ["cue-definitions", "lattice-domain-kernel"]
			cueSurface: {
				constructs: ["strings", "regular expressions", "map-key guards"]
				exampleExpr: "#KebabIdentifier"
			}
			validation: [{
				id:   "string-identifier-vets"
				mode: "vet-passes"
				expr: "cueIdiomCatalog"
			}]
		}
		"bounded-number": {
			family:         "number"
			pillarClass:    "cue-language-pillars"
			coverageStatus: "seed"
			title:  "Bound numeric values with explicit ranges"
			problem: "Numeric evidence can be structurally valid while carrying impossible counts or limits."
			rule:   "Use lower and upper bounds on numeric fields and derive computed limits from constrained inputs."
			sourceRefs: ["cue-definitions", "cue-by-example"]
			cueSurface: {
				constructs: ["int", "bounds", "derived fields"]
				exampleExpr: "int & >=0"
			}
			validation: [{
				id:   "number-seed-exports"
				mode: "export-passes"
				expr: "cueIdiomCatalog"
			}]
		}
		"package-boundary": {
			family:         "package"
			pillarClass:    "cue-language-pillars"
			coverageStatus: "seed"
			title:  "Use package boundaries to separate authority surfaces"
			problem: "A single package can blur schemas, fixtures, projections, and generated feedback."
			rule:   "Keep packages aligned to authority boundaries and import explicitly across those boundaries."
			sourceRefs: ["cue-packages", "cue-modules"]
			cueSurface: {
				constructs: ["packages", "modules", "imports"]
				exampleExpr: "github.com/fatb4f/lattice/profiles/code-intel:codeintelprofile"
			}
			validation: [{
				id:   "package-boundary-vets"
				mode: "vet-passes"
				expr: "cueIdiomCatalog"
			}]
		}
		"stdlib-import-boundary": {
			family:         "stdlib"
			pillarClass:    "cue-language-pillars"
			coverageStatus: "partial"
			title:  "Use standard library imports for structural operations"
			problem: "Ad hoc encodings for string length or key sorting are harder to audit than standard library calls."
			rule:   "Use stdlib packages such as strings and list for reusable structural checks and projections."
			sourceRefs: ["cue-imports", "lattice-domain-kernel"]
			cueSurface: {
				constructs: ["imports", "list.SortStrings", "strings.MinRunes"]
				exampleExpr: "list.SortStrings"
			}
			validation: [{
				id:   "stdlib-boundary-vets"
				mode: "vet-passes"
				expr: "cueIdiomCatalog"
			}]
		}
	}
}

