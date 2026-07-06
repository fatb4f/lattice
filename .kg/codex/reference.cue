package codexdrift

latticeReference: #DriftModel & {
	schema: "codex-drift-model.v1"

	surfaceIDs: [
		"pattern-suite",
		"control-profile",
		"source-registry",
		"meta-kernel",
		"validation-controller",
		"codex-drift-kg",
		"generated-codex-facts",
	]

	surfaces: close({
		"pattern-suite": {
			id:          "pattern-suite"
			kind:        "authority"
			description: "Flat executable 16-pattern CUE kernel pattern suite."

			requiredPaths: [
				"patterns/schema.cue",
				"patterns/unification.cue",
				"patterns/definitions.cue",
				"patterns/defaults.cue",
				"patterns/disjunctions.cue",
				"patterns/comprehensions.cue",
				"patterns/closedness.cue",
				"patterns/subsumption.cue",
				"patterns/negative-fixtures.cue",
				"patterns/projections.cue",
				"patterns/constructors.cue",
				"patterns/top-and-bottom.cue",
				"patterns/bounds.cue",
				"patterns/hidden-and-let.cue",
				"patterns/cycles.cue",
				"patterns/lists.cue",
				"patterns/attributes.cue",
			]

			forbiddenPaths: [
				"pillars",
				"idioms",
				"patterns/catalog.cue",
				"patterns/pillars.cue",
				"patterns/language_pillars.cue",
				"patterns/contract_pillars.cue",
				"patterns/adapter_pillars.cue",
				"patterns/idiom_families.cue",
			]
		}

		"control-profile": {
			id:          "control-profile"
			kind:        "verification"
			description: "Profile catalogue for deriving closed-loop feedback techniques from idiomatic patterns."

			requiredPaths: [
				"profiles/control/schema.cue",
				"profiles/control/techniques.cue",
			]

			forbiddenPaths: [
				"patterns/control",
				"patterns/control.cue",
			]
		}

		"source-registry": {
			id:          "source-registry"
			kind:        "verification"
			description: "Reference/source registry for CUE pattern research inputs."

			requiredPaths: [
				"sources/apercue.cue",
				"sources/cue_by_example.cue",
				"sources/cuetorials.cue",
				"sources/official_docs.cue",
				"sources/sources.cue",
			]

			forbiddenPaths: [
				"idioms",
				"patterns/sources.cue",
				"patterns/official_docs.cue",
				"patterns/cue_by_example.cue",
				"patterns/cuetorials.cue",
				"patterns/apercue.cue",
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
			description: "Codex drift policy outside the pattern validation path."

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
				"patterns/kg.cue",
				"patterns/kg",
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
		"pattern-suite-required-path-present": {
			id:       "pattern-suite-required-path-present"
			kind:     "missing-required-surface"
			surface:  "pattern-suite"
			severity: "violation"
			response: "block"
			reason:   "A required pattern suite authority file is missing."
		}

		"no-pattern-registry": {
			id:       "no-pattern-registry"
			kind:     "duplicate-authority"
			surface:  "pattern-suite"
			severity: "violation"
			response: "block"
			reason:   "The flat pattern files are authority; catalog-style registries duplicate authority."
		}

		"source-registry-required-path-present": {
			id:       "source-registry-required-path-present"
			kind:     "missing-required-surface"
			surface:  "source-registry"
			severity: "violation"
			response: "block"
			reason:   "A required source registry file is missing."
		}

		"control-profile-required-path-present": {
			id:       "control-profile-required-path-present"
			kind:     "missing-required-surface"
			surface:  "control-profile"
			severity: "violation"
			response: "block"
			reason:   "The closed-loop control profile must remain under profiles/control."
		}

		"control-profile-outside-patterns": {
			id:       "control-profile-outside-patterns"
			kind:     "duplicate-authority"
			surface:  "control-profile"
			severity: "violation"
			response: "block"
			reason:   "Control feedback techniques are profile projections, not pattern authority."
		}

		"sources-outside-patterns": {
			id:       "sources-outside-patterns"
			kind:     "duplicate-authority"
			surface:  "source-registry"
			severity: "violation"
			response: "block"
			reason:   "Reference source registries belong under sources/, not patterns/."
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
			reason:   "The KG layer checks Codex drift and must not enter meta or pattern validation."
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
