package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"attributes": {

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
		target: "./pillars/attributes.cue"
	}
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "attributes"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	invalidKind: {
		kind:   "fmt"
		target: "./pillars"
	}
}

}
}
