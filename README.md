# DESSEM2Julia

Convert DESSEM input files (.DAT and related text files) into structured Julia objects and persist them in JLD2 format.

DESSEM is a hydrothermal dispatch optimization model used for short-term operational planning in Brazilian power systems.

## Quickstart

Open this folder in VS Code, then in a Julia REPL run:

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
Pkg.test()
```

## Documentation

- **Tasks and roadmap**: [`TASKS.md`](TASKS.md)
- **Architecture overview**: [`docs/architecture.md`](docs/architecture.md)
- **DESSEM file format specifications**: [`docs/dessem-complete-specs.md`](docs/dessem-complete-specs.md)
- **File coverage status**: [`docs/file_formats.md`](docs/file_formats.md)

## Contributing

Tests run in CI on pushes/PRs. To run tests locally before committing, enable the pre-commit hook:

**PowerShell:**
```powershell
./scripts/setup-hooks.ps1
```

Then commit as usual; the hook will run `Pkg.test()`.

## Development

- Main module: `src/DESSEM2Julia.jl`
- Type definitions: `src/types.jl`
- Parser infrastructure: `src/parser/`
  - Common utilities: `src/parser/common.jl`
  - TERMDAT parser: `src/parser/termdat.jl` ✅ (110 tests passing)
- JLD2 I/O: `src/io.jl`
- Public API: `src/api.jl`
- Tests: `test/runtests.jl`, `test/termdat_tests.jl`

## Current Status

✅ **TERMDAT.DAT Parser** - Complete with comprehensive test coverage
- Parses thermal plant registry (CADUSIT, CADUNIDT, CURVACOMB records)
- 110 tests passing including real production data validation
- Successfully parses 98 plants, 387 units from actual DESSEM files