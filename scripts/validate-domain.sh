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

pattern_files=(
	patterns/unification.cue
	patterns/definitions.cue
	patterns/defaults.cue
	patterns/disjunctions.cue
	patterns/comprehensions.cue
	patterns/closedness.cue
	patterns/subsumption.cue
	patterns/negative-fixtures.cue
	patterns/projections.cue
	patterns/constructors.cue
	patterns/top-and-bottom.cue
	patterns/bounds.cue
	patterns/hidden-and-let.cue
	patterns/cycles.cue
	patterns/lists.cue
	patterns/attributes.cue
)

validate_patterns() {
	local expected
	expected="$(printf '%s\n' "${pattern_files[@]}" | sort)"
	local actual
	actual="$(find patterns -maxdepth 1 -type f -name '*.cue' | sort)"
	if [[ "$actual" != "$expected" ]]; then
		printf 'unexpected patterns/ surface\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual"
		return 1
	fi

	local pattern_file
	for pattern_file in "${pattern_files[@]}"; do
		cue eval "$pattern_file" -e canonical --out cue >/dev/null
		cue eval "$pattern_file" -e positive --out cue >/dev/null
	done

	expect_failure cue eval patterns/unification.cue -e negative.incompatibleTier --out cue
	expect_failure cue eval patterns/definitions.cue -e negative.invalidRole --out cue
	expect_failure cue eval patterns/defaults.cue -e negative.invalidLogLevel --out cue
	expect_failure cue eval patterns/disjunctions.cue -e negative.invalidSelector --out cue
	expect_failure cue eval patterns/comprehensions.cue -e negative.badServicePort --out cue
	expect_failure cue eval patterns/closedness.cue -e negative.extraField --out cue
	expect_failure cue eval patterns/subsumption.cue -e negative.incompatibleField --out cue
	expect_failure cue eval patterns/negative-fixtures.cue -e negative.proof --out cue
	expect_failure cue eval patterns/projections.cue -e negative.widenedProjection --out cue
	expect_failure cue eval patterns/constructors.cue -e negative.badPort --out cue
	expect_failure cue eval patterns/top-and-bottom.cue -e negative.conflict --out cue
	expect_failure cue eval patterns/bounds.cue -e negative.portTooHigh --out cue
	expect_failure cue eval patterns/bounds.cue -e negative.badID --out cue
	expect_failure cue eval patterns/hidden-and-let.cue -e negative.privateConflict --out cue
	expect_failure cue eval patterns/cycles.cue -e negative.arithmeticCycle --out cue
	expect_failure cue eval patterns/lists.cue -e negative.emptyCommands --out cue
	expect_failure cue eval patterns/lists.cue -e negative.badTuple --out cue
	expect_failure cue eval patterns/attributes.cue -e negative.invalidKind --out cue
}

cue vet ./domain
cue vet ./idioms
cue vet ./profiles
cue vet ./profiles/code-intel
cue vet ./exports

validate_patterns

cue export ./domain -e _closedState --out cue >/dev/null
cue export ./idioms -e cueIdiomSources --out cue >/dev/null
cue export ./profiles/code-intel -e expectedCodeIntelProfile --out cue >/dev/null
cue export ./profiles/code-intel -e codeIntelProfileFeedbackReport --out cue >/dev/null
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
