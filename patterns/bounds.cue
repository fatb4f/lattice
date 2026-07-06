package patterns

import domain "github.com/fatb4f/lattice/domain"

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
	validation: (domain.#MakeClosedObligationState & {in: {
		id: "bounds"
		resources: {}
		operations: {}
		gates: {}
		witnesses: {}
	}}).out
}

negative: {
	portTooHigh: #Port & 70000
	badID:       #Identifier & "API_SERVER"
}
