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

expect_closedness_extra_field_failure() {
	local probe="pillars/.closedness-extra-field-probe.cue"
	cat >"$probe" <<'EOF'
package pillars

_probe: #ClosedKernelResource & #Pillars["closedness"].negative.extraField
EOF
	if cue eval pillars/closedness.cue "$probe" -e _probe --out cue >/dev/null 2>&1; then
		rm -f "$probe"
		printf 'expected failure but closedness extra-field probe passed\n'
		return 1
	fi
	rm -f "$probe"
}

pillar_files=(
	pillars/unification.cue
	pillars/definitions.cue
	pillars/defaults.cue
	pillars/disjunctions.cue
	pillars/comprehensions.cue
	pillars/closedness.cue
	pillars/subsumption.cue
	pillars/negative-fixtures.cue
	pillars/projections.cue
	pillars/constructors.cue
	pillars/top-and-bottom.cue
	pillars/bounds.cue
	pillars/hidden-and-let.cue
	pillars/cycles.cue
	pillars/lists.cue
	pillars/attributes.cue
)

validate_meta() {
	cue vet ./meta
	cue export ./meta -e _closedState --out cue >/dev/null

	expect_failure cue export ./meta -e '((#MakeNegativeFixture & {"in": {
		id:          "negative-conflict"
		description: "Negative fixture derives paired destructive probe input"
		authority:   _validState
		invalid: {
			id: "valid-state"
			resources: {
				"authority-file": {
					path: "contracts/authority.cue"
					role: "forbidden"
				}
				"generated-file": {
					path: "generated/assertions.json"
					role: "generated-output"
				}
			}
			operations: {}
			gates: {}
			witnesses: {}
		}
	}}).out).probe.proof' --out cue

	expect_failure cue export ./meta -e '(#MakeClosedObligationState & {"in": {
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

	expect_failure cue export ./meta -e '(#MakeClosedObligationState & {"in": {
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
}

validate_pillars() {
	local expected
	expected="$(printf '%s\n' "${pillar_files[@]}" | sort)"
	local actual
	actual="$(find pillars -maxdepth 1 -type f -name '*.cue' | sort)"
	if [[ "$actual" != "$expected" ]]; then
		printf 'unexpected pillars/ surface\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual"
		return 1
	fi

	local pillar_file
	for pillar_file in "${pillar_files[@]}"; do
		local pillar_id
		pillar_id="$(basename "$pillar_file" .cue)"
		cue eval "$pillar_file" -e "#Pillars[\"$pillar_id\"].canonical" --out cue >/dev/null
		cue eval "$pillar_file" -e "#Pillars[\"$pillar_id\"].positive" --out cue >/dev/null
		cue eval "$pillar_file" -e "#Pillars[\"$pillar_id\"].negative" --out cue >/dev/null
	done

	cue vet ./pillars

	expect_failure cue eval pillars/unification.cue -e '(#Pillars["unification"].#KernelResource & #Pillars["unification"].negative.incompatibleRole)' --out cue
	expect_failure cue eval pillars/definitions.cue -e '(#Pillars["definitions"].#KernelResourceRef & #Pillars["definitions"].negative.invalidRole)' --out cue
	expect_failure cue eval pillars/defaults.cue -e '(#Pillars["defaults"].#KernelGatePolicy & #Pillars["defaults"].negative.invalidRequired)' --out cue
	expect_failure cue eval pillars/disjunctions.cue -e '(#Pillars["disjunctions"].#KernelOperationIntent & #Pillars["disjunctions"].negative.invalidSelector)' --out cue
	expect_failure cue eval pillars/comprehensions.cue -e '(#Pillars["comprehensions"].#ResourceInputs & #Pillars["comprehensions"].negative.badServicePort)' --out cue
	expect_closedness_extra_field_failure
	expect_failure cue eval pillars/subsumption.cue -e '(#Pillars["subsumption"].#AuthorityResource & #Pillars["subsumption"].negative.incompatibleField)' --out cue
	expect_failure cue eval pillars/negative-fixtures.cue -e '(meta.#MakeNegativeFixture & {in: #Pillars["negative-fixtures"].negative.proof}).out.probe.proof' --out cue
	expect_failure cue eval pillars/projections.cue -e '(meta.#NoWideningProof & {
		authority: #Pillars["projections"]._closedAuthority
		target: (meta.#MakeClosedObligationState & {
			in: #Pillars["projections"]._authority & #Pillars["projections"].negative.widenedProjection
		}).out
	})' --out cue
	expect_failure cue eval pillars/constructors.cue -e '(#Pillars["constructors"].#MakeResource & {in: #Pillars["constructors"].negative.badResource}).out' --out cue
	expect_failure cue eval pillars/top-and-bottom.cue -e '(#Pillars["top-and-bottom"].negative.conflict.left & #Pillars["top-and-bottom"].negative.conflict.right)' --out cue
	expect_failure cue eval pillars/bounds.cue -e '(#Pillars["bounds"].#NonEmptyText & #Pillars["bounds"].negative.emptyDescription)' --out cue
	expect_failure cue eval pillars/bounds.cue -e '(#Pillars["bounds"].#KernelID & #Pillars["bounds"].negative.badID)' --out cue
	expect_failure cue eval pillars/hidden-and-let.cue -e '(#Pillars["hidden-and-let"]._generatedRole & #Pillars["hidden-and-let"].negative.privateConflict)' --out cue
	expect_failure cue eval pillars/cycles.cue -e '#Pillars["cycles"].negative.arithmeticCycle.expression.x' --out cue
	expect_failure cue eval pillars/lists.cue -e '(#Pillars["lists"].#NonEmptyKeyList & #Pillars["lists"].negative.emptyCommands)' --out cue
	expect_failure cue eval pillars/lists.cue -e '(#Pillars["lists"].#AuthorityKeyTuple & #Pillars["lists"].negative.badTuple)' --out cue
	expect_failure cue eval pillars/attributes.cue -e '(#Pillars["attributes"].#TaggedKernelSelector & #Pillars["attributes"].negative.invalidKind)' --out cue
}

validate_idioms() {
	cue vet ./idioms
	cue export ./idioms -e cueIdiomSources --out cue >/dev/null
}

validate_projections() {
	cue vet ./projections
	cue vet ./projections/code-intel
	cue export ./projections/code-intel -e expectedCodeIntelProfile --out cue >/dev/null
	cue export ./projections/code-intel -e codeIntelProfileFeedbackReport --out cue >/dev/null
}

validate_meta
validate_pillars
validate_idioms
validate_projections

cue vet ./exports

cue export ./exports -e codeIntelProfileExpectation --out cue >/dev/null
