package registry

import "strings"

#NonEmptyString: string & strings.MinRunes(1)
#Digest:          =~"^sha256:[0-9a-f]{64}$"

#AuthorityClass: "asserted" | "observed" | "derived" | "external"

#RegistrySnapshotIdentity: close({
	id:             #NonEmptyString
	revision:       #NonEmptyString
	graphDigest:    #Digest
	contractVersion: "lattice.registry.v1"
})

#RegistryManifest: close({
	schema:   "lattice.registry-manifest.v1"
	identity: #RegistrySnapshotIdentity
	graph:    "graph.jsonld"
})

#EvidenceRef: close({
	id:       #NonEmptyString
	path:     #NonEmptyString
	startLine: int & >=1
	endLine:   int & >=startLine
})

#RegistryEntity: close({
	id:              #NonEmptyString
	kind:            #NonEmptyString
	authority:       #AuthorityClass
	path?:           #NonEmptyString
	qualifiedSymbol?: #NonEmptyString
	shortSymbol?:     #NonEmptyString
	evidence:         [#NonEmptyString, ...#NonEmptyString]
})

#RegistryRelation: close({
	id:        #NonEmptyString
	predicate: #NonEmptyString
	subject:   #NonEmptyString
	object:    #NonEmptyString
	external?: bool
	evidence:  [#NonEmptyString, ...#NonEmptyString]
}) & ({object: !~"^urn:lattice:"} | {object: =~"^urn:lattice:", external?: false})

#RegistryGraph: close({
    "@context": "https://lattice.dev/context/registry/v1"
	entities:   [...#RegistryEntity]
	relations:  [...#RegistryRelation]
	evidence:   [...#EvidenceRef]
})

#Focus: close({
	ids?:     [...#NonEmptyString]
	paths?:   [...#NonEmptyString]
	symbols?: [...#NonEmptyString]
}) & ({ids: [#NonEmptyString, ...#NonEmptyString]} | {paths: [#NonEmptyString, ...#NonEmptyString]} | {symbols: [#NonEmptyString, ...#NonEmptyString]})

#ContextBudget: close({
	maxDepth: int & >=0 & <=8
	maxNodes: int & >=1 & <=128
	maxEdges: int & >=0 & <=256
	maxScannedEdges: int & >=1 & <=4096
	maxDiagnostics: int & >=0 & <=128
	maxBytes: int & >=512 & <=1048576
})

#ComposeRequest: close({
	schema: "lattice.compose-request.v1"
	intent: "inspect"
	focus:  #Focus
	budget: #ContextBudget
})

#Diagnostic: close({
	code:    #NonEmptyString
	message: #NonEmptyString
})

#ContextPacket: close({
	schema:       "lattice.context-packet.v1"
	packetDigest: #Digest
	compositionPolicyVersion: "inspect-v1"
	serializerVersion: "json-v1"
	snapshot:     #RegistrySnapshotIdentity
	intent:       "inspect"
	entities:     [...#RegistryEntity]
	relations:    [...#RegistryRelation]
	evidence:     [...#EvidenceRef]
	diagnostics:  [...#Diagnostic]
})

#CompositionTrace: close({
	schema:       "lattice.composition-trace.v1"
	traceDigest:  #Digest
	packetDigest: #Digest
	compositionPolicyVersion: "inspect-v1"
	resolvedSeeds: [...#NonEmptyString]
	excluded:      [...#Diagnostic]
})

#ErrorEnvelope: close({
	schema:       "lattice.error-envelope.v1"
	code:         #NonEmptyString
	message:      #NonEmptyString
	diagnostics:  [...#Diagnostic]
})
