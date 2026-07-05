package patterns

_topAcceptsString: _ & "accepted"
_topAcceptsStruct: _ & {
	id: "accepted-struct"
}

_bottomWitness: close({
	id:          "top-bottom-conflict"
	description: "A value cannot be both the string accepted and the integer 1."
	probeExpr:   "\"accepted\" & 1"
})

cuePillarSpecs: {
	pillars: {
		"top-and-bottom": {
			title:  "Top And Bottom"
			class:  "language"
			status: "validated"
			mechanics: [
				"_ is the unconstrained top value.",
				"_|_ is bottom, the result of contradiction.",
				"Bottom can be used as an intentional failure witness.",
			]
			idioms: {
				"top-refinement-bottom-conflict": {
					title: "Refine top and prove contradictions with bottom"
					problem: "Unconstrained values and impossible values are often described without a checkable witness."
					rule: "Use _ for an unconstrained input slot and expected-bottom probes for contradictions."
					constructs: ["_", "_|_", "&"]
					canonical: {
						expr:  "_topAcceptsStruct"
						value: _topAcceptsStruct
					}
					positive: {
						expr:  "_topAcceptsString"
						value: _topAcceptsString
					}
					expectedBottom: {
						probeExpr: _bottomWitness.probeExpr
						reason:    _bottomWitness.description
					}
				}
			}
		}
	}
}
