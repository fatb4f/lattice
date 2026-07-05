package patterns

#NonEmptyCommandList: [...("vet" | "export" | "eval")] & [_, ...]
#CommandTuple: ["vet", "export", string]

listCanonical: close({
	open:     [...string]
	nonEmpty: #NonEmptyCommandList
	tuple:    #CommandTuple
}) & {
	open:     ["vet", "export", "eval", "fmt"]
	nonEmpty: ["vet"]
	tuple:    ["vet", "export", "cueIdiomCatalog"]
}

cuePillarSpecs: {
	pillars: {
		lists: {
			title:  "Lists"
			class:  "language"
			status: "validated"
			mechanics: [
				"Open lists admit additional elements through ellipsis.",
				"Tuples constrain position and length.",
				"Non-empty lists can be expressed with a lower-bound tuple.",
			]
			idioms: {
				"non-empty-and-tuple-list": {
					title: "Choose open lists, non-empty lists, or tuples deliberately"
					problem: "List shape is often underspecified, allowing empty evidence or malformed positional data."
					rule: "Use ellipsis for open lists, [_, ...] for non-empty lists, and tuples for positional contracts."
					constructs: ["ellipsis", "tuple", "[_, ...]"]
					canonical: {
						expr:  "listCanonical"
						value: listCanonical
					}
					expectedBottom: {
						probeExpr: "#NonEmptyCommandList & []"
						reason:    "The list must contain at least one command."
					}
				}
			}
		}
	}
}
