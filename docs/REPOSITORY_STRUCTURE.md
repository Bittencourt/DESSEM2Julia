# Repository Structure Guide

**Last Updated**: November 2, 2025  
**Purpose**: This document describes the organized structure of the DESSEM2Julia repository.

## Directory Organization

### Root Directory
```
DESSEM2Julia/
├── README.md                    # Project overview and quickstart
├── Project.toml                 # Julia package configuration
├── Manifest.toml               # Julia dependency lock file (gitignored)
├── .gitignore                  # Git exclusion patterns
├── .gitattributes              # Git line-ending configuration
├── .JuliaFormatter.toml        # JuliaFormatter configuration
├── .github/                    # GitHub Actions CI/CD workflows
├── .githooks/                  # Git hooks (pre-commit tests)
├── .vscode/                    # VS Code workspace settings
├── src/                        # Source code (see below)
├── test/                       # Test suite (see below)
├── docs/                       # Documentation (see below)
├── examples/                   # Example scripts (see below)
└── scripts/                    # Development utilities (see below)
```

## Source Code (`src/`)

**Purpose**: Core library implementation

```
src/
├── DESSEM2Julia.jl            # Main module entry point
├── types.jl                   # Legacy type definitions (to be migrated)
├── api.jl                     # Public API exports
├── io.jl                      # JLD2 persistence layer
├── models/
│   └── core_types.jl          # ⭐ New type system (40+ types, 15/32 files)
└── parser/
    ├── common.jl              # Shared parser utilities
    ├── registry.jl            # Parser registration system
    ├── dessemarq.jl           # ✅ dessem.arq parser (68/68 tests)
    ├── termdat.jl             # ✅ TERMDAT.DAT parser (110/110 tests)
    ├── entdados.jl            # ✅ ENTDADOS.DAT parser (2331/2334 tests)
    ├── operuh.jl              # ✅ OPERUH.DAT parser (41/41 tests)
    └── operut.jl              # ✅ OPERUT.DAT parser (72/72 tests)
```

**Key Components**:
- **models/core_types.jl**: Comprehensive type system covering all 32 DESSEM files
- **parser/**: Individual file parsers with fixed-width column handling
- **api.jl**: User-facing functions like `parse_dessem_case()`

## Test Suite (`test/`)

**Purpose**: Comprehensive test coverage

```
test/
├── runtests.jl                # Test runner entry point
├── core_types_test.jl         # Core type system tests
├── convert_tests.jl           # Data conversion tests
├── dessemarq_tests.jl         # dessem.arq parser tests
├── termdat_tests.jl           # TERMDAT.DAT parser tests
├── entdados_tests.jl          # ENTDADOS.DAT parser tests
├── operuh_tests.jl            # OPERUH.DAT parser tests
├── operut_tests.jl            # OPERUT.DAT parser tests
└── parser/
    └── common_tests.jl        # Common parser utility tests
```

**Test Organization**:
- Each parser has a corresponding `*_tests.jl` file
- Tests use real CCEE/ONS sample data from `docs/Sample/`
- Run all tests: `julia --project=. test/runtests.jl`
- Run specific tests: `julia --project=. test/operut_tests.jl`

## Documentation (`docs/`)

**Purpose**: Organized documentation by category

### Planning & Progress (`docs/planning/`)
```
docs/planning/
├── TASKS.md                   # Project roadmap and task tracking
└── ONS_COMPATIBILITY_SUMMARY.md  # ONS case validation results
```

**Purpose**: Project management, progress tracking, compatibility verification

### Architecture & Design (`docs/`)
```
docs/
├── architecture.md            # System architecture overview
├── type_system.md             # ⭐ Core type system guide
├── dessem-complete-specs.md   # Complete DESSEM format specifications
├── file_formats.md            # File coverage status matrix
└── FORMAT_NOTES.md            # Format implementation notes and quirks
```

**Purpose**: Technical documentation for understanding the system design

### Parser Implementation Guides (`docs/parsers/`)
```
docs/parsers/
├── OPERUT_IMPLEMENTATION.md   # Complete OPERUT parser guide
├── idessem_comparison.md      # Comparison with IDESEM Python library
└── BINARY_FILES.md            # Binary format specifications (HIDR.DAT, etc.)
```

**Purpose**: Detailed implementation guides for specific parsers

### Session Summaries (`docs/sessions/`)
```
docs/sessions/
├── session5_summary.md        # Core type system implementation session
└── session6_summary.md        # OPERUT parser implementation session
```

**Purpose**: Historical development session notes and achievements

### Sample Data (`docs/Sample/`)
```
docs/Sample/
├── DS_CCEE_102025_SEMREDE_RV0D28/  # CCEE case (no network)
│   ├── dessem.arq
│   ├── termdat.dat
│   ├── entdados.dat
│   ├── operuh.dat
│   ├── operut.dat
│   └── ... (20+ other DESSEM files)
│
└── DS_ONS_102025_RV2D11/           # ONS case (with network)
    ├── dessem.arq
    ├── termdat.dat
    └── ... (all DESSEM files)
```

**Purpose**: Real CCEE and ONS data for testing and validation

## Examples (`examples/`)

**Purpose**: Runnable example scripts demonstrating library usage

```
examples/
├── parse_sample_case.jl       # Comprehensive CCEE case parsing demo
├── verify_ons_compatibility.jl  # ONS case compatibility verification
└── test_operuh_parse.jl       # Simple OPERUH parser demonstration
```

**Usage**:
```julia
julia --project=. examples/parse_sample_case.jl
julia --project=. examples/test_operuh_parse.jl
```

**Note**: These are tracked examples showing best practices. Temporary scratch files should use `scratch_*.jl` or `temp_*.jl` patterns (gitignored).

## Scripts (`scripts/`)

**Purpose**: Development utilities and automation

```
scripts/
├── setup-hooks.ps1            # Git hooks installation (pre-commit testing)
└── format_ci.jl               # Run JuliaFormatter in a temp env (mirrors CI, no Project.toml changes)
```

**Usage**:
```powershell
# Install pre-commit hook to run tests before commits
.\scripts\setup-hooks.ps1
 
# Apply CI formatting locally without touching dependencies
julia --project=. scripts/format_ci.jl
```

**Note**: Development scripts like `investigate_*.jl`, `debug_*.jl`, `test_*.jl` are gitignored and not tracked.

## File Organization Principles

### 1. Separation of Concerns
- **Source code** (`src/`) - Implementation only
- **Tests** (`test/`) - Validation and verification
- **Documentation** (`docs/`) - Knowledge and specifications
- **Examples** (`examples/`) - Usage demonstrations
- **Scripts** (`scripts/`) - Development automation

### 2. Documentation Categories
- **Planning** - Roadmaps, tasks, compatibility
- **Architecture** - System design and specifications
- **Parser Guides** - Implementation-specific details
- **Sessions** - Historical development notes

### 3. Naming Conventions
- **Parsers**: `<filename>.jl` (e.g., `operut.jl`)
- **Tests**: `<filename>_tests.jl` (e.g., `operut_tests.jl`)
- **Documentation**: `<TOPIC>.md` or `<topic>.md` for guides
- **Examples**: `<action>_<subject>.jl` (e.g., `parse_sample_case.jl`)

### 4. Gitignore Strategy
```gitignore
# Tracked files (examples of good practices)
examples/parse_sample_case.jl
examples/verify_ons_compatibility.jl
examples/test_operuh_parse.jl

# Ignored files (temporary/development)
examples/scratch_*.jl
examples/temp_*.jl
scripts/test_*.jl
scripts/investigate_*.jl
scripts/debug_*.jl
```

## Navigation Guide

### I want to...

**Understand the project**
→ Start with `README.md`
→ Read `docs/architecture.md`
→ Review `docs/planning/TASKS.md`

**Use the library**
→ See `examples/parse_sample_case.jl`
→ Check `src/api.jl` for public functions
→ Read `docs/type_system.md` for data structures

**Implement a new parser**
→ Study `docs/parsers/OPERUT_IMPLEMENTATION.md`
→ Review `src/parser/operut.jl` as reference
→ Check `docs/FORMAT_NOTES.md` for format quirks
→ See `docs/parsers/idessem_comparison.md` for IDESEM reference

**Add tests**
→ Look at `test/operut_tests.jl` as template
→ Use sample data from `docs/Sample/`
→ Run with `julia --project=. test/<your_test>.jl`

**Understand DESSEM formats**
→ Read `docs/dessem-complete-specs.md`
→ Check `docs/file_formats.md` for coverage
→ See `docs/FORMAT_NOTES.md` for implementation notes

**Track progress**
→ Check `docs/planning/TASKS.md`
→ Review session summaries in `docs/sessions/`

**Set up development environment**
→ Run `.\scripts\setup-hooks.ps1` (pre-commit testing)
→ See `README.md` Contributing section

## Migration History

**October 12, 2025**: Repository reorganization
- Created `docs/planning/` for project management docs
- Created `docs/parsers/` for implementation guides
- Created `docs/sessions/` for historical summaries
- Moved `TASKS.md` → `docs/planning/TASKS.md`
- Moved `ONS_COMPATIBILITY_SUMMARY.md` → `docs/planning/ONS_COMPATIBILITY_SUMMARY.md`
- Moved `OPERUT_IMPLEMENTATION.md` → `docs/parsers/OPERUT_IMPLEMENTATION.md`
- Moved `idessem_comparison.md` → `docs/parsers/idessem_comparison.md`
- Moved `BINARY_FILES.md` → `docs/parsers/BINARY_FILES.md`
- Moved `session5_summary.md` → `docs/sessions/session5_summary.md`
- Moved `session6_summary.md` → `docs/sessions/session6_summary.md`
- Moved `scripts/test_operuh_parse.jl` → `examples/test_operuh_parse.jl`
- Updated all documentation links in `README.md`
- Updated `.gitignore` to reflect new structure

**Rationale**:
- Improved discoverability through categorization
- Separated planning docs from technical docs
- Distinguished parser-specific guides from general architecture
- Consolidated session summaries in one location
- Cleaned up scripts/ to contain only utilities

## Maintenance Guidelines

### When adding new files...

**New parser**: 
1. Create `src/parser/<filename>.jl`
2. Create `test/<filename>_tests.jl`
3. Update `docs/planning/TASKS.md`
4. Consider adding implementation guide to `docs/parsers/`

**New documentation**:
1. **Planning/tasks** → `docs/planning/`
2. **Architecture/design** → `docs/`
3. **Parser implementation** → `docs/parsers/`
4. **Session summary** → `docs/sessions/`

**New example**:
1. Create in `examples/` with descriptive name
2. Add to README.md examples section
3. Ensure it uses real sample data

**New script**:
1. Utilities → `scripts/` (tracked if valuable)
2. Temporary/debug → `scripts/` with `test_*`, `debug_*`, or `investigate_*` prefix (gitignored)
3. Formatting → prefer `scripts/format_ci.jl` to mirror CI behavior

### When updating references...

**If a file moves**:
1. Update `README.md` links
2. Search for references: `git grep "old/path"`
3. Update all documentation cross-references
4. Test that links work in GitHub

## Current Status

**Parsers Implemented**: 5/32 files (16%)
- ✅ dessem.arq (68/68 tests)
- ✅ TERMDAT.DAT (110/110 tests)
- ✅ ENTDADOS.DAT (2331/2334 tests)
- ✅ OPERUH.DAT (41/41 tests)
- ✅ OPERUT.DAT (72/72 tests)

**Type System**: 40+ types, 15/32 files (47%)

**Documentation**: Well-organized and comprehensive
- Planning: 2 documents
- Architecture: 5 documents
- Parser guides: 3 documents
- Session summaries: 2 documents

**Examples**: 3 working examples
**Scripts**: 1 utility (git hooks)
**CI/Lint**: JuliaFormatter enforced in CI; LF line endings via `.gitattributes`

---

**Organization Status**: ✅ COMPLETE

The repository now has a clear, logical structure that separates concerns and improves discoverability!
