# DESSEM2Julia

Convert DESSEM input files (.DAT and related text files) into structured Julia objects and persist them in JLD2 format.

## Quickstart

Open this folder in VS Code, then in a Julia REPL run:

using Pkg
Pkg.activate(".")
Pkg.instantiate()
Pkg.test()

## Roadmap and docs

- Tasks and phases: `TASKS.md`
- Architecture: `docs/architecture.md`
- File formats coverage: `docs/file_formats.md`

## Contributing

Tests run in CI on pushes/PRs. To run tests locally before committing, enable the pre-commit hook:

PowerShell:

./scripts/setup-hooks.ps1

Then commit as usual; the hook will run `Pkg.test()`.

## Development

- Main module: `src/DESSEM2Julia.jl`
- Tests: `test/runtests.jl`