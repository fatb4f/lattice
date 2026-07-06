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

pattern_files=(
	patterns/schema.cue
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

pattern_entry_files=(
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
	expected="$(printf '%s\n' "${pattern_files[@]}" | sort)"
	local actual
	actual="$(find patterns -maxdepth 1 -type f -name '*.cue' | sort)"
	if [[ "$actual" != "$expected" ]]; then
		printf 'unexpected patterns/ surface\nexpected:\n%s\nactual:\n%s\n' "$expected" "$actual"
		return 1
	fi

	local pattern_file
	for pattern_file in "${pattern_entry_files[@]}"; do
		local pattern_id
		pattern_id="$(basename "$pattern_file" .cue)"
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].name" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].id" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].family" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].status" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].summary" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].problem" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].demonstrates" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].abstraction" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].fixtures" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].checks" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].promotion" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].canonical" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].positive" --out cue >/dev/null
		cue eval patterns/schema.cue "$pattern_file" -e "#Patterns[\"$pattern_id\"].negative" --out cue >/dev/null
	done

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

validate_meta
validate_patterns
validate_sources
validate_projections

cue vet ./exports

cue export ./exports -e codeIntelProfileExpectation --out cue >/dev/null
