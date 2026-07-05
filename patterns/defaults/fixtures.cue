package defaultsfixtures

#DefaultedVisibility: close({
	id:         string
	visibility: "public" | "internal" | "restricted" | *"internal"
})

#DefaultedNestedPolicy: close({
	id: string
	policy: close({
		required: bool | *true
		level:    "low" | "medium" | "high" | *"medium"
	})
})

#DefaultConstructor: close({
	in: {
		id: string
		visibility?: "public" | "internal" | "restricted"
	}
	out: #DefaultedVisibility & {
		id: in.id
		if in.visibility != _|_ {
			visibility: in.visibility
		}
	}
})

scalarDefault: #DefaultedVisibility & {
	id: "scalar-default"
}

enumDefault: #DefaultedVisibility & {
	id: "enum-default"
}

nestedDefault: #DefaultedNestedPolicy & {
	id: "nested-default"
	policy: {}
}

defaultOverriddenByInput: #DefaultedVisibility & {
	id:         "default-overridden-by-input"
	visibility: "restricted"
}

defaultSurvivesConstructor: (#DefaultConstructor & {
	in: {
		id: "default-survives-constructor"
	}
}).out

defaultsFixtureReport: close({
	schema: "fatb4f.lattice.pattern-fixtures.defaults.v1"
	fixtures: {
		scalarDefaultApplied:       scalarDefault.visibility == "internal"
		enumDefaultApplied:         enumDefault.visibility == "internal"
		nestedDefaultRequired:      nestedDefault.policy.required == true
		nestedDefaultLevel:         nestedDefault.policy.level == "medium"
		inputOverrideApplied:       defaultOverriddenByInput.visibility == "restricted"
		constructorDefaultApplied:  defaultSurvivesConstructor.visibility == "internal"
	}
	accepted: fixtures.scalarDefaultApplied &&
		fixtures.enumDefaultApplied &&
		fixtures.nestedDefaultRequired &&
		fixtures.nestedDefaultLevel &&
		fixtures.inputOverrideApplied &&
		fixtures.constructorDefaultApplied
})
