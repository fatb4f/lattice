package unificationpatterns

#ComposableProfile: close({
	id:        =~"^[a-z0-9]+(-[a-z0-9]+)*$"
	authority: string
	enabled:   bool | *true
})

baseProfile: #ComposableProfile & {
	id:        "unification-pattern"
	authority: "patterns"
}

operatorOverride: {
	enabled: true
}

unifiedProfile: baseProfile & operatorOverride
