# Architecture Patterns

**Domain:** Julia data parser with validation layer
**Researched:** 2026-02-18
**Context:** Adding validation layer to existing DESSEM parser

## Current Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         PUBLIC API (src/api.jl)                  │
│                    convert_inputs(input_dir, output_path)        │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    PARSER REGISTRY (src/parser/registry.jl)      │
│              filename → parser function routing                  │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│ ENTDADOS.jl  │      │  TERMDAT.jl  │      │   ...36+     │
│ (parser)     │      │  (parser)    │      │   parsers    │
└──────────────┘      └──────────────┘      └──────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                RAW TYPES (src/types.jl)                          │
│        TMRecord, UHRecord, UTRecord, DPRecord, etc.             │
│        (1:1 mapping with file formats)                          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                DOMAIN TYPES (src/models/core_types.jl)           │
│        DessemCase, HydroSystem, ThermalSystem, etc.             │
│        (aggregated, semantically meaningful structures)         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    IO LAYER (src/io.jl)                          │
│                save_jld2 / load_jld2                             │
└─────────────────────────────────────────────────────────────────┘
```

### Current Data Flow

```
Input Directory
       │
       ▼
┌──────────────────┐
│ walkdir()        │  Enumerate files
└──────────────────┘
       │
       ▼
┌──────────────────┐
│ normalize_name() │  Uppercase, strip path
└──────────────────┘
       │
       ▼
┌──────────────────┐
│ get_parser()     │  Route to parser via registry
└──────────────────┘
       │
       ▼
┌──────────────────┐
│ parse_xxx()      │  Parse file using FieldSpec pattern
└──────────────────┘
       │
       ▼
┌──────────────────┐
│ DessemData       │  Aggregate into Dict{String, Any}
│ (files_map)      │
└──────────────────┘
       │
       ▼
┌──────────────────┐
│ save_jld2()      │  Serialize to JLD2
└──────────────────┘
```

### Key Patterns in Existing Code

#### 1. FieldSpec Pattern (Parser Common)

```julia
# Define field specifications
fields = [
    FieldSpec(:plant_num, 5, 7, Int; required=true),
    FieldSpec(:plant_name, 10, 21, String; default=""),
    FieldSpec(:capacity, 30, 39, Float64; default=0.0)
]

# Extract and parse fields from line
values = extract_fields(line, fields; file=filename, line_num=line_num)
```

#### 2. Parser Registry Pattern

```julia
# Registration (in __init__)
register_parser!("TERMDAT.DAT", parse_termdat)
register_parser!("ENTDADOS.DAT", parse_entdados)

# Lookup
parser = get_parser(normalize_name(filename))
```

#### 3. Type Hierarchy

```julia
# Raw records (file-format aligned)
struct UHRecord
    plant_num::Int
    plant_name::String
    subsystem::Int
    # ...
end

# Domain types (aggregated, semantic)
struct HydroPlant
    plant_num::Int
    plant_name::String
    # ...
end

struct HydroSystem
    plants::Vector{HydroPlant}
    reservoirs::Vector{HydroReservoir}
    operations::Vector{HydroOperation}
end
```

## Recommended Validation Architecture

### Design Principles

1. **Separation of Concerns**: Validation is separate from parsing
2. **Post-Parse Validation**: Validates after all files are parsed (enables cross-file checks)
3. **Composable Rules**: Individual validators can be combined
4. **Configurable Strictness**: Warning vs error behavior
5. **Detailed Reporting**: Clear error messages with context

### Component Structure

```
src/
├── validation/
│   ├── Validation.jl        # Module, exports, types
│   ├── types.jl             # ValidationResult, ValidationError, etc.
│   ├── interface.jl         # AbstractValidator, validate() interface
│   ├── registry.jl          # Cross-file reference validation
│   ├── cross_file.jl        # Cross-file consistency checks
│   ├── range.jl             # Value range validation
│   └── temporal.jl          # Time period consistency
├── parser/                  # (existing)
├── models/                  # (existing)
└── api.jl                   # (enhanced with validation)
```

### Data Flow with Validation

```
Input Directory
       │
       ▼
┌──────────────────┐
│ Parse All Files  │  Existing parser infrastructure
└──────────────────┘
       │
       ▼
┌──────────────────┐
│ DessemData       │  Raw parsed data (Dict{String, Any})
│ (files_map)      │
└──────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│         VALIDATION LAYER (NEW)            │
│  ┌─────────────────────────────────────┐  │
│  │ Reference Integrity                 │  │
│  │ - Plants exist in registry          │  │
│  │ - Subsystems are defined            │  │
│  │ - Cross-references are valid        │  │
│  └─────────────────────────────────────┘  │
│  ┌─────────────────────────────────────┐  │
│  │ Range Validation                    │  │
│  │ - Volumes within bounds             │  │
│  │ - Capacities are positive           │  │
│  │ - Percentages 0-100                 │  │
│  └─────────────────────────────────────┘  │
│  ┌─────────────────────────────────────┐  │
│  │ Temporal Consistency                │  │
│  │ - Time periods sequential           │  │
│  │ - No gaps in discretization         │  │
│  │ - Start/end dates valid             │  │
│  └─────────────────────────────────────┘  │
│  ┌─────────────────────────────────────┐  │
│  │ Cross-File Consistency              │  │
│  │ - Operations reference valid plants │  │
│  │ - Demand subsystems exist           │  │
│  │ - Maintenance references valid units│  │
│  └─────────────────────────────────────┘  │
└──────────────────────────────────────────┘
       │
       ▼
┌──────────────────┐
│ ValidationResult │  errors: Vector{ValidationError}
│                  │  warnings: Vector{ValidationWarning}
└──────────────────┘
       │
       ▼ (if valid)
┌──────────────────┐
│ DessemCase       │  Domain-level aggregated structure
└──────────────────┘
```

### Type Definitions

```julia
# src/validation/types.jl

"""
Severity level for validation issues.
"""
@enum ValidationSeverity begin
    VALIDATION_ERROR    # Must be fixed, blocks processing
    VALIDATION_WARNING  # Should be reviewed, doesn't block
    VALIDATION_INFO     # Informational, for debugging
end

"""
Source context for a validation issue.
"""
struct ValidationContext
    file::Union{String, Nothing}        # Source file (if applicable)
    record_type::Union{Type, Nothing}   # Type of record with issue
    record_id::Union{String, Nothing}   # Identifier (e.g., plant number)
    field::Union{Symbol, Nothing}       # Field name (if applicable)
    line::Union{Int, Nothing}           # Line number (if applicable)
end

"""
A single validation issue (error or warning).
"""
struct ValidationIssue
    severity::ValidationSeverity
    code::Symbol                         # Machine-readable code (e.g., :MISSING_REFERENCE)
    message::String                      # Human-readable description
    context::ValidationContext           # Where the issue occurred
    suggestion::Union{String, Nothing}   # Optional fix suggestion
end

"""
Result of validating a DessemData or DessemCase.
"""
struct ValidationResult
    is_valid::Bool                       # True if no errors (warnings allowed)
    errors::Vector{ValidationIssue}      # Blocking issues
    warnings::Vector{ValidationIssue}    # Non-blocking issues
    info::Vector{ValidationIssue}        # Informational messages
    
    function ValidationResult(errors, warnings, info)
        new(isempty(errors), errors, warnings, info)
    end
end
```

### Validator Interface

```julia
# src/validation/interface.jl

"""
Abstract type for validators.
"""
abstract type AbstractValidator end

"""
Validate data and return issues found.
"""
function validate end

"""
Combine multiple validators.
"""
struct CompositeValidator <: AbstractValidator
    validators::Vector{AbstractValidator}
end

function validate(v::CompositeValidator, data::DessemData)
    all_issues = ValidationIssue[]
    for validator in v.validators
        append!(all_issues, validate(validator, data))
    end
    return all_issues
end
```

### Cross-File Reference Validation

```julia
# src/validation/registry.jl

"""
Validates that referenced entities exist in their registries.
"""
struct ReferenceValidator <: AbstractValidator
    # Configuration
    strict::Bool  # Error vs warning for missing references
end

function validate(v::ReferenceValidator, data::DessemData)
    issues = ValidationIssue[]
    
    # Build registries (lookup tables)
    thermal_plants = Set{Int}()
    hydro_plants = Set{Int}()
    subsystems = Set{Int}()
    
    # Extract registry data
    if haskey(data.files_map, "TERMDAT.DAT")
        for plant in data.files_map["TERMDAT.DAT"].plants
            push!(thermal_plants, plant.plant_num)
        end
    end
    
    # Check ENTDADOS thermal operations reference valid plants
    if haskey(data.files_map, "ENTDADOS.DAT")
        entdados = data.files_map["ENTDADOS.DAT"]
        for ut in entdados.thermal_plants
            if ut.plant_num ∉ thermal_plants
                push!(issues, ValidationIssue(
                    v.strict ? VALIDATION_ERROR : VALIDATION_WARNING,
                    :MISSING_THERMAL_REFERENCE,
                    "Thermal plant $(ut.plant_num) in ENTDADOS not found in TERMDAT registry",
                    ValidationContext("ENTDADOS.DAT", UTRecord, "$(ut.plant_num)", nothing, nothing),
                    "Add plant $(ut.plant_num) to TERMDAT.DAT or remove from ENTDADOS"
                ))
            end
        end
    end
    
    return issues
end
```

### API Integration

```julia
# src/api.jl (enhanced)

export convert_inputs, convert_inputs!, validate

"""
Options for validation behavior.
"""
@kwdef struct ValidationOptions
    enabled::Bool = true
    strict::Bool = false           # Errors block processing
    on_warning::Symbol = :continue # :continue, :warn, :error
    validators::Vector{Symbol} = [:all]  # Which validators to run
end

"""
Validate parsed data.
"""
function validate(data::DessemData, opts::ValidationOptions=ValidationOptions())
    if !opts.enabled
        return ValidationResult([], [], [])
    end
    
    # Build validator chain
    validators = AbstractValidator[]
    
    if :all in opts.validators || :reference in opts.validators
        push!(validators, ReferenceValidator(opts.strict))
    end
    if :all in opts.validators || :range in opts.validators
        push!(validators, RangeValidator())
    end
    if :all in opts.validators || :temporal in opts.validators
        push!(validators, TemporalValidator())
    end
    
    # Run validation
    composite = CompositeValidator(validators)
    issues = validate(composite, data)
    
    # Categorize by severity
    errors = filter(i -> i.severity == VALIDATION_ERROR, issues)
    warnings = filter(i -> i.severity == VALIDATION_WARNING, issues)
    info = filter(i -> i.severity == VALIDATION_INFO, issues)
    
    return ValidationResult(errors, warnings, info)
end

"""
Convert inputs with optional validation.
"""
function convert_inputs(
    input_dir::AbstractString, 
    output_path::AbstractString;
    validation::ValidationOptions=ValidationOptions()
)
    # Parse all files (existing logic)
    files_map = Dict{String,Any}()
    for (root, _, files) in walkdir(String(input_dir))
        for f in files
            norm = normalize_name(f)
            parser = get_parser(norm)
            full = joinpath(root, f)
            if parser === nothing
                files_map[norm] = read(full, String)
            else
                files_map[norm] = parser(full)
            end
        end
        break
    end
    
    data = DessemData(files_map, Dict("input_dir" => String(input_dir)))
    
    # Validate if enabled
    result = validate(data, validation)
    
    if !result.is_valid
        error("Validation failed with $(length(result.errors)) errors:\n" *
              join(["  - $(e.message)" for e in result.errors], "\n"))
    end
    
    if !isempty(result.warnings) && validation.on_warning == :error
        error("Validation failed with $(length(result.warnings)) warnings")
    end
    
    return save_jld2(String(output_path), data)
end
```

## Component Boundaries

| Component | Responsibility | Depends On |
|-----------|---------------|------------|
| `Parser.*` | Parse individual files into raw records | `ParserCommon`, `Types` |
| `Types` | Define raw record types (file-format aligned) | None |
| `CoreTypes` | Define domain types (aggregated, semantic) | None |
| `Validation` | Check data consistency and integrity | `Types`, `CoreTypes` |
| `API` | High-level user interface | `Parser.*`, `Validation`, `IO` |
| `IO` | Serialization/deserialization | `Types` |

## Data Flow Direction

```
                    ┌─────────────┐
                    │ Input Files │
                    └──────┬──────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                      PARSER LAYER                             │
│  (Stateless functions: file → raw records)                   │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ DessemData  │  Dict{String, Any} of raw records
                    └──────┬──────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────────┐
│                    VALIDATION LAYER                           │
│  (Check integrity, cross-references, ranges)                 │
└──────────────────────────────────────────────────────────────┘
                           │
                           ▼
                ┌──────────────────┐
                │ ValidationResult │  errors, warnings
                └────────┬─────────┘
                         │
                         ▼ (if valid)
                    ┌─────────────┐
                    │ DessemCase  │  Domain-level aggregated structure
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │    JLD2     │  Serialized output
                    └─────────────┘
```

**Key principle:** Data flows in ONE direction. Validation doesn't modify data, only checks it.

## Build Order for Validation Layer

Based on dependencies, implement in this order:

### Phase 1: Validation Types and Interface
1. `src/validation/types.jl` - ValidationResult, ValidationIssue, ValidationContext
2. `src/validation/interface.jl` - AbstractValidator, validate() function signature
3. `src/validation/Validation.jl` - Module with exports

**Dependencies:** None (standalone types)

### Phase 2: Basic Validators
4. `src/validation/range.jl` - RangeValidator (value bounds checking)
5. `src/validation/temporal.jl` - TemporalValidator (time period consistency)

**Dependencies:** Phase 1

### Phase 3: Cross-File Validators
6. `src/validation/registry.jl` - ReferenceValidator (cross-file reference checking)
7. `src/validation/cross_file.jl` - Additional cross-file consistency rules

**Dependencies:** Phase 1, Phase 2, understanding of type relationships

### Phase 4: API Integration
8. Update `src/api.jl` - Add validate() function, integrate with convert_inputs()
9. Update `src/DESSEM2Julia.jl` - Export validation types and functions

**Dependencies:** Phase 1-3 complete

### Phase 5: Tests and Documentation
10. `test/validation/` - Test suite for validators
11. `docs/src/validation.md` - User documentation

**Dependencies:** Phase 1-4 complete

## Anti-Patterns to Avoid

### Anti-Pattern 1: Validation During Parsing

**What:** Adding validation logic inside parser functions
**Why bad:** 
- Couples parsing and validation
- Cannot check cross-file references (not all files parsed yet)
- Makes parsers harder to test in isolation
**Instead:** Parse first, validate after all files are processed

### Anti-Pattern 2: Mutable Validation State

**What:** Having validators mutate input data or global state
**Why bad:**
- Makes validation non-deterministic
- Hard to reason about what changed
- Breaks functional data flow
**Instead:** Validators should be pure functions returning ValidationIssue vectors

### Anti-Pattern 3: Silent Fixes

**What:** Validators "fixing" issues automatically without reporting
**Why bad:**
- User doesn't know data was modified
- Hidden bugs can propagate
- Hard to debug downstream issues
**Instead:** Report all issues, let user decide how to fix

### Anti-Pattern 4: Monolithic Validator

**What:** One giant validation function with all rules
**Why bad:**
- Hard to test individual rules
- Hard to enable/disable specific checks
- Hard to understand what failed
**Instead:** Composable validators, each with single responsibility

## Scalability Considerations

| Concern | Current (~32 files) | Large Cases (~100+ files) |
|---------|---------------------|---------------------------|
| Parse time | <1 second | ~5-10 seconds |
| Validation time | <0.5 seconds | ~2-5 seconds |
| Memory usage | ~50MB | ~500MB |
| Cross-file lookups | Dict O(1) | Dict O(1), same approach |

**Optimization opportunities:**
- Parallel file parsing (already independent)
- Lazy validation (only run requested validators)
- Incremental validation (re-validate only changed files)

## Sources

- Codebase analysis of DESSEM2Julia (HIGH confidence - direct examination)
- Julia type system patterns (HIGH confidence - official docs)
- Data validation library patterns (MEDIUM confidence - general software engineering)
