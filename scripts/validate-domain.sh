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
	local probe="patterns/.closedness-extra-field-probe.cue"
	cat >"$probe" <<'EOF'
package patterns

_probe: #ClosedKernelResource & #Patterns["closedness"].negative.extraField
EOF
	if cue eval patterns/closedness.cue "$probe" -e _probe --out cue >/dev/null 2>&1; then
		rm -f "$probe"
		printf 'expected failure but closedness extra-field probe passed\n'
		return 1
	fi
	rm -f "$probe"
}

kg_files=(
	.kg/codex/model.cue
	.kg/codex/reference.cue
	.kg/codex/checks.cue
	.kg/codex/kg.cue
	.kg/codex/policy.cue
)

kg_role_dirs=(
	.kg/codex/core
	.kg/codex/vocab
	.kg/codex/ext
	.kg/codex/aggregate
	.kg/codex/mcp
	.kg/codex/tests/valid
	.kg/codex/tests/invalid
)

kg_pattern_paths() {
	cue export "${kg_files[@]}" -e 'latticeReference.surfaces["pattern-suite"].requiredPaths' --out json | jq -r '.[]'
}

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
		id: "missing-read-state"
		resources: {}
		operations: {
			"read-missing": {
				kind:        "inspect"
				description: "Reads missing resource"
				reads: {"missing-resource": true}
				writes: {}
				creates: {}
				requiresGates: {}
				requiresWitnesses: {}
			}
		}
		gates: {}
		witnesses: {}
	}}).out' --out cue

	expect_failure cue export ./meta -e '(#MakeClosedObligationState & {"in": {
		id: "missing-write-state"
		resources: {}
		operations: {
			"write-missing": {
				kind:        "inspect"
				description: "Writes missing resource"
				reads: {}
				writes: {"missing-resource": true}
				creates: {}
				requiresGates: {}
				requiresWitnesses: {}
			}
		}
		gates: {}
		witnesses: {}
	}}).out' --out cue

	expect_failure cue export ./meta -e '(#MakeClosedObligationState & {"in": {
		id: "missing-gate-state"
		resources: {}
		operations: {
			"require-missing-gate": {
				kind:        "inspect"
				description: "Requires missing gate"
				reads: {}
				writes: {}
				creates: {}
				requiresGates: {"missing-gate": true}
				requiresWitnesses: {}
			}
		}
		gates: {}
		witnesses: {}
	}}).out' --out cue

	expect_failure cue export ./meta -e '(#MakeClosedObligationState & {"in": {
		id: "missing-witness-state"
		resources: {}
		operations: {
			"require-missing-witness": {
				kind:        "inspect"
				description: "Requires missing witness"
				reads: {}
				writes: {}
				creates: {}
				requiresGates: {}
				requiresWitnesses: {"missing-witness": true}
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

validate_patterns() {
	local expected
	expected="$(kg_pattern_paths | sort)"
	local actual
	actual="$(find patterns -type f -name '*.cue' | sort)"
	if [[ "$actual" != "$expected" ]]; then
		printf 'unexpected patterns/ surface\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual"
		return 1
	fi

	local pattern_file
	while IFS= read -r pattern_file; do
		[[ "$pattern_file" == "patterns/schema.cue" ]] && continue

		local pattern_id
		pattern_id="$(basename "$pattern_file" .cue)"
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].checks" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].canonical" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].positive" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].negative" --out cue >/dev/null
	done < <(kg_pattern_paths)

	cue vet ./patterns
	cue export ./patterns -e 'cueVersionCoverage["v0.17.0"]' --out cue >/dev/null
	cue export ./patterns -e 'cueVersionCoverage["v0.17.0"].features.shortcircuit.maturity' --out cue >/dev/null
	cue export ./patterns -e 'cueVersionCoverage["v0.17.0"].features.jsonschema_encoder.maturity' --out cue >/dev/null

	expect_failure cue eval patterns/unification.cue -e '(#Patterns["unification"].#KernelResource & #Patterns["unification"].negative.incompatibleRole)' --out cue
	expect_failure cue eval patterns/definitions.cue -e '(#Patterns["definitions"].#KernelResourceRef & #Patterns["definitions"].negative.invalidRole)' --out cue
	expect_failure cue eval patterns/defaults.cue -e '(#Patterns["defaults"].#KernelGatePolicy & #Patterns["defaults"].negative.invalidRequired)' --out cue
	expect_failure cue eval patterns/disjunctions.cue -e '(#Patterns["disjunctions"].#KernelOperationIntent & #Patterns["disjunctions"].negative.invalidSelector)' --out cue
	expect_failure cue eval patterns/comprehensions.cue -e '(#Patterns["comprehensions"].#ResourceInputs & #Patterns["comprehensions"].negative.badServicePort)' --out cue
	expect_closedness_extra_field_failure
	expect_failure cue eval patterns/subsumption.cue -e '(#Patterns["subsumption"].#AuthorityResource & #Patterns["subsumption"].negative.incompatibleField)' --out cue
	expect_failure cue eval patterns/negative-fixtures.cue -e '(meta.#MakeNegativeFixture & {in: #Patterns["negative-fixtures"].negative.proof}).out.probe.proof' --out cue
	expect_failure cue eval patterns/projections.cue -e '(meta.#NoWideningProof & {
		authority: #Patterns["projections"]._closedAuthority
		target: (meta.#MakeClosedObligationState & {
			in: #Patterns["projections"]._authority & #Patterns["projections"].negative.widenedProjection
		}).out
	})' --out cue
	expect_failure cue eval patterns/constructors.cue -e '(#Patterns["constructors"].#MakeResource & {in: #Patterns["constructors"].negative.badResource}).out' --out cue
	expect_failure cue eval patterns/top-and-bottom.cue -e '(#Patterns["top-and-bottom"].negative.conflict.left & #Patterns["top-and-bottom"].negative.conflict.right)' --out cue
	expect_failure cue eval patterns/bounds.cue -e '(#Patterns["bounds"].#NonEmptyText & #Patterns["bounds"].negative.emptyDescription)' --out cue
	expect_failure cue eval patterns/bounds.cue -e '(#Patterns["bounds"].#KernelID & #Patterns["bounds"].negative.badID)' --out cue
	expect_failure cue eval patterns/hidden-and-let.cue -e '(#Patterns["hidden-and-let"]._generatedRole & #Patterns["hidden-and-let"].negative.privateConflict)' --out cue
	expect_failure cue eval patterns/cycles.cue -e '#Patterns["cycles"].negative.arithmeticCycle.expression.x' --out cue
	expect_failure cue eval patterns/lists.cue -e '(#Patterns["lists"].#NonEmptyKeyList & #Patterns["lists"].negative.emptyCommands)' --out cue
	expect_failure cue eval patterns/lists.cue -e '(#Patterns["lists"].#AuthorityKeyTuple & #Patterns["lists"].negative.badTuple)' --out cue
	expect_failure cue eval patterns/attributes.cue -e '(#Patterns["attributes"].#TaggedKernelSelector & #Patterns["attributes"].negative.invalidKind)' --out cue
}

validate_sources() {
	cue vet ./sources
	cue export ./sources -e cuePatternSources --out cue >/dev/null
}

validate_projections() {
	cue vet ./projections
	cue vet ./projections/code-intel
	cue export ./projections/code-intel -e expectedCodeIntelProfile --out cue >/dev/null
	cue export ./projections/code-intel -e codeIntelProfileFeedbackReport --out cue >/dev/null
}

validate_profiles() {
	cue vet ./profiles/control
	cue export ./profiles/control -e '#Techniques["constructor-normalization-loop"].control.feedback.stability' --out cue >/dev/null
	cue export ./profiles/control -e '#Techniques["projection-observer-loop"].control.sensors' --out cue >/dev/null
	cue export ./profiles/control -e '#Techniques["fixture-error-signal-loop"].checks' --out cue >/dev/null
}

validate_kg() {
	cue vet "${kg_files[@]}"
	local kg_dir
	for kg_dir in "${kg_role_dirs[@]}"; do
		cue vet -c "$kg_dir"/*.cue
	done
	cue export "${kg_files[@]}" -e 'latticeReference.patternClassifications' --out cue >/dev/null
	cue export "${kg_files[@]}" -e 'latticeReference.surfaces["pattern-suite"].requiredPaths' --out json >/dev/null
	cue export .kg/codex/aggregate/*.cue -e promotionStatus --out json >/dev/null
	cue export .kg/codex/mcp/*.cue -e mcpPolicy --out json >/dev/null
}

validate_meta
validate_kg
validate_patterns
validate_sources
validate_projections
validate_profiles

cue vet ./exports

cue export ./exports -e codeIntelProfileExpectation --out cue >/dev/null
