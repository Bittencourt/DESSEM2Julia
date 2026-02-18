# DESSEM2Julia

## What This Is

A Julia package that parses DESSEM (Brazilian power system hydrothermal dispatch optimization model) input files and converts them into structured Julia data. Handles all valid DESSEM input variations — CCEE datasets for PLD price calculation (no network) and ONS datasets for operation planning (with network). Outputs clean, validated data for downstream Julia applications. Open source package targeting v1.0 release.

## Core Value

Convert all valid DESSEM input file sets into reliable, validated, structured Julia data that downstream applications can confidently consume.

## Requirements

### Validated

- ✓ 32+ file format parsers (hydro, thermal, network, constraints, reserves, DECOMP interface)
- ✓ Fixed-width text parsing infrastructure with FieldSpec system
- ✓ Binary file parsing for HIDR.DAT and DECOMP files
- ✓ JLD2 serialization for parsed data
- ✓ Basic test infrastructure with ONS/CCEE sample data
- ✓ Parser registry for file-type dispatch
- ✓ Domain model types in core_types.jl

### Active

- [ ] Standardize error handling across all parsers (ParserError everywhere, no silent failures)
- [ ] Fix validation error handling (capacity validation, heat rate validation)
- [ ] Complete binary file handling (INFOFCF.DEC, MAPCUT.DEC, CORTES.DEC type definitions)
- [ ] Implement data validation layer (cross-file consistency checks, referential integrity)
- [ ] Improve API for cleaner downstream use
- [ ] Complete test coverage (uncomment disabled tests, add error path testing)
- [ ] Split large files for maintainability (types.jl, entdados.jl, core_types.jl)
- [ ] Expand CI testing to Julia 1.6-1.10
- [ ] Make visualization dependencies optional (GraphPlot, Compose)
- [ ] Remove deprecated SIMUL parser or document clearly
- [ ] Clean up manual cleanup files in project root
- [ ] Add documentation for v1.0 release

### Out of Scope

- Write support (creating/modifying DESSEM files) — would require CEPEL format specs
- Older DESSEM data versions — focus on current version only
- Batch processing API for multiple cases — future enhancement
- Parallel file parsing — optimization for later

## Context

**Brownfield project** with substantial existing infrastructure. Technical debt already documented in `.planning/codebase/CONCERNS.md` including:
- Inconsistent error handling patterns (`error()`, `throw(ParserError())`, `@warn` + return)
- Validation tests disabled due to wrong exception types
- Incomplete binary type definitions pending CEPEL specs
- Silent failures with `@warn` logging
- Large files difficult to maintain (types.jl: 3,114 lines)

**Sample data:** Integration tests use real ONS and CCEE sample files. Tests skip when sample files not present.

**Downstream users:** Open source community who need DESSEM data in Julia applications.

## Constraints

- **Backward Compatibility:** Must maintain existing public API; breaking changes require migration path
- **Julia Version:** Must support Julia 1.6+ (compat declared in Project.toml)
- **Output Format:** JLD2 serialization required for parsed data persistence
- **Data Version:** Current DESSEM format only; no legacy version support

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Standardize on ParserError | Consistent error handling lets users catch parsing failures predictably | — Pending |
| Keep JLD2 as primary output | Already implemented, HDF5-based, good Julia ecosystem support | — Pending |
| Focus on current DESSEM version | CEPEL releases new formats; supporting all versions would be unmaintainable | — Pending |

---
*Last updated: 2026-02-18 after initialization*
