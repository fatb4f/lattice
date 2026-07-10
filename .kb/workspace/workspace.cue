package workspace

import "quicue.ca/kg/ext@v0"

// #WorkspaceV1 is the stable repository workspace contract.
#WorkspaceV1: ext.#Workspace

Graph: {
	"lattice-workspace": #WorkspaceV1 & {
		name:        "lattice"
		description: "Workspace boundary for lattice KG source, hook runtime, and projection outputs."
		components: {
			repository: {
				path:        "."
				description: "Lattice repository root."
				module:      "github.com/fatb4f/lattice"
			}
			knowledge: {
				path:        ".kb"
				description: "Canonical project knowledge authority."
			}
			hooks: {
				path:        ".kg"
				description: "KG hook and Codex drift-control runtime."
			}
		}
	}
}
