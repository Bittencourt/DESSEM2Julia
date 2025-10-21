# DESSEM2Julia

Convert DESSEM input files (.DAT and related text files) into structured Julia objects and persist them in JLD2 format.

DESSEM is a hydrothermal dispatch optimization model used for short-term operational planning in Brazilian power systems.

---

## 📚 Documentation

> **🗺️ [Complete Documentation Index](docs/INDEX.md)** - Wiki-style navigation for all documentation  
> **📖 [Documentation Hub](docs/README.md)** - Organized documentation overview  
> **🗺️ [Documentation Sitemap](docs/SITEMAP.md)** - Visual map of all docs

**Quick Links**:
- 🚀 [Quick Start Guide](docs/planning/QUICK_START_GUIDE.md) - Get started in minutes
- 🔗 [Entity Relationships](docs/ENTITY_RELATIONSHIPS.md) - Complete ER model ⭐ **ESSENTIAL**
- 💧 [HIDR Quick Reference](docs/HIDR_QUICK_REFERENCE.md) - Hydro plant parsing
- 📋 [File Formats](docs/file_formats.md) - Parser status overview

---

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
- **Entity relationships (Database-like model)**: [`docs/ENTITY_RELATIONSHIPS.md`](docs/ENTITY_RELATIONSHIPS.md) 🔗 **NEW**
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
  - Master file index: `src/parser/dessemarq.jl` ✅ (68/68 tests passing, ordered registry via `DessemFileRecord`)
  - TERMDAT parser: `src/parser/termdat.jl` ✅ (110/110 tests passing)
  - ENTDADOS parser: `src/parser/entdados.jl` ✅ (129/129 tests passing, 30+ record types)
  - OPERUT parser: `src/parser/operut.jl` ✅ (62/62 tests passing)
  - OPERUH parser: `src/parser/operuh.jl` ✅ (all tests passing)
  - DADVAZ parser: `src/parser/dadvaz.jl` ✅ (13/13 tests passing)
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
- Ordered `files` registry exposes every entry as `DessemFileRecord` for iteration

### ✅ TERMDAT.DAT Parser - Production Ready
- Parses thermal plant registry (CADUSIT, CADUNIDT, CURVACOMB records)
- **110/110 tests passing** (100%)
- Successfully parses 98 plants, 387 units from actual DESSEM files

### ✅ ENTDADOS.DAT Parser - Production Ready ⭐ **100% COMPLETE**
- Parses general operational data (**35+ record types** - complete coverage)
- **2,362/2,362 tests passing** (100%)
- Successfully parses all real CCEE and ONS data:
  - **Core data**: 73 time periods, 5 subsystems, 168 hydro plants, 116 thermal plants, 293 demand records
  - **Network configuration**: RD (network options), RIVAR (variable restrictions), REE (energy regions)
  - **Hydro modeling**: TVIAG (water travel time), USIE (pump storage stations)
  - **Electrical constraints**: RE (constraint definitions), LU (limits with optional fields)
  - **Plant adjustments**: AC (variable format support), AG (aggregate groups)
  - **Coefficient records**: FH, FT, FI, FE, FR, FC (hydro/thermal/interchange/energy/renewable/load)
  - **Advanced parameters**: TX (discount rate), EZ (coupling %), R11 (gauge variations), FP (FPHA), SECR (river sections), CR (head-flow polynomials)

### ✅ OPERUT.DAT Parser - Production Ready
- Parses thermal unit operational data (INIT, OPER records)
- **62/62 tests passing** (100%)
- Successfully parses real CCEE production data:
  - 387 thermal units (47 ON, 340 OFF states)
  - 422 operational constraint records
  - Fixed-width column format based on IDESEM reference
- INIT records publish `initial_status` (0=off, 1=on) for cross-parser consistency

### ✅ DADVAZ.DAT Parser - Production Ready ⭐ NEW
- Parses natural inflow data and metadata
- **13/13 tests passing** (100%)
- Successfully parses real CCEE data:
  - Header metadata (plant roster, study start, FCF configuration)
  - Daily inflow slices for 168 hydro plants
  - Handles symbolic period markers ("I"/"F") and optional hours

### ✅ OPERUH.DAT Parser - Production Ready ⭐ NEW
- Parses hydro operational constraints (REST, ELEM, LIM, VAR records)
- **All tests passing** (100%)
- Successfully parses real ONS data:
  - Constraint definitions (REST records)
  - Plant participation factors (ELEM records)
  - Time-varying operational limits (LIM records)
  - Ramp/variation constraints (VAR records)
  - Constraint ID linking validated

### ✅ DESSELET.DAT Parser - Production Ready ⭐ NEW
- Parses network case mapping (base cases + patamares)
- **15/15 tests passing** (100%)
- Successfully parses real ONS data:
  - Base network cases (4 PWF files: leve, media, pesada, etc.)
  - Patamar scenarios (48 half-hourly time stages)
  - Date/time scheduling with duration
  - Base case reference linking
- **Exception**: Uses split() instead of fixed-width (variable spacing in actual files)

---

### 📊 Overall Parser Progress

**Completed**: 10/32 parsers (31% coverage)
- ✅ dessem.arq (master file registry)
- ✅ termdat.dat (thermal plant registry)
- ✅ entdados.dat (general system data - 30+ record types)
- ✅ operut.dat (thermal operations)
- ✅ dadvaz.dat (hydro inflows)
- ✅ deflant.dat (previous flows for travel time)
- ✅ operuh.dat (hydro constraints)
- ✅ desselet.dat (network case mapping)

**In Progress**: 2/32 parsers
- 🔄 hidr.dat (binary hydro data - partial)

**Pending High Priority**:
- confhd.dat (hydro configuration)
- modif.dat (modifications)

---

### 🧪 Test Coverage

**Total Tests**: 3,935 tests passing ✅
- ParserCommon utilities: 124 tests
- TERMDAT parser: 136 tests
- ENTDADOS parser: 2,362 tests
- DessemArq parser: 69 tests
- OPERUT parser: 106 tests
- DADVAZ parser: 17 tests
- DEFLANT parser: 1,076 tests
- DESSELET parser: 15 tests
- ONS Integration: 123 tests
- ✅ TERMDAT.DAT (thermal plant registry)
- ✅ **ENTDADOS.DAT (general operational data)** - 35+ record types ⭐
- ✅ OPERUT.DAT (thermal operations)
- ✅ DADVAZ.DAT (natural inflows)
- ✅ DEFLANT.DAT (previous flows)
- ✅ OPERUH.DAT (hydro constraints)
- ✅ DESSELET.DAT (network case mapping)

**Total Tests**: **3,935 tests passing** across all parsers (100% success rate)

**Validation**: All parsers tested against real ONS and CCEE operational data