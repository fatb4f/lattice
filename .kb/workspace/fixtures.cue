package workspace

validWorkspaceV1Fixture: {
	name:           "fixture"
	description:    "Positive workspace contract fixture."
	components: repository: {
		path:        "."
		description: "Fixture repository root."
	}
}

invalidWorkspaceV1Fixture: {
	name:           ""
	description:    ""
	components: repository: {
		path:        ""
		description: ""
	}
}
