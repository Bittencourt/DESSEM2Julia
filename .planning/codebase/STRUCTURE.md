# Codebase Structure

**Analysis Date:** 2026-02-18

## Directory Layout

```
DESSEM2Julia/
├── src/                    # Source code (main package)
│   ├── parser/             # File-specific parsers (30+ files)
│   └── models/             # Domain model types
├── test/                   # Test suite
│   └── parser/             # Parser-specific tests
├── examples/               # Usage examples and analysis scripts
├── docs/                   # Documentation
│   ├── parsers/            # Parser-specific documentation
│   └── sessions/           # Development session notes
├── scripts/                # Development utilities
├── .github/                # CI/CD workflows
├── .planning/              # Planning documents (this file)
├── Project.toml            # Julia package manifest
└── README.md               # Project overview
```

## Directory Purposes

**`src/`:**
- Purpose: Main package source code
- Contains: Module definitions, types, parsers, API
- Key files: `DESSEM2Julia.jl`, `types.jl`, `io.jl`, `api.jl`

**`src/parser/`:**
- Purpose: File-format-specific parsers
- Contains: One Julia file per DESSEM file type
- Key files: `common.jl`, `registry.jl`, `termdat.jl`, `entdados.jl`, `hidr.jl`

**`src/models/`:**
- Purpose: Domain model type definitions
- Contains: `core_types.jl` - comprehensive data model
- Key files: `core_types.jl`

**`test/`:**
- Purpose: Unit tests for all parsers and utilities
- Contains: One test file per parser + integration tests
- Key files: `runtests.jl`, `termdat_tests.jl`, `entdados_tests.jl`, `ons_integration_tests.jl`

**`examples/`:**
- Purpose: Usage demonstrations and data analysis scripts
- Contains: Scripts for parsing, visualization, analysis
- Key files: `parse_sample_case.jl`, `visualize_hydro_cascades.jl`, `analyze_demand.jl`

**`docs/`:**
- Purpose: Project documentation
- Contains: Architecture docs, file format specs, entity diagrams
- Key files: `README.md`, `INDEX.md`, `architecture.md`, `type_system.md`

**`scripts/`:**
- Purpose: Development and CI utilities
- Contains: Code formatting scripts, git hook setup
- Key files: `format_code.jl`, `format_ci.jl`

## Key File Locations

**Entry Points:**
- `src/DESSEM2Julia.jl`: Main module, exports, parser registration
- `test/runtests.jl`: Test suite entry point
- `examples/parse_sample_case.jl`: Typical usage example

**Configuration:**
- `Project.toml`: Package dependencies and compat bounds
- `.JuliaFormatter.toml`: Code formatting configuration
- `.github/workflows/`: CI/CD pipeline definitions

**Core Logic:**
- `src/types.jl`: Raw record types matching file formats
- `src/models/core_types.jl`: Domain model types
- `src/parser/common.jl`: Shared parsing utilities
- `src/parser/registry.jl`: Parser dispatch registry
- `src/api.jl`: High-level conversion API
- `src/io.jl`: JLD2 serialization

**Testing:**
- `test/runtests.jl`: Test orchestration
- `test/parser/common_tests.jl`: Parser utility tests
- `test/*_tests.jl`: Parser-specific tests (30+ files)
- `test/ons_integration_tests.jl`: Integration tests with real ONS data

## Naming Conventions

**Files:**
- Parsers: `{filetype}.jl` (lowercase, matching DESSEM file name without extension)
  - Example: `termdat.jl` parses TERMDAT.DAT
- Tests: `{filetype}_tests.jl`
  - Example: `termdat_tests.jl`
- Types: `types.jl` (raw records), `core_types.jl` (domain model)

**Directories:**
- Lowercase with underscores: `src/`, `src/parser/`, `test/`

**Modules:**
- PascalCase with "Parser" suffix for parser modules
  - Example: `TermdatParser`, `EntdadosParser`, `HidrParser`
- PascalCase for type modules: `Types`, `CoreTypes`, `IO`, `API`

**Types (Structs):**
- PascalCase for struct names
  - Raw records: `CADUSIT`, `UHRecord`, `TMRecord`
  - Domain types: `HydroPlant`, `ThermalSystem`, `DessemCase`
  - Container suffix: `XxxData` (e.g., `HidrData`, `RespotData`)

**Functions:**
- snake_case for parser functions
  - Example: `parse_termdat()`, `parse_entdados()`, `extract_fields()`
- snake_case with `!` suffix for mutation: `register_parser!()`

**Constants:**
- SCREAMING_SNAKE_CASE for module-level constants
  - Example: `_REGISTRY`, `FieldSpec`

## Where to Add New Code

**New File Parser:**
1. Create parser: `src/parser/{newfile}.jl`
   - Follow module pattern from existing parsers
   - Use `FieldSpec` + `extract_fields()` for fixed-column parsing
2. Add types (if needed): `src/types.jl` for raw records, `src/models/core_types.jl` for domain types
3. Register in `src/DESSEM2Julia.jl`:
   - Add `include("parser/{newfile}.jl")`
   - Add `using .NewfileParser: parse_newfile`
   - Add `export parse_newfile`
   - Add `register_parser!("NEWFILE.DAT", parse_newfile)` in `__init__()`
4. Create tests: `test/{newfile}_tests.jl`
5. Include tests in `test/runtests.jl`: `include("{newfile}_tests.jl")`

**New Domain Type:**
- Primary code: `src/models/core_types.jl`
- Export from CoreTypes module
- Re-export from main module if needed

**New Utility Function:**
- Parsing utilities: `src/parser/common.jl`
- Export from ParserCommon module

**New Example:**
- Scripts: `examples/{descriptive_name}.jl`

**New Test:**
- Unit tests: `test/{parser_or_feature}_tests.jl`
- Integration tests: `test/ons_integration_tests.jl` or new file

## Special Directories

**`.github/`:**
- Purpose: GitHub Actions CI/CD configuration
- Contains: `workflows/` with YAML workflow definitions
- Generated: No
- Committed: Yes

**`.githooks/`:**
- Purpose: Git hooks for development workflow
- Contains: Pre-commit hooks, etc.
- Generated: No
- Committed: Yes

**`docs/parsers/`:**
- Purpose: Parser-specific documentation
- Contains: Detailed file format documentation
- Generated: No
- Committed: Yes

**`.planning/`:**
- Purpose: GSD planning documents
- Contains: Codebase analysis, phase plans
- Generated: Yes (by GSD commands)
- Committed: Optional (recommended for team projects)

## File Counts by Directory

| Directory | Files | Purpose |
|-----------|-------|---------|
| `src/` | 6 | Core module files |
| `src/parser/` | 35 | File-specific parsers |
| `src/models/` | 1 | Domain types |
| `test/` | 41 | Test files |
| `examples/` | 30 | Example scripts |
| `docs/` | 30+ | Documentation |

## Parser File Inventory

**System Configuration:**
- `dessopc.jl` - Execution options (DESSOPC.DAT)
- `dessemarq.jl` - File registry (DESSEM.ARQ)
- `entdados.jl` - General data (ENTDADOS.DAT)

**Hydro System:**
- `hidr.jl` - Hydro plant registry (HIDR.DAT)
- `hidr_binary.jl` - Binary HIDR variant
- `operuh.jl` - Hydro operations (OPERUH.DAT)
- `dadvaz.jl` - Natural flows (DADVAZ.DAT)
- `deflant.jl` - Previous outflows (DEFLANT.DAT)
- `curvtviag.jl` - Travel time curves (CURVTVIAG.DAT)
- `cotasr11.jl` - R11 gauge levels (COTASR11.DAT)

**Thermal System:**
- `termdat.jl` - Thermal registry (TERMDAT.DAT)
- `operut.jl` - Thermal operations (OPERUT.DAT)
- `ptoper.jl` - Operating points (PTOPER.DAT)

**Renewables:**
- `renovaveis.jl` - Wind/Solar (RENOVAVEIS.DAT)

**Network:**
- `desselet.jl` - Network index (DESSELET.DAT)
- `network_topology.jl` - Topology (PDO_SOMFLUX.DAT)
- `pwf.jl` - PWF format (optional dependency)
- `ilstri.jl` - Pereira Barreto (ILS_TRI.DAT)

**Constraints:**
- `rampas.jl` - Ramp constraints (RAMPAS.DAT)
- `rstlpp.jl` - LPP constraints (RSTLPP.DAT)
- `restseg.jl` - Table constraints (RESTSEG.DAT)
- `rmpflx.jl` - Flow ramps (RMPFLX.DAT)
- `rivar.jl` - Soft constraints (RIVAR.DAT)
- `areacont.jl` - Control areas (AREACONT.DAT)

**Reserves:**
- `respot.jl` - Power reserve (RESPOT.DAT)
- `respotele.jl` - Network reserve (RESPOTELE.DAT)

**DECOMP Interface:**
- `cortdeco.jl` - FCF cuts (cortdeco.rv2)
- `binary_dec.jl` - Binary DECOMP files
- `infofcf.jl` - FCF info (INFOFCF.DAT)

**Other:**
- `bateria.jl` - Batteries (BATERIA.DAT)
- `mlt.jl` - FPHA data (MLT.DAT)
- `metas.jl` - Goals (METAS.DAT)
- `tolperd.jl` - Loss tolerances (TOLPERD.DAT)
- `modif.jl` - Modifications (MODIF.DAT)

---

*Structure analysis: 2026-02-18*
