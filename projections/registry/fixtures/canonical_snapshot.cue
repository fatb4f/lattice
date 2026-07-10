package registryfixture

import registry "github.com/fatb4f/lattice/projections/registry"

canonicalManifest: registry.#RegistryManifest & {
	schema: "lattice.registry-manifest.v1"
	identity: {
		id:             "lattice-fixture"
		revision:       "fixture-r1"
		graphDigest:    "sha256:3a295f6390191dd38e3ad864ddfb0f445ffc60df6d9c8f79de0801d2bd6bf338"
		contractVersion: "lattice.registry.v1"
	}
	graph: "graph.jsonld"
}

canonicalGraph: registry.#RegistryGraph & {
	"@context": "https://lattice.dev/context/registry/v1"
	entities: [
		{id: "urn:lattice:entity:file:meta-kernel", kind: "file", authority: "asserted", path: "meta/kernel.cue", evidence: ["ev-meta-kernel"]},
		{id: "urn:lattice:entity:symbol:make-closed-obligation-state", kind: "definition", authority: "asserted", path: "meta/kernel.cue", qualifiedSymbol: "meta.#MakeClosedObligationState", shortSymbol: "MakeClosedObligationState", evidence: ["ev-make-closed"]},
		{id: "urn:lattice:entity:file:patterns-closedness", kind: "file", authority: "asserted", path: "patterns/closedness.cue", evidence: ["ev-pattern-closedness"]},
	]
	relations: [
		{id: "urn:lattice:relation:meta-contains-maker", predicate: "contains", subject: "urn:lattice:entity:file:meta-kernel", object: "urn:lattice:entity:symbol:make-closed-obligation-state", evidence: ["ev-meta-kernel"]},
		{id: "urn:lattice:relation:maker-uses-closedness", predicate: "uses", subject: "urn:lattice:entity:symbol:make-closed-obligation-state", object: "urn:lattice:entity:file:patterns-closedness", evidence: ["ev-pattern-closedness"]},
	]
	evidence: [
		{id: "ev-meta-kernel", path: "meta/kernel.cue", startLine: 1, endLine: 1},
		{id: "ev-make-closed", path: "meta/kernel.cue", startLine: 1, endLine: 1},
		{id: "ev-pattern-closedness", path: "patterns/closedness.cue", startLine: 1, endLine: 1},
	]
}
