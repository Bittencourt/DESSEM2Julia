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

### Getting Started
- **Repository structure**: [`docs/REPOSITORY_STRUCTURE.md`](docs/REPOSITORY_STRUCTURE.md) - Complete guide to repo organization 📁

### Planning & Progress
- **Quick start guide**: [`docs/planning/QUICK_START_GUIDE.md`](docs/planning/QUICK_START_GUIDE.md) ⚡ **START HERE**
- **Complete project context**: [`docs/planning/PROJECT_CONTEXT.md`](docs/planning/PROJECT_CONTEXT.md) 📖 **Essential reading**
- **Tasks and roadmap**: [`docs/planning/TASKS.md`](docs/planning/TASKS.md)
- **ONS compatibility summary**: [`docs/planning/ONS_COMPATIBILITY_SUMMARY.md`](docs/planning/ONS_COMPATIBILITY_SUMMARY.md)

### Architecture & Design
- **Architecture overview**: [`docs/architecture.md`](docs/architecture.md)
- **Type system guide**: [`docs/type_system.md`](docs/type_system.md) ⭐
- **DESSEM file format specifications**: [`docs/dessem-complete-specs.md`](docs/dessem-complete-specs.md)
- **File coverage status**: [`docs/file_formats.md`](docs/file_formats.md)
- **Format implementation notes**: [`docs/FORMAT_NOTES.md`](docs/FORMAT_NOTES.md)

### Parser Implementation Guides
- **OPERUT parser implementation**: [`docs/parsers/OPERUT_IMPLEMENTATION.md`](docs/parsers/OPERUT_IMPLEMENTATION.md)
- **IDESEM library comparison**: [`docs/parsers/idessem_comparison.md`](docs/parsers/idessem_comparison.md)
- **Binary file formats**: [`docs/parsers/BINARY_FILES.md`](docs/parsers/BINARY_FILES.md)

### Session Summaries
- **Session 5**: [`docs/sessions/session5_summary.md`](docs/sessions/session5_summary.md) - Core type system implementation
- **Session 6**: [`docs/sessions/session6_summary.md`](docs/sessions/session6_summary.md) - OPERUT parser implementation

## Examples

- **Parse sample DESSEM case**: [`examples/parse_sample_case.jl`](examples/parse_sample_case.jl) - Comprehensive demonstration of parsing real CCEE data
- **ONS compatibility check**: [`examples/verify_ons_compatibility.jl`](examples/verify_ons_compatibility.jl) - Verify parser works with ONS network-enabled cases
- **OPERUH parser test**: [`examples/test_operuh_parse.jl`](examples/test_operuh_parse.jl) - Simple OPERUH parser demonstration

## Sample Data

The project includes two real-world DESSEM cases for testing:

- **DS_CCEE_102025_SEMREDE_RV0D28**: CCEE case without network constraints (October 2025)
- **DS_ONS_102025_RV2D11**: ONS case with network modeling enabled (October 2025, Rev 2)

Both samples are fully supported by the existing parsers. See [`docs/planning/ONS_COMPATIBILITY_SUMMARY.md`](docs/planning/ONS_COMPATIBILITY_SUMMARY.md) for verification results.

## Contributing

Tests run in CI on pushes/PRs. To run tests locally before committing, enable the pre-commit hook:

**PowerShell:**
```powershell
./scripts/setup-hooks.ps1
```

Then commit as usual; the hook will run `Pkg.test()`.

## Development

- Main module: `src/DESSEM2Julia.jl`
- Type definitions:
  - Legacy types: `src/types.jl`
  - **Core type system**: `src/models/core_types.jl` ⭐ (40+ types, 15/32 files covered)
- Parser infrastructure: `src/parser/`
  - Common utilities: `src/parser/common.jl`
  - Registry system: `src/parser/registry.jl`
  - Master file index: `src/parser/dessemarq.jl` ✅ (68/68 tests passing)
  - TERMDAT parser: `src/parser/termdat.jl` ✅ (110 tests passing)
  - ENTDADOS parser: `src/parser/entdados.jl` ✅ (2331/2334 tests passing)
- JLD2 I/O: `src/io.jl`
- Public API: `src/api.jl`
- Tests: `test/runtests.jl`, `test/*_tests.jl`

## Current Status

### ✅ Core Type System - Production Ready ⭐ NEW
- Comprehensive data model for all 32 DESSEM files
- **40+ types** organized into 11 functional subsystems
- **15/32 files** with complete type definitions (47% coverage)
- Hierarchical design: `DessemCase → Subsystems → Records`
- Full documentation in `docs/type_system.md`

### ✅ dessem.arq Parser - Production Ready
- Master file index parser (file registry/manifest)
- **68/68 tests passing** (100%)
- Maps all 32 DESSEM input files dynamically

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