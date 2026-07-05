package datafixtures

dataIngestionNegativeCase: close({
	id:          "authority-evidence-bottom"
	description: "External evidence marked as authority should bottom against the evidence-only schema."
	probeExpr:   "#ProfileSnapshotEvidence & {source: \"json\", authority: true, evidenceOnly: true}"
})
