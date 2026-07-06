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
		id:          "bounds"
		family:      "bounds"
		status:      "implemented"
		problem:     "Identifiers and human text need reusable validity constraints."
		abstraction: "Bounded identifier and non-empty text constraints"
		fixtures: {canonical: canonical, positive: positive, negative: negative}
		checks: {pass: ["cue eval patterns/bounds.cue -e #Patterns.bounds.positive"], fail: ["cue eval patterns/bounds.cue -e #Patterns.bounds.negative.badID"]}
		promotion: {source: "docs/patterns.md", reason: "Promotes data-structure and ordering constraints into reusable schema bounds."}

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
