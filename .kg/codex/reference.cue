package codexdrift

latticeReference: #DriftModel & {
	schema: "codex-drift-model.v1"

	surfaceIDs: [
		"idiom-suite",
		"source-registry",
		"meta-kernel",
		"validation-controller",
		"codex-drift-kg",
		"generated-codex-facts",
	]

	surfaces: close({
		"idiom-suite": {
			id:          "idiom-suite"
			kind:        "authority"
			description: "Flat executable 16-idiom CUE kernel pattern suite."

			requiredPaths: [
				"idioms/unification.cue",
				"idioms/definitions.cue",
				"idioms/defaults.cue",
				"idioms/disjunctions.cue",
				"idioms/comprehensions.cue",
				"idioms/closedness.cue",
				"idioms/subsumption.cue",
				"idioms/negative-fixtures.cue",
				"idioms/projections.cue",
				"idioms/constructors.cue",
				"idioms/top-and-bottom.cue",
				"idioms/bounds.cue",
				"idioms/hidden-and-let.cue",
				"idioms/cycles.cue",
				"idioms/lists.cue",
				"idioms/attributes.cue",
			]

			forbiddenPaths: [
				"pillars",
				"idioms/catalog.cue",
				"idioms/pillars.cue",
				"idioms/language_pillars.cue",
				"idioms/contract_pillars.cue",
				"idioms/adapter_pillars.cue",
				"idioms/idiom_families.cue",
			]
		}

		"source-registry": {
			id:          "source-registry"
			kind:        "verification"
			description: "Reference/source registry for CUE idiom research inputs."

			requiredPaths: [
				"sources/apercue.cue",
				"sources/cue_by_example.cue",
				"sources/cuetorials.cue",
				"sources/official_docs.cue",
				"sources/sources.cue",
			]

			forbiddenPaths: [
				"idioms/sources.cue",
				"idioms/official_docs.cue",
				"idioms/cue_by_example.cue",
				"idioms/cuetorials.cue",
				"idioms/apercue.cue",
			]
		}

		"meta-kernel": {
			id:          "meta-kernel"
			kind:        "authority"
			description: "Reusable CUE validation and proof kernel."

			requiredPaths: [
				"meta/kernel.cue",
			]

			protectedPaths: [
				"meta/kernel.cue",
			]
		}

		"validation-controller": {
			id:          "validation-controller"
			kind:        "controller"
			description: "Shell controller for selector validation and destructive probes."

			requiredPaths: [
				"scripts/validate-domain.sh",
			]

			protectedPaths: [
				"scripts/validate-domain.sh",
			]
		}

		"codex-drift-kg": {
			id:          "codex-drift-kg"
			kind:        "policy"
			description: "Codex drift policy outside the idiom validation path."

			requiredPaths: [
				".kg/codex/model.cue",
				".kg/codex/reference.cue",
				".kg/codex/checks.cue",
				".kg/codex/kg.cue",
				".kg/codex/policy.cue",
				".kg/codex/scripts/drift-facts",
				".kg/codex/scripts/drift-check",
				".kg/codex/scripts/drift-hook",
			]

			protectedPaths: [
				".kg/codex/model.cue",
				".kg/codex/reference.cue",
				".kg/codex/checks.cue",
				".kg/codex/kg.cue",
				".kg/codex/policy.cue",
				".kg/codex/scripts/drift-facts",
				".kg/codex/scripts/drift-check",
				".kg/codex/scripts/drift-hook",
			]

			forbiddenPaths: [
				"idioms/kg.cue",
				"idioms/kg",
				"meta/kg.cue",
				"meta/kg",
			]
		}

		"generated-codex-facts": {
			id:          "generated-codex-facts"
			kind:        "generated"
			description: "Generated observations from git diff, repo scan, and validation output."

			protectedPaths: [
				"generated/codex",
			]
		}
	})

	rules: close({
		"idiom-suite-required-path-present": {
			id:       "idiom-suite-required-path-present"
			kind:     "missing-required-surface"
			surface:  "idiom-suite"
			severity: "violation"
			response: "block"
			reason:   "A required idiom suite authority file is missing."
		}

		"no-idiom-registry": {
			id:       "no-idiom-registry"
			kind:     "duplicate-authority"
			surface:  "idiom-suite"
			severity: "violation"
			response: "block"
			reason:   "The flat idiom files are authority; catalog-style registries duplicate authority."
		}

		"source-registry-required-path-present": {
			id:       "source-registry-required-path-present"
			kind:     "missing-required-surface"
			surface:  "source-registry"
			severity: "violation"
			response: "block"
			reason:   "A required source registry file is missing."
		}

		"sources-outside-idioms": {
			id:       "sources-outside-idioms"
			kind:     "duplicate-authority"
			surface:  "source-registry"
			severity: "violation"
			response: "block"
			reason:   "Reference source registries belong under sources/, not idioms/."
		}

		"meta-kernel-required-path-present": {
			id:       "meta-kernel-required-path-present"
			kind:     "missing-required-surface"
			surface:  "meta-kernel"
			severity: "violation"
			response: "block"
			reason:   "The meta kernel authority file is missing."
		}

		"validation-controller-required-path-present": {
			id:       "validation-controller-required-path-present"
			kind:     "missing-required-surface"
			surface:  "validation-controller"
			severity: "violation"
			response: "block"
			reason:   "The validation controller script is missing."
		}

		"codex-drift-kg-required-path-present": {
			id:       "codex-drift-kg-required-path-present"
			kind:     "missing-required-surface"
			surface:  "codex-drift-kg"
			severity: "violation"
			response: "block"
			reason:   "A required Codex drift KG file is missing."
		}

		"kg-outside-validator": {
			id:       "kg-outside-validator"
			kind:     "adapter-boundary-crossed"
			surface:  "codex-drift-kg"
			severity: "violation"
			response: "block"
			reason:   "The KG layer checks Codex drift and must not enter meta or idiom validation."
		}

		"codex-drift-kg-change-review": {
			id:       "codex-drift-kg-change-review"
			kind:     "policy-violated"
			surface:  "codex-drift-kg"
			severity: "warning"
			response: "require-review"
			reason:   "Codex drift KG changes alter advisory and enforcement behavior."
		}

		"kernel-change-review": {
			id:       "kernel-change-review"
			kind:     "authority-moved"
			surface:  "meta-kernel"
			severity: "warning"
			response: "require-review"
			reason:   "Kernel validation vocabulary changes alter the proof surface."
		}

		"validator-change-review": {
			id:       "validator-change-review"
			kind:     "controller-bypassed"
			surface:  "validation-controller"
			severity: "warning"
			response: "require-review"
			reason:   "Validator changes may weaken selector coverage or expected-failure probes."
		}

		"generated-facts-not-authority": {
			id:       "generated-facts-not-authority"
			kind:     "generated-promoted-to-authority"
			surface:  "generated-codex-facts"
			severity: "violation"
			response: "block"
			reason:   "Generated Codex observations are sensor output and must not become source authority."
		}
	})
}
