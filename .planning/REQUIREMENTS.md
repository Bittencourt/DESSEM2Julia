# Requirements: DESSEM2Julia

**Defined:** 2026-02-18
**Core Value:** Convert all valid DESSEM input file sets into reliable, validated, structured Julia data

## v1 Requirements

Requirements for v1.0 release. Each maps to roadmap phases.

### Error Handling

- [ ] **ERR-01**: All parsers throw ParserError consistently (no `error()`, no `@warn` + return nothing)
- [ ] **ERR-02**: Capacity validation throws ParserError instead of MethodError when min_generation > capacity
- [ ] **ERR-03**: Heat rate validation throws ParserError for invalid values (zero, negative)
- [ ] **ERR-04**: Silent failure patterns replaced with explicit errors (operuh.jl, hidr.jl, pwf.jl)

### Data Validation

- [ ] **VAL-01**: Cross-file referential integrity validation (IDs referenced in one file exist in another)
- [ ] **VAL-02**: Thermal plant IDs in OPERUT validated against TERMDAT CADUSIT
- [ ] **VAL-03**: Hydro plant IDs in OPERUH validated against HIDR
- [ ] **VAL-04**: Bus IDs in network files validated against ENTDADOS
- [ ] **VAL-05**: Subsystem codes consistent across all files

### API

- [ ] **API-01**: Public API exports audited (internal functions removed from exports)
- [ ] **API-02**: Docstrings added to all exported functions and types
- [ ] **API-03**: Module documentation updated for v1.0 release

### Technical Debt

- [ ] **DEBT-01**: Binary file type definitions completed (INFOFCF.DEC, MAPCUT.DEC, CORTES.DEC)
- [ ] **DEBT-02**: Large files split for maintainability (types.jl, entdados.jl, core_types.jl)
- [ ] **DEBT-03**: CI testing expanded to Julia 1.6, 1.10, 1.11
- [ ] **DEBT-04**: Visualization dependencies made optional (GraphPlot, Compose)
- [ ] **DEBT-05**: Deprecated SIMUL parser removed or documented
- [ ] **DEBT-06**: Manual cleanup files removed from project root
- [ ] **DEBT-07**: Commented-out tests resolved (fixed or documented as known limitation)
- [ ] **DEBT-08**: Test coverage for error paths added

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Enhanced Validation

- **VAL-06**: Lazy validation mode (collect all errors before failing)
- **VAL-07**: Structured error reports (grouped by category)
- **VAL-08**: Custom validation rules API (user-extensible hooks)
- **VAL-09**: Validation severity levels (error vs warning)

### Additional Features

- **FEAT-01**: Data summary/reports (quick statistics on parsed data)
- **FEAT-02**: Round-trip verification (serialize back, compare)
- **FEAT-03**: Streaming/chunked parsing (large file handling)
- **FEAT-04**: Batch processing API (multiple cases)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Write support (creating DESSEM files) | Requires CEPEL format specs unavailable |
| Automatic format detection | Leads to silent mis-parsing |
| Silent coercion with logging | Hides data quality issues |
| Parallel parsing by default | Adds complexity; file dependencies |
| Legacy DESSEM format support | Unmaintainable; focus on current version |
| Database output | Out of scope for parser library |
| GUI/file browser | Out of scope for parser library |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ERR-01 | Phase 1 | Pending |
| ERR-02 | Phase 1 | Pending |
| ERR-03 | Phase 1 | Pending |
| ERR-04 | Phase 1 | Pending |
| VAL-01 | Phase 5 | Pending |
| VAL-02 | Phase 5 | Pending |
| VAL-03 | Phase 5 | Pending |
| VAL-04 | Phase 5 | Pending |
| VAL-05 | Phase 5 | Pending |
| API-01 | Phase 6 | Pending |
| API-02 | Phase 7 | Pending |
| API-03 | Phase 7 | Pending |
| DEBT-01 | Phase 4 | Pending |
| DEBT-02 | Phase 3 | Pending |
| DEBT-03 | Phase 2 | Pending |
| DEBT-04 | Phase 6 | Pending |
| DEBT-05 | Phase 6 | Pending |
| DEBT-06 | Phase 3 | Pending |
| DEBT-07 | Phase 2 | Pending |
| DEBT-08 | Phase 1 | Pending |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-18*
*Last updated: 2026-02-18 after initial definition*
