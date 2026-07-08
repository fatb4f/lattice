// JSON-LD vocabulary context used as the semantic lens for KG hook packets.
package vocab

context: {
	"@context": {
		"kg":      "https://quicue.ca/kg#"
		"dcterms": "http://purl.org/dc/terms/"
		"prov":    "http://www.w3.org/ns/prov#"
		"oa":      "http://www.w3.org/ns/oa#"
		"dcat":    "http://www.w3.org/ns/dcat#"
		"rdfs":    "http://www.w3.org/2000/01/rdf-schema#"
		"xsd":     "http://www.w3.org/2001/XMLSchema#"

		"Decision": "kg:Decision"
		"Insight":  "kg:Insight"
		"Rejected": "kg:Rejected"
		"Pattern":  "kg:Pattern"

		"Derivation":         "kg:Derivation"
		"Context":            "kg:Context"
		"Workspace":          "kg:Workspace"
		"SourceFile":         "kg:SourceFile"
		"CollectionProtocol": "kg:CollectionProtocol"
		"PipelineRun":        "kg:PipelineRun"

		"id":          "kg:id"
		"title":       "dcterms:title"
		"description": "dcterms:description"
		"date":        "dcterms:date"
		"status":      "kg:status"
		"decision":    "kg:decision"
		"rationale":   "kg:rationale"
		"statement":   "kg:statement"
		"evidence": {"@id": "kg:evidence", "@container": "@list"}
		"approach": "kg:approach"
		"reason":   "kg:reason"
		"problem":  "kg:problem"
		"solution": "kg:solution"
		"module":   "kg:module"
		"repo":     "kg:repo"
		"related": {
			"@id":        "kg:related"
			"@type":      "@id"
			"@container": "@set"
		}
	}
}
