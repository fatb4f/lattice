package patterns

import domain "github.com/fatb4f/lattice/domain"

#CommandList: [...("vet" | "export" | "eval")] & [_, ...]
#CommandTuple: ["vet", "export", string]

canonical: {
	id:       "lists"
	commands: #CommandList
	tuple:    #CommandTuple
}

positive: {
	commands: #CommandList & ["vet", "export"]
	tuple: #CommandTuple & ["vet", "export", "canonical"]
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "lists"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	emptyCommands: #CommandList & []
	badTuple: #CommandTuple & ["vet", "eval", "canonical"]
}
