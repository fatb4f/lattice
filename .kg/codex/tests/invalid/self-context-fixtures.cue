package codexdrift

invalidGeneratedAuthoritySelfContext: {
	schema: "lattice-self-context.v1"
	surfaces: {
		"generated-codex": {
			id:          "generated-codex"
			kind:        "generated"
			role:        "authority"
			path:        "generated/codex"
			description: "Invalid fixture: generated output is promoted to authority."
		}
	}
}

invalidProviderRoleSelfContext: {
	schema: "lattice-self-context.v1"
	surfaces: {
		"codex-provider": {
			id:          "codex-provider"
			kind:        "provider"
			role:        "adapter"
			path:        ".kg/codex"
			description: "Invalid fixture: provider is not declared as authority."
		}
	}
}
