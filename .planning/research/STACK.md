# Stack Research

**Domain:** Julia data parser package with validation layer
**Researched:** 2025-02-18
**Confidence:** HIGH (verified with official Julia docs and package registries)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Julia | 1.10+ | Base language | LTS version, best performance, improved compilation. Your Project.toml supports 1.6-1.11 but 1.10+ is recommended for new development. |
| Test.jl | stdlib | Testing framework | Julia's standard library. Zero dependencies, integrated with `pkg> test`, widely used. Already in use. |
| ArgCheck.jl | 2.x | Argument validation | Clean `@argcheck` macro for preconditions. Better error messages than raw `@assert`. Used by 100+ packages. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Aqua.jl | 0.8+ | Package QA checks | CI/CD pipeline to catch method ambiguities, undefined exports, stale deps. Add to test suite. |
| SafeTestsets.jl | 0.1+ | Test isolation | Each `@safetestset` runs in its own module, preventing test pollution. Consider for large test suites. |
| ResultTypes.jl | 1.0+ | Result type (Either monad) | Optional: for parse operations that should not throw. Faster than try-catch in hot paths. |
| DocStringExtensions.jl | 0.9+ | Enhanced docstrings | Optional: reduces docstring boilerplate with `@doc` macros. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| JuliaFormatter.jl | Code formatting | Already have `.JuliaFormatter.toml`. Run via `format(".")` in REPL. |
| Revise.jl | Interactive development | Auto-reload code changes in REPL. Essential for development workflow. |
| Infiltrator.jl | Debugging | `@infiltrate` breakpoint macro. Lighter than Debugger.jl. |

## Installation

```julia
# Core (already installed)
# Test is stdlib - no installation needed

# Add validation
using Pkg
Pkg.add("ArgCheck")

# Add QA tools (dev dependencies)
Pkg.add("Aqua")
Pkg.add("SafeTestsets")  # optional

# Development tools (in global environment)
# Don't add to Project.toml - use ~/.julia/environments/v1.10/Project.toml
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| ArgCheck.jl | @assert | Quick prototypes where error message quality doesn't matter |
| ArgCheck.jl | Manual if-throw | When you need complex validation logic beyond assertions |
| Test.jl | ReTest.jl | When you need parallel test execution (ReTest runs tests in parallel) |
| Test.jl | TestItems.jl | When you want pytest-style test discovery and parallel execution |
| Native exceptions | ResultTypes.jl | When parsing millions of records and errors are expected/common (avoids exception overhead) |
| ParserError (custom) | DomainError/ArgumentError | When you don't need file/line context (simpler but less debuggable) |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| @assert for validation | Can be disabled in production (via `--compile=min`); poor error messages | `@argcheck` from ArgCheck.jl |
| try-catch for control flow | ~100x slower than conditional checks in happy path | Pre-validation with `@argcheck` or ResultTypes.jl for bulk operations |
| PyCall/Python libraries | Julia-native is faster, no FFI overhead | Pure Julia solutions |
| Global state for parsers | Breaks composability, makes testing harder | Pass context/config as function arguments |
| Type piracy | Extending Base methods on types you don't own can break other packages | Define your own methods on your own types |

## Stack Patterns by Variant

**If you need cross-file validation (semantic validation):**
- Create a `Validation` module with `validate_semantic(data::GeneralData)` function
- Use `@argcheck` for preconditions, return `Vector{ValidationWarning}` for soft errors
- Pattern: collect all warnings, then throw `ValidationError` if any critical

**If you need parse-time vs post-parse validation separation:**
- Parse-time (syntax): `ParserError` with file/line (already exists)
- Post-parse (semantic): `ValidationError` with rule name and affected records

**If you need Result types for bulk parsing:**
- Add ResultTypes.jl as optional dependency with `Requires.jl`
- Provide both `parse_file(path)` (throws) and `try_parse_file(path)` (returns Result)

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| ArgCheck@2.x | Julia 1.6+ | Works with your current compat bounds |
| Aqua@0.8 | Julia 1.6+ | Works with your current compat bounds |
| SafeTestsets@0.1 | Julia 1.0+ | Works with your current compat bounds |

## Julia API Design Patterns (from Style Guide & mature packages)

### 1. Argument Validation Pattern

```julia
# Recommended: Use ArgCheck.jl
using ArgCheck

function parse_record(line::AbstractString; file::String="", line_num::Int=0)
    @argcheck !isempty(line) "Line cannot be empty"
    @argcheck length(line) >= 10 "Line too short for record format"
    # ... parsing logic
end

# Alternative: Custom exception with context (your current pattern - good!)
struct ParserError <: Exception
    msg::String
    file::String
    line::Int
    content::String
end
```

### 2. Error Handling Hierarchy

```julia
# Recommended hierarchy for this project:
abstract type DESSEMError <: Exception end

# Parse-time errors (syntax, format)
struct ParserError <: DESSEMError
    msg::String
    file::String
    line::Int
    content::String
end

# Semantic errors (cross-file validation, business rules)
struct ValidationError <: DESSEMError
    rule::Symbol          # :cross_reference, :range_check, etc.
    msg::String
    context::NamedTuple   # (:file => "...", :record_id => 123, etc.)
end
```

### 3. Function Naming Conventions (Julia Style Guide)

```julia
# Mutating functions end with !
filter_valid!(records)  # mutates records
filter_valid(records)   # returns new collection

# Parsing functions: parse_ prefix (you already follow this!)
parse_entdados, parse_hidr, parse_dadvaz

# Validation functions: validate_ prefix
validate_references(data::GeneralData)
validate_ranges(data::GeneralData)

# Boolean queries: is_ or has_ prefix
is_valid(record) = true/false
has_required_fields(record) = true/false
```

### 4. Public API Pattern

```julia
# In src/DESSEM2Julia.jl - only export public interface
export
    # Main entry points
    convert_inputs, load_jld2, save_jld2,
    
    # Validation
    validate, validate!, ValidationError,
    
    # High-level types (hide implementation details)
    DessemData, DessemCase

# DO NOT export internal types/functions
# Users who need internals can access via DESSEM2Julia.InternalModule
```

### 5. Result Type Pattern (optional, for bulk operations)

```julia
using ResultTypes

# Provide both throwing and non-throwing versions
function parse_file(path::String)
    result = try_parse_file(path)
    return unwrap(result)  # throws on error
end

function try_parse_file(path::String)::Result{ParsedData, ParseError}
    # Return Ok(data) or Err(ParseError(...))
end
```

## Sources

- **Julia Style Guide** (official docs) — https://docs.julialang.org/en/v1/manual/style-guide/ — HIGH confidence
- **Julia Exception Handling** (official docs) — https://docs.julialang.org/en/v1/manual/control-flow/#Exception-Handling — HIGH confidence
- **ArgCheck.jl** — https://juliapackages.com/p/argcheck — HIGH confidence (package docs)
- **Aqua.jl** — https://juliapackages.com/p/aqua — HIGH confidence (package docs)
- **ResultTypes.jl** — https://juliapackages.com/p/resulttypes — HIGH confidence (package docs)
- **DataFrames.jl patterns** — https://dataframes.juliadata.org/stable/ — HIGH confidence (reference package)
- **SafeTestsets.jl** — https://juliapackages.com/p/safetestsets — HIGH confidence (package docs)
- **JuliaTesting org** — https://github.com/JuliaTesting — HIGH confidence (official testing tools)

---
*Stack research for: Julia data parser validation layer*
*Researched: 2025-02-18*
