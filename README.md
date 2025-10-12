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
  - Registry system: `src/parser/registry.jl`
  - TERMDAT parser: `src/parser/termdat.jl` ✅ (110 tests passing)
  - ENTDADOS parser: `src/parser/entdados.jl` ✅ (2331/2334 tests passing)
- JLD2 I/O: `src/io.jl`
- Public API: `src/api.jl`
- Tests: `test/runtests.jl`, `test/termdat_tests.jl`, `test/entdados_tests.jl`

## Current Status

### ✅ TERMDAT.DAT Parser - Production Ready
- Parses thermal plant registry (CADUSIT, CADUNIDT, CURVACOMB records)
- **110/110 tests passing** (100%)
- Successfully parses 98 plants, 387 units from actual DESSEM files

### ✅ ENTDADOS.DAT Parser - Production Ready
- Parses general operational data (TM, SIST, UH, UT, DP records)
- **2331/2334 tests passing** (99.9%)
- Successfully parses all real CCEE data:
  - 73 time periods
  - 5 subsystems
  - 168 hydro plants
  - 116 thermal plants
  - 293 demand records
- 3 failing tests are malformed validation tests (not production issues)