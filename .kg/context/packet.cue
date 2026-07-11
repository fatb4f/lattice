package context

#NonEmptyString: string & !=""

#ContextSelectionInput: close({
	host:  "codex"
	event: "UserPromptSubmit"

	prompt: string & !=""

	kb: close({
		root:     ".kb"
		manifest: ".kb/manifest.cue"
	})

	vocab: close({
		preferred: ".kb/cue.mod/pkg/quicue.ca/kg/vocab/context.cue"
		fallback:  ".kg/vocab/context.cue"
		selected:  preferred | fallback
		namespace: "https://quicue.ca/kg#"
	})
})

#ContextEntityType:
	"Decision" |
	"Insight" |
	"Rejected" |
	"Pattern" |
	"Context" |
	"Workspace" |
	"SourceFile" |
	"Derivation" |
	"PipelineRun"

#ContextGraphNode: {
	"@id": string & !=""
	"@type": string | [...string]
	id: string & !=""

	title?:        string & !=""
	"rdfs:label"?: string & !=""
	related?: [...close({
		"@id": string & !=""
	})]

	// JSON-LD graph nodes carry KG-native domain payload fields.
	[string]: _
}

#LegacyContextPacket: close({
	schema: "lattice.context-packet.v1"

	host:  "codex"
	event: "UserPromptSubmit"

	kb: close({
		root: ".kb"
	})

	selection: close({
		query:    string
		selector: "kg-native-context-json-ld"
	})

	entities: [...close({
		id:      string & !=""
		type:    #ContextEntityType
		source:  string & !=""
		summary: string & !=""
	})]

	resources: [...close({
		uri:      string & !=""
		path:     string & !=""
		source:   "kg" | "mcp"
		readOnly: true
	})]

	vocab: close({
		kind:      "jsonld-context"
		source:    ".kb/cue.mod/pkg/quicue.ca/kg/vocab/context.cue" | ".kg/vocab/context.cue"
		namespace: "https://quicue.ca/kg#"
		context: close({
			"@context": _
			"@graph"?: [...]
		})
	})

	graph: close({
		"@context": _
		"@graph": [...#ContextGraphNode]
	})

	output: close({
		target: "codex.additionalContext"
	})

	evaluatedAt: #UTCTimestamp
	gates:       #ContextGateResults

	generated: true
	authority: false
})

#MaterializedContextPacket: close({
	schema:            "lattice.context-packet.v1"
	requestId:         #NonEmptyString
	routePacketDigest: #SHA256Digest
	packetDigest:      #SHA256Digest
	index: close({
		schema:             "lattice.kg-full-index-envelope.v1"
		repositoryRevision: #NonEmptyString
		inputDigest:        #SHA256Digest
		policyDigest:       #SHA256Digest
		tools: close({
			kg:  #NonEmptyString
			cue: #NonEmptyString
		})
	})
	budget: close({
		maxNodes: int & >=1 & <=128
		maxEdges: int & >=0 & <=512
		maxBytes: int & >=1024 & <=1048576
		maxDepth: int & >=0 & <=8
	})
	selection: close({
		seedEntities: [...#EntityID]
		materializedEntities: [...#EntityID]
		relations: [...close({
			source:    #EntityID
			predicate: #NonEmptyString
			target:    #EntityID
			evidence: [#SHA256Digest, ...#SHA256Digest]
		})]
	})
	projection: close({
		format:         "application/ld+json"
		contextVersion: #NonEmptyString
		document: close({
			"@context": _
			"@graph": [...]
		})
	})
	truncated: bool
	diagnostics: [...]
})

#ContextPacket: #LegacyContextPacket | #MaterializedContextPacket

#GraphRoutePacketBase: close({
	schema:    "lattice.graph-route-packet.v1"
	requestId: #NonEmptyString
	query:     #NonEmptyString
	route:     "graph-derived"
	index: close({
		schema:             "lattice.kg-full-index-envelope.v1"
		repositoryRevision: #NonEmptyString
		inputDigest:        #SHA256Digest
		policyDigest:       #SHA256Digest
		tools: close({
			kg:  #SHA256Digest
			cue: #NonEmptyString
		})
	})
	policy:       #GraphRoutingPolicy
	policyDigest: #SHA256Digest
	selection: close({
		entities: [...#EntityID]
		resources: [...#MCPResourceURI]
	})
	candidates: [...close({
		entityId:    #EntityID
		rank:        int & >=1
		score:       int & >=0
		disposition: "included" | "excluded" | "down-ranked"
		reasons: [_, ...]
	})]
	packetDigest: #SHA256Digest
})

_graphRoutePacketBounds: {
	policy: #GraphRoutingPolicy
	selection: {
		entities: [...#EntityID]
		resources: [...#MCPResourceURI]
	}
	candidates: [...]
	if len(candidates) > policy.budgets.maxCandidates {
		_|_("graph route candidates exceed policy budget")
	}
	if len(selection.entities) > policy.budgets.maxEntities {
		_|_("graph route entities exceed policy budget")
	}
	if len(selection.resources) > policy.budgets.maxResources {
		_|_("graph route resources exceed policy budget")
	}
}

#GraphRoutePacket: #GraphRoutePacketBase & _graphRoutePacketBounds

#CodexPromptContext: close({
	schema:    "lattice.codex-prompt-context.v1"
	requestId: #NonEmptyString
	route:     #RouteID
	selection: close({
		entities: [...#EntityID]
		resources: [...#MCPResourceURI]
		files: [...#RepoPath]
	})
	indexInputDigest: #SHA256Digest
	policyDigest:     #SHA256Digest
	instruction:      #NonEmptyString
})

#AuditBoundCodexPromptContextBase: close({
	promptContext: #CodexPromptContext
	auditPacket:   #RoutePolicyBoundPacket
	gateSummary: close({
		status:         "pass"
		evidenceDigest: #SHA256Digest
	})
	auditArtifact: close({
		digest: #SHA256Digest
		let D = digest
		uri: "artifact://lattice/hook-audit/\(D)"
	})
})

_auditBoundCodexPromptContextRelationships: {
	promptContext: _
	auditPacket:   _
	if promptContext.requestId != auditPacket.requestId {
		_|_("prompt context request ID does not match audit packet")
	}
	if promptContext.route != auditPacket.route {
		_|_("prompt context route does not match audit packet")
	}
	if promptContext.selection.entities != auditPacket.selection.entities {
		_|_("prompt context entity selection does not match audit packet")
	}
	if promptContext.selection.resources != auditPacket.selection.resources {
		_|_("prompt context resource selection does not match audit packet")
	}
	if promptContext.selection.files != auditPacket.selection.files {
		_|_("prompt context file selection does not match audit packet")
	}
	if promptContext.indexInputDigest != auditPacket.index.inputDigest {
		_|_("prompt context index digest does not match audit packet")
	}
	if promptContext.policyDigest != auditPacket.policyDigest {
		_|_("prompt context policy digest does not match audit packet")
	}
	if promptContext.instruction != auditPacket.instruction {
		_|_("prompt context instruction does not match audit packet")
	}
}

#AuditBoundCodexPromptContext: #AuditBoundCodexPromptContextBase & _auditBoundCodexPromptContextRelationships

#ContextRoutePacket: close({
	schema:       "lattice.context-route-packet.v1"
	requestId:    #NonEmptyString
	packetDigest: #SHA256Digest

	host:  "codex"
	event: "UserPromptSubmit"

	query: #NonEmptyString

	route:      #RouteID
	confidence: number & >=0 & <=1

	authority:   false
	generated:   true
	transient:   true
	evaluatedAt: #UTCTimestamp

	index: close({
		schema:             "lattice.kg-full-index-envelope.v1"
		repositoryRevision: #NonEmptyString
		inputDigest:        #SHA256Digest
		policyDigest:       #SHA256Digest
		tools: close({
			kg:  #NonEmptyString
			cue: #NonEmptyString
		})
	})
	policyDigest: #SHA256Digest
	candidates: [...close({
		entityId:    #EntityID
		rank:        int & >=1
		score:       int & >=0
		disposition: "included" | "excluded" | "down-ranked"
		reasons: [...]
	})]

	budget: close({
		maxInlineEntities:   int & >=0 & <=3
		maxInlineBytes:      int & >=0 & <=4096
		maxResourceHandles:  int & >=0 & <=8
		maxAutoReadBytes:    int & >=0 & <=4096
		allowExpensiveReads: bool
		preferMCP:           true
	})

	selection: close({
		entities: [...#EntityID]
		resources: [...#MCPResourceURI]
		files: [...#RepoPath]
	})

	gates: #ContextRouteGateResults

	hardExclusions: [...#NonEmptyString]
	instruction: #NonEmptyString
})
