package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"lists": {

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
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "lists"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	emptyCommands: []
	badTuple: ["vet", "eval", "canonical"]
}

}
}
