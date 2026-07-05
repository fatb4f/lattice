package codeintelprofile

import (
	"list"

	patterns "github.com/fatb4f/lattice/patterns"
	fixtures "github.com/fatb4f/lattice/profiles/code-intel/fixtures:codeintelprofilefixtures"
)

profileSnapshot: #CodeIntelProfileSnapshot & fixtures.validProfileSnapshot

profileCoverage: close({
	required: profileSnapshot.requiredIdiomFamilies
	available: [
		for _, idiom in patterns.cueIdiomCatalog.idioms {
			idiom.family
		},
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
	catalogSchema: string
	coverage: _
	authorityBoundary: _
	accepted: bool
})

codeIntelProfileFeedbackReport: #CodeIntelProfileFeedbackReport & {
	profileID:         profileSnapshot.id
	catalogSchema:    patterns.cueIdiomCatalog.schema
	coverage:         profileCoverage
	authorityBoundary: profileAuthorityBoundary
	accepted:         profileCoverage.accepted && profileAuthorityBoundary.accepted
}
