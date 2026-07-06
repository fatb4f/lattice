package codexdrift

latticeResponsePolicy: {
	model: latticeReference

	defaultResponseBySeverity: {
		info:      "allow"
		warning:   "require-review"
		violation: "block"
		critical:  "block"
	}

	protectedSurfaces: {
		"meta-kernel":            true
		"validation-controller":  true
		"codex-drift-kg":         true
		"generated-codex-facts":  true
	}

	blockedWithoutReview: {
		"duplicate-authority":              true
		"adapter-boundary-crossed":         true
		"generated-promoted-to-authority":  true
		"policy-violated":                  true
	}
}
