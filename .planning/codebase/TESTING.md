# Testing Patterns

**Analysis Date:** 2026-02-18

## Test Framework

**Runner:** Julia built-in `Test` module

**Assertion Library:** `Test` module macros (`@test`, `@test_throws`, `@testset`)

**Run Commands:**
```bash
# Run all tests
julia --project=. -e "using Pkg; Pkg.test()"

# Run with coverage
julia --project=. --code-coverage=user -e "using Pkg; Pkg.test(coverage=true)"

# Run specific test file
julia --project=. -e "include(\"test/termdat_tests.jl\")"
```

**Configuration:**
- Test dependencies in `Project.toml` under `[extras]` and `[targets]`
- Main test entry point: `test/runtests.jl`

## Test File Organization

**Location:**
- All tests in `test/` directory
- Subdirectory for nested tests: `test/parser/common_tests.jl`

**Naming Convention:**
- Pattern: `{module_or_parser}_tests.jl`
- Examples: `termdat_tests.jl`, `entdados_tests.jl`, `parser/common_tests.jl`

**Structure:**
```
test/
├── runtests.jl           # Main test entry point
├── termdat_tests.jl      # TERMDAT parser tests
├── entdados_tests.jl     # ENTDADOS parser tests
├── operut_tests.jl       # OPERUT parser tests
├── ons_integration_tests.jl  # Integration tests
└── parser/
    └── common_tests.jl   # ParserCommon module tests
```

## Test Structure

**Suite Organization:**
```julia
using Test
using DESSEM2Julia
using DESSEM2Julia.ParserCommon

@testset "Module Name Tests" begin
    @testset "Feature/Record Type" begin
        @test condition
        @test value ≈ expected  # For floating point
        @test_throws ParserError function_call(args)
    end
    
    @testset "Another Feature" begin
        # More tests
    end
end

println("✅ All tests completed!")
```

**Test Patterns:**
```julia
# Basic assertion
@test result == expected

# Floating point comparison (uses ≈ for approximate equality)
@test value ≈ 123.45

# Type checking
@test data isa ThermalRegistry

# Exception testing
@test_throws ParserError parse_cadusit("bad line", "test.dat", 1)

# Collection assertions
@test length(registry.plants) == 2
@test all(u -> u.unit_capacity > 0, registry.units)

# Boolean assertions
@test isnothing(value)
@test !isempty(collection)

# Conditional test (skip if prereq missing)
if isfile(sample_file)
    # run tests
else
    @warn "Sample file not found, skipping test: $sample_file"
end
```

## Mocking

**Framework:** No mocking framework used

**Patterns:**
- Use temporary files for file-based tests
- Use `IOBuffer` for string-based parsing tests
- Real sample data for integration tests

**File-Based Test Pattern:**
```julia
@testset "Full File Parsing" begin
    content = """
    & Test TERMDAT file
    &
    CADUSIT   1 PLANT A       1 2020 01 01 00 0    2
    CADUSIT   2 PLANT B       2 2020 06 15 00 1    1
    """
    
    tmpfile = tempname() * ".dat"
    write(tmpfile, content)
    
    try
        registry = parse_termdat(tmpfile)
        @test length(registry.plants) == 2
    finally
        rm(tmpfile, force = true)
    end
end
```

**IOBuffer Pattern:**
```julia
@testset "TM Record Parsing" begin
    line = "TM  28    0   0      0.5     0     LEVE"
    data = parse_entdados(IOBuffer(line))
    @test length(data.time_periods) == 1
end
```

**What to Mock:**
- Not applicable - tests use real data or temporary files

**What NOT to Mock:**
- Parser functions - test with real parsing logic
- File I/O - use temporary files or IOBuffer

## Fixtures and Factories

**Test Data:**
```julia
# Inline test data as multi-line strings
content = """
& Test TERMDAT file
&
CADUSIT   1 PLANT A       1 2020 01 01 00 0    2
CADUNIDT   1  1 2025 04 26 00 0     100.000     50.000     0     0
"""

# Sample data directory
const ONS_SAMPLE_DIR = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")
```

**Location:**
- Inline test data within test files
- Sample data files in `docs/Sample/` directory
- Real ONS production data samples used for integration tests

**Factory Pattern:**
Not used - tests create data directly via parsing or inline strings

## Coverage

**Requirements:** Not strictly enforced, but coverage is collected

**View Coverage:**
```bash
# Generate coverage report
julia --project=. --code-coverage=user -e "using Pkg; Pkg.test(coverage=true)"

# Process coverage with Julia tools
# (CI uses julia-actions/julia-processcoverage@v1)
```

**CI Coverage:**
- Uses `codecov/codecov-action@v4` to upload coverage
- Coverage token required: `${{ secrets.CODECOV_TOKEN }}`

## Test Types

**Unit Tests:**
- Test individual parsing functions
- Test helper utilities (e.g., `extract_field`, `parse_int`)
- Test validation functions
- Located in `test/parser/common_tests.jl` for utilities
- Per-module tests in `test/{module}_tests.jl`

```julia
@testset "extract_field" begin
    line = "ABCDEFGHIJKLMNOP"
    @test extract_field(line, 1, 3) == "ABC"
    @test extract_field(line, 20, 25) == ""  # Beyond line length
end
```

**Integration Tests:**
- Test full file parsing
- Test cross-file consistency
- Located in `test/ons_integration_tests.jl`
- Use real ONS sample data from `docs/Sample/`

```julia
@testset "ONS Cross-File Consistency" begin
    entdados = parse_entdados(entdados_path)
    termdat = parse_termdat(termdat_path)
    
    # Validate consistency between files
    @test length(entdados.thermal_plants) > 0
    @test length(termdat.plants) > 0
end
```

**E2E Tests:**
- Not explicitly separated
- Integration tests serve as E2E for the parsing pipeline

## Common Patterns

**Async Testing:**
Not applicable - no async code in this project

**Error Testing:**
```julia
# Test that validation throws expected error
@test_throws ParserError parse_cadusit(
    "CADUSIT1000 INVALID       1 2020 01 01 00 0    1",
    "test.dat",
    1,
)

# Test specific error properties
err = ParserError("Test error", "test.dat", 42, "problematic line")
@test err.msg == "Test error"
@test err.line == 42

# Test error message formatting
io = IOBuffer()
showerror(io, err)
msg = String(take!(io))
@test occursin("test.dat:42", msg)
```

**Table-Driven Tests:**
Not extensively used; prefer explicit test cases in separate `@testset` blocks

**Setup/Teardown:**
```julia
@testset "File-based test" begin
    tmpfile = tempname() * ".dat"
    
    try
        # Setup
        write(tmpfile, content)
        
        # Test
        result = parse_file(tmpfile)
        @test condition
        
    finally
        # Teardown
        rm(tmpfile, force = true)
    end
end
```

**Conditional Tests:**
```julia
@testset "Real Sample File Parsing" begin
    sample_file = joinpath(@__DIR__, "..", "docs", "Sample", "termdat.dat")
    
    if isfile(sample_file)
        registry = parse_termdat(sample_file)
        @test length(registry.plants) == 98
    else
        @warn "Sample file not found, skipping test: $sample_file"
    end
end
```

## Test Organization Best Practices

**Grouping:**
- Use nested `@testset` for logical groupings
- Group by record type or feature
- Separate validation tests from parsing tests

**Naming:**
- Test set names describe what is being tested
- Use descriptive names like "CADUSIT - Basic Parsing" or "TM Record Parsing"

**Test Independence:**
- Each test should be independent
- Use `try/finally` for cleanup
- Don't rely on test execution order

**Output:**
- Print summary messages with `println("✅ All tests completed!")`
- Use `@warn` for skipped tests with reason
- Print diagnostic info for integration tests

## CI Integration

**Workflow:** `.github/workflows/ci.yml`

**Test Matrix:**
- OS: ubuntu-latest, windows-latest
- Julia version: 1.11

**Test Command (CI):**
```yaml
- name: Run tests
  run: julia --project=. --code-coverage=user -e "using Pkg; Pkg.test(coverage=true)"
```

**Lint Check (runs before tests):**
```yaml
- name: Run JuliaFormatter (check only)
  run: julia --color=yes scripts/format_ci.jl
```

---

*Testing analysis: 2026-02-18*
