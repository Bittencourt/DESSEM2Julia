# Changelog

All notable changes to DESSEM2Julia will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - February 17, 2026
- **cortdeco.rv2 Binary Parser**: Complete FCF (Future Cost Function) cuts parser
  - Parse Benders cuts from NEWAVE/DECOMP cortdeco.rv2 binary files
  - Linked-list traversal algorithm matching inewave reference implementation
  - Binary format: 1664-byte records (16-byte header + 206 Float64 coefficients)
  - Helper functions: `get_water_value()`, `get_active_cuts()`, `get_cut_statistics()`
  - Updated FCF types: `FCFCut`, `FCFCutsData`, `DecompCut` with backward compatibility
  - Comprehensive test suite: 51 tests covering all functionality
  - Cross-platform compatible (Windows, Linux, macOS)
  - Complete documentation: `docs/parsers/CORTDECO_IMPLEMENTATION.md`
  - Reference: Based on https://github.com/rjmalves/inewave
- Documentation improvements:
  - Added cortdeco binary format to `FORMAT_NOTES.md`
  - Updated `README.md` with FCF parser coverage
  - Created implementation guide with examples and troubleshooting

### Added - December 20, 2025 - PROJECT COMPLETE 🎉
- **Project Completion**: All 32 DESSEM parsers implemented!
  - 26 production-ready parsers with full structured parsing
  - 6 appropriate placeholder parsers for binary/proprietary formats
  - 7,680+ tests passing

### Changed - December 20, 2025
- **MLT.DAT Parser**: Converted from text line reader to binary byte reader
  - Discovery: MLT.DAT is binary (not text) - byte pattern `243, 0, 0, 0...`
  - Updated `MltData` type to store `raw_bytes::Vector{UInt8}` instead of records
  - Removed obsolete `MltRecord` type
- **Documentation**: Updated all docs to reflect project completion
  - TASKS.md, README.md, PROJECT_CONTEXT.md, PARSER_COMPLETENESS_AUDIT_v3.md
  - copilot-instructions.md, file_formats.md, FORMAT_NOTES.md
- **Binary Parser Docs**: Enhanced documentation explaining placeholders are correct
  - `binary_dec.jl`, `mlt.jl`, `modif.jl` now have comprehensive module docs
  - Added "Binary Files - Proprietary Formats" section to FORMAT_NOTES.md

### Added - October 26, 2025 (Session 21-23)
- **RENOVAVEIS, RESPOT, RIVAR, RAMPAS, PTOPER Parsers**: Completed remaining constraint and operational parsers
  - RENOVAVEIS.DAT: Renewable energy plants (wind, solar) with subsystem/bus mappings
  - RESPOT.DAT: Power reserve constraints (reserve pools and limits)
  - RIVAR.DAT: Soft variation constraints with penalty costs
  - RAMPAS.DAT: Thermal unit ramp trajectories
  - PTOPER.DAT: Operating point/schedule definitions
- **Documentation Updates**: Updated all project documentation for final parsers
  - Updated TASKS.md with Sessions 21-23 progress
  - Updated README.md with parser progress (32/32, 100%), test counts (7,680+ passing)
  - Updated PROJECT_CONTEXT.md with project completion status
  - Updated file_formats.md to mark all parsers as complete
  - Session summaries for sessions 21-23 documenting final implementation work

### Added - October 26, 2025 (Session 20)
- **RENOVAVEIS.DAT Complete Parser**: Full renewable energy data with all relationships
  - EOLICA records: Plant registrations (wind, solar, biomass, small hydro)
  - EOLICASUBM records: Plant-to-subsystem market mappings (N, NE, S, SE)
  - EOLICABARRA records: Plant-to-bus electrical network connections
  - EOLICA-GERACAO records: Time series generation availability forecasts
- Four new type structures:
  - `RenovaveisRecord`: Plant data (code, name, pmax, fcap, cadastro)
  - `RenovaveisSubsystemRecord`: Subsystem mapping relationships
  - `RenovaveisBusRecord`: Electrical bus connection relationships
  - `RenovaveisGenerationRecord`: Time-varying generation forecasts
- Enhanced `RenovaveisData` structure with four data vectors
- Comprehensive test suite: 45 tests validating all record types and relationships
- Parser count: 19/32 complete (59% coverage)
- Test count: 2,759 passing tests (excluding SIMUL parser with test data issues)

### Added - October 18, 2025 (Session 8)
- **ENTDADOS Record Type Expansion**: Added 16 new record types to ENTDADOS parser
  - RE: Electrical constraint definitions
  - LU: Constraint limits with optional blank field support
  - FH, FT, FI, FE, FR, FC: Coefficient records for various components
  - TX: Discount rate parameter
  - EZ: Coupling volume percentage
  - R11: Gauge 11 variations
  - FP: FPHA parameters (8 fields)
  - SECR: River section with upstream plant pairs
  - CR: Head-flow polynomial with degree and coefficients
  - AC: Generic plant adjustment with variable format support (2 ints, 1 float, or int+float)
  - AG: Aggregate group with optional group_id
- Updated GeneralData struct from 8 to 24 vector fields
- Test count increased to 2,600+ passing tests across all parsers

### Changed - October 18, 2025
- ENTDADOS parser now supports 30+ record types (up from ~8)
- Enhanced LURecord with Union{Float64, Nothing} for optional limits
- Enhanced AGRecord with Union{Int, Nothing} for optional group_id
- Improved AC parser with flexible format handling using try-catch blocks
- Updated documentation: README.md, file_formats.md, TASKS.md
- Created session8_summary.md with detailed implementation notes

### Fixed - October 18, 2025
- LU records with blank limit fields now parse correctly
- AC records with variable value formats (2 ints, 1 float, int+float) handled properly
- AG records with minimal format (missing group_id) parse without errors
- Reduced parser warnings from hundreds to <100 (only less common record types remain)

---

## [0.2.0] - October 13, 2025 (Session 7)

### Added
- **DADVAZ.DAT Parser**: Natural inflow data and metadata parser
  - Header metadata: plant count, roster, study start, FCF configuration
  - Daily inflow records with symbolic period markers ("I"/"F")
  - 13 tests validating against CCEE sample data
  - New types: DadvazHeader, DadvazInflowRecord, DadvazData

### Changed
- Enhanced test coverage with real CCEE data validation
- Improved documentation with session7_summary.md

---

## [0.1.0] - October 12, 2025 (Session 6)

### Added
- **OPERUT.DAT Parser**: Thermal unit operational data parser
  - Fixed-width column format based on IDESSEM reference
  - INIT block: thermal unit initial conditions
  - OPER block: operational limits and costs by time period
  - 62 tests passing with real CCEE production data
  - Successfully parses 387 thermal units (47 ON, 340 OFF)

### Changed
- Switched from split-based to fixed-width parsing for OPERUT
- Updated parser to handle 12-character plant name fields
- Added comprehensive edge case testing

### Fixed
- Plant name parsing with embedded spaces and special characters
- Optional field handling for min/max generation values
- Special "F" (final) marker in end_day fields

---

## [0.0.5] - Previous Sessions

### Added
- **OPERUH.DAT Parser**: Hydro operational constraints (REST, ELEM, LIM, VAR records)
- **DESSELET.DAT Parser**: Network case mapping (base cases + patamares)
- **TERMDAT.DAT Parser**: Thermal plant registry (110 tests passing)
- **ENTDADOS.DAT Parser**: General operational data (initial implementation with TM, SIST, UH, UT, DP records)
- **dessem.arq Parser**: Master file index (68 tests passing)
- Core type system with 40+ types organized into 11 functional subsystems
- Comprehensive test suite with 2,588+ tests

### Changed
- Established fixed-width parsing patterns across all parsers
- Integrated IDESSEM Python library as authoritative reference
- Enhanced error handling with ParserError context

---

## Notes

### Version Numbering
- Major version (X.0.0): Breaking API changes or major feature additions
- Minor version (0.X.0): New parser implementations or significant features
- Patch version (0.0.X): Bug fixes and minor improvements

### Test Coverage
- All parsers validated against real ONS and CCEE operational data
- Comprehensive edge case testing for optional fields and variable formats
- Integration tests verify cross-file consistency

### Documentation
- Session summaries document implementation details and key learnings
- README.md provides quickstart and overview
- docs/planning/ contains project context and tasks
- docs/parsers/ contains detailed implementation guides
