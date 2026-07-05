package patterns

#AttributedCommand: {
	kind:   "vet" | "export" @tag(kind)
	target: string @tag(target)
}

attributedCommand: #AttributedCommand & {
	kind:   "vet"
	target: "./patterns"
}

cuePillarSpecs: {
	pillars: {
		attributes: {
			title:  "Attributes"
			class:  "adapter"
			status: "validated"
			mechanics: [
				"Attributes attach metadata to fields.",
				"Adapter hints can stay beside the CUE contract.",
				"Attributes should annotate authority rather than replace it.",
			]
			idioms: {
				"tagged-adapter-fields": {
					title: "Attach adapter metadata to constrained fields"
					problem: "External tool metadata can drift when tracked separately from the field contract."
					rule: "Use attributes as metadata on fields that still have normal CUE constraints."
					constructs: ["attributes", "@tag", "field constraints"]
					canonical: {
						expr:  "attributedCommand"
						value: attributedCommand
					}
				}
			}
		}
	}
}
