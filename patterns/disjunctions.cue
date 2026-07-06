package patterns

import domain "github.com/fatb4f/lattice/domain"

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
		target:   "./patterns/disjunctions.cue"
		selector: "canonical"
	}
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "disjunctions"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	invalidSelector: #Command & {
		kind:     "export"
		target:   "./patterns/disjunctions.cue"
		selector: 1
	}
}
