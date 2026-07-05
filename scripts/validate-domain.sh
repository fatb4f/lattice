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

cue vet ./domain

cue export ./domain -e _closedState --out cue >/dev/null

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
