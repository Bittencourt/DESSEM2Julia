# Phase 1: Error Handling Foundation - Research

**Researched:** 2026-02-18
**Domain:** Julia exception handling, parser error patterns
**Confidence:** HIGH

## Summary

This research investigates the current state of error handling in the DESSEM2Julia codebase and identifies all locations where error patterns need to be standardized to use `ParserError` consistently. The codebase already has a well-designed `ParserError` struct with file/line context, but it is not used consistently across all parsers. Three main anti-patterns were identified: (1) `error()` calls that throw generic `ErrorException`, (2) `@warn` followed by `return nothing` that silently swallows errors, and (3) helper functions that throw `ArgumentError` instead of `ParserError`.

**Primary recommendation:** Replace all `error()` calls and `@warn` + `return nothing` patterns with `throw(ParserError(...))` using the existing validation helpers (`validate_positive`, `validate_nonnegative`, `validate_range`) from `ParserCommon`.

## Reference Implementations

These external repositories serve as reference implementations and dependencies:

| Repository | Purpose | URL |
|------------|---------|-----|
| **idessem** | Reference implementation for DESSEM file parsing in Julia | https://github.com/renan-iod/idessem |
| **inewave** | Reference implementation for NEWAVE file parsing (related ecosystem) | https://github.com/renan-iod/inewave |
| **pwf.jl** | Dependency for reading PWF (Power World Format) network files | https://github.com/renan-iod/pwf.jl |

**Usage notes:**
- `pwf.jl` is a direct dependency used by `src/parser/pwf.jl` for parsing network topology files
- `idessem` and `inewave` provide patterns for error handling, validation, and parser structure
- When making changes, verify alignment with these reference implementations

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ParserError | existing | Custom exception with file/line context | Already defined in codebase, well-designed |
| validate_positive | existing | Positive value validation | Throws ParserError with context |
| validate_nonnegative | existing | Non-negative value validation | Throws ParserError with context |
| validate_range | existing | Range validation | Throws ParserError with context |

### Supporting
| Function | Location | Purpose | When to Use |
|----------|----------|---------|-------------|
| Base.showerror | common.jl:35 | Format ParserError output | Already implemented |
| extract_fields | common.jl:278 | Field extraction with validation | Throws ParserError on failure |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| error("message") | throw(ParserError(...)) | ParserError has file context, ErrorException doesn't |
| @warn + return nothing | throw(ParserError(...)) | Fails fast with context vs silent failure |
| ArgumentError | ParserError | ParserError has file/line context |

**Current ParserError Definition (src/parser/common.jl:28-39):**
```julia
struct ParserError <: Exception
    msg::String
    file::String
    line::Int
    content::String
end

function Base.showerror(io::IO, e::ParserError)
    print(io, "ParserError in $(e.file):$(e.line)\n")
    print(io, "  $(e.msg)\n")
    print(io, "  Line content: $(e.content)")
end
```

## Architecture Patterns

### Recommended Error Handling Pattern
```julia
# GOOD: Use ParserError with file context
function parse_record(line::AbstractString, file::String, line_num::Int)
    try
        data = extract_fields(line, specs, file=file, line_num=line_num)
        validate_positive(data.capacity, "capacity"; file=file, line_num=line_num, line=line)
        return RecordType(...)
    catch e
        if isa(e, ParserError)
            rethrow(e)
        else
            throw(ParserError("Failed to parse record: $(sprint(showerror, e))", file, line_num, line))
        end
    end
end
```

### Anti-Patterns to Avoid
- **`error("message")`:** Throws generic `ErrorException` without file/line context. Use `throw(ParserError(...))` instead.
- **`@warn "message" return nothing`:** Silently swallows errors. User never knows parsing failed.
- **`ArgumentError("message")`:** Built-in exception without file context. Use `ParserError` instead.
- **Catching and ignoring:** `try ... catch e @warn ... end` without rethrowing hides problems.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Positive validation | `if x <= 0 error(...) end` | `validate_positive(x, "field"; file, line_num, line)` | Includes context, consistent message |
| Non-negative validation | `if x < 0 error(...) end` | `validate_nonnegative(x, "field"; ...)` | Includes context |
| Range validation | `if x < min \|\| x > max error(...) end` | `validate_range(x, min, max, "field"; ...)` | Includes context |
| Field extraction | Manual parsing with error() | `extract_fields(line, specs; file, line_num)` | Throws ParserError on failure |

**Key insight:** The validation helpers already exist and are well-designed. The problem is that some parsers use them while others use `error()` or `@warn`.

## Affected Files and Error Patterns

### Files with `error()` calls (Need ParserError replacement)

| File | Lines | Issue |
|------|-------|-------|
| src/parser/simul.jl | 69, 109, 135, 218, 299 | Uses `error("...")` for parsing failures |
| src/parser/pwf.jl | 100, 266, 360, 370 | Uses `error("...")` for parsing failures |
| src/parser/renovaveis.jl | 82, 90, 147, 184, 227 | Uses `error("...")` for parsing failures |
| src/parser/hidr_binary.jl | 211 | Uses `error("File not found")` |
| src/parser/operut.jl | 16, 22 | Helper functions use `error("Cannot parse...")` |
| src/parser/desselet.jl | 38, 68, 78 | Uses `error("...")` for parsing failures |
| src/parser/cortdeco.jl | 134, 309, 318, 322 | Uses `error("...")` for validation failures |
| src/parser/dadvaz.jl | 57-199 (many) | Uses `error("Missing/Invalid...")` for validation |

### Files with `@warn` + `return nothing` (Silent failure pattern)

| File | Lines | Issue |
|------|-------|-------|
| src/parser/operuh.jl | 114, 151, 191, 235 | `@warn ... return nothing` in catch blocks |
| src/parser/pwf.jl | 198, 213 | `@warn ...` then continues (swallows errors) |
| src/parser/hidr.jl | 635 | `@warn "Unknown record type"` (non-critical) |

### Files with capacity/heat_rate validation (Need review)

| File | Lines | Current Status |
|------|-------|----------------|
| src/parser/termdat.jl | 201-213 | GOOD: Already uses `validate_positive`, `validate_nonnegative`, throws ParserError |
| src/parser/termdat.jl | 309 | GOOD: `validate_positive(data.heat_rate, "heat_rate")` |
| src/parser/hidr.jl | 497-498 | GOOD: Uses validation helpers for unit_capacity, min_generation |

**Note:** The termdat.jl capacity validation (ERR-02) already throws ParserError correctly. The existing code at line 204-213:
```julia
if data.min_generation > data.unit_capacity
    throw(ParserError(file, line_num, line,
        "Minimum generation ($(data.min_generation) MW) exceeds unit capacity ($(data.unit_capacity) MW)"))
end
```

The heat rate validation (ERR-03) also already uses `validate_positive` at line 309.

### Priority Files for Modification

1. **operuh.jl** (HIGH) - 4 instances of `@warn` + `return nothing` (silent failures)
2. **simul.jl** (HIGH) - 5 instances of `error()` (but deprecated file - check if needed)
3. **renovaveis.jl** (MEDIUM) - 5 instances of `error()`
4. **pwf.jl** (MEDIUM) - 4 instances of `error()` + 2 `@warn`
5. **operut.jl** (MEDIUM) - 2 helper functions with `error()`
6. **dadvaz.jl** (MEDIUM) - Many `error()` calls
7. **desselet.jl** (LOW) - 3 instances of `error()`
8. **cortdeco.jl** (LOW) - 4 instances of `error()`
9. **hidr_binary.jl** (LOW) - 1 instance of `error()`

## Common Pitfalls

### Pitfall 1: Inconsistent Error Types
**What goes wrong:** User catches `ParserError` but some parsers throw `ErrorException` or `ArgumentError`.
**Why it happens:** Different parsers written at different times without standardized patterns.
**How to avoid:** Always use `throw(ParserError(...))` for parsing failures.
**Warning signs:** `error()` calls, `ArgumentError` throws, `@warn` without rethrow.

### Pitfall 2: Silent Failures
**What goes wrong:** Parser logs a warning and returns nothing, but caller assumes parsing succeeded.
**Why it happens:** Pattern of `@warn ... return nothing` in catch blocks.
**How to avoid:** Never return nothing on error. Always throw or propagate the exception.
**Warning signs:** `return nothing` after `@warn`, catch blocks without rethrow.

### Pitfall 3: Missing File Context
**What goes wrong:** Error message says "field X is invalid" but user doesn't know which file/line.
**Why it happens:** Using `error()` or `ArgumentError` instead of `ParserError`.
**How to avoid:** Always pass `file`, `line_num`, and `line` to validation functions.
**Warning signs:** Error messages without file path or line number.

### Pitfall 4: ParserError Argument Order
**What goes wrong:** ParserError fields are (msg, file, line, content) but some code passes arguments in wrong order.
**Why it happens:** Inconsistent ordering in existing code.
**How to avoid:** Use keyword arguments pattern: `throw(ParserError("msg", file, line_num, line))`.
**Warning signs:** Check existing correct usage at termdat.jl:206-212.

## Code Examples

### Correct Pattern (from termdat.jl)
```julia
// Source: src/parser/termdat.jl lines 200-213
# Validate capacity and generation
validate_positive(data.unit_capacity, "unit_capacity")
validate_nonnegative(data.min_generation, "min_generation")

if data.min_generation > data.unit_capacity
    throw(
        ParserError(
            file,
            line_num,
            line,
            "Minimum generation ($(data.min_generation) MW) exceeds unit capacity ($(data.unit_capacity) MW)",
        ),
    )
end
```

### Anti-Pattern to Fix (operuh.jl)
```julia
// Source: src/parser/operuh.jl lines 113-116 (CURRENT - NEEDS FIX)
catch e
    @warn "Failed to parse OPERUH REST record" line exception = e
    return nothing
end
```

**Should become:**
```julia
catch e
    if isa(e, ParserError)
        rethrow(e)
    else
        throw(ParserError("Failed to parse OPERUH REST record: $(sprint(showerror, e))", filename, line_num, line))
    end
end
```

### Anti-Pattern to Fix (simul.jl)
```julia
// Source: src/parser/simul.jl line 69 (CURRENT - NEEDS FIX)
catch e
    error("Error parsing SIMUL header at $filename:$line_num: $e\nLine: '$line'")
end
```

**Should become:**
```julia
catch e
    if isa(e, ParserError)
        rethrow(e)
    else
        throw(ParserError("Error parsing SIMUL header: $(sprint(showerror, e))", filename, line_num, line))
    end
end
```

### Anti-Pattern to Fix (operut.jl helper)
```julia
// Source: src/parser/operut.jl lines 14-18 (CURRENT - NEEDS FIX)
function parse_int(s::AbstractString)
    s_clean = strip(s)
    isempty(s_clean) && error("Cannot parse empty string as Int")
    return parse(Int, s_clean)
end
```

**Should use ParserCommon helpers or throw ParserError with context.**

## Test Infrastructure

### Current Test Structure
Tests are in `test/` directory, organized by parser:
- `test/runtests.jl` - Main test runner, includes all test files
- `test/parser/common_tests.jl` - Tests for common utilities including ParserError
- `test/{parser}_tests.jl` - Individual parser tests

### Existing Error Path Tests (common_tests.jl:246-261)
```julia
@testset "ParserCommon - Error Handling" begin
    @testset "ParserError" begin
        err = ParserError("Test error", "test.dat", 42, "problematic line")
        @test err.msg == "Test error"
        @test err.file == "test.dat"
        @test err.line == 42
        @test err.content == "problematic line"

        # Test error message formatting
        io = IOBuffer()
        showerror(io, err)
        msg = String(take!(io))
        @test occursin("test.dat:42", msg)
        @test occursin("Test error", msg)
        @test occursin("problematic line", msg)
    end
end
```

### Existing Validation Tests (common_tests.jl:194-243)
```julia
@testset "validate_positive" begin
    @test validate_positive(5, "test") == 5
    @test_throws ParserError validate_positive(0, "test", file = "f.dat", line_num = 5)
    @test_throws ParserError validate_positive(-1, "test", file = "f.dat", line_num = 5)
end
```

### Where Error Path Tests Should Go
1. **New test file:** `test/parser/error_handling_tests.jl` - Centralized error path tests
2. **Or distributed:** Add error path tests to each parser's test file (e.g., `operuh_tests.jl`)

### Test Pattern for Error Paths
```julia
@testset "Error Handling" begin
    @testset "Throws ParserError on invalid input" begin
        invalid_line = "INVALID DATA HERE"
        @test_throws ParserError parse_rest_record(invalid_line, "test.dat", 1)
        
        # Verify error contains file/line context
        try
            parse_rest_record(invalid_line, "test.dat", 42)
        catch e
            @test isa(e, ParserError)
            @test e.file == "test.dat"
            @test e.line == 42
        end
    end
    
    @testset "Does NOT throw MethodError for capacity validation" begin
        # Test ERR-02: min_generation > capacity
        invalid_line = "CADUNIDT 001 001 ... 100.0 ... 200.0 ..."  # min > capacity
        @test_throws ParserError parse_cadunidt(invalid_line, "test.dat", 1)
    end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `error()` calls | `throw(ParserError(...))` | Partially done in termdat.jl | Consistent error handling |
| `@warn` + `return nothing` | Throw ParserError | Not done yet | No silent failures |
| `ArgumentError` | ParserError | Not done yet | File context included |

**Deprecated/outdated:**
- SIMUL parser: Uses `error()` but file is deprecated (commented out in runtests.jl). May skip or remove entirely.
- Local helper functions in operut.jl: Should use ParserCommon functions instead.

## Open Questions

1. **SIMUL parser status**
   - What we know: SIMUL parser uses `error()` in 5 places, but it's commented out in runtests.jl with note "SIMUL is legacy/deprecated"
   - What's unclear: Should we fix SIMUL or remove it entirely?
   - Recommendation: Check with user. If deprecated, skip fixes. If needed, fix like other parsers.

2. **operut.jl local helper functions**
   - What we know: operut.jl defines its own `parse_int`, `parse_float` that throw `error()`
   - What's unclear: Should these use ParserCommon versions or be fixed locally?
   - Recommendation: Import and use ParserCommon helpers. They already handle blanks properly.

3. **Test file organization**
   - What we know: Tests are currently distributed per-parser
   - What's unclear: Should error path tests be centralized or distributed?
   - Recommendation: Add error path tests to each parser's test file. Add shared error handling tests to common_tests.jl.

## Implementation Approach

### Phase 1-01: Standardize ParserError usage across all parsers
**Files to modify:**
1. operuh.jl - Replace `@warn` + `return nothing` with `throw(ParserError(...))`
2. simul.jl - Replace `error()` with `throw(ParserError(...))` (if not deprecated)
3. renovaveis.jl - Replace `error()` with `throw(ParserError(...))`
4. pwf.jl - Replace `error()` with `throw(ParserError(...))`
5. operut.jl - Use ParserCommon helpers or fix local helpers

### Phase 1-02: Fix capacity and heat rate validation
**Status:** Already correct in termdat.jl
- Capacity validation (ERR-02): Lines 201-213 already throw ParserError
- Heat rate validation (ERR-03): Line 309 already uses validate_positive

**Action:** Verify with tests that these work correctly. No code changes needed.

### Phase 1-03: Replace silent failures with explicit errors
**Files to modify:**
1. operuh.jl - 4 catch blocks with `@warn` + `return nothing`
2. pwf.jl - 2 catch blocks with `@warn` (lines 198, 213)
3. hidr.jl - 1 `@warn` for unknown record type (may be acceptable for unknown types)

### Phase 1-04: Add error path tests
**Files to create/modify:**
1. Add error path tests to each parser's test file
2. Ensure all error paths throw ParserError (not MethodError, ArgumentError, etc.)

## Sources

### Primary (HIGH confidence)
- Codebase analysis - src/parser/*.jl files examined directly
- src/parser/common.jl - ParserError definition and validation helpers
- test/parser/common_tests.jl - Existing error handling tests

### Secondary (MEDIUM confidence)
- .planning/REQUIREMENTS.md - Requirements ERR-01 through ERR-04
- .planning/codebase/CONVENTIONS.md - Error handling conventions

### Tertiary (LOW confidence)
- .planning/research/STACK.md - General Julia exception patterns (supplementary)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - ParserError and validation helpers already exist in codebase
- Architecture: HIGH - Pattern established in termdat.jl, just needs replication
- Affected files: HIGH - Direct grep/search results
- Pitfalls: HIGH - Based on observed patterns in codebase
- Test infrastructure: HIGH - Existing test structure documented

**Research date:** 2026-02-18
**Valid until:** 30 days (codebase is actively developed)
