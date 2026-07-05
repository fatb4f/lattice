---
name: dotfiles-code-intel
description: Scaffold-aligned code-intel bundle shell for dotfiles contract validation.
---

# Dotfiles Code Intel

This plugin projection is the installable scaffold shell for the code-intel bundle. Runtime evidence remains under the source contract surfaces, not under `contracts/plugin-bundle/generated/code-intel`.

## Contract boundary

- Treat generated plugin projection files as evidence only.
- Do not treat MCP output, LSP diagnostics, generated type stubs, or generated workflow JSON as source authority.
- Do not import or depend on the agent-context-resolver bundle.
- Do not place `contracts`, `generated`, or `manifest.json` under the installable generated root.

## Validation

```sh
cue vet ./contracts/plugin-bundle/code-intel
cue vet ./contracts/plugin-bundle/code-intel/checks
cue vet ./contracts/plugin-bundle/code-intel/src
cue vet ./contracts/plugin-bundle/code-intel/src/contracts/code-intel
cue vet ./contracts/plugin-bundle/code-intel/src/contracts/code-intel/checks
cue export ./contracts/plugin-bundle/code-intel/src/contracts/code-intel -e normalizedMaterializedBundleShapeManifest
cue export ./contracts/plugin-bundle/code-intel/src/contracts/code-intel -e materializedBundleShapeValidationPlan
cue export ./contracts/plugin-bundle/code-intel/src/contracts/code-intel -e materializedBundleShapeCompletionReportContract
cue export ./contracts/plugin-bundle/code-intel/src/contracts/code-intel -e codeIntelBoundaryReport
cue export ./contracts/plugin-bundle/code-intel/src/contracts/code-intel -e codeIntelImplementationRecommendations
test ! -e contracts/plugin-bundle/generated/code-intel/manifest.json
test ! -e contracts/plugin-bundle/generated/code-intel/contracts
test ! -e contracts/plugin-bundle/generated/code-intel/generated
```
