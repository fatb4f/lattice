#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir/.."

export KG_BIN="${KG_BIN:-$PWD/.cache/bin/kg}"
export PATH="$PWD/.cache/bin:$PATH"
scripts/require-toolchain.sh

validation_runtime=$(mktemp -d "${TMPDIR:-/tmp}/lattice-validation.XXXXXX")
shared_index_envelope="$validation_runtime/full-index.json"
diagnostic_bundle="$validation_runtime/diagnostics-review"
trap 'rm -rf "$validation_runtime"' EXIT

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

kg_declared_paths() {
	cue export "${kg_files[@]}" -e 'latticeReference.surfaces["codex-drift-kg"].requiredPaths' --out json | jq -r '.[]'
}

project_kg_declared_paths() {
	cue export "${kg_files[@]}" -e 'latticeReference.surfaces["project-knowledge-kg"].requiredPaths' --out json | jq -r '.[]'
}

validate_kg_runtime() {
	cue vet ./.kg/context/*.cue
	cue export ./.kg/vocab/context.cue -e context --out json >/dev/null
	cue export ./.kb/cue.mod/pkg/quicue.ca/kg/vocab/context.cue -e context --out json >/dev/null
	cue export ./.kg/context/*.cue -e selectionPolicy --out json >/dev/null
	cue export ./.kg/context/*.cue -e contextRuntimeClosed --out json >/dev/null
	expect_failure cue export ./.kg/context/*.cue -e '(#GeneratedArtifact & {path: ".kg/generated/context/prompt-routes.json", role: "static-export", runtimeInput: true})' --out cue

	local generated_context_input
	for generated_context_input in \
		.kg/generated/context/context-index.json \
		.kg/generated/context/resolver-fragments.json \
		.kg/generated/context/prompt-routes.json \
		.kg/generated/context/route-inventory.json; do
		if [[ -e "$generated_context_input" ]]; then
			printf 'forbidden generated runtime context input exists: %s\n' "$generated_context_input"
			return 1
		fi
	done

	local hook_output prompt_context audit_binding audit_digest audit_path route_packet packet_probe status
	if [[ -f "$diagnostic_bundle/packets/hook-prompt-context.json" && -f "$diagnostic_bundle/packets/hook-audit.json" ]]; then
		prompt_context=$(<"$diagnostic_bundle/packets/hook-prompt-context.json")
		hook_output=$(jq -cn --arg context "$prompt_context" '{
			hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $context}
		}')
	else
		hook_output=$(printf '{"hook_event_name":"UserPromptSubmit","prompt":"project knowledge graph context"}' |
			.kg/hooks/codex/user-prompt-submit)
	fi
	printf '%s\n' "$hook_output" |
		jq -e '.hookSpecificOutput.hookEventName == "UserPromptSubmit"
			and (.hookSpecificOutput.additionalContext | fromjson
				| .schema == "lattice.codex-prompt-context.v1"
				and ((keys | sort) == ["indexInputDigest", "instruction", "policyDigest", "requestId", "route", "schema", "selection"])
				and (.selection.resources | length) <= 8
				and (.selection.resources | all(test("^(kg|codex)://")))
				and (.instruction | test("Use MCP resources")))' >/dev/null
	prompt_context=$(printf '%s\n' "$hook_output" | jq -r '.hookSpecificOutput.additionalContext')
	[[ $(printf '%s' "$prompt_context" | wc -c) -le 4096 ]]
	audit_path="$diagnostic_bundle/packets/hook-audit.json"
	audit_binding="$diagnostic_bundle/packets/hook-audit-binding.json"
	[[ -f "$audit_binding" ]]
	audit_digest=$(jq -r '.auditArtifact.digest' "$audit_binding")
	jq -e '.gateSummary.status == "pass"
		and (.gateSummary.evidenceDigest | startswith("sha256:"))
		and (.auditArtifact.uri | startswith("artifact://lattice/hook-audit/sha256:"))
		and (.auditArtifact.digest | startswith("sha256:"))' "$audit_binding" >/dev/null
	[[ -f "$audit_path" ]]
	[[ "sha256:$(sha256sum "$audit_path" | awk '{print $1}')" == "$audit_digest" ]]
	route_packet=$(<"$audit_path")
	printf '%s\n' "$route_packet" |
		jq -e '.schema == "lattice.context-route-packet.v1"
			and .budget.preferMCP == true
			and (.selection.entities | length) <= .budget.maxInlineEntities
			and (.selection.resources | length) <= .budget.maxResourceHandles
			and (.gates["no-generated-input"].status == "pass")
			and (.gates["no-plugin-cache-input"].status == "pass")
			and (.gates["no-raw-transcript-input"].status == "pass")
			and ([.gates[] | select(.status == "pass") | .evidence[]
					| (.observedAt <= .expiresAt)
					and (.ref == ("inline:" + .digest))
					and (.record.exitStatus == 0)
					and (.record.inputManifest.inputDigest | startswith("sha256:"))
					and (.record.inputManifest.executionManifestDigest | startswith("sha256:"))
					and (.record.inputManifest.inputs | length == 5)
					and (.record.inputManifest.outputs | length == 2)
					and (.record.resultDigest == .digest)] | all)
				and ([.gates[].evidence[0].digest] | unique | length == 6)
				and ([.candidates[] | select(.disposition == "included") | .entityId] == .selection.entities)' >/dev/null
	local digest_root_a digest_root_b digest_a digest_b manifest_a manifest_b input_digest
	digest_root_a=$(mktemp -d "${TMPDIR:-/tmp}/lattice-digest-a.XXXXXX")
	digest_root_b=$(mktemp -d "${TMPDIR:-/tmp}/lattice-digest-b.XXXXXX")
	cp -R .kb/. "$digest_root_a/"
	cp -R .kb/. "$digest_root_b/"
	digest_a=$(cd "$digest_root_a" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | awk '{print "sha256:" $1}')
	digest_b=$(cd "$digest_root_b" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum | sha256sum | awk '{print "sha256:" $1}')
	[[ "$digest_a" == "$digest_b" ]]
	input_digest=$(printf '%s\n' "$route_packet" | jq -r '.gates["kb-valid"].evidence[0].record.inputManifest.inputDigest')
	manifest_a=$(printf '%s\n' "$route_packet" | jq -cS '.gates["kb-valid"].evidence[0].record.inputManifest | .outputs |= map(.path = ("/tmp/run-a/" + .role))')
	manifest_b=$(printf '%s\n' "$route_packet" | jq -cS '.gates["kb-valid"].evidence[0].record.inputManifest | .outputs |= map(.path = ("/tmp/run-b/" + .role))')
	[[ "$input_digest" == "$(printf '%s\n' "$manifest_a" | jq -r '.inputDigest')" ]]
	[[ "$input_digest" == "$(printf '%s\n' "$manifest_b" | jq -r '.inputDigest')" ]]
	[[ "$(printf '%s' "$manifest_a" | sha256sum | awk '{print $1}')" != "$(printf '%s' "$manifest_b" | sha256sum | awk '{print $1}')" ]]
	rm -rf "$digest_root_a" "$digest_root_b"
	packet_probe=$(mktemp "${TMPDIR:-/tmp}/lattice-packet-probe.XXXXXX.cue")
	trap 'rm -f "$packet_probe"' RETURN

	for status in fail skipped unsupported indeterminate; do
		{
			printf 'package context\n\n_probe: '
			printf '%s\n' "$route_packet" | jq --arg status "$status" '.gates["kb-valid"].status = $status'
		} >"$packet_probe"
		expect_failure cue export ./.kg/context/*.cue "$packet_probe" -e '(_probe & #RoutePolicyBoundPacket)' --out json
	done

	{
		printf 'package context\n\n_probe: '
		printf '%s\n' "$route_packet" | jq 'del(.gates["kb-valid"])'
	} >"$packet_probe"
	expect_failure cue export ./.kg/context/*.cue "$packet_probe" -e '(_probe & #RoutePolicyBoundPacket)' --out json

	{
		printf 'package context\n\n_probe: '
		printf '%s\n' "$route_packet" | jq '.evaluatedAt = "2099-01-01T00:00:00Z"'
	} >"$packet_probe"
	expect_failure cue export ./.kg/context/*.cue "$packet_probe" -e '(_probe & #RoutePolicyBoundPacket)' --out json

	{
		printf 'package context\n\n_probe: '
		printf '%s\n' "$route_packet" | jq '.gates["kb-valid"].evidence[0].ref = "inline:sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"'
	} >"$packet_probe"
	expect_failure cue export ./.kg/context/*.cue "$packet_probe" -e '(_probe & #RoutePolicyBoundPacket)' --out json

	{
		printf 'package context\n\n_probe: '
		printf '%s\n' "$route_packet" | jq 'del(.gates["kb-valid"].evidence[0].record)'
	} >"$packet_probe"
	expect_failure cue export ./.kg/context/*.cue "$packet_probe" -e '(_probe & #RoutePolicyBoundPacket)' --out json
	expect_failure cue eval ./.kg/context -e '(#ValidatedContextPacket & {
		evaluatedAt: "2099-01-01T00:00:00Z"
		gates: {"kb-valid": {evaluatedAt: "2026-01-01T00:00:00Z"}}
	}).gates["kb-valid"].evaluatedAt'
	expect_failure cue export ./.kg/context -e '(#ValidatedContextGateResults & {})' --out json
	expect_failure sh -c 'printf '\''{"hook_event_name":"UserPromptSubmit","messages":[{"role":"user","content":"raw"}]}\n'\'' | .kg/hooks/codex/user-prompt-submit >/dev/null'
	expect_failure sh -c 'printf '\''{"hook_event_name":"UserPromptSubmit","message":[{"role":"user","content":"raw"}]}\n'\'' | .kg/hooks/codex/user-prompt-submit >/dev/null'
	expect_failure sh -c 'printf '\''{"hook_event_name":"UserPromptSubmit","message":{"messages":[{"role":"user","content":"raw"}]}}\n'\'' | .kg/hooks/codex/user-prompt-submit >/dev/null'
	expect_failure sh -c 'printf '\''user: raw transcript\nassistant: response\n'\'' | .kg/hooks/codex/user-prompt-submit >/dev/null'
	expect_failure sh -c 'printf '\''{"hook_event_name":"UserPromptSubmit","prompt":"one","message":"two"}\n'\'' | .kg/hooks/codex/user-prompt-submit >/dev/null'
	expect_failure sh -c 'printf '\''{"hook_event_name":"UserPromptSubmit","prompt":"raw","undeclared":true}\n'\'' | .kg/hooks/codex/user-prompt-submit >/dev/null'

	cue export ./.kg/context -e _negativeGateFixtures --out json |
		jq -e '.fail.status == "fail"
			and .skipped.status == "skipped"
			and .unsupported.status == "unsupported"
			and .indeterminate.status == "indeterminate"' >/dev/null
	expect_failure cue export ./.kg/context -e '(#PassingGateResult & {
		gateId: "missing-evidence-pass", checker: "fixture", status: "pass", policy: "fail-closed",
		startedAt: "2026-01-01T00:00:00Z", completedAt: "2026-01-01T00:00:00Z", evaluatedAt: "2026-01-01T00:00:00Z",
		inputs: ["fixture:missing-evidence"], evidence: [], diagnostics: []
	})' --out json
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
		if [[ "$kg_dir" == ".kg/codex/aggregate" ]]; then
			cue vet -c "${kg_files[@]}" "$kg_dir"/*.cue
		elif [[ "$kg_dir" == ".kg/codex/tests/valid" ]]; then
			cue vet -c "${kg_files[@]}" .kg/codex/aggregate/*.cue "$kg_dir"/*.cue
		else
			cue vet -c "$kg_dir"/*.cue
		fi
	done

	local expected_kg_paths
	expected_kg_paths="$(kg_declared_paths | sort)"
	local actual_kg_paths
	actual_kg_paths="$(find .kg/codex -type f | sort)"
	if [[ "$actual_kg_paths" != "$expected_kg_paths" ]]; then
		printf 'unexpected .kg/codex surface\nexpected:\n%s\nactual:\n%s\n' "$expected_kg_paths" "$actual_kg_paths"
		return 1
	fi

	cue export "${kg_files[@]}" -e 'latticeReference.patternClassifications' --out cue >/dev/null
	cue export "${kg_files[@]}" -e 'latticeReference.surfaces["pattern-suite"].requiredPaths' --out json >/dev/null
	cue export "${kg_files[@]}" .kg/codex/aggregate/*.cue -e promotionStatus --out json >/dev/null
	cue export "${kg_files[@]}" .kg/codex/aggregate/*.cue -e codexKGIndex --out json >/dev/null
	cue export "${kg_files[@]}" .kg/codex/aggregate/*.cue .kg/codex/tests/valid/*.cue -e blockedPhaseWatchdog --out json >/dev/null
	cue export "${kg_files[@]}" .kg/codex/aggregate/*.cue .kg/codex/tests/valid/*.cue -e admissiblePhaseWatchdog --out json >/dev/null
	cue export .kg/codex/mcp/*.cue -e mcpPolicy --out json >/dev/null
	expect_failure cue export .kg/codex/mcp/*.cue .kg/codex/tests/invalid/mutation-tool.cue -e '(#ReadOnlyMCPTool & invalidMutationTool)' --out cue
	cue export "${kg_files[@]}" .kg/codex/tests/invalid/self-context-fixtures.cue -e '(#SelfContextChecks & {selfContext: invalidGeneratedAuthoritySelfContext}).findings[0] & {kind: "generated-promoted-to-authority", response: "block"}' --out cue >/dev/null
	cue export "${kg_files[@]}" .kg/codex/tests/invalid/self-context-fixtures.cue -e '(#SelfContextChecks & {selfContext: invalidProviderRoleSelfContext}).findings[0] & {kind: "policy-violated", response: "block"}' --out cue >/dev/null
}

validate_project_kg() {
	if ! command -v kg >/dev/null 2>&1; then
		printf 'kg CLI required for .kb validation\n' >&2
		return 1
	fi

	local expected_project_kg_paths
	expected_project_kg_paths="$(project_kg_declared_paths | sort)"
	local actual_project_kg_paths
	actual_project_kg_paths="$(find .kb -type f | sort)"
	if [[ "$actual_project_kg_paths" != "$expected_project_kg_paths" ]]; then
		printf 'unexpected .kb surface\nexpected:\n%s\nactual:\n%s\n' "$expected_project_kg_paths" "$actual_project_kg_paths"
		return 1
	fi

	kg vet >/dev/null
	uv run lattice index build --out "$shared_index_envelope"
	jq -e '
		.graph.context.name == .graph.project
		and (.graph.entities["project-context"].collection == "context")
		and ([.graph.decisions, .graph.insights, .graph.rejected, .graph.patterns,
			.graph.sources, .graph.tasks, .graph.workspace] | all(type == "object"))
	' "$shared_index_envelope" >/dev/null
	kg settle >/dev/null
	(cd .kb && cue vet .)
	(cd .kb/decisions && cue vet .)
	(cd .kb/insights && cue vet .)
	(cd .kb/patterns && cue vet .)
	(cd .kb/rejected && cue vet .)
	(cd .kb/tasks && cue vet .)
	(cd .kb/workspace && cue vet .)
	(cd .kb/sources && cue vet .)
	(cd .kb && cue export . -e kb --out json >/dev/null)
	(cd .kb && cue export . -e '_index.entities' --out json >/dev/null)
	(cd .kb && cue export . -e _graphAssemblyClosure --out json >/dev/null)
	expect_failure bash -c 'cd .kb && cue export . fixtures/manifest-only-graph.cue -e _graphAssemblyClosure --out json'
	expect_failure bash -c 'cd .kb && cue export . fixtures/collection-only-graph.cue -e _graphAssemblyClosure --out json'
	(cd .kb/tasks && cue export . -e '(#TaskV1 & validTaskV1Fixture)' --out json >/dev/null)
	expect_failure bash -c 'cd .kb/tasks && cue export . -e "(#TaskV1 & invalidTaskV1Fixture)" --out json'
	(cd .kb/sources && cue export . -e '(#SourceV1 & validSourceV1Fixture)' --out json >/dev/null)
	expect_failure bash -c 'cd .kb/sources && cue export . -e "(#SourceV1 & invalidSourceV1Fixture)" --out json'
	(cd .kb/workspace && cue export . -e '(#WorkspaceV1 & validWorkspaceV1Fixture)' --out json >/dev/null)
	expect_failure bash -c 'cd .kb/workspace && cue export . -e "(#WorkspaceV1 & invalidWorkspaceV1Fixture)" --out json'
	node --test .kg/mcp/server.test.js
	bun .kg/mcp/server.js </dev/null
}

validate_python_runtime() {
	uv sync --locked
	uv run lattice diagnostics runtime-surface --root .
	uv run pytest -m "not integration"
	cue vet ./.kg/diagnostics/*.cue
	uv run lattice diagnose --envelope "$shared_index_envelope" --format json --bundle "$diagnostic_bundle" |
		jq -e '.summary.status == "pass" and .summary.counts.nonPassing == 0' >/dev/null
	jq -e '.schema == "lattice.diagnostics-review-bundle.v1"
		and (.files | index("checks.json") != null)
		and (.files | index("logs/diagnostics.log") != null)
		and (.files | index("workbook.html") != null)' "$diagnostic_bundle/manifest.json" >/dev/null
}

validate_meta
validate_kg
validate_project_kg
validate_python_runtime
validate_kg_runtime
validate_patterns
validate_sources
validate_projections
validate_profiles

cue vet ./exports

cue export ./exports -e codeIntelProfileExpectation --out cue >/dev/null
