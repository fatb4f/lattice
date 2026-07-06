package codexdrift

latticeReference: #DriftModel & {
	schema: "codex-drift-model.v1"

	surfaceIDs: [
		"pillar-suite",
		"meta-kernel",
		"validation-controller",
		"codex-drift-kg",
		"generated-codex-facts",
	]

	surfaces: close({
		"pillar-suite": {
			id:          "pillar-suite"
			kind:        "authority"
			description: "Flat executable 16-pillar CUE idiom suite."

			requiredPaths: [
				"pillars/unification.cue",
				"pillars/definitions.cue",
				"pillars/defaults.cue",
				"pillars/disjunctions.cue",
				"pillars/comprehensions.cue",
				"pillars/closedness.cue",
				"pillars/subsumption.cue",
				"pillars/negative-fixtures.cue",
				"pillars/projections.cue",
				"pillars/constructors.cue",
				"pillars/top-and-bottom.cue",
				"pillars/bounds.cue",
				"pillars/hidden-and-let.cue",
				"pillars/cycles.cue",
				"pillars/lists.cue",
				"pillars/attributes.cue",
			]

			forbiddenPaths: [
				"pillars/catalog.cue",
				"pillars/pillars.cue",
				"pillars/language_pillars.cue",
				"pillars/contract_pillars.cue",
				"pillars/adapter_pillars.cue",
				"pillars/idiom_families.cue",
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
				"pillars/kg.cue",
				"pillars/kg",
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
		"pillar-suite-required-path-present": {
			id:       "pillar-suite-required-path-present"
			kind:     "missing-required-surface"
			surface:  "pillar-suite"
			severity: "violation"
			response: "block"
			reason:   "A required pillar suite authority file is missing."
		}

		"no-pillar-registry": {
			id:       "no-pillar-registry"
			kind:     "duplicate-authority"
			surface:  "pillar-suite"
			severity: "violation"
			response: "block"
			reason:   "The flat pillar files are authority; catalog-style registries duplicate authority."
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
			reason:   "The KG layer checks Codex drift and must not enter meta or pillar validation."
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
