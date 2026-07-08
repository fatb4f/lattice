package codexdrift

import (
	"list"
	"strings"
)

#CheckFinding: close({
	rule?:    #KebabID
	kind:     #DriftKind
	surface:  #KebabID
	path?:    #Path
	severity: #Severity
	response: #Response
	reason:   #NonEmptyString
})

#CheckReport: close({
	model:  #DriftModel
	repo?:  #ObservedRepo
	patch?: #ObservedPatch

	findings: _
})

#PathMatches: {
	path:    #Path
	pattern: #Path
	matches: path == pattern || strings.HasPrefix(path, "\(pattern)/")
}

#DriftKG: {
	schema: "codex-drift-kg.v1"

	model: #DriftModel
	facts: close({
		repo?:  #ObservedRepo
		patch?: #ObservedPatch
		selfContext: #SelfContextFacts | *{
			schema:     "lattice-self-context.v1"
			surfaces:   {}
			invariants: {}
		}
	})
}

#RepoDriftKG: close({
	schema: "codex-drift-kg.v1"
	model:  #DriftModel
	facts: close({
		repo: #ObservedRepo
	})

	let Model = model
	let Repo = facts.repo

	repoCheck: (#RepoSurfaceChecks & {
		model: Model
		repo:  Repo
	}).output

	findings: repoCheck.findings
})

#PatchDriftKG: close({
	schema: "codex-drift-kg.v1"
	model:  #DriftModel
	facts: close({
		patch: #ObservedPatch
	})

	let Model = model
	let Patch = facts.patch

	patchCheck: (#PatchSurfaceChecks & {
		model: Model
		patch: Patch
	}).output

	findings: patchCheck.findings
})

#FullDriftKG: close({
	schema: "codex-drift-kg.v1"
	model:  #DriftModel
	facts: close({
		repo:  #ObservedRepo
		patch: #ObservedPatch
		selfContext: #SelfContextFacts | *{
			schema:     "lattice-self-context.v1"
			surfaces:   {}
			invariants: {}
		}
	})

	let Model = model
	let Repo = facts.repo
	let Patch = facts.patch

	repoCheck: (#RepoSurfaceChecks & {
		model: Model
		repo:  Repo
	}).output

	patchCheck: (#PatchSurfaceChecks & {
		model: Model
		patch: Patch
	}).output

	selfContextCheck: (#SelfContextChecks & {
		selfContext: facts.selfContext
	})

	findings: list.Concat([
		[for finding in repoCheck.findings {finding}],
		[for finding in patchCheck.findings {finding}],
		[for finding in selfContextCheck.findings {finding}],
	])
})

#SelfContextChecks: close({
	selfContext: #SelfContextFacts

	findings: [
		for id, declaredSurface in selfContext.surfaces
		if declaredSurface.kind == "provider" && declaredSurface.role != "authority" {
			kind:     "policy-violated"
			surface:  id
			path:     declaredSurface.path
			severity: "violation"
			response: "block"
			reason:   "Provider surfaces must be authority surfaces."
		},

		for id, declaredSurface in selfContext.surfaces
		if declaredSurface.kind == "generated" && declaredSurface.role == "authority" {
			kind:     "generated-promoted-to-authority"
			surface:  id
			path:     declaredSurface.path
			severity: "critical"
			response: "block"
			reason:   "Generated surfaces cannot be authority surfaces."
		},
	]
})

#RepoSurfaceChecks: close({
	let Model = model
	let Repo = repo
	let Findings = findings

	model: #DriftModel
	repo:  #ObservedRepo
	_paths: list.SortStrings([for path, _ in repo.filesByPath {path}])

	findings: [
		for _, surfaceID in model.surfaceIDs
		let surface = model.surfaces[surfaceID]
		for _, pathValue in surface.requiredPaths
		if list.Contains(_paths, pathValue) != true {
			if model.rules["\(surfaceID)-required-path-present"] != _|_ {
				rule: model.rules["\(surfaceID)-required-path-present"].id
			}
			kind:     "missing-required-surface"
			surface:  surfaceID
			path:     pathValue
			severity: "violation"
			response: "block"
			reason:   "A required control surface path is missing."
		},
		for _, surfaceID in model.surfaceIDs
		let surface = model.surfaces[surfaceID]
		for _, pathValue in surface.forbiddenPaths
		for _, observedPath in _paths
		if (#PathMatches & {path: observedPath, pattern: pathValue}).matches == true {
			if model.rules["\(surfaceID)-forbidden-path-absent"] != _|_ {
				rule: model.rules["\(surfaceID)-forbidden-path-absent"].id
			}
			if model.rules["no-pattern-registry"].surface == surfaceID {
				rule: model.rules["no-pattern-registry"].id
			}
			if model.rules["sources-outside-patterns"].surface == surfaceID {
				rule: model.rules["sources-outside-patterns"].id
			}
			if model.rules["control-profile-outside-patterns"].surface == surfaceID {
				rule: model.rules["control-profile-outside-patterns"].id
			}
			if model.rules["kg-outside-validator"].surface == surfaceID {
				rule: model.rules["kg-outside-validator"].id
			}
			kind:     "unexpected-surface"
			surface:  surfaceID
			path:     observedPath
			severity: "violation"
			response: "block"
			reason:   "A forbidden control surface path is present."
		},
	]

	output: #CheckReport & {
		model:    Model
		repo:     Repo
		findings: Findings
	}
})

#PatchSurfaceChecks: close({
	let Model = model
	let Patch = patch
	let Findings = findings

	model: #DriftModel
	patch: #ObservedPatch

	findings: [
		for _, surfaceID in model.surfaceIDs
		let surface = model.surfaces[surfaceID]
		for _, pathValue in surface.protectedPaths
		for change in patch.changes
		if (#PathMatches & {path: change.path, pattern: pathValue}).matches == true {
			if model.rules["kernel-change-review"].surface == surfaceID {
				rule: model.rules["kernel-change-review"].id
			}
			if model.rules["validator-change-review"].surface == surfaceID {
				rule: model.rules["validator-change-review"].id
			}
			if model.rules["codex-drift-kg-change-review"].surface == surfaceID {
				rule: model.rules["codex-drift-kg-change-review"].id
			}
			if model.rules["generated-facts-not-authority"].surface == surfaceID {
				rule: model.rules["generated-facts-not-authority"].id
			}
			kind:     "policy-violated"
			surface:  surfaceID
			path:     change.path
			severity: "warning"
			response: "require-review"
			reason:   "A protected control surface path changed."
		},
	]

	output: #CheckReport & {
		model:    Model
		patch:    Patch
		findings: Findings
	}
})
