package sources

import "quicue.ca/kg/ext@v0"

// #SourceV1 is the stable repository provenance-source contract.
#SourceV1: ext.#SourceFile

Graph: {
	"SRC-001": #SourceV1 & {
		id:          "SRC-001"
		file:        "https://kg.quicue.ca/spec/"
		format:      "html"
		origin:      "quicue.ca"
		description: "Upstream quicue KG operating model and vocabulary reference."
	}
}
