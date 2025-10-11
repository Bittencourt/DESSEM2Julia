# Architecture

This project parses DESSEM input files and converts them into an internal, typed data model that is then persisted in JLD2.

## Modules

- DESSEM2Julia
  - Parsers: per-file modules with pure parsing functions
  - Model: immutable structs representing inputs
  - IO: JLD2 save/load
  - CLI: thin entry point around library API

## Data flow

input folder -> enumerate files -> select parser -> parse to structs -> validate -> write JLD2
