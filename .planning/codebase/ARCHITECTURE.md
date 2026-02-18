# Architecture

**Analysis Date:** 2026-02-18

## Pattern Overview

**Overall:** Modular Parser Library with Registry-based Dispatch

**Key Characteristics:**
- Julia module-based package architecture (`module DESSEM2Julia`)
- Registry pattern for file-type dispatch (parsers registered by filename)
- Layered type system: raw record types (Types module) + domain model types (CoreTypes module)
- Fixed-column file format parsing with field specifications

## Layers

**Types Layer (`src/types.jl`):**
- Purpose: Define raw data structures that mirror DESSEM file formats
- Location: `src/types.jl` (~1600+ lines)
- Contains: Record structs matching fixed-column file layouts (CADUSIT, UHRecord, DPRecord, etc.)
- Depends on: Dates stdlib
- Used by: All parser modules

**CoreTypes Layer (`src/models/core_types.jl`):**
- Purpose: Define domain model types for processed/aggregated data
- Location: `src/models/core_types.jl` (~1200 lines)
- Contains: Domain entities (HydroSystem, ThermalSystem, DessemCase, etc.)
- Depends on: Dates stdlib
- Used by: API layer, examples

**Parser Common Layer (`src/parser/common.jl`):**
- Purpose: Shared parsing utilities, field extraction, validation
- Location: `src/parser/common.jl` (~676 lines)
- Contains: FieldSpec struct, extract_fields(), parse_int(), parse_float(), validation helpers
- Depends on: Dates stdlib
- Used by: All file-specific parser modules

**Parser Registry Layer (`src/parser/registry.jl`):**
- Purpose: Map filenames to parser functions
- Location: `src/parser/registry.jl` (~28 lines)
- Contains: `register_parser!()`, `get_parser()`, `_REGISTRY` Dict
- Depends on: ParserCommon (normalize_name)
- Used by: API layer (convert_inputs), main module `__init__()`

**File Parser Layer (`src/parser/*.jl`):**
- Purpose: Parse specific DESSEM file formats
- Location: `src/parser/` (30+ parser files)
- Contains: One module per file type (TermdatParser, EntdadosParser, HidrParser, etc.)
- Depends on: Types, ParserCommon
- Used by: Main module, Registry

**IO Layer (`src/io.jl`):**
- Purpose: Serialize/deserialize parsed data to JLD2 format
- Location: `src/io.jl` (~26 lines)
- Contains: `save_jld2()`, `load_jld2()`
- Depends on: JLD2 package, Types (DessemData)
- Used by: API layer

**API Layer (`src/api.jl`):**
- Purpose: High-level interface for batch conversion
- Location: `src/api.jl` (~43 lines)
- Contains: `convert_inputs()` - walks directory, dispatches to parsers, aggregates into DessemData
- Depends on: Types, ParserCommon, ParserRegistry, IO
- Used by: End users, examples

## Data Flow

**Parse Pipeline:**

1. User calls `convert_inputs(input_dir, output_path)` or individual `parse_XXX(filepath)`
2. For batch: `convert_inputs()` enumerates files, normalizes filenames via `normalize_name()`
3. Registry lookup: `get_parser(normalized_name)` returns parser function or `nothing`
4. Parser function reads file, uses `FieldSpec` + `extract_fields()` for fixed-column extraction
5. Parser returns typed struct (e.g., `ThermalRegistry`, `GeneralData`, `HidrData`)
6. Results aggregated into `DessemData(files_map, metadata)`
7. Optionally saved via `save_jld2()` to HDF5-based JLD2 format

**State Management:**
- Stateless parser functions (pure functions: file path → parsed struct)
- Registry is module-level mutable state (`const _REGISTRY = Dict{String,Function}()`)
- DessemData is immutable container for all parsed files

## Key Abstractions

**FieldSpec:**
- Purpose: Define fixed-column field layout for DESSEM files
- Examples: `FieldSpec(:plant_num, 9, 11, Int; required=true)`
- Pattern: Specification object passed to `extract_fields()`

```julia
struct FieldSpec
    name::Symbol
    start_col::Int
    end_col::Int
    type::Type
    required::Bool
    default::Any
end
```

**DessemData:**
- Purpose: Top-level container for all parsed files from a case
- Examples: `src/types.jl` (end of file)
- Pattern: Simple container struct with files Dict and metadata Dict

**DessemCase:**
- Purpose: Domain model container with processed data organized by subsystem
- Examples: `src/models/core_types.jl`
- Pattern: Hierarchical struct (HydroSystem, ThermalSystem, PowerSystem, etc.)

**Parser Module Pattern:**
- Purpose: Consistent structure for all file parsers
- Examples: `src/parser/termdat.jl`, `src/parser/entdados.jl`
- Pattern:
```julia
module XxxParser
  using ..Types, ..ParserCommon
  export parse_xxx
  
  function parse_xxx(path::AbstractString)
    # Open file, iterate lines, dispatch to record parsers
  end
  
  function parse_record_type(line, file, line_num)
    # Use FieldSpec + extract_fields
  end
end
```

## Entry Points

**Main Module (`src/DESSEM2Julia.jl`):**
- Location: `src/DESSEM2Julia.jl` (431 lines)
- Triggers: `using DESSEM2Julia` (Julia module load)
- Responsibilities:
  - Include all submodules (types, models, parsers, io, api)
  - Re-export public types and functions
  - Register parsers in `__init__()` callback

**Test Entry (`test/runtests.jl`):**
- Location: `test/runtests.jl` (45 lines)
- Triggers: `Pkg.test("DESSEM2Julia")`
- Responsibilities:
  - Organize test files by parser type
  - Include individual test files

**Example Scripts (`examples/*.jl`):**
- Location: `examples/` (30+ scripts)
- Triggers: `include("examples/xxx.jl")` or `julia examples/xxx.jl`
- Responsibilities:
  - Demonstrate parser usage
  - Analyze parsed data
  - Generate visualizations

## Error Handling

**Strategy:** Custom exception type with file/line context

**Patterns:**
- `ParserError` struct in `src/parser/common.jl`:
```julia
struct ParserError <: Exception
    msg::String
    file::String
    line::Int
    content::String
end
```
- Validation helpers throw ParserError: `validate_range()`, `validate_positive()`, `validate_nonnegative()`
- All field extraction errors include file path and line number

## Cross-Cutting Concerns

**Logging:** Uses Julia's built-in `@warn` macro (e.g., PWF parser optional loading)

**Validation:** Per-field validation in parsers using helper functions:
- `validate_range(value, min, max, field_name)`
- `validate_positive(value, field_name)`
- `validate_nonnegative(value, field_name)`

**Authentication:** Not applicable (local file parsing only)

**Extensibility:**
- New parsers: Create `src/parser/xxx.jl`, add include/export to main module, register in `__init__()`
- New record types: Add to `src/types.jl` or `src/models/core_types.jl`

## Module Dependency Graph

```
DESSEM2Julia.jl (main)
├── Types (types.jl)
├── CoreTypes (models/core_types.jl)
├── IO (io.jl) ──────────→ JLD2
├── ParserCommon (parser/common.jl)
├── ParserRegistry (parser/registry.jl)
├── API (api.jl)
└── [30+ parser modules]
    ├── TermdatParser
    ├── EntdadosParser
    ├── HidrParser
    ├── OperuhParser
    ├── OperutParser
    └── ... (all in src/parser/)
```

## File Format Support

**Text Formats (fixed-column):**
- ENTDADOS.DAT (general data)
- TERMDAT.DAT (thermal registry)
- HIDR.DAT (hydro registry)
- OPERUH.DAT (hydro operations)
- OPERUT.DAT (thermal operations)
- DADVAZ.DAT (natural flows)
- DEFLANT.DAT (previous outflows)
- And 25+ other file types

**Binary Formats:**
- HIDR binary variant
- MLT.DAT (FPHA data)
- cortdeco.rv2 (FCF cuts)
- INFOFCF.DEC, MAPCUT.DEC, CORTES.DEC

---

*Architecture analysis: 2026-02-18*
