package patterns

import domain "github.com/fatb4f/lattice/domain"

_authority: {
	id: "negative-fixtures"
	resources: {
		"authority-file": {
			path: "contracts/authority.cue"
			role: "authority"
		}
	}
	operations: {}
	gates: {}
	witnesses: {}
}

_invalid: {
	id: "negative-fixtures"
	resources: {
		"authority-file": {
			path: "contracts/authority.cue"
			role: "forbidden"
		}
	}
	operations: {}
	gates: {}
	witnesses: {}
}

canonical: {
	id: "negative-fixtures"
	spec: (domain.#MakeNegativeFixtureSpec & {in: {
		id:          "negative-fixtures"
		description: "Expected-bottom fixture metadata"
		authority:   _authority
		invalid:     _invalid
	}}).out
}

positive: {
	specOnly: canonical.spec
	validation: (domain.#MakeClosedObligationState & {in: _authority}).out
}

negative: {
	proof: (domain.#MakeNegativeFixture & {in: {
		id:          "negative-fixtures"
		description: "Expected-bottom fixture proof"
		authority:   _authority
		invalid:     _invalid
	}}).out.probe.proof
}
