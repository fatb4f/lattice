package kg

import (
	decisionpkg "github.com/fatb4f/lattice/kg/decisions"
	insightpkg "github.com/fatb4f/lattice/kg/insights"
	patternpkg "github.com/fatb4f/lattice/kg/patterns"
	rejectedpkg "github.com/fatb4f/lattice/kg/rejected"
	sourcepkg "github.com/fatb4f/lattice/kg/sources"
	taskpkg "github.com/fatb4f/lattice/kg/tasks"
	workspacepkg "github.com/fatb4f/lattice/kg/workspace"
)

_collections: {
	decisions: decisionpkg.Graph
	insights:  insightpkg.Graph
	rejected:  rejectedpkg.Graph
	patterns:  patternpkg.Graph
	sources:   sourcepkg.Graph
	tasks:     taskpkg.Graph
	workspace: workspacepkg.Graph
}

_manifestGraphSet: close({
	for id, _ in kb.graphs {
		(id): true
	}
})

_collectionGraphSet: close({
	for id, _ in _collections {
		(id): true
	}
})

_graphAssemblyClosure: _manifestGraphSet & _collectionGraphSet

_projectName: project.name
_contextValue: project

#KGIndexV1: {
	project: string & !=""
	context: {...}
	decisions: {...}
	insights: {...}
	rejected: {...}
	patterns: {...}
	sources: {...}
	tasks: {...}
	workspace: {...}
	entities: {...}

	summary: {
		total_decisions: len(decisions)
		total_insights:  len(insights)
		total_rejected:  len(rejected)
		total_patterns:  len(patterns)
		total_sources:   len(sources)
		total_tasks:     len(tasks)
		total_workspace: len(workspace)
		total: total_decisions + total_insights + total_rejected + total_patterns + total_sources + total_tasks + total_workspace
	}

	by_status: {for status in ["proposed", "accepted", "deprecated", "superseded"] {
		(status): {for id, decision in decisions if decision.status == status {(id): decision.title}}
	}}

	by_confidence: {for confidence in ["high", "medium", "low"] {
		(confidence): {for id, insight in insights if insight.confidence == confidence {(id): insight.statement}}
	}}
}

_index: #KGIndexV1 & {
	project:   _projectName
	context:   _contextValue
	decisions: _collections.decisions
	insights:  _collections.insights
	rejected:  _collections.rejected
	patterns:  _collections.patterns
	sources:   _collections.sources
	tasks:     _collections.tasks
	workspace: _collections.workspace

	// Collection-agnostic adapters resolve IDs through this derived map.
	entities: {
		"project-context": {
			collection: "context"
			value:      _contextValue
		}
		for collectionName, collection in _collections
		for id, entity in collection {
			(id): {
				collection: collectionName
				value:      entity
			}
		}
	}
}
