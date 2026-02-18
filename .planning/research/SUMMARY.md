# Project Research Summary

**Project:** DESSEM2Julia Validation Layer
**Domain:** Julia data parser library with validation layer addition
**Researched:** 2026-02-18
**Confidence:** HIGH

## Executive Summary

DESSEM2Julia is a Julia package that parses fixed-width and binary DESSEM power system optimization files into typed Julia structures. The codebase currently has 32+ working parsers but lacks a cohesive validation layer — field validation exists but cross-file referential integrity checks are completely missing. Research reveals this is a mature parser needing a **post-parse validation architecture** rather than validation mixed into parsing code.

The recommended approach is a three-tier validation system: (1) **Tier 1** — field-level validation during parsing (already exists via `validate_range`, `validate_positive` helpers), (2) **Tier 2** — cross-field validation within a single record, and (3) **Tier 3** — cross-file semantic validation (referential integrity, temporal consistency). The validation layer should be a separate module with composable validators, returning structured `ValidationResult` objects with errors and warnings rather than throwing exceptions for each issue.

Key risks include **inconsistent exception types** (some parsers use `error()` instead of `ParserError`, breaking test suites) and **silent failures** (parsers returning `nothing` after `@warn` instead of throwing). Both must be fixed before v1.0. The existing codebase has good patterns in `common.jl` but they're underutilized across parsers.

## Key Findings

### Recommended Stack

Julia 1.10+ (LTS) with Test.jl (stdlib), ArgCheck.jl for preconditions, and Aqua.jl for package QA. Development workflow uses Revise.jl for REPL reload and JuliaFormatter.jl (already configured).

**Core technologies:**
- **Julia 1.10+** — Base language; LTS version with best performance. Project.toml supports 1.6-1.11.
- **ArgCheck.jl 2.x** — `@argcheck` macro for preconditions with better error messages than `@assert`.
- **Test.jl** — Standard library testing; zero dependencies, integrated with `pkg> test`.
- **Aqua.jl 0.8+** — Package QA checks for CI (method ambiguities, undefined exports, stale deps).

**Optional enhancements:**
- **ResultTypes.jl** — For bulk operations where exception overhead matters (parse returns `Result{T,E}`).
- **SafeTestsets.jl** — Test isolation for large test suites (each test runs in own module).

### Expected Features

**Must have (table stakes for v1.0):**
- **Typed field extraction** — Core functionality; already implemented via FieldSpec system.
- **Error with file/line context** — Already have `ParserError` with location; must standardize usage.
- **Consistent error types everywhere** — Currently broken; some parsers throw `error()` not `ParserError`.
- **Cross-file referential integrity (basic)** — Critical for trust; currently missing.
- **Lazy validation** — Collect multiple errors before failing (Pydantic/pandera pattern).
- **Structured error reports** — Programmatic access to all errors for debugging.
- **API documentation** — Users need to know what's available.

**Should have (competitive differentiators):**
- **Validation severity levels** — Distinguish errors (must fix) from warnings (anomalies but valid).
- **Custom validation rules API** — User-extensible validation hooks.
- **Data summary/reports** — Quick data quality overview.

**Defer (v2+):**
- **Schema inference** — Auto-detect field types from sample data (different paradigm from explicit FieldSpec).
- **Version-aware parsing** — Handle DESSEM format evolution across CEPEL versions.
- **Streaming/chunked parsing** — Large file handling without full memory load.

### Architecture Approach

Current architecture: `Parser Registry → Individual Parsers → Raw Types (TMRecord, UHRecord) → Domain Types (DessemCase) → JLD2`. The validation layer should be inserted **between Raw Types and Domain Types** as a separate module with composable validators.

**Major components:**
1. **`Validation/types.jl`** — `ValidationResult`, `ValidationIssue`, `ValidationContext`, severity enum.
2. **`Validation/interface.jl`** — `AbstractValidator` supertype, `validate()` function signature, `CompositeValidator`.
3. **`Validation/range.jl`** — Value bounds checking (leveraging existing `validate_range` helpers).
4. **`Validation/registry.jl`** — Cross-file referential integrity (build lookup Dicts, check references).
5. **`Validation/temporal.jl`** — Time period consistency validation.

**Key principle:** Data flows in ONE direction. Validators are pure functions that don't modify data — they return `ValidationIssue` vectors. Cross-file validation requires all files parsed first (can't validate references to data that doesn't exist yet).

### Critical Pitfalls

1. **Inconsistent exception types** — Some parsers use `error()` or `@assert` instead of `ParserError`. Tests use `@test_throws ParserError` which silently passes when wrong exceptions thrown. **Fix:** Audit all `throw`/`error` calls before v1.0; replace with `ParserError` with file/line context.

2. **Silent failures via `@warn` + `return nothing`** — Parsers log warnings and return `nothing` instead of throwing. Callers proceed with incomplete data. **Fix:** Default to `:error` mode; provide `on_unknown_record=:error|:warn|:skip` option for opt-in leniency.

3. **Validation at wrong abstraction layer** — Field validation mixed into parsers, cross-file validation missing entirely. **Fix:** Separate Validation module; three-tier system (field/record/semantic).

4. **Breaking public API in v1.0** — Adding validation changes behavior; previously silent failures become exceptions. **Fix:** Audit `export` list; use deprecation pattern with opt-in flags; document in CHANGELOG.

5. **Performance degradation from validation overhead** — Cross-file validation requires loading multiple files; each check adds overhead. **Fix:** Make expensive validation optional (`validate_refs=false`); use type-stable paths; build lookup Dicts once.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Error Handling Standardization
**Rationale:** Cannot build validation layer on broken foundation. Inconsistent exceptions and silent failures will undermine all subsequent work.
**Delivers:** All parsers use `ParserError` consistently; no silent failures; all `@test_throws ParserError` tests uncommented and passing.
**Addresses:** Table stakes (consistent error types), existing parser reliability
**Avoids:** Pitfall 1 (inconsistent exceptions), Pitfall 2 (silent failures)
**Features:** Error with file/line context, consistent error types

### Phase 2: Validation Types and Interface
**Rationale:** Foundation for all validators. Must define types before implementing validation logic.
**Delivers:** `ValidationResult`, `ValidationIssue`, `ValidationContext`, `AbstractValidator`, `CompositeValidator`.
**Uses:** ArgCheck.jl for preconditions in validator constructors
**Implements:** Architecture component: validation/types.jl, validation/interface.jl
**Features:** Structured error reports (data structure)

### Phase 3: Basic Validators
**Rationale:** Simple validators with clear patterns. Validates the interface design before tackling complex cross-file logic.
**Delivers:** `RangeValidator`, `TemporalValidator` working and tested.
**Uses:** Existing `validate_range`, `validate_positive` helpers from common.jl
**Implements:** Architecture component: validation/range.jl, validation/temporal.jl
**Features:** Value range validation (post-parse layer)

### Phase 4: Cross-File Validation
**Rationale:** The key differentiator. Requires understanding type relationships across all parsers. Most complex validation logic.
**Delivers:** `ReferenceValidator` checking referential integrity (thermal plant IDs exist in TERMDAT, hydro plant IDs in HIDR, etc.).
**Implements:** Architecture component: validation/registry.jl, validation/cross_file.jl
**Features:** Cross-file referential integrity — **critical differentiator**
**Avoids:** Pitfall 3 (validation at wrong layer), Pitfall 5 (performance - use Dict lookups)

### Phase 5: API Integration and Documentation
**Rationale:** Expose validation to users. Document public API before v1.0 commitment.
**Delivers:** `validate(data::DessemData)` function in public API; `ValidationOptions` for configuration; docstrings for all exports.
**Implements:** Architecture component: api.jl enhancement, module exports
**Features:** Lazy validation (via `ValidationOptions`), structured error reports, API documentation
**Avoids:** Pitfall 4 (breaking public API)

### Phase Ordering Rationale

- **Phase 1 first:** Foundation fix. Cannot test validation if parsers throw wrong exceptions.
- **Phases 2-3 before 4:** Validate interface with simple validators before complex cross-file logic.
- **Phase 4 is the value:** Cross-file referential integrity is the key differentiator that competing parsers lack.
- **Phase 5 last:** API stability matters only after implementation proven.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 4:** Complex cross-file relationships. Need to map all ID references across 32+ parsers. Consider `/gsd-research-phase` for detailed reference mapping.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Well-documented Julia exception patterns; codebase already has correct examples in `common.jl`.
- **Phase 2-3:** Standard validator patterns from Pydantic/pandera; Julia type patterns well-documented.
- **Phase 5:** Julia module export patterns well-documented in Style Guide.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Verified with official Julia docs, package registries, existing Project.toml. |
| Features | HIGH | Based on competitor analysis (Pydantic, pandera, serde) and codebase audit. |
| Architecture | HIGH | Direct codebase examination; existing patterns are clear and well-structured. |
| Pitfalls | HIGH | Identified from actual codebase issues (commented tests, `@warn` patterns in source). |

**Overall confidence:** HIGH

### Gaps to Address

- **Reference mapping for Phase 4:** Need detailed inventory of which ID fields reference which registry files. Currently known: OPERUT→TERMDAT, OPERUH→HIDR. Full mapping requires systematic review of all parsers.
- **Performance baseline:** No benchmarks exist for current parsing speed. Should establish baseline before adding validation to measure overhead.
- **Julia 1.6 compatibility testing:** Declared minimum version is 1.6 but CI only tests recent versions. Should verify validation layer works on 1.6 before v1.0.

## Sources

### Primary (HIGH confidence)
- Julia Style Guide — https://docs.julialang.org/en/v1/manual/style-guide/ — API patterns, naming conventions
- Julia Exception Handling — https://docs.julialang.org/en/v1/manual/control-flow/#Exception-Handling — Error handling patterns
- ArgCheck.jl docs — https://juliapackages.com/p/argcheck — Validation library usage
- Pydantic documentation — https://docs.pydantic.dev/latest/ — Validation patterns, lazy mode, error structure
- Pandera documentation — https://pandera.readthedocs.io/en/stable/ — DataFrame validation patterns
- DESSEM2Julia codebase analysis — Direct examination of src/, test/, existing patterns

### Secondary (MEDIUM confidence)
- Serde documentation — https://serde.rs/ — Validation patterns from Rust ecosystem
- Marshmallow documentation — https://marshmallow.readthedocs.io/en/stable/ — Schema validation patterns
- JuliaTesting org — https://github.com/JuliaTesting — Testing tooling (Aqua, SafeTestsets)
- ResultTypes.jl — https://juliapackages.com/p/resulttypes — Result type patterns

### Tertiary (LOW confidence)
- General software engineering patterns for validation layers — Inferred from multiple sources, needs validation during implementation.

---
*Research completed: 2026-02-18*
*Ready for roadmap: yes*
