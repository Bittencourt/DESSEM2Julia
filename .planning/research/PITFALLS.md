# Pitfalls Research: Julia Data Parser Validation Layer

**Domain:** Julia data parser with validation layer addition
**Researched:** 2026-02-18
**Confidence:** HIGH (based on codebase analysis + Julia style guide + Pkg documentation)

---

## Critical Pitfalls

### Pitfall 1: Inconsistent Exception Types Break Error Handling

**What goes wrong:**
Validators throw `MethodError`, `DomainError`, or generic `ErrorException` instead of the package's custom `ParserError`. Test suites use `@test_throws ParserError` which fails silently when wrong exceptions are thrown, leading to commented-out tests and undetected bugs.

**Why it happens:**
- Julia's built-in validation functions (like `@assert`) throw different exception types
- Developers copy validation patterns from different sources without standardizing
- The `ParserError` constructor signature (msg, file, line, content) differs from `ErrorException(msg)`, making direct replacement non-trivial

**Consequences:**
- Tests get disabled instead of fixed (current state: `test/termdat_tests.jl` lines 169-172, 226-239)
- Users cannot catch parsing failures predictably with a single exception type
- Error messages lack file/line context needed for debugging

**How to avoid:**
1. **Never use naked `@assert` for validation** — use `validate_*` helpers that throw `ParserError`
2. **Audit all throw statements** before v1.0: grep for `throw(ArgumentError`, `throw(DomainError`, `error("`
3. **Standardize constructor call pattern:**
   ```julia
   # WRONG
   error("Minimum generation exceeds capacity")
   
   # CORRECT
   throw(ParserError(
       "Minimum generation exceeds capacity",
       file, line_num, line
   ))
   ```

**Warning signs:**
- `@test_throws ParserError` tests commented out
- Tests catching `@test_throws Exception` or `@test_throws ErrorException` instead
- Validators calling `error()` directly

**Phase to address:** Phase 1 (Error Handling Standardization) — must be fixed before any validation layer work

---

### Pitfall 2: Silent Failures via `@warn` + `return nothing`

**What goes wrong:**
Parsers log warnings and return `nothing` instead of throwing, causing silent data loss. Callers that don't check for `nothing` proceed with incomplete data.

**Why it happens:**
- "Be lenient in what you accept" philosophy applied too broadly
- Fear of breaking existing workflows that depend on partial parsing
- Warning logs look like progress output and get ignored

**Current examples in codebase:**
- `src/parser/operuh.jl` lines 114, 151, 191, 235: returns `nothing` on parse failure
- `src/parser/hidr.jl` line 635: `@warn` for unknown record types
- `src/parser/termdat.jl` line 534: `@warn` for unknown record types
- `src/parser/pwf.jl` lines 198, 213: catches exceptions and continues

**Consequences:**
- Invalid records silently skipped — data integrity compromised
- Downstream calculations use incomplete data without knowing
- Difficult to debug: logs may not be captured in automated runs

**How to avoid:**
1. **Make failure mode configurable** with explicit options:
   ```julia
   parse_hidr(path; on_unknown_record=:error)  # :error | :warn | :skip
   ```
2. **Default to `:error` for v1.0** — users explicitly opt-in to leniency
3. **Collect errors instead of immediate throw** for batch validation:
   ```julia
   struct ValidationResult
       errors::Vector{ParserError}
       warnings::Vector{String}
       data::Union{DessemData, Nothing}
   end
   ```

**Warning signs:**
- `@warn` followed by `return nothing` or `continue`
- Functions returning `Union{T, Nothing}` where `nothing` indicates failure
- Test output containing warning logs but no error assertions

**Phase to address:** Phase 1 (Error Handling Standardization) — must define policy before validation layer

---

### Pitfall 3: Validation at Wrong Abstraction Layer

**What goes wrong:**
Field-level validation (range checks) added to parsers, but cross-field and cross-file validation deferred indefinitely or never implemented. Users get "valid" data that fails business rules.

**Why it happens:**
- Field validation is easy (single function call per field)
- Cross-file validation requires loading multiple files — unclear who "owns" this logic
- No clear validation layer architecture defined upfront

**Current state:**
- Field validation exists: `validate_range()`, `validate_positive()`, `validate_nonnegative()` in `common.jl`
- Cross-field validation partially exists: `min_generation > capacity` check in `termdat.jl`
- Cross-file validation: **completely missing** (per CONCERNS.md)

**Consequences:**
- Parser output is "syntactically valid" but semantically invalid
- Downstream optimization model fails with cryptic errors
- Users must implement their own validation layer

**How to avoid:**
1. **Define three validation tiers explicitly:**
   ```
   Tier 1 (Parser): Field format, range checks → ParserError
   Tier 2 (Record): Cross-field within same record → ParserError or ValidationError
   Tier 3 (Semantic): Cross-record, cross-file → ValidationResult with errors/warnings
   ```
2. **Create dedicated Validation module** separate from parsers:
   ```julia
   module Validation
       validate_referential_integrity(data::DessemData)::ValidationResult
       validate_temporal_consistency(data::DessemData)::ValidationResult
       validate_all(data::DessemData)::ValidationResult
   end
   ```
3. **Expose validation functions** so users can run validation without full re-parse

**Warning signs:**
- Validation logic scattered across parser files
- No `validate()` or `validate_all()` function in public API
- Cross-file checks mentioned in TODO but not implemented

**Phase to address:** Phase 2 (Validation Layer Implementation) — explicit scope definition required

---

### Pitfall 4: Breaking Public API in v1.0

**What goes wrong:**
Adding validation changes behavior that downstream users depend on. Previously silent failures become exceptions. Data that previously parsed now fails.

**Why it happens:**
- "More strict is better" philosophy applied without migration path
- No clear distinction between public API (SemVer protected) and internal behavior
- Test suite doesn't cover all public API use cases

**Julia-specific concerns:**
- `export` list in `DESSEM2Julia.jl` defines public API — any change is potentially breaking
- Return type changes break users doing `parse_xxx()::ExpectedType`
- Exception type changes break `try/catch` blocks in user code

**How to avoid:**
1. **Audit `export` list before v1.0** — everything exported is public API
2. **Use deprecation pattern for behavior changes:**
   ```julia
   function parse_hidr(path; strict::Union{Bool,Nothing}=nothing, kwargs...)
       if strict === nothing
           strict = get(ENV, "DESSEM2JULIA_STRICT_PARSING", "false") == "true"
       end
       # ... parsing logic
   end
   ```
3. **Document default behavior changes in CHANGELOG** with migration guide
4. **Add `version` parameter for format evolution:**
   ```julia
   parse_hidr(path; format_version=v"1.0")  # Explicit opt-in to new behavior
   ```

**Warning signs:**
- Changing exception types thrown by exported functions
- Changing return types (e.g., `Union{T, Nothing}` → `T`)
- Adding required parameters to exported functions
- Tests using internal functions that users might be calling

**Phase to address:** Throughout — every change must be evaluated for API impact

---

### Pitfall 5: Performance Degradation from Validation Overhead

**What goes wrong:**
Adding validation layer doubles or triples parsing time. Large files (HIDR.DAT with thousands of records) become impractical to parse.

**Why it happens:**
- Each validation check adds function call overhead
- Cross-file validation requires loading multiple files or keeping them in memory
- No early-exit for invalid data — full parse happens before validation

**Julia-specific concerns:**
- Julia's JIT compilation can eliminate some overhead, but only after warmup
- Type-instability in validation paths defeats compiler optimizations
- Large `Dict` lookups for referential integrity are slow

**How to avoid:**
1. **Validate during parsing when possible** (fail fast):
   ```julia
   # Instead of parsing everything then validating
   function parse_hidr(path)
       records = []
       for line in eachline(path)
           record = parse_record(line)  # Validates during parse
           push!(records, record)
       end
       return HidrData(records)
   end
   ```
2. **Make expensive validation optional:**
   ```julia
   parse_hidr(path; validate_refs=false)  # Skip expensive cross-file checks
   ```
3. **Use type-stable validation paths:**
   ```julia
   # BAD: Type instability
   function validate(x)
       x === nothing && return nothing  # Union{T, Nothing} return
       validate_impl(x)
   end
   
   # GOOD: Type stable, throws on error
   function validate!(x)
       x === nothing && throw(ArgumentError("..."))
       validate_impl(x)  # Returns x, same type
   end
   ```
4. **Provide validation-only mode for already-parsed data:**
   ```julia
   data = parse_hidr_lazy(path)  # Fast, minimal validation
   validate(data; strict=true)   # Optional thorough check
   ```

**Warning signs:**
- Validation functions returning `Union{T, Nothing}`
- Cross-file lookups using `findfirst` on unsorted vectors
- Validation triggered for every access instead of once at parse time

**Phase to address:** Phase 2 (Validation Layer) — performance benchmarks required

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `@warn` + `return nothing` | Lenient parsing, fewer errors | Silent data loss, hard to debug | Never for v1.0 |
| `error()` instead of `ParserError` | Faster to write | Breaks error handling patterns | Never |
| Comment out failing tests | CI passes | Bugs undetected, tests become stale | Never — fix or track as issue |
| Validation in parser functions | Single location | Parser code bloat, hard to test separately | Acceptable for Tier 1 only |
| Skip cross-file validation | Simpler implementation | Invalid data passes to downstream | Only in MVP before v1.0 |
| Union return types | Handle edge cases | Type instability, slow code | Only for genuinely optional results |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| JLD2 serialization | Serialize raw structs without versioning | Add schema version to saved data |
| Parser registry | Assume all parsers return same base type | Define `AbstractParserData` supertype |
| CI testing | Only test on latest Julia | Test on minimum declared version (1.6) and current LTS (1.10) |
| Sample file tests | Skip when files missing | Use synthetic test data for critical paths |
| Error context | Omit file/line in ParserError | Always include context from parsing loop |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Type-unstable validation | Slow validation, allocations in profile | Return same type, throw on error | 10K+ records |
| Cross-file lookup in loop | O(n²) validation time | Build lookup Dicts once, validate after | 1K+ records |
| Regex in hot path | Parsing time dominated by regex | Use fixed-column extraction (already done) | Any file size |
| String interning missing | Memory bloat with repeated names | Consider `Symbol` for identifiers | 100K+ string fields |
| Validation on every access | Getters become slow | Validate once at construction | Any usage pattern |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Path traversal in file open | Read arbitrary files | Validate paths don't contain `..`, use `realpath()` |
| Unbounded binary file read | Memory exhaustion | Check file size before reading, add limits |
| Integer overflow in validation | Incorrect bounds checks | Use `checked_mul`/`checked_add` for critical values |
| Malformed input crash | DoS via crafted input | Wrap parsing in try/catch at API boundary |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces for v1.0:

- [ ] **Error handling:** ParserError used everywhere — verify no `error()` or `@assert` in production code
- [ ] **Validation tests:** All `@test_throws ParserError` tests uncommented and passing
- [ ] **Public API stability:** `export` list finalized, documented as SemVer-protected
- [ ] **Cross-file validation:** Referential integrity checks implemented (currently missing)
- [ ] **Julia version support:** CI tests on Julia 1.6 (declared minimum) and 1.10 (LTS)
- [ ] **Documentation:** Public API documented with docstrings, not just README
- [ ] **Deprecation path:** Legacy behavior documented with migration guide if changed
- [ ] **Error messages:** Include actionable guidance (file:line + what to check)
- [ ] **Memory limits:** Binary file size validation before reading

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Inconsistent exceptions | MEDIUM | 1. Audit all `throw`/`error` calls 2. Create mapping table 3. Incremental replacement |
| Silent failures | HIGH | 1. Change default to error 2. Provide `lenient=true` option 3. Document behavior change as breaking |
| No validation layer | HIGH | 1. Define validation tiers 2. Create Validation module 3. Incrementally add checks |
| API breakage | HIGH | 1. Yank release 2. Restore old behavior with deprecation 3. Major version bump |
| Performance regression | MEDIUM | 1. Profile to identify hotspots 2. Make expensive checks optional 3. Optimize lookup structures |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls:

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Inconsistent exceptions | Phase 1: Error Handling | All `@test_throws ParserError` pass, no `error()` calls |
| Silent failures | Phase 1: Error Handling | No `@warn` + `return nothing` patterns in production code |
| Validation at wrong layer | Phase 2: Validation Layer | Validation module exists, three tiers documented |
| API breakage | All phases | `export` list unchanged, return types unchanged, tests pass |
| Performance degradation | Phase 2: Validation Layer | Benchmarks show <20% overhead for validation |

---

## Specific Codebase Warnings

### Files Requiring Immediate Attention

| File | Line(s) | Issue | Fix |
|------|---------|-------|-----|
| `src/parser/termdat.jl` | 204-213 | Throws ParserError correctly, but tests disabled | Fix test, not parser |
| `src/parser/operuh.jl` | 114, 151, 191, 235 | Returns `nothing` on failure | Change to throw ParserError |
| `src/parser/pwf.jl` | 198, 213 | Catches and logs, continues | Make behavior configurable |
| `test/termdat_tests.jl` | 169-172, 226-239 | Tests commented out | Uncomment and fix underlying issue |
| `src/parser/common.jl` | validate_* functions | Correct pattern, underutilized | Audit all parsers use these |

### Patterns to Follow (From common.jl)

```julia
# CORRECT: Use validation helpers
validate_range(data.plant_num, 1, 999, "plant_num"; file=file, line_num=line_num, line=line)
validate_positive(data.subsystem, "subsystem"; file=file, line_num=line_num, line=line)

# CORRECT: Throw ParserError with context
throw(ParserError(
    "Minimum generation ($(data.min_generation) MW) exceeds capacity",
    file, line_num, line
))
```

### Patterns to Avoid

```julia
# AVOID: Generic error without context
error("Invalid plant number")

# AVOID: Warning and continue
@warn "Unknown record type: $record_type"
return nothing

# AVOID: Assert (disappears in production if assertions disabled)
@assert value > 0 "Must be positive"
```

---

## Sources

- Julia Style Guide: https://docs.julialang.org/en/v1/manual/style-guide/
- Julia Pkg Documentation: https://pkgdocs.julialang.org/v1/creating-packages/
- Julia Public API Definition: https://docs.julialang.org/en/v1/manual/faq/#man-api
- Codebase analysis: `.planning/codebase/CONCERNS.md`, test files, parser implementations
- Julia performance tips: https://docs.julialang.org/en/v1/manual/performance-tips/

---

*Pitfalls research for: DESSEM2Julia validation layer addition*
*Target: v1.0 release with backward compatibility*
*Researched: 2026-02-18*
