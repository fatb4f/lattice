package diagnostics

#NonEmptyString: string & !=""
#Timestamp:      #NonEmptyString & =~"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"
#Digest:         #NonEmptyString & =~"^sha256:[0-9a-f]{64}$"
#Status:         "pass" | "fail" | "skipped" | "unsupported" | "indeterminate"

#DiagnosticCheckResultBase: close({
	schema:             "lattice.diagnostic-check-result.v1"
	checkId:            #NonEmptyString
	subsystem:          #NonEmptyString
	status:             #Status
	severity:           "info" | "warning" | "error" | "critical"
	blocking:           bool
	checker:            #NonEmptyString
	operation:          #NonEmptyString
	repositoryRevision: #NonEmptyString
	toolVersions: {
		[string]: _
	}
	normalizedInputs: close({
		digest: #Digest
		value:  _
	})
	evidence: [...#DiagnosticEvidence]
	diagnostics: [...close({
		code:    #NonEmptyString
		message: #NonEmptyString
	})]
	remediation: string
	startedAt:   #Timestamp
	completedAt: #Timestamp
	evaluatedAt: #Timestamp
})

#DiagnosticEvidence: close({
	digest: #Digest
	let D = digest
	ref:        "inline:\(D)"
	observedAt: #Timestamp
	expiresAt:  #Timestamp
	record:     #DiagnosticEvidenceRecord
})

#DiagnosticEvidenceRecord: close({
	checker:            #NonEmptyString
	operation:          #NonEmptyString
	repositoryRevision: #NonEmptyString
	toolVersions: {
		[string]: _
	}
	normalizedInputs: close({
		digest: #Digest
		value:  _
	})
	result: #NonEmptyString
	status: #Status
})

#PassingDiagnosticCheckResult: #DiagnosticCheckResultBase & {
	status:      "pass"
	evaluatedAt: #Timestamp
	checker:     #NonEmptyString
	let E = evaluatedAt
	let C = checker
	evidence: [#DiagnosticEvidence, ...#DiagnosticEvidence]
	_freshEvidence: {
		for index, item in evidence {
			"evidence-\(index)-observed": (item.observedAt <= E) & true
			"evidence-\(index)-fresh":    (E < item.expiresAt) & true
			"evidence-\(index)-checker":  (item.record.checker == C) & true
			"evidence-\(index)-success":  (item.record.status == "pass") & true
		}
	}
	remediation: ""
}

#NonPassingDiagnosticCheckResult: #DiagnosticCheckResultBase & {
	status:      "fail" | "skipped" | "unsupported" | "indeterminate"
	remediation: #NonEmptyString
}

#DiagnosticCheckResult: #PassingDiagnosticCheckResult | #NonPassingDiagnosticCheckResult

#DiagnosticsSummaryBase: close({
	schema:             "lattice.diagnostics-summary.v1"
	repositoryRevision: #NonEmptyString
	status:             "pass" | "fail"
	counts: close({
		total:      pass + nonPassing
		pass:       int & >=0
		nonPassing: int & >=0
	})
	evaluatedAt: #Timestamp
})

#PassingDiagnosticsSummary: #DiagnosticsSummaryBase & {
	status: "pass"
	counts: nonPassing: 0
}

#NonPassingDiagnosticsSummary: #DiagnosticsSummaryBase & {
	status: "fail"
	counts: nonPassing: int & >=1
}

#DiagnosticsSummary: #PassingDiagnosticsSummary | #NonPassingDiagnosticsSummary

#DiagnosticsReportBase: close({
	summary: #DiagnosticsSummary
	checks: [...#DiagnosticCheckResult]
})

_diagnosticsReportBounds: {
	summary: #DiagnosticsSummary
	checks: [...#DiagnosticCheckResult]
	_passingChecks: [for item in checks if item.status == "pass" {item}]
	_nonPassingChecks: [for item in checks if item.status != "pass" {item}]
	if len(checks) != summary.counts.total {
		_|_("diagnostics report count does not match summary")
	}
	if len(_passingChecks) != summary.counts.pass {
		_|_("diagnostics passing check count does not match summary")
	}
	if len(_nonPassingChecks) != summary.counts.nonPassing {
		_|_("diagnostics non-passing check count does not match summary")
	}
}

#DiagnosticsReport: #DiagnosticsReportBase & _diagnosticsReportBounds

#ReviewBundleManifest: close({
	schema:             "lattice.diagnostics-review-bundle.v1"
	repositoryRevision: #NonEmptyString
	summaryDigest:      #Digest
	files: [
		"checks.json",
		"logs/diagnostics.log",
		"summary.json",
		"workbook.html",
		...#NonEmptyString & !~"(^/|(^|/)\\.\\.(/|$))",
	]
})
