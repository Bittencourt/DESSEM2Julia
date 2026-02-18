# Coding Conventions

**Analysis Date:** 2026-02-18

## Language

**Primary:** Julia 1.6-1.11

**Project Type:** Julia package (DESSEM2Julia.jl)

## Naming Patterns

**Files:**
- Source files: `lowercase.jl` (e.g., `termdat.jl`, `common.jl`)
- Test files: `lowercase_tests.jl` (e.g., `termdat_tests.jl`)
- Parser modules: Match the file being parsed (e.g., `hidr.jl` for HIDR.DAT)

**Modules:**
- PascalCase with descriptive names (e.g., `TermdatParser`, `ParserCommon`)
- Submodules for logical groupings (e.g., `Types`, `API`, `IO`)

**Types/Structs:**
- PascalCase (e.g., `CADUSIT`, `ThermalRegistry`, `ParserError`)
- Record types use uppercase abbreviations matching source files (e.g., `CADUSIT`, `CADUNIDT`)
- Container types use PascalCase with descriptive names (e.g., `ThermalRegistry`, `GeneralData`)

**Functions:**
- snake_case (e.g., `parse_termdat`, `extract_field`, `validate_range`)
- Parser functions follow `parse_{record_type}` pattern (e.g., `parse_cadusit`, `parse_curvacomb`)
- Helper functions use verb_noun pattern (e.g., `strip_comments`, `read_nonblank_lines`)

**Variables:**
- snake_case (e.g., `plant_num`, `unit_capacity`, `file_path`)
- Boolean variables often use `_flag` suffix (e.g., `skip_comments`, `required`)

**Constants:**
- SCREAMING_SNAKE_CASE for module-level constants (e.g., `ONS_SAMPLE_DIR`)

## Code Style

**Formatting Tool:** JuliaFormatter v1

**Configuration:** `.JuliaFormatter.toml`
```toml
indent = 4
margin = 92
always_for_in = true
remove_extra_newlines = true
short_to_long_function_def = false
always_use_return = false
```

**Key Formatting Rules:**
- 4-space indentation
- 92-character line margin
- Use `for item in collection` (not `for item = collection`)
- Return statements are optional (not enforced)
- Keep function definitions short-to-long

**Linting:**
- CI enforces formatting via `scripts/format_ci.jl`
- Fails build if code is not formatted

## Module Organization

**Pattern:**
```julia
"""
Module docstring explaining purpose.
"""
module ModuleName

using ..ParentModule  # Parent module reference
using ..Types: SomeType, AnotherType  # Explicit imports

export public_function, PublicType  # Public API

# Implementation follows

end # module
```

**Import Conventions:**
- Use `using` for importing modules and types
- Explicitly list imported types with `using ..Types: TypeA, TypeB`
- Use `export` to expose public API
- Use `..` for parent module references (e.g., `using ..ParserCommon`)

## Type Definitions

**Struct Declaration:**
Use `Base.@kwdef` for structs with default values:
```julia
Base.@kwdef struct CADUSIT
    plant_num::Int
    plant_name::String
    subsystem::Int
    commission_year::Union{Int,Nothing} = nothing
    heat_rate::Float64 = 0.0
end
```

**Union Types:**
- Use `Union{Type, Nothing}` for optional fields
- Use `Union{Int, String}` for fields that can be symbolic (e.g., `start_day`)

**Abstract Types:**
Not extensively used; most types are concrete structs

## Error Handling

**Custom Exception Type:**
```julia
# Defined in src/parser/common.jl
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

**Throwing Errors:**
```julia
throw(ParserError(
    "Field 'plant_num' value out of range [1, 999]",
    file,
    line_num,
    line
))
```

**Validation Helpers:**
```julia
# Use these from ParserCommon
validate_range(value, min_val, max_val, "field_name")
validate_positive(value, "field_name")
validate_nonnegative(value, "field_name")
```

**Pattern:**
- Throw `ParserError` with file context for parsing failures
- Include the problematic line content for debugging
- Use `try/catch` to wrap and re-throw with additional context

## Documentation

**Docstrings:**
Use Julia's docstring format for public functions:
```julia
"""
    parse_termdat(filepath::AbstractString) -> ThermalRegistry

Parse a TERM.DAT file and return a ThermalRegistry object.

# Arguments
- `filepath`: Path to the TERM.DAT file

# Returns
- `ThermalRegistry`: Container with all parsed thermal plant data

# Example
```julia
registry = parse_termdat("termdat.dat")
println("Parsed ", length(registry.plants), " plants")
```
"""
function parse_termdat(filepath::AbstractString)
    # implementation
end
```

**Type Documentation:**
Document struct fields with Julia docstrings:
```julia
"""
    CADUSIT

Thermal plant information record from TERM.DAT.

# Fields
- `plant_num::Int`: Plant identification number (1-999)
- `plant_name::String`: Plant name (12 characters max)
- `subsystem::Int`: Subsystem number per SIST records
"""
Base.@kwdef struct CADUSIT
    plant_num::Int
    plant_name::String
    subsystem::Int
end
```

## Comments

**When to Comment:**
- Module-level docstrings explaining purpose
- Function docstrings for public API
- Type docstrings explaining field meanings
- Inline comments for non-obvious logic (e.g., column positions that differ from documentation)

**Comment Style:**
- Use `#` for inline comments
- Use `"""` for docstrings
- Use section headers like `# ============================================================================`

## Function Design

**Size:** Functions typically 10-50 lines; larger parsing functions acceptable

**Parameters:**
- Use keyword arguments for optional parameters
- Use `Base.@kwdef` for struct-like parameter bundles
- Order: required parameters first, then options

**Return Values:**
- Parser functions return typed structs (e.g., `ThermalRegistry`)
- Helper functions return primitive types or `nothing`
- Use `Union{T, Nothing}` for optional returns

**Example Pattern:**
```julia
function parse_cadusit(line::AbstractString, file::String, line_num::Int)
    # 1. Define field specifications
    specs = [
        FieldSpec(:plant_num, 9, 11, Int; required = true),
        # ...
    ]
    
    # 2. Extract fields
    data = extract_fields(line, specs, file = file, line_num = line_num)
    
    # 3. Validate values
    validate_range(data.plant_num, 1, 999, "plant_num")
    
    # 4. Construct and return type
    return CADUSIT(
        plant_num = data.plant_num,
        plant_name = data.plant_name,
        # ...
    )
end
```

## Module Design

**Exports:**
- Export all public types and functions at module level
- Use explicit `export` lists, not `export *`

**Submodule Pattern:**
```julia
module DESSEM2Julia

# 1. Export public API
export greet, DessemData, parse_termdat

# 2. Include submodules
include("types.jl")
using .Types: DessemData, ThermalRegistry

include("parser/common.jl")
using .ParserCommon: ParserError, FieldSpec

include("parser/termdat.jl")
using .TermdatParser: parse_termdat

# 3. Module initialization
function __init__()
    register_parser!("TERMDAT.DAT", parse_termdat)
end

end # module
```

**File Organization:**
- One module per file
- Parser modules in `src/parser/`
- Type definitions in `src/types.jl` and `src/models/`
- API functions in `src/api.jl`

---

*Convention analysis: 2026-02-18*
