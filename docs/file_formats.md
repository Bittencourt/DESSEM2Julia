# File formats coverage

> **📚 Part of**: [DESSEM2Julia Documentation](INDEX.md) | **📖 Also see**: [DESSEM Complete Specs](dessem-complete-specs.md), [Entity Relationships](ENTITY_RELATIONSHIPS.md), [Format Notes](FORMAT_NOTES.md)

This document tracks DESSEM input files and their parsing coverage.

For detailed format specifications, see [dessem-complete-specs.md](dessem-complete-specs.md).

For entity relationships (database-like model), see [ENTITY_RELATIONSHIPS.md](ENTITY_RELATIONSHIPS.md) 🔗.

## Core Input Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| DESSEM.ARQ | Index file with case configuration | ✅ Parser | § 2 |
| DADVAZ.XXX | Case information and natural inflows | ✅ Parser | § 3 |
| ENTDADOS.XXX | General data file (30+ record types: TM, SIST, UH, UT, DP, DA, MH, MT, RE, LU, FH, FT, FI, FE, FR, FC, TX, EZ, R11, FP, SECR, CR, AC, AG) | ✅ Parser | § 4 |
| **SIMUL.XXX** | **Simulation data (DISC, VOLI, OPER blocks)** | **⚠️ LEGACY** | **§ 5** |

> **Note on SIMUL.XXX**: File marked "(F)" (Fixed/not used) in modern DESSEM cases. Not present in ONS/CCEE production samples. IDESEM reference implementation does not parse this file (only registry entry exists). Parser maintained for legacy compatibility only, cannot be validated against real data.

## Plant Registry Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| HIDR.DAT | Hydroelectric plant registry (CADUSIH, USITVIAG, POLCOT, POLARE, POLJUS, COEFEVA, CADCONJ records) | ✅ Binary & Text Parsers | § 6 |
| TERM.DAT | Thermal plant registry (CADUSIT, CADUNIDT, CURVACOMB, CONFGEST records) | ✅ Parser | § 7 |

## Operational Data Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| OPERUH.XXX | Hydro plant operational constraints (REST, ELEM, LIM, VAR records) | ✅ Parser | § 8 |
| OPERUT.XXX | Thermal unit operational data (INIT, OPER, RAMP, CUSTO, RESTR blocks) | ✅ Parser | § 9 |
| PTOPER.DAT | Operating point / schedule definitions (PTOPER record) | ✅ Parser | § 9 |

## DECOMP Integration Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| MAPCUT.DEC | DECOMP cut mapping (binary) | ✅ Parser (Placeholder) | § 10 |
| CORTES.DEC | DECOMP Benders cuts (binary) | ✅ Parser (Placeholder) | § 10 |
| INFOFCF.DEC | Future cost function info (binary) | ✅ Parser (Placeholder) | § 10 |

## Electrical Network Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| DESSELET.XXX | Network data index | ✅ Parser | § 11 |
| leve.dat | Light load network case (ANAREDE format: DBAR, DLIN, DGLT blocks) | ⚠️ Not Implemented¹ | § 11 |
| media.dat | Medium load network case (ANAREDE format) | ⚠️ Not Implemented¹ | § 11 |
| pesada.dat | Heavy load network case (ANAREDE format) | ⚠️ Not Implemented¹ | § 11 |

> **¹ Note on ANAREDE Files**: These are ANAREDE-format binary power flow files. DESSELET.XXX parser extracts network case references. Full ANAREDE binary parsing is outside the scope of DESSEM file parsing (these are input files to ANAREDE, not DESSEM native format). Network topology extraction from PDO output files is implemented via `network_topology.jl`.

## Optional Constraint Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| AREACONT.DAT | Control area definition | ✅ Parser | § 12 |
| RESPOT.XXX | Power reserve constraints (RP: pools, LM: limits) | ✅ Parser | § 12 |
| RESPOTELE.DAT | Electrical reserve constraints (RP: pools, LM: limits) | ✅ Parser | § 12 |
| RESTSEG.XXX | Dynamic security constraints | ✅ Parser | § 12 |
| RSTLPP.XXX | Linear piecewise security constraints | ✅ Parser | § 12 |
| RMPFLX.DAT | Flow ramp constraints | ✅ Parser | § 12 |

## Renewable Energy Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| RENOVAVEIS.DAT | Renewable plant data and forecasts (EOLICA, EOLICASUBM, EOLICABARRA, EOLICA-GERACAO) | ✅ Parser | § 13 |
| EOLICA.XXX | Legacy wind plant format (superseded by RENOVAVEIS.DAT) | N/A | § 13 |
| SOLAR.XXX | Solar plant data and forecasts | ✅ Parser (via RENOVAVEIS) | § 13 |
| BATERIA.XXX | Battery storage characteristics and operation | TODO | § 13 |

## Auxiliary Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| MLT.DAT | Long-term average flows (monthly) | ✅ Parser (Placeholder) | § 14 |
| DEFLANT.XXX | Previous outflows (for travel time) | ✅ Parser | § 14 |
| COTASR11.XXX | Itaipu R11 gauge data | ✅ Parser | § 14 |
| CURVTVIAG.DAT | Travel time curves | ✅ Parser | § 14 |
| ILSTRI.DAT | Ilha Solteira - Três Irmãos channel data | TODO | § 14 |
| RAMPAS.DAT | Thermal unit ramp trajectories | ✅ Parser | § 14 |
| TOLPERD.XXX | Loss tolerance parameters | TODO | § 14 |
| RIVAR.DAT | Soft variation constraints | ✅ Parser (via ENTDADOS) | § 14 |
| MODIF.DAT | Modifications | ✅ Parser (Placeholder) | § 14 |

## Files That Do Not Exist in Modern DESSEM

The following files have been referenced in historical documentation but **do not exist in current DESSEM versions**:

| File | Reason | Evidence | See Also |
|------|--------|----------|----------|
| **CONFHD.DAT** | Hydro configuration (hypothetical) | ❌ Not in IDESEM<br>❌ No samples<br>✅ Data in other files | [Investigation](parsers/CONFHD_INVESTIGATION.md) |
| **SIMUL.XXX** | Simulation data (legacy) | ⚠️ IDESEM registry only<br>❌ No samples<br>📝 Parser exists | [Status](parsers/SIMUL_STATUS.md) |

**Note**: Hydro configuration data is fully covered by existing parsers:
- **HIDR.DAT** - Plant characteristics (binary format)
- **ENTDADOS.DAT** - UH/FH/MH records (text format)
- **OPERUH.DAT** - Operational constraints
- **DEFLANT.DAT** - Initial conditions
- **DADVAZ.DAT** - Inflow forecasts

## Future Work & Refinement (November 2025)

With most core files implemented, remaining work focuses on refining placeholders and implementing low-priority auxiliary files.

### Binary Decoding (Refinement)

The following files have placeholder parsers that read raw bytes. Full decoding logic is pending specification or need:
- `MAPCUT.DEC` – DECOMP cut mapping.
- `CORTES.DEC` – DECOMP Benders cuts.
- `INFOFCF.DEC` – Future cost function information.

### Missing Auxiliary Parsers

The following files are recognized in the registry but lack parsers (low priority / no sample data):
- `BATERIA.XXX` – Battery storage characteristics and operation.
- `ILSTRI.DAT` – Ilha Solteira–Três Irmãos channel data (placeholder exists).
- `TOLPERD.XXX` – Loss tolerance parameters (placeholder exists).
- `METAS.DAT` – Target restrictions (placeholder exists).

### Binary File Placeholders

These files use proprietary binary formats not documented in IDESEM or public sources:

- `MLT.DAT` – **Binary** FPHA data (stores raw bytes, 15KB typical).
- `INFOFCF.DEC` – Binary FCF cut information from DECOMP (stores raw bytes).
- `MAPCUT.DEC` – Binary cut mapping header from DECOMP (stores raw bytes).
- `CORTES.DEC` – Binary FCF cuts from DECOMP (stores raw bytes).

### Text File Placeholders

These files have unknown formats with no sample data available:

- `MODIF.DAT` – Runtime case modifications (stores raw lines).

For a historical view of earlier priority phases and how we arrived here, see `docs/planning/PROJECT_CONTEXT.md` and `docs/planning/TASKS.md`.

## Model Capacity Reference

From DESSEM User Manual v19.0.24.3 (see § 15 in specs):

| Limit | Value | Description |
|-------|-------|-------------|
| ZUSIH | 220 | Maximum hydroelectric plants |
| ZUSIT | 150 | Maximum thermal plants |
| ZDIAS | 14 | Maximum study days |
| ZPAT | 48 | Maximum periods per day |
| ZUNH | 750 | Maximum hydro units |
| ZUNT | 450 | Maximum thermal units |
| ZSIS | 10 | Maximum subsystems |
| ZBUS | 9500 | Maximum buses |
| ZLIN | 13000 | Maximum transmission lines |
| ZEOL | 2000 | Maximum wind plants |

See complete specs for full capacity limit reference.
