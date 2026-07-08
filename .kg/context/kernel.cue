package context

import "github.com/fatb4f/lattice/meta"

_contextRuntimeState: {
	id: "context-runtime"

	resources: {
		"project-kg": {
			path: ".kb"
			role: "authority"
		}
		"kb-manifest": {
			path: ".kb/manifest.cue"
			role: "authority"
		}
		"kg-vocab": {
			path: ".kb/cue.mod/pkg/quicue.ca/kg/vocab/context.cue"
			role: "authority"
		}
		"context-selector": {
			path: ".kg/context/select.cue"
			role: "adapter"
		}
		"context-routes": {
			path: ".kg/context/routes.cue"
			role: "adapter"
		}
		"context-budget": {
			path: ".kg/context/budget.cue"
			role: "adapter"
		}
		"context-packet-schema": {
			path: ".kg/context/packet.cue"
			role: "adapter"
		}
		"context-validator": {
			path: ".kg/context/validate.cue"
			role: "adapter"
		}
		"context-emitter": {
			path: ".kg/context/emit.cue"
			role: "adapter"
		}
		"kg-hook-tool": {
			path: ".kg/tools/kg"
			role: "adapter"
		}
		"codex-hook": {
			path: ".kg/hooks/codex/user-prompt-submit"
			role: "adapter"
		}
		"context-packet": {
			path: "stdout:hookSpecificOutput.additionalContext"
			role: meta.#GeneratedOutputResourceRole
			visibility: "restricted"
		}
	}

	operations: {
		"select-context": {
			kind:        "project"
			description: "Classify the prompt route and emit bounded KG/MCP resource IDs without broad KG body injection."
			reads: {
				"project-kg":   true
				"kb-manifest":  true
				"context-selector": true
				"context-routes":   true
				"context-budget":   true
			}
			writes: {}
			creates: {
				"context-packet": true
			}
			requiresGates: {
				"kb-valid": true
				"vocab-mapped": true
				"no-generated-input": true
			}
			requiresWitnesses: {
				"transient-packet": true
			}
		}
		"validate-context": {
			kind:        "validate"
			description: "Validate transient context packets before Codex hook emission."
			reads: {
				"context-packet-schema": true
				"context-validator":     true
				"context-packet":        true
			}
			writes: {}
			creates: {}
			requiresGates: {
				"no-parent-traversal": true
				"transient-projection": true
			}
			requiresWitnesses: {
				"validated-packet": true
			}
		}
		"emit-codex-context": {
			kind:        "emit"
			description: "Emit the validated transient packet as Codex additionalContext."
			reads: {
				"context-emitter": true
				"kg-hook-tool":    true
				"codex-hook":      true
				"context-packet":  true
			}
			writes: {}
			creates: {}
			requiresGates: {
				"transient-projection": true
			}
			requiresWitnesses: {
				"codex-hook-output": true
			}
		}
	}

	gates: {
		"kb-valid": {
			description: "The .kb graph validates before selection."
		}
		"vocab-mapped": {
			description: "The KG JSON-LD vocabulary context exports before selection."
		}
		"no-generated-input": {
			description: "Generated resolver artifacts are not runtime context inputs."
		}
		"no-parent-traversal": {
			description: "Runtime hook inputs reject parent traversal for authority paths."
		}
		"transient-projection": {
			description: "The context packet is a transient projection, not source authority."
		}
	}

	witnesses: {
		"transient-packet": {
			description: "The selected context packet is created only in stdout or tmp."
		}
		"validated-packet": {
			description: "The packet validates against #ValidatedContextPacket."
		}
		"codex-hook-output": {
			description: "The hook emits hookSpecificOutput.additionalContext."
		}
	}
}

contextRuntimeClosed: (meta.#MakeClosedObligationState & {
	in: _contextRuntimeState
}).out
