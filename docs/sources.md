# CUE Pattern Sources

`sources/` records source references for the local CUE pattern suite. It is not
the executable pattern registry.

`patterns/` is the executable pattern suite. Each pattern file exposes a named
case under `#Patterns`, and `patterns/schema.cue` defines the shared executable
case contract.
