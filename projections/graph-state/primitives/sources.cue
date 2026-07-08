package primitives

#SourceRole:
	"primary-state-and-intent" |
	"storage-and-substrate" |
	"conceptual-model"

#SourceWitness: close({
	id:          #KebabID
	name:        #NonEmptyString
	role:        #SourceRole
	description: #NonEmptyString
})

sourceLedger: {
	"gitbutler-stack": #SourceWitness & {
		name:        "GitButler Stack"
		role:        "primary-state-and-intent"
		description: "Supports streams through stable identity, source refs, upstreams, order, workspace membership, and heads."
	}
	"gitbutler-hunk-assignment": #SourceWitness & {
		name:        "GitButler HunkAssignment"
		role:        "primary-state-and-intent"
		description: "Supports fragments and assignments through hunk identity, path, stack assignment, branch target, line numbers, and diff data."
	}
	"gitbutler-hunk-dependency": #SourceWitness & {
		name:        "GitButler hunk dependency surfaces"
		role:        "primary-state-and-intent"
		description: "Supports dependencies through apply and merge-conflict constraints between patch fragments."
	}
	"go-git-storage": #SourceWitness & {
		name:        "go-git storage"
		role:        "storage-and-substrate"
		description: "Supports commit, tree, blob, tag, ref, and worktree substrate primitives."
	}
	"pro-git-concepts": #SourceWitness & {
		name:        "Pro Git"
		role:        "conceptual-model"
		description: "Supports object database, refs, and three-tree vocabulary."
	}
}

primitiveSourceLedger: {
	target: {
		"go-git-storage":   true
		"pro-git-concepts": true
	}
	workspace: {
		"go-git-storage":   true
		"pro-git-concepts": true
	}
	stream: {
		"gitbutler-stack": true
	}
	fragment: {
		"gitbutler-hunk-assignment": true
	}
	assignment: {
		"gitbutler-hunk-assignment": true
	}
	dependency: {
		"gitbutler-hunk-dependency": true
	}
	conflict: {
		"gitbutler-hunk-dependency": true
	}
	projection: {
		"go-git-storage":   true
		"pro-git-concepts": true
	}
	context: {
		"gitbutler-stack":  true
		"pro-git-concepts": true
	}
	producer: {
		"gitbutler-stack": true
		"go-git-storage":  true
	}
}

sourceLedgerComplete: close({
	for primitive, witnesses in primitiveSourceLedger {
		"\(primitive)-has-witness": true & (len([for _, _ in witnesses {true}]) > 0)
	}
})

sourceRolesSeparated: close({
	"gitbutler-stack-primary":  true & (sourceLedger["gitbutler-stack"].role == "primary-state-and-intent")
	"go-git-storage-substrate": true & (sourceLedger["go-git-storage"].role == "storage-and-substrate")
	"pro-git-conceptual":       true & (sourceLedger["pro-git-concepts"].role == "conceptual-model")
})
