package patterns

cueIdiomCatalog: #CueIdiomCatalog & {
	idioms: {
		"closed-state-constructor": {
			family: "constructor"
			title:  "Use constructor definitions to close and normalize partial input"
			problem: "Input fixtures are convenient when partial, but validation needs stable IDs, defaults, and derived proof fields."
			rule:   "Expose a #Make-style constructor with an input shape and a fully constrained output shape."

			sourceRefs: [
				"lattice-domain-kernel",
				"cue-definitions",
			]

			cueSurface: {
				constructs: [
					"definitions",
					"let bindings",
					"field comprehensions",
					"unification",
				]
				exampleExpr: "#MakeClosedObligationState.out"
			}

			validation: [
				{
					id:   "closed-state-exports"
					mode: "export-passes"
					expr: "_closedState"
				},
			]
		}
	}
}

#ConstructorExample: {
	in: {
		id: #KebabIdentifier
		role?: "authority" | "projection"
	}
	out: close({
		id:   in.id
		role: "authority" | "projection" | *"authority"
		if in.role != _|_ {
			role: in.role
		}
	})
}

constructorExampleOutput: (#ConstructorExample & {
	in: id: "constructed-authority"
}).out

cuePillarSpecs: {
	pillars: {
		constructors: {
			title:  "Constructors"
			class:  "contract"
			status: "validated"
			mechanics: [
				"Constructors separate partial input from normalized output.",
				"Output values apply defaults and derived fields.",
				"Closed output prevents callers from widening the constructed target.",
			]
			idioms: {
				"in-out-normalizer": {
					title: "Normalize partial input into a closed output"
					problem: "Partial fixtures are useful inputs but unstable as authority."
					rule: "Expose an in/out constructor and validate only the constructed output."
					constructs: ["in/out shape", "defaults", "close"]
					canonical: {
						expr:  "constructorExampleOutput"
						value: constructorExampleOutput
					}
					positive: {
						expr:  "constructorExampleOutput"
						value: constructorExampleOutput
					}
				}
			}
		}
	}
}
