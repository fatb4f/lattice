#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir/.."

expect_failure() {
	if "$@" >/dev/null 2>&1; then
		printf 'expected failure but command passed:'
		printf ' %q' "$@"
		printf '\n'
		return 1
	fi
}

check_pattern_surfaces() {
	local requirements
	requirements="$(mktemp)"
	trap 'rm -f "$requirements"' RETURN

	cue export ./patterns -e cuePillarExpectations --out json |
		jq -r '
			.pillars[] |
			.surface as $surface |
			[
				[$surface.requiresReadme, "README.md"],
				[$surface.requiresPattern, "pattern.cue"],
				[$surface.requiresPositive, "positive.cue"],
				[$surface.requiresNegative, "negative.cue"],
				[$surface.requiresReport, "report.cue"]
			][] |
			select(.[0] == true) |
			"patterns/\($surface.dir)/\(.[1])"
		' >"$requirements"

	while IFS= read -r required_file; do
		if [[ ! -f "$required_file" ]]; then
			printf 'missing declared pattern surface: %s\n' "$required_file"
			return 1
		fi
	done <"$requirements"
}

cue vet ./domain
cue vet ./idioms
cue vet ./patterns
cue vet ./profiles
cue vet ./profiles/code-intel
cue vet ./exports

check_pattern_surfaces

cue export ./domain -e _closedState --out cue >/dev/null
cue export ./idioms -e cueIdiomSources --out cue >/dev/null
cue export ./patterns -e cueIdiomCatalog --out cue >/dev/null
cue export ./patterns -e cuePillarExpectations --out cue >/dev/null
cue export ./patterns/defaults -e defaultsFixtureReport --out cue >/dev/null
cue export ./patterns/disjunctions -e disjunctionsFixtureReport --out cue >/dev/null
cue export ./patterns/packages -e packagesFixtureReport --out cue >/dev/null
cue export ./patterns/data -e dataIngestionFixtureReport --out cue >/dev/null
cue export ./patterns/tooling -e toolingFixtureReport --out cue >/dev/null
cue export ./profiles/code-intel -e expectedCodeIntelProfile --out cue >/dev/null
cue export ./profiles/code-intel -e codeIntelProfileFeedbackReport --out cue >/dev/null
cue export ./exports -e cueIdiomCatalog --out cue >/dev/null
cue export ./exports -e cuePillarExpectations --out cue >/dev/null
cue export ./exports -e codeIntelProfileExpectation --out cue >/dev/null

expect_failure cue export ./domain -t negativeproof -e _negativeFixtureConflictBinding.probe.proof --out cue

expect_failure cue export ./domain -e '(#MakeClosedObligationState & {"in": {
	id: "missing-create-state"
	resources: {}
	operations: {
		"create-missing": {
			kind:        "inspect"
			description: "Creates missing resource"
			reads: {}
			writes: {}
			creates: {
				"missing-resource": true
			}
			requiresGates: {}
			requiresWitnesses: {}
		}
	}
	gates: {}
	witnesses: {}
}}).out' --out cue

expect_failure cue export ./domain -e '(#MakeClosedObligationState & {"in": {
	id: "authority-create-state"
	resources: {
		"authority-file": {
			path: "contracts/authority.cue"
			role: "authority"
		}
	}
	operations: {
		"create-authority": {
			kind:        "inspect"
			description: "Creates authority resource"
			reads: {}
			writes: {}
			creates: {
				"authority-file": true
			}
			requiresGates: {}
			requiresWitnesses: {}
		}
	}
	gates: {}
	witnesses: {}
}}).out' --out cue
