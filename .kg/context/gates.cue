package context

#GateStatus:      "pass" | "fail" | "skipped" | "unsupported" | "indeterminate"
#GatePolicy:      "fail-open" | "fail-closed"
#KebabIdentifier: #NonEmptyString & =~"^[a-z0-9]+(-[a-z0-9]+)*$"
#UTCTimestamp:    #NonEmptyString & =~"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"
#SHA256Digest:    #NonEmptyString & =~"^sha256:[0-9a-f]{64}$"

#GateEvidenceRecord: close({
	gateId:             #KebabIdentifier
	checker:            #NonEmptyString
	operation:          #NonEmptyString
	repositoryRevision: #NonEmptyString
	inputManifest: close({
		inputDigest:             #SHA256Digest
		executionManifestDigest: #SHA256Digest
		inputs: [#GateManifestInput, ...#GateManifestInput]
		outputs: [#GateManifestOutput, ...#GateManifestOutput]
	})
	exitStatus:   int & >=0
	resultDigest: #NonEmptyString & =~"^sha256:[0-9a-f]{64}$"
	result:       #NonEmptyString
})

#GateManifestInput: close({
	role:   #NonEmptyString
	path:   #NonEmptyString
	digest: #NonEmptyString & =~"^sha256:[0-9a-f]{64}$"
})

#GateManifestOutput: close({
	role: #NonEmptyString
	path: #NonEmptyString
})

#GateEvidence: close({
	digest: #SHA256Digest
	let D = digest
	ref:        "inline:\(D)"
	observedAt: #UTCTimestamp
	expiresAt:  #UTCTimestamp
	record:     #GateEvidenceRecord
})

#GateDiagnostic: close({
	code:    #NonEmptyString
	message: #NonEmptyString
})

#GateResultBase: close({
	gateId:      #KebabIdentifier
	checker:     #NonEmptyString
	status:      #GateStatus
	policy:      #GatePolicy
	startedAt:   #UTCTimestamp
	completedAt: #UTCTimestamp
	evaluatedAt: #UTCTimestamp
	inputs: [#NonEmptyString, ...#NonEmptyString]
	evidence: [...#GateEvidence]
	diagnostics: [...#GateDiagnostic]
})

// Passing is the only state that carries a success claim. It requires at least
// one evidence reference, and every reference must still be within its declared
// freshness window. evaluatedAt is supplied by the admission boundary;
// producers do not report a derived age.
#PassingGateResult: #GateResultBase & {
	evaluatedAt: #UTCTimestamp
	gateId:      #KebabIdentifier
	checker:     #NonEmptyString
	status:      "pass"
	evidence: [#GateEvidence, ...#GateEvidence]
	_freshEvidence: {
		for index, item in evidence {
			"evidence-\(index)-observed": (item.observedAt <= evaluatedAt) & true
			"evidence-\(index)-fresh":    (evaluatedAt < item.expiresAt) & true
			"evidence-\(index)-gate":     (item.record.gateId == gateId) & true
			"evidence-\(index)-checker":  (item.record.checker == checker) & true
			"evidence-\(index)-success":  (item.record.exitStatus == 0) & true
			"evidence-\(index)-digest":   (item.record.resultDigest == item.digest) & true
		}
	}
}

#NonPassingGateResult: #GateResultBase & {
	status: "fail" | "skipped" | "unsupported" | "indeterminate"
}

#GateResult: #PassingGateResult | #NonPassingGateResult

#GateResultMap: close({
	[ID=#KebabIdentifier]: #GateResult & {gateId: ID}
})

#PassedFailClosedGate: #PassingGateResult & {policy: "fail-closed"}

#ContextGateResults: close({
	"vocab-mapped": #GateResult & {gateId: "vocab-mapped", policy: "fail-closed"}
	"kb-valid": #GateResult & {gateId: "kb-valid", policy: "fail-closed"}
	"no-dangling-refs": #GateResult & {gateId: "no-dangling-refs", policy: "fail-closed"}
	"no-generated-input": #GateResult & {gateId: "no-generated-input", policy: "fail-closed"}
	"no-parent-traversal": #GateResult & {gateId: "no-parent-traversal", policy: "fail-closed"}
	"transient-projection": #GateResult & {gateId: "transient-projection", policy: "fail-closed"}
})

#ValidatedContextGateResults: close({
	"vocab-mapped": #PassedFailClosedGate & {gateId: "vocab-mapped"}
	"kb-valid": #PassedFailClosedGate & {gateId: "kb-valid"}
	"no-dangling-refs": #PassedFailClosedGate & {gateId: "no-dangling-refs"}
	"no-generated-input": #PassedFailClosedGate & {gateId: "no-generated-input"}
	"no-parent-traversal": #PassedFailClosedGate & {gateId: "no-parent-traversal"}
	"transient-projection": #PassedFailClosedGate & {gateId: "transient-projection"}
})

// Runtime safety claims are mandatory and fail closed. A producer cannot omit
// one or silently change its admission policy.
#ContextRouteGateResults: close({
	"kb-valid": #GateResult & {gateId: "kb-valid", policy: "fail-closed"}
	"no-dangling-refs": #GateResult & {gateId: "no-dangling-refs", policy: "fail-closed"}
	"no-generated-input": #GateResult & {gateId: "no-generated-input", policy: "fail-closed"}
	"no-plugin-cache-input": #GateResult & {gateId: "no-plugin-cache-input", policy: "fail-closed"}
	"no-raw-transcript-input": #GateResult & {gateId: "no-raw-transcript-input", policy: "fail-closed"}
	"transient-projection": #GateResult & {gateId: "transient-projection", policy: "fail-closed"}
})

#ValidatedContextRouteGateResults: close({
	"kb-valid": #PassedFailClosedGate & {gateId: "kb-valid"}
	"no-dangling-refs": #PassedFailClosedGate & {gateId: "no-dangling-refs"}
	"no-generated-input": #PassedFailClosedGate & {gateId: "no-generated-input"}
	"no-plugin-cache-input": #PassedFailClosedGate & {gateId: "no-plugin-cache-input"}
	"no-raw-transcript-input": #PassedFailClosedGate & {gateId: "no-raw-transcript-input"}
	"transient-projection": #PassedFailClosedGate & {gateId: "transient-projection"}
})
