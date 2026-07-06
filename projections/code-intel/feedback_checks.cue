package codeintelprofile

import (
	"list"

	fixtures "github.com/fatb4f/lattice/projections/code-intel/fixtures:codeintelprofilefixtures"
)

profileSnapshot: #CodeIntelProfileSnapshot & fixtures.validProfileSnapshot

profileCoverage: close({
	required: profileSnapshot.requiredPillars
	available: [
		"unification",
		"definitions",
		"defaults",
		"disjunctions",
		"comprehensions",
		"closedness",
		"subsumption",
		"negative-fixtures",
		"projections",
		"constructors",
		"top-and-bottom",
		"bounds",
		"hidden-and-let",
		"cycles",
		"lists",
		"attributes",
	]
	missing: [
		for family in required if !list.Contains(available, family) {
			family
		},
	]
	accepted: len(missing) == 0
})

profileAuthorityBoundary: close({
	cueLspAuthority:    profileSnapshot.providers.cueLsp.authority
	cueLspEvidenceOnly: profileSnapshot.providers.cueLsp.evidenceOnly
	accepted: cueLspAuthority == false && cueLspEvidenceOnly == true
})

#CodeIntelProfileFeedbackReport: close({
	schema: "fatb4f.lattice.code-intel-profile-feedback.v1"
	profileID: string
	pillarSuite: string
	coverage: _
	authorityBoundary: _
	accepted: bool
})

codeIntelProfileFeedbackReport: #CodeIntelProfileFeedbackReport & {
	profileID:         profileSnapshot.id
	pillarSuite:       "pillars/*.cue"
	coverage:         profileCoverage
	authorityBoundary: profileAuthorityBoundary
	accepted:         profileCoverage.accepted && profileAuthorityBoundary.accepted
}
