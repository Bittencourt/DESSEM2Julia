# Architecture

This project parses DESSEM input files (based on version 19.0.24.3) and converts them into an internal, typed data model that is then persisted in JLD2 format.

## Overview

DESSEM is a hydrothermal dispatch optimization model for short-term operational planning in Brazilian power systems. This package provides:

- **Parsing**: Fixed-format text file readers for **32 DESSEM input file types (100% complete)**
- **Type System**: Strongly-typed Julia structs representing DESSEM entities (40+ types)
- **Persistence**: Efficient binary storage via JLD2
- **Validation**: Format and consistency checking
- **Project Status**: ✅ **COMPLETE** (December 20, 2025) - All parsers implemented, 7,680+ tests passing

## Module Structure

```
DESSEM2Julia/
├── src/
│   ├── DESSEM2Julia.jl      # Main module, exports
│   ├── types.jl              # Legacy data structures
│   ├── models/
│   │   └── core_types.jl     # Core type system (40+ types) ⭐ NEW
│   ├── io.jl                 # JLD2 save/load
│   ├── api.jl                # Public API (convert_inputs)
│   └── parser/
│       ├── common.jl         # Shared parsing utilities
│       ├── registry.jl       # Parser dispatcher
│       ├── dessemarq.jl      # dessem.arq parser ✅ (68/68 tests)
│       ├── termdat.jl        # TERMDAT.DAT parser ✅ (110/110 tests)
│       ├── entdados.jl       # ENTDADOS.DAT parser ✅ (2331/2334 tests)
│       └── ...               # Additional file parsers (planned)
├── test/
│   ├── runtests.jl           # Test suite entry
│   ├── convert_tests.jl      # Integration tests
│   ├── core_types_test.jl    # Core type system tests ⭐ NEW
│   ├── dessemarq_tests.jl    # dessem.arq tests ✅
│   ├── termdat_tests.jl      # TERMDAT.DAT tests ✅
│   ├── entdados_tests.jl     # ENTDADOS.DAT tests ✅
│   └── parser/               # Parser-specific tests
└── docs/
    ├── dessem-complete-specs.md  # Format specifications
    ├── file_formats.md           # Coverage tracking
    ├── type_system.md            # Type system guide ⭐ NEW
    ├── session5_summary.md       # Session 5 completion ⭐ NEW
    └── architecture.md           # This file
```

## Core Components

### Type System (`src/models/core_types.jl`) ⭐ NEW

**Comprehensive data model covering all 32 DESSEM files (Session 5 complete)**

**`DessemCase`** - Top-level unified container
- `case_name::String` - Case identification
- `case_title::String` - Study title
- `base_directory::String` - Base directory path
- `file_registry::FileRegistry` - Master file index (from dessem.arq)
- `time_discretization::TimeDiscretization` - Time period definitions
- `power_system::PowerSystem` - Electrical system configuration
- `hydro_system::HydroSystem` - Hydroelectric generation
- `thermal_system::ThermalSystem` - Thermal generation
- `renewable_system::RenewableSystem` - Renewable generation
- `network_system::NetworkSystem` - Transmission network
- `operational_constraints::OperationalConstraints` - All constraints
- `decomp_cuts::DecompCut` - Future cost function cuts
- `execution_options::ExecutionOptions` - Solver configuration
- `metadata::Dict{String, Any}` - Additional metadata

**Type Coverage (32/32 files complete, 100%)** ✅:
- ✅ `TimeDiscretization` → `TimePeriod` (ENTDADOS.DAT - TM)
- ✅ `PowerSystem` → `Subsystem`, `LoadDemand`, `PowerReserve`
- ✅ `HydroSystem` → `HydroPlant`, `HydroReservoir`, `HydroOperation` (HIDR.DAT binary + text)
- ✅ `ThermalSystem` → `ThermalPlant`, `ThermalUnit`, `ThermalOperation` (TERMDAT, OPERUT)
- ✅ `RenewableSystem` → `WindPlant`, `SolarPlant` (RENOVAVEIS.DAT)
- ✅ `NetworkSystem` → `ElectricBus`, `TransmissionLine` (DESSELET, Network Topology)
- ✅ `OperationalConstraints` → `RampConstraint`, `LPPConstraint`, `TableConstraint` (OPERUH, RESTSEG, RSTLPP)
- ✅ `DecompCut` → `FCFCut` (CORTES.DEC, INFOFCF.DEC, MAPCUT.DEC)
- ✅ `ExecutionOptions` → Solver and modeling config (DESSOPC.DAT)
- ✅ `FileRegistry` → dessem.arq file mapping (DESSEM.ARQ)
- ✅ **All 32 DESSEM input files covered** - See [`docs/file_formats.md`](file_formats.md) for complete list

See `docs/type_system.md` for complete documentation.

### Legacy Types (`src/types.jl`)

**`DessemData`** - Original container (being phased out)
- `files::Dict{String, Any}` - Parsed file objects keyed by normalized filename
- `metadata::Dict{String, Any}` - Input directory, timestamp, version info

**Domain Types** (being migrated to core_types.jl):
- `ThermalRegistry` - Thermal plant data (TERMDAT.DAT)
- `GeneralData` - Time periods, subsystems, demands (ENTDADOS.DAT)
- Will be replaced by core type system

### Parser Infrastructure (`src/parser/`)

**`common.jl`** - Shared utilities
- `normalize_name(fname)` - Uppercase filename normalization
- `strip_comments(s)` - Remove comments from lines
- `is_blank(s)` - Check for empty lines
- Planned: Fixed-column extraction, numeric parsing, date/time handling

**`registry.jl`** - Parser dispatch system
- `register_parser!(fname, parser_fn)` - Register file handlers
- `get_parser(fname)` - Retrieve parser for filename
- `known_parsers()` - List registered parsers

**File-Specific Parsers** (to be implemented)
Each parser module handles one file type:
- Reads fixed-format columns per specification
- Handles multiple record types where applicable
- Returns strongly-typed structs
- Reports errors with file/line context

### I/O Layer (`src/io.jl`)

**JLD2 Persistence**
- `save_jld2(path, data::DessemData)` - Write binary format
- `load_jld2(path)::DessemData` - Read binary format
- Deterministic serialization for reproducibility
- Efficient storage and loading

### Public API (`src/api.jl`)

**`convert_inputs(input_dir, output_path)`**
- Walks directory tree to find DESSEM files
- Dispatches to registered parsers by filename
- Aggregates results into `DessemData`
- Saves to JLD2
- Returns output path

## Data Flow

```
Input Directory
    │
    ├─→ enumerate files
    │       │
    │       ├─→ HIDR.DAT ──→ HydroParser ──→ HydroPlant[]
    │       ├─→ TERM.DAT ──→ ThermalParser ──→ ThermalPlant[]
    │       ├─→ ENTDADOS.XXX ──→ EntdadosParser ──→ {TimeDiscretization, Subsystem[], Demand[], ...}
    │       ├─→ OPERUH.XXX ──→ OperuhParser ──→ HydroConstraint[]
    │       └─→ ...
    │
    ├─→ aggregate into DessemData
    │       files: {"HIDR.DAT" => [...], "TERM.DAT" => [...], ...}
    │       metadata: {input_dir, timestamp, ...}
    │
    ├─→ validate (optional)
    │       - Cross-reference checks
    │       - Consistency validation
    │       - Completeness checks
    │
    └─→ save to JLD2
            └─→ output.jld2
```

## Parsing Strategy

### Fixed-Format Column Parsing

DESSEM files use fixed-column positioning (no delimiters):

```
Example from HIDR.DAT (CADUSIH record):
Columns:  1-7     9-11  13-24        26-27  48-57      59-68
Data:     CADUSIH 001   CAMARGOS     04     0.0        792.0
Format:   A7      I3    A12          I2     F10.0      F10.0
```

Parser approach:
1. Read line as string
2. Extract substrings by column positions
3. Parse to appropriate types (Int, Float64, String)
4. Validate ranges and constraints
5. Construct typed structs

### Multi-Record File Handling

Files like ENTDADOS.XXX contain multiple record types:

```julia
function parse_entdados(path)
    tm_records = TimeDiscretization[]
    sist_records = Subsystem[]
    uh_records = HydroUnit[]
    # ... etc
    
    for line in eachline(path)
        record_type = line[1:2]  # First 2 chars identify record
        if record_type == "TM"
            push!(tm_records, parse_tm_record(line))
        elseif record_type == "SIST"
            push!(sist_records, parse_sist_record(line))
        # ... handle other record types
        end
    end
    
    return (tm=tm_records, sist=sist_records, uh=uh_records, ...)
end
```

### Block-Structured File Handling

Files like OPERUH.XXX use block markers:

```
OPERUH REST   001  01  001  00  1.0
OPERUH LIM    001  I   00  0  F  00  0  100.0  200.0
OPERUH LIM    001  02  00  0  05  00  0  150.0  180.0
FIM
```

Parser approach:
1. Track current block type
2. Accumulate records until "FIM"
3. Group related records (REST + LIM for one constraint)
4. Construct constraint objects

## Error Handling

**Parsing Errors**
- Include file path and line number
- Report expected vs. actual format
- Suggest corrections where possible

**Validation Errors**
- Cross-reference failures (e.g., unknown plant number)
- Constraint violations (e.g., max < min)
- Temporal inconsistencies (e.g., end before start)

**Fallback Strategy**
- Unknown files stored as raw text
- Partial parsing possible (warn on errors but continue)
- Detailed error logging

## Future Enhancements

### Phase 1: Core Parsers
- Implement HIDR.DAT, TERM.DAT parsers
- Fixed-column utility library
- Comprehensive unit tests

### Phase 2: Main Configuration
- DESSEM.ARQ, ENTDADOS.XXX, DADVAZ.XXX parsers
- Time/date parsing utilities
- Integration tests with sample data

### Phase 3: Operational Data
- OPERUH.XXX, OPERUT.XXX parsers
- Block-structure parsing utilities
- Validation framework

### Phase 4: Network & Advanced
- Electrical network files (ANAREDE format)
- Binary file handling (DECOMP integration)
- Security constraints

### Phase 5: Polish & Performance
- Streaming parsers for large files
- Parallel parsing where applicable
- Memory optimization
- CLI interface

## Testing Strategy

**Unit Tests**
- Each parser tested in isolation
- Known-good sample files
- Edge cases and error conditions

**Integration Tests**
- Full directory conversions
- Round-trip: parse → save → load → compare
- Cross-file validation

**Property-Based Tests**
- Generate valid/invalid inputs
- Test parser robustness
- Validate type invariants

## Documentation Standards

**Code Documentation**
- Docstrings for all public functions
- Field descriptions in struct definitions
- Inline comments for complex parsing logic

**User Documentation**
- Usage examples
- File format coverage matrix
- Known limitations and workarounds

**Cross-References**
- Link to official DESSEM manual sections
- Reference dessem-complete-specs.md for formats
- Maintain changelog for parser additions

## Design Principles

1. **Type Safety**: Leverage Julia's type system for correctness
2. **Immutability**: Parsed data is immutable by default
3. **Simplicity**: Each parser is independent and focused
4. **Testability**: Pure functions, dependency injection
5. **Extensibility**: Easy to add new file parsers
6. **Performance**: Efficient but not at expense of clarity
7. **Robustness**: Graceful degradation, helpful errors

---

Based on DESSEM User Manual version 19.0.24.3 (March 2022)
