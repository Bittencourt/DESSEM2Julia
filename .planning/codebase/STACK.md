# Technology Stack

**Analysis Date:** 2026-02-18

## Languages

**Primary:**
- Julia 1.6-1.11 - Main implementation language (entire codebase)
- CI tests on Julia 1.11; compatibility declared for 1.6, 1.7, 1.8, 1.9, 1.10, 1.11

**Secondary:**
- PowerShell - Git hook setup script (`scripts/setup-hooks.ps1`)

## Runtime

**Environment:**
- Julia runtime (no containerization)
- Package manager: Pkg (Julia built-in)
- Lockfile: `Manifest.toml` is gitignored; only `Project.toml` is tracked

## Frameworks

**Core:**
- Julia Package ecosystem - Standard Julia module structure
- No web framework (library package, not an application)

**Testing:**
- Test.jl (Julia standard library) - Unit testing framework
- Config: Tests defined in `test/runtests.jl`, includes 40+ test files

**Build/Dev:**
- JuliaFormatter 1.x - Code formatting/linting
- CI workflow runs on ubuntu-latest and windows-latest

## Key Dependencies

**Critical:**
- JLD2 (0.4, 0.5) - HDF5-based data serialization/persistence for DessemData objects
  - Used in `src/io.jl` for `save_jld2()` and `load_jld2()` functions
  - Primary output format for parsed DESSEM data
- Dates (stdlib) - Date/time handling for DESSEM temporal data
- Printf (stdlib) - Formatted string output for fixed-width file parsing

**Visualization/Graph:**
- Graphs (1.8-1.11) - Graph data structures for network topology
- GraphPlot (0.5, 0.6) - Network visualization (buses, transmission lines)
- Colors (0.12) - Color utilities for visualizations
- Compose (0.9) - Graphics composition for network diagrams

## Configuration

**Environment:**
- No external environment variables required
- No `.env` files; purely file-based configuration
- Configuration via `Project.toml` for package metadata and dependencies

**Build:**
- `Project.toml` - Package manifest with dependencies and compatibility
- `.JuliaFormatter.toml` - Code formatting configuration:
  - `indent = 4`
  - `margin = 92`
  - `always_for_in = true`
  - `remove_extra_newlines = true`
- `.gitattributes` - Enforces LF line endings for `.jl`, `.toml`, `.yml`, `.yaml`, `.json`

## Platform Requirements

**Development:**
- Julia 1.6+ (1.11 recommended for CI)
- Works on Windows, macOS, Linux
- No system-level dependencies

**Production:**
- Julia runtime only
- Deployed as Julia package via Pkg.add from GitHub
- No server/hosting infrastructure (library package)

---

## Package Details

**Package Identity:**
- Name: `DESSEM2Julia`
- UUID: `5b3a2f8f-9ef8-4a52-9f7b-2a6d29f86e1c`
- Version: `0.1.0`
- Repository: `https://github.com/Bittencourt/DESSEM2Julia.jl`

**Purpose:**
Parser for DESSEM (Brazilian power system hydrothermal dispatch optimization model) data files. Converts proprietary fixed-width text formats into structured Julia objects and persists them in JLD2 format.

**Supported DESSEM File Formats:**
- 32 parser modules for different DESSEM file types
- Fixed-width text parsing (primary format)
- Binary file parsing (HIDR.DAT, DECOMP integration files)
- Semicolon-delimited parsing (RENOVAVEIS.DAT - exception)

---

*Stack analysis: 2026-02-18*
