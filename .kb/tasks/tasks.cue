package tasks

#Task: close({
	id:          string & !=""
	title:       string & !=""
	status:      "planned" | "active" | "done" | "blocked"
	description: string & !=""
	refs?: {[string]: true}
})

graph: {
	"kg-hook-runtime": #Task & {
		id:          "kg-hook-runtime"
		title:       "Route Codex prompt context through KG hook runtime"
		status:      "active"
		description: "Replace static resolver artifacts with transient context packets selected from the CUE-native .kb graph."
		refs: {
			"ADR-003": true
		}
	}
}
