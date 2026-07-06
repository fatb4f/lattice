package patterns

import domain "github.com/fatb4f/lattice/domain"

#TaggedCommand: {
	kind:   "vet" | "export" @tag(kind)
	target: string           @tag(target)
}

canonical: {
	id:      "attributes"
	command: #TaggedCommand
}

positive: {
	command: #TaggedCommand & {
		kind:   "vet"
		target: "./patterns/attributes.cue"
	}
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "attributes"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	invalidKind: #TaggedCommand & {
		kind:   "fmt"
		target: "./patterns"
	}
}
