# External Integrations

**Analysis Date:** 2026-02-18

## Overview

**This is a standalone data parsing library with no external service integrations.**

DESSEM2Julia is a pure Julia package that reads local DESSEM format files and writes to JLD2 files. It has no runtime dependencies on external APIs, databases, or cloud services.

---

## APIs & External Services

**None.** This package:
- Does not call external REST APIs
- Does not use SDKs for cloud services (AWS, GCP, Azure)
- Does not integrate with payment providers
- Does not send webhooks or callbacks

## Data Storage

**Databases:**
- None. No database connections (PostgreSQL, MySQL, MongoDB, etc.)

**File Storage:**
- Local filesystem only
- Input: DESSEM format files (`.DAT`, `.DEC`, `.ARQ`, `.RV0`, `.RV2`)
- Output: JLD2 files (`.jld2`) via `src/io.jl`
  - `save_jld2(path, data)` - Serialize DessemData to HDF5-based format
  - `load_jld2(path)` - Deserialize DessemData from JLD2

**Caching:**
- None. No Redis, Memcached, or similar caching layer

## Authentication & Identity

**Auth Provider:**
- Not applicable (no authentication required)
- Package is a library, not an application with users

## Monitoring & Observability

**Error Tracking:**
- None configured (no Sentry, Rollbar, etc.)

**Logs:**
- `@warn` macro used in `src/DESSEM2Julia.jl` for optional PWF parser loading failure
- Standard Julia logging only; no structured logging frameworks

## CI/CD & Deployment

**Hosting:**
- GitHub repository: `https://github.com/Bittencourt/DESSEM2Julia.jl`
- Deployed as Julia package via Pkg.add (no server deployment)

**CI Pipeline:**
- GitHub Actions (`.github/workflows/ci.yml`)
  - Triggers: Push to main/dev/feat/*, PRs to main/dev
  - Jobs:
    1. **Lint** - JuliaFormatter check on ubuntu-latest, Julia 1.11
    2. **Test** - Full test suite on ubuntu-latest and windows-latest, Julia 1.11
  - Uses: `julia-actions/setup-julia@v2`, `julia-actions/julia-processcoverage@v1`
  - Code coverage: `codecov/codecov-action@v4`

**Release Pipeline:**
- GitHub Actions (`.github/workflows/release.yml`)
  - Triggers: Git tags matching `v*`
  - Creates GitHub releases with auto-generated notes
  - Runs full test suite before release

**Pre-commit Hooks:**
- Git hooks in `.githooks/`
- Setup script: `scripts/setup-hooks.ps1` (PowerShell)
- Runs `Pkg.test()` before commits

## Environment Configuration

**Required env vars:**
- None for package usage
- `CODECOV_TOKEN` - Required in CI secrets for codecov upload

**Secrets location:**
- GitHub repository secrets (CODECOV_TOKEN only)

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

---

## Data Sources

**DESSEM Data Files (Input):**
- Format: Proprietary Brazilian power system model files
- Sources:
  - CCEE (Câmara de Comercialização de Energia Elétrica) - Sample: `DS_CCEE_102025_SEMREDE_RV0D28`
  - ONS (Operador Nacional do Sistema Elétrico) - Sample: `DS_ONS_102025_RV2D11`
- Location: Local filesystem, typically `docs/Sample/` (gitignored due to size)
- Not fetched via API; must be provided by user

**File Types Parsed:**
| Category | Files | Parser Module |
|----------|-------|---------------|
| Core | `dessem.arq`, `termdat.dat`, `entdados.dat` | `src/parser/dessemarq.jl`, etc. |
| Hydro | `hidr.dat`, `operuh.dat`, `dadvaz.dat` | `src/parser/hidr.jl`, etc. |
| Thermal | `operut.dat`, `ptoper.dat` | `src/parser/operut.jl`, etc. |
| Network | `desselet.dat`, network topology | `src/parser/desselet.jl`, etc. |
| Constraints | `restseg.dat`, `rstlpp.dat`, `rampas.dat` | `src/parser/restseg.jl`, etc. |
| Renewables | `renovaveis.dat` | `src/parser/renovaveis.jl` |
| DECOMP Integration | `cortdeco.rv0`, `cortdeco.rv2`, `infofcf.dec` | `src/parser/cortdeco.jl`, etc. |

---

## Optional Dependencies

**PWF.jl (Optional):**
- External Julia package for PWF file parsing
- Dynamically loaded at runtime if available:
  ```julia
  # In src/DESSEM2Julia.jl
  pwf_available = try
      Base.require(Base.PkgId(Base.UUID("a8ba2b29-9f20-5e9c-a0e4-6cf9a9c686e9"), "PWF"))
      true
  catch
      false
  end
  ```
- Not listed in `Project.toml` dependencies
- Gracefully falls back if unavailable

---

*Integration audit: 2026-02-18*
