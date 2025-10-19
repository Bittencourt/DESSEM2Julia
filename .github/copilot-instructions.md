# GitHub Copilot Instructions for DESSEM2Julia Project

## Project Overview
Parse 32 DESSEM (Brazilian hydrothermal dispatch) legacy text files into structured Julia objects. Files use fixed-width columns, mixed encoding, and inconsistent formatting. Current status: **7/32 parsers complete (22%)**.

## 🏆 #1 RULE: Check IDESEM First

**Always consult the IDESEM reference implementation before implementing any parser!**

- **Repository**: https://github.com/rjmalves/idessem
- **Location**: `idessem/dessem/modelos/<filename>.py`
- **Why**: Authoritative reference, battle-tested, saves hours of debugging
- **Example**: Session 6 OPERUT parser went from 81% → 99.7% success after checking IDESEM

### Converting IDESEM to Julia

IDESEM uses **0-indexed** positions (Python), Julia uses **1-indexed**:

```python
# IDESEM (Python, 0-indexed)
LiteralField(12, 4)  # Characters at positions 4-15 (0-indexed)

# Julia equivalent (1-indexed)
extract_field(line, 5, 16)  # Characters at positions 5-16 (1-indexed)
```

**Rule**: Add 1 to IDESEM start positions for Julia.

## Fixed-Width Format Parsing

### ❌ NEVER Use split() for Fixed-Width Files

```julia
# ❌ WRONG - Fails with values containing spaces
parts = split(line)  # Breaks on "ANGRA 1", "N.VENECIA 2", "ERB CANDEIA"
```

### ✅ ALWAYS Use Fixed Column Positions from IDESEM

```julia
# ✅ CORRECT - Extract by column positions
plant_name = strip(extract_field(line, 5, 16))  # Always 12 characters
plant_num = parse(Int, extract_field(line, 1, 3))
```

**How to identify fixed-width format**: Check IDESEM for `LiteralField(size, start)` - this indicates fixed-width!

## Standard Parser Implementation Pattern

### 1. Research Phase (Required First Step)

```bash
# Visit IDESEM repository
https://github.com/rjmalves/idessem/blob/main/idessem/dessem/modelos/<filename>.py

# Identify:
# - Field positions (LiteralField, IntegerField, FloatField)
# - Special values ("F" for final, 99.9 for missing, etc.)
# - Edge cases and optional fields
```

### 2. Define Types

Location: `src/types.jl` or `src/models/core_types.jl`

```julia
Base.@kwdef struct XxxRecord
    field1::Int
    field2::String
    optional_field::Union{Float64, Nothing} = nothing  # Optional fields allow Nothing
end

Base.@kwdef struct XxxData
    records::Vector{XxxRecord} = XxxRecord[]
end
```

**Type System Rules**:
- Use `@kwdef` for keyword construction
- Use `Union{T, Nothing}` for optional fields
- Default optional fields to `nothing` (not `0`, `""`, or other values)
- Immutable by default (prefer `struct` over `mutable struct`)

### 3. Implement Parser

Location: `src/parser/xxx.jl`

```julia
module XxxParser

using ..DESSEM2Julia: XxxRecord, XxxData
using ..ParserCommon: extract_field, is_comment, is_blank

"""
    parse_xxx_record(line, filename, line_num) -> XxxRecord

Parse a single XXX record from a line.

# IDESEM Reference
idessem/dessem/modelos/xxx.py
"""
function parse_xxx_record(line::AbstractString, filename::AbstractString, line_num::Int)
    # Extract fields using IDESEM column positions (add 1 for Julia 1-indexing)
    field1 = parse(Int, strip(extract_field(line, 1, 5)))
    field2 = strip(extract_field(line, 7, 20))
    
    # Handle optional fields
    optional_str = strip(extract_field(line, 25, 35))
    optional_field = isempty(optional_str) ? nothing : parse(Float64, optional_str)
    
    return XxxRecord(
        field1=field1,
        field2=field2,
        optional_field=optional_field
    )
end

"""
    parse_xxx(io, filename) -> XxxData

Parse complete XXX file.
"""
function parse_xxx(io::IO, filename::AbstractString)
    records = XxxRecord[]
    
    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        is_comment(line) && continue
        is_blank(line) && continue
        
        # Parse record
        record = parse_xxx_record(line, filename, line_num)
        push!(records, record)
    end
    
    return XxxData(records=records)
end

# Convenience method
parse_xxx(filename::AbstractString) = open(io -> parse_xxx(io, filename), filename)

export parse_xxx, parse_xxx_record

end  # module
```

### 4. Write Comprehensive Tests

Location: `test/xxx_tests.jl`

```julia
using Test
using DESSEM2Julia

@testset "XXX Parser Tests" begin
    @testset "Single Record Parsing" begin
        line = "  123  field2_value      45.67"
        record = parse_xxx_record(line, "test.dat", 1)
        
        @test record.field1 == 123
        @test record.field2 == "field2_value"
        @test record.optional_field == 45.67
    end
    
    @testset "Optional Field Handling" begin
        line = "  123  field2_value          "  # Empty optional field
        record = parse_xxx_record(line, "test.dat", 1)
        
        @test record.optional_field === nothing  # Use === for nothing checks
    end
    
    @testset "Real CCEE Data" begin
        filepath = "docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/xxx.dat"
        if isfile(filepath)
            result = parse_xxx(filepath)
            @test length(result.records) > 0
            # Add specific validation checks for real data
        end
    end
    
    @testset "Real ONS Data" begin
        filepath = "docs/Sample/DS_ONS_102025_RV2D11/xxx.dat"
        if isfile(filepath)
            result = parse_xxx(filepath)
            @test length(result.records) > 0
        end
    end
end
```

**Testing Requirements**:
1. ✅ Unit tests (individual record parsing)
2. ✅ Edge cases (empty fields, special characters)
3. ✅ Real CCEE data validation
4. ✅ Real ONS data validation (if applicable)
5. ✅ Target: **100% tests passing** before marking "production ready"

## Common Patterns

### Handling Optional Fields

```julia
# ✅ CORRECT - Return nothing for missing optional fields
field_str = strip(extract_field(line, 30, 39))
field = isempty(field_str) ? nothing : parse(Float64, field_str)

# ❌ WRONG - Don't use 0, "", or other placeholder values
field = isempty(field_str) ? 0.0 : parse(Float64, field_str)  # BAD!
```

### Special Values

Check IDESEM for special value handling:

```julia
# Example: Day can be integer or "F" (final)
day_str = strip(extract_field(line, 29, 30))
day = day_str == "F" ? "F" : parse(Int, day_str)

# Type definition must accommodate both
day::Union{Int, String, Nothing}
```

### Block Structure Parsing

```julia
in_block = false
records = Record[]

for line in eachline(io)
    # Block start marker
    if occursin(r"^\s*INIT", line)
        in_block = true
        continue
    end
    
    # Block end marker
    if occursin(r"^\s*FIM", line)
        in_block = false
        continue
    end
    
    # Parse records within block
    if in_block
        record = parse_record(line)
        push!(records, record)
    end
end
```

### Comment Detection

```julia
function is_comment(line::AbstractString)
    stripped = strip(line)
    isempty(stripped) && return false
    
    # Common comment markers in DESSEM files
    startswith(stripped, "&") ||
    startswith(stripped, "*") ||
    startswith(stripped, "#") ||
    startswith(stripped, "//")
end
```

## Critical Pitfalls to Avoid

### 1. Using split() on Fixed-Width Format
**Problem**: Values with spaces break field alignment  
**Detection**: IDESEM uses `LiteralField(size, start)`  
**Solution**: Use `extract_field()` with column positions

### 2. Ignoring IDESEM
**Problem**: Hours wasted debugging formats already solved  
**Example**: Session 6 went 81% → 93% → 81% → 99.7% after checking IDESEM  
**Solution**: Always check IDESEM first!

### 3. 0-Indexed vs 1-Indexed Confusion
**Problem**: Python uses 0-indexing, Julia uses 1-indexing  
**Solution**: Add 1 to all IDESEM start positions

### 4. Not Testing with Real Data
**Problem**: Synthetic tests pass, production files fail  
**Solution**: Always validate with `docs/Sample/DS_CCEE_*` and `DS_ONS_*`

### 5. Treating Binary Files as Text
**Problem**: Garbled data, parser crashes  
**Example**: HIDR.DAT is 792-byte binary records!  
**Solution**: Check IDESEM to identify binary formats

### 6. Incomplete Optional Field Handling
**Problem**: Missing values treated as zeros or empty strings  
**Solution**: Return `nothing` for missing optional fields

### 7. Not Documenting Format Quirks
**Problem**: Unusual behaviors forgotten, forcing rediscovery  
**Solution**: Document immediately in `docs/FORMAT_NOTES.md`

### 8. Hardcoding Record Counts
**Problem**: Different cases have different numbers of records  
**Solution**: Parse until EOF or block marker, don't assume counts

## File Locations

### Source Code
- **Types**: `src/types.jl` or `src/models/core_types.jl`
- **Parsers**: `src/parser/<filename>.jl`
- **Common utilities**: `src/parser/common.jl`
- **Main module**: `src/DESSEM2Julia.jl`

### Tests
- **Parser tests**: `test/<filename>_tests.jl`
- **Main test runner**: `test/runtests.jl`

### Documentation
- **Project context**: `docs/planning/PROJECT_CONTEXT.md` (comprehensive guide)
- **Tasks & roadmap**: `docs/planning/TASKS.md`
- **Type system**: `docs/type_system.md`
- **Format notes**: `docs/FORMAT_NOTES.md` (document quirks here!)
- **Parser guides**: `docs/parsers/` (e.g., `OPERUT_IMPLEMENTATION.md`)

### Sample Data
- **CCEE sample**: `docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/`
- **ONS sample**: `docs/Sample/DS_ONS_102025_RV2D11/`

## Workflow Checklist

When implementing a new parser:

- [ ] 1. **Research**: Check `idessem/dessem/modelos/<file>.py` for format
- [ ] 2. **Column positions**: Note field positions (add 1 for Julia)
- [ ] 3. **Special values**: Identify special handling ("F", 99.9, etc.)
- [ ] 4. **Define types**: Add to `src/types.jl` or `src/models/core_types.jl`
- [ ] 5. **Implement parser**: Create `src/parser/<file>.jl`
- [ ] 6. **Write tests**: Create `test/<file>_tests.jl`
- [ ] 7. **Test real data**: Validate with CCEE and ONS samples
- [ ] 8. **Document quirks**: Add findings to `docs/FORMAT_NOTES.md`
- [ ] 9. **Update progress**: Edit `docs/planning/TASKS.md`
- [ ] 10. **100% tests passing**: Verify all tests pass before PR

## Quick Reference

### Common Utilities

```julia
# Extract fixed-width field
extract_field(line::String, start_pos::Int, end_pos::Int) -> String

# Safe parsing with Nothing for failures
parse_int(s::String) -> Union{Int, Nothing}
parse_float(s::String) -> Union{Float64, Nothing}

# Line classification
is_comment(line::String) -> Bool
is_blank(line::String) -> Bool
is_block_start(line::String, keyword::String) -> Bool
```

### Running Tests

```bash
# All tests
julia --project=. test/runtests.jl

# Specific parser
julia --project=. test/xxx_tests.jl

# With coverage
julia --project=. --code-coverage=user test/runtests.jl
```

### IDESEM Field Types

```python
# IDESEM field definitions (0-indexed)
IntegerField(size, start)     # Integer field
LiteralField(size, start)     # String field (FIXED WIDTH!)
FloatField(size, start, decimals)  # Float field
StageDateField(starting_position, special_day_character)  # Date/time
```

## Reference Parsers

**Best Practices Examples**:
- `src/parser/operut.jl` - Most recent, comprehensive
- `docs/parsers/OPERUT_IMPLEMENTATION.md` - Complete implementation guide
- `src/parser/entdados.jl` - Complex multi-record parser (30+ types)

## Priority Files (Next to Implement)

From `docs/planning/TASKS.md`:

1. **DEFLANT.DAT** - Previous flows (initial conditions)
2. **HIDR.DAT** - Hydro plant registry (**BINARY FORMAT** - 792 bytes/record)
3. **CONFHD.DAT** - Hydro configuration
4. **MODIF.DAT** - Modifications

## Project Statistics

- **Status**: 7/32 parsers complete (22%)
- **Tests**: 2,600+ passing
- **Real data validation**: 100% CCEE and ONS compatibility
- **Type coverage**: 40+ types, 15/32 files

## Key Success Metrics

Before marking parser "production ready":
- ✅ 100% tests passing
- ✅ Real CCEE data validated
- ✅ Real ONS data validated (if applicable)
- ✅ Format quirks documented
- ✅ IDESEM reference consulted
- ✅ No hardcoded assumptions

## Additional Resources

- **IDESEM Repository**: https://github.com/rjmalves/idessem
- **Full Project Context**: `docs/planning/PROJECT_CONTEXT.md`
- **Architecture Guide**: `docs/architecture.md`
- **Session Summaries**: `docs/sessions/`

---

**Remember**: Check IDESEM first. Use fixed-width parsing. Test with real data. Document quirks immediately. Aim for 100% test coverage.
