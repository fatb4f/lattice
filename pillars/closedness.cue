package pillars

import meta "github.com/fatb4f/lattice/meta"

#ClosedCommand: close({
	kind:   "vet" | "export"
	target: string
})

#Pillars: {
	"closedness": {

canonical: {
	id:      "closedness"
	command: #ClosedCommand
}

positive: {
	command: #ClosedCommand & {
		kind:   "vet"
		target: "./pillars/closedness.cue"
	}
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "closedness"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	extraField: {
		kind:   "vet"
		target: "./pillars"
		extra:  true
	}
}

}
}
