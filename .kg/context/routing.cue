package context

#GraphRoutingField:
	"id" |
	"type" |
	"tags" |
	"path" |
	"owner" |
	"metadata"

#GraphRoutingPolicy: close({
	schema:  "lattice.graph-routing-policy.v1"
	version: "1.0.0"

	weights: close({
		id:       int & >=0
		type:     int & >=0
		tags:     int & >=0
		path:     int & >=0
		owner:    int & >=0
		metadata: int & >=0
	})

	allowedMetadataFields: [#NonEmptyString, ...#NonEmptyString]

	relationDistance: close({
		maxDepth:        int & >=0 & <=4
		numerator:       int & >=0 & <=16
		denominator:     int & >=1 & <=16
		minimumScore:    int & >=0 & <=64
		direction:       "undirected"
		propagationMode: "direct-match-only"
	})

	candidatePolicy: close({
		includeWhen: "positive-score"
		tieBreak:    "score-descending-id-ascending"
	})

	ceilings: close({
		maxCandidates: int & >=0 & <=128
		maxEntities:   int & >=0 & <=32
		maxResources:  int & >=0 & <=32
	})

	budgets: close({
		maxCandidates: int & >=0 & <=ceilings.maxCandidates
		maxEntities:   int & >=0 & <=ceilings.maxEntities
		maxResources:  int & >=0 & <=ceilings.maxResources
	})
})

graphRoutingPolicy: #GraphRoutingPolicy & {
	weights: {
		id:       24
		type:     12
		tags:     10
		path:     9
		owner:    8
		metadata: 2
	}
	allowedMetadataFields: [
		"description",
		"name",
		"reason",
		"statement",
		"status",
		"summary",
		"title",
	]
	relationDistance: {
		maxDepth:        1
		numerator:       1
		denominator:     4
		minimumScore:    1
		direction:       "undirected"
		propagationMode: "direct-match-only"
	}
	candidatePolicy: {
		includeWhen: "positive-score"
		tieBreak:    "score-descending-id-ascending"
	}
	ceilings: {
		maxCandidates: 128
		maxEntities:   32
		maxResources:  32
	}
	budgets: {
		maxCandidates: 32
		maxEntities:   8
		maxResources:  8
	}
}
