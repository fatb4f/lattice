package patterns

import (
	"strings"

	meta "github.com/fatb4f/lattice/meta"
)

#Patterns: {
	"bounds": {

		name:    "Bounds"
		summary: "Constrain identifiers and text with regex and standard-library string bounds."
		demonstrates: ["bounds", "regular expressions", "standard library constraints"]

		#KernelID:     string & strings.MinRunes(1) & =~"^[a-z0-9]+(-[a-z0-9]+)*$"
		#NonEmptyText: string & strings.MinRunes(1)

		canonical: {
			id:          "bounds"
			kernelUse:   "meta/kernel.cue:#KebabIdentifier"
			resourceID:  #KernelID
			description: #NonEmptyText
		}

		positive: {
			resourceID:  #KernelID & "authority-file"
			description: #NonEmptyText & "Run CUE validation"
			validation: (meta.#MakeClosedObligationState & {in: {
				id: "bounds"
				resources: {}
				operations: {}
				gates: {}
				witnesses: {}
			}}).out
		}

		negative: {
			badID:            "Authority_File"
			emptyDescription: ""
		}

	}
}
