package context

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
	"@id":   string & !=""
	"@type": string | [...string]
	id:      string & !=""

	title?:        string & !=""
	"rdfs:label"?: string & !=""
	related?: [...close({
		"@id": string & !=""
	})]

	// JSON-LD graph nodes carry KG-native domain payload fields.
	[string]: _
}

#ContextPacket: close({
	schema: "lattice.context-packet.v1"

	host:  "codex"
	event: "UserPromptSubmit"

	kb: close({
		root: ".kb"
	})

	selection: close({
		query: string
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
			"@graph"?: [..._]
		})
	})

	graph: close({
		"@context": _
		"@graph": [...#ContextGraphNode]
	})

	output: close({
		target: "codex.additionalContext"
	})

	gates: close({
		vocabMapped:         true
		kbValid:             true
		noDanglingRefs:      true
		noGeneratedInput:    true
		noParentTraversal:   true
		transientProjection: true
	})

	generated: true
	authority: false
})
