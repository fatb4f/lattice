package pillars

import meta "github.com/fatb4f/lattice/meta"

#Pillars: {
	"bounds": {

#Port:       int & >=1 & <=65535
#Identifier: string & =~"^[a-z][a-z0-9-]*$"

canonical: {
	id:      "bounds"
	port:    #Port
	service: #Identifier
}

positive: {
	port:    #Port & 8080
	service: #Identifier & "api-server"
	validation: (meta.#MakeClosedObligationState & {in: {
		id: "bounds"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	portTooHigh: 70000
	badID:       "API_SERVER"
}

}
}
