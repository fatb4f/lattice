package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"defaults": {

#LogLevel: "debug" | "info" | "warn" | *"info"

canonical: {
	id:       "defaults"
	logLevel: #LogLevel
}

positive: {
	explicit: {
		logLevel: #LogLevel & "debug"
	}
	implicit: {
		logLevel: #LogLevel
	}
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "defaults"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	invalidLogLevel: "trace"
}

}
}
