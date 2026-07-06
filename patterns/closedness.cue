package patterns

import domain "github.com/fatb4f/lattice/domain"

#ClosedCommand: close({
	kind:   "vet" | "export"
	target: string
})

canonical: {
	id:      "closedness"
	command: #ClosedCommand
}

positive: {
	command: #ClosedCommand & {
		kind:   "vet"
		target: "./patterns/closedness.cue"
	}
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "closedness"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	extraField: #ClosedCommand & {
		kind:   "vet"
		target: "./patterns"
		extra:  true
	}
}
