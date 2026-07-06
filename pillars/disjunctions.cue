package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"disjunctions": {

#Command:
	close({
		kind:   "vet"
		target: string
	}) |
	close({
		kind:     "export"
		target:   string
		selector: string
	})

canonical: {
	id:      "disjunctions"
	command: #Command
}

positive: {
	command: #Command & {
		kind:     "export"
		target:   "./pillars/disjunctions.cue"
		selector: "canonical"
	}
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "disjunctions"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	invalidSelector: {
		kind:     "export"
		target:   "./pillars/disjunctions.cue"
		selector: 1
	}
}

}
}
