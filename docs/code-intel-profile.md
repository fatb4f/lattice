# Code-Intel Profile

The code-intel profile expectation is a lattice-owned validation target for
generated code-intel profile snapshots.

`profiles/code-intel` consumes a snapshot-shaped fixture and validates:

- required idiom-family coverage
- lattice idiom authority references
- cue-lsp as evidence-only provider
- generated/operator context as non-authority

Export the feedback report with:

```sh
cue export ./profiles/code-intel -e codeIntelProfileFeedbackReport
```

