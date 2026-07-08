---
name: dotfiles-code-intel
description: Read-only code-intelligence reference overlays for dotfiles work.
---

# Dotfiles Code Intel

This installed plugin contains one operator skill and read-only reference material for dotfiles code-intelligence work.

## Contract boundary

- Load reference/type overlays as read-only operator context.
- Do not treat reference files as source authority.
- Do not treat MCP output, LSP diagnostics, type stubs, or workflow JSON as source authority.
- Do not import or depend on the retired agent-context-resolver bundle.
- Do not place `contracts`, `generated`, `skills`, or `manifest.json` under the installed plugin root.
- All CUE authority remains in factory/plugin-bundle contracts.
- All dotfiles source authority remains in dotfiles source paths.

## Reference layout

- `reference/lsp/`: LSP provider and routing context.
- `reference/tools/`: formatter and lint tool context.
- `reference/types/`: Neovim and WezTerm type overlays.
- `reference/workflows/`: Lua-first operator workflow context.
