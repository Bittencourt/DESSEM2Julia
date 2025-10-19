# Changelog

All notable changes to DESSEM2Julia will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
