package kg

import "quicue.ca/kg/aggregate@v0"

_index: aggregate.#KGIndex & {
	project: "lattice"

	decisions: {
		(d001.id): d001
		(d002.id): d002
	}

	insights: {
		(i001.id): i001
		(i002.id): i002
	}

	rejected: {
		(r001.id): r001
		(r002.id): r002
	}

	patterns: {
		"struct-as-set": struct_as_set
		"adr-as-cue": adr_as_cue
		"comprehension-index": comprehension_index
	}
}
