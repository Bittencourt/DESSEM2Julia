# Roadmap: DESSEM2Julia

## Overview

Transform a functional parser library into a v1.0 release quality package by standardizing error handling, adding cross-file validation, cleaning technical debt, and documenting the public API. The journey progresses from foundation fixes (error handling) through feature addition (validation layer) to release preparation (API documentation).

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Error Handling Foundation** - Standardize all parsers on ParserError
- [ ] **Phase 2: Test Infrastructure** - Expand CI and resolve disabled tests
- [ ] **Phase 3: Code Organization** - Split large files and clean project root
- [ ] **Phase 4: Binary File Support** - Complete binary type definitions
- [ ] **Phase 5: Validation Layer** - Cross-file referential integrity checks
- [ ] **Phase 6: API Hygiene** - Audit exports and make optional deps optional
- [ ] **Phase 7: Documentation** - Docstrings and module documentation for v1.0

## Phase Details

### Phase 1: Error Handling Foundation
**Goal**: All parsers fail predictably with ParserError containing file/line context
**Depends on**: Nothing (first phase)
**Requirements**: ERR-01, ERR-02, ERR-03, ERR-04, DEBT-08
**Success Criteria** (what must be TRUE):
  1. User catches ParserError (not MethodError or generic error) when any parsing operation fails
  2. ParserError message includes file path and line number where the failure occurred
  3. No parser returns nothing after logging a warning — all failures throw
  4. Error path tests pass for capacity validation, heat rate validation, and silent failure patterns
**Plans**: 4 plans in 2 waves

Plans:
- [ ] 01-01-PLAN.md — Replace error() calls with ParserError across 8 parser files (Wave 1)
- [ ] 01-02-PLAN.md — Fix ParserError argument order in termdat.jl + validation tests (Wave 1)
- [ ] 01-03-PLAN.md — Replace silent failures in operuh.jl with explicit errors (Wave 1)
- [ ] 01-04-PLAN.md — Create comprehensive error path tests (Wave 2, depends on 01-01, 01-02, 01-03)

### Phase 2: Test Infrastructure
**Goal**: CI validates all supported Julia versions and all tests run
**Depends on**: Phase 1
**Requirements**: DEBT-03, DEBT-07
**Success Criteria** (what must be TRUE):
  1. CI runs tests on Julia 1.6, 1.10, and 1.11
  2. All previously commented-out tests are uncommented and passing
  3. Test suite runs green on all three tested Julia versions
**Plans**: TBD

Plans:
- [ ] 02-01: Expand CI matrix to Julia 1.6, 1.10, 1.11
- [ ] 02-02: Resolve commented-out tests (fix or document)

### Phase 3: Code Organization
**Goal**: Codebase is maintainable with reasonably-sized files
**Depends on**: Phase 2
**Requirements**: DEBT-02, DEBT-06
**Success Criteria** (what must be TRUE):
  1. No source file exceeds 800 lines (after splitting types.jl, entdados.jl, core_types.jl)
  2. Project root contains only standard Julia project files (no manual cleanup files)
  3. Module structure reflects logical domain groupings (hydro types, thermal types, network types)
**Plans**: TBD

Plans:
- [ ] 03-01: Split types.jl into domain-focused modules
- [ ] 03-02: Split entdados.jl and core_types.jl if needed
- [ ] 03-03: Remove manual cleanup files from project root

### Phase 4: Binary File Support
**Goal**: All binary file types are fully defined with typed fields
**Depends on**: Phase 3
**Requirements**: DEBT-01
**Success Criteria** (what must be TRUE):
  1. INFOFCF.DEC files parse into typed Julia structures (not raw bytes)
  2. MAPCUT.DEC files parse into typed Julia structures
  3. CORTES.DEC files parse into typed Julia structures
  4. Binary file parsing tests pass with available sample data
**Plans**: TBD

Plans:
- [ ] 04-01: Define typed structures for INFOFCF.DEC
- [ ] 04-02: Define typed structures for MAPCUT.DEC
- [ ] 04-03: Define typed structures for CORTES.DEC

### Phase 5: Validation Layer
**Goal**: Cross-file referential integrity is automatically verified
**Depends on**: Phase 4
**Requirements**: VAL-01, VAL-02, VAL-03, VAL-04, VAL-05
**Success Criteria** (what must be TRUE):
  1. User calls validate(data) and receives structured list of all validation issues
  2. Invalid thermal plant IDs in OPERUT are detected and reported with context
  3. Invalid hydro plant IDs in OPERUH are detected and reported with context
  4. Invalid bus IDs in network files are detected and reported with context
  5. Inconsistent subsystem codes across files are detected and reported
**Plans**: TBD

Plans:
- [ ] 05-01: Create Validation module with types and interface
- [ ] 05-02: Implement basic validators (range, temporal)
- [ ] 05-03: Implement cross-file reference validators
- [ ] 05-04: Integrate validation into public API

### Phase 6: API Hygiene
**Goal**: Only intended functions are exported, dependencies are minimal
**Depends on**: Phase 5
**Requirements**: API-01, DEBT-04, DEBT-05
**Success Criteria** (what must be TRUE):
  1. Internal helper functions are not exported from main module
  2. GraphPlot and Compose dependencies install only when user requests visualization
  3. SIMUL parser status is clear (removed or documented as deprecated with migration note)
  4. Pkg.add installs only essential dependencies for parsing functionality
**Plans**: TBD

Plans:
- [ ] 06-01: Audit and prune public API exports
- [ ] 06-02: Make visualization dependencies optional
- [ ] 06-03: Handle deprecated SIMUL parser

### Phase 7: Documentation
**Goal**: Users can discover and understand the complete public API
**Depends on**: Phase 6
**Requirements**: API-02, API-03
**Success Criteria** (what must be TRUE):
  1. All exported functions have docstrings with usage examples
  2. All exported types have docstrings describing their fields and purpose
  3. Module-level documentation describes package purpose and basic usage pattern
  4. User can read docstrings via Julia's help system (?) for any public symbol
**Plans**: TBD

Plans:
- [ ] 07-01: Add docstrings to all exported functions
- [ ] 07-02: Add docstrings to all exported types
- [ ] 07-03: Update module-level documentation for v1.0

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Error Handling Foundation | 0/4 | Planned | - |
| 2. Test Infrastructure | 0/2 | Not started | - |
| 3. Code Organization | 0/3 | Not started | - |
| 4. Binary File Support | 0/3 | Not started | - |
| 5. Validation Layer | 0/4 | Not started | - |
| 6. API Hygiene | 0/3 | Not started | - |
| 7. Documentation | 0/3 | Not started | - |

---
*Roadmap created: 2026-02-18*
*Depth: comprehensive*
*Total phases: 7*
