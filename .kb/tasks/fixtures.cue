package tasks

validTaskV1Fixture: {
	schema_version: "lattice.task.v1"
	id:             "fixture-task"
	title:          "Validate task contract"
	status:         "pending"
	project:        "lattice"
	priority:       "medium"
	"@type_tags":  {validation: true}
	depends_on:     {}
	refs:           {"ADR-003": true}
	description:    "Positive task contract fixture."
}

invalidTaskV1Fixture: {
	schema_version: "lattice.task.v1"
	id:             "fixture-task"
	title:          "Missing required linkage"
	status:         "planned"
	project:        ""
	priority:       "urgent"
	"@type_tags":  {}
	depends_on:     {}
	refs:           {"not-a-kb-id": true}
}
