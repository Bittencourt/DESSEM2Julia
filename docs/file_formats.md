# File formats coverage

This document tracks DESSEM input files and their parsing coverage.

For detailed format specifications, see [dessem-complete-specs.md](dessem-complete-specs.md).

## Core Input Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| DESSEM.ARQ | Index file with case configuration | TODO | § 2 |
| DADVAZ.XXX | Case information and natural inflows | ✅ Parser | § 3 |
| ENTDADOS.XXX | General data file (TM, SIST, UH, UT, DP, IA, CD, VR, RD, PD records) | TODO | § 4 |
| SIMUL.XXX | Simulation data (DISC, VOLI, OPER blocks) | TODO | § 5 |

## Plant Registry Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| HIDR.DAT | Hydroelectric plant registry (CADUSIH, USITVIAG, POLCOT, POLARE, POLJUS, COEFEVA, CADCONJ records) | TODO | § 6 |
| TERM.DAT | Thermal plant registry (CADUSIT, CADUNIDT, CURVACOMB, CONFGEST records) | TODO | § 7 |

## Operational Data Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| OPERUH.XXX | Hydro plant operational constraints (REST, LIM, VAR records) | TODO | § 8 |
| OPERUT.XXX | Thermal unit operational data (INIT, OPER, RAMP, CUSTO, RESTR blocks) | TODO | § 9 |

## DECOMP Integration Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| MAPCUT.DEC | DECOMP cut mapping (binary) | TODO | § 10 |
| CORTES.DEC | DECOMP Benders cuts (binary) | TODO | § 10 |
| INFOFCF.DEC | Future cost function info (binary) | TODO | § 10 |

## Electrical Network Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| DESSELET.XXX | Network data index | TODO | § 11 |
| leve.dat | Light load network case (ANAREDE format: DBAR, DLIN, DGLT blocks) | TODO | § 11 |
| media.dat | Medium load network case (ANAREDE format) | TODO | § 11 |
| pesada.dat | Heavy load network case (ANAREDE format) | TODO | § 11 |

## Optional Constraint Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| AREACONT.DAT | Control area definition | TODO | § 12 |
| RESPOT.XXX | Power reserve constraints | TODO | § 12 |
| RESTSEG.XXX | Dynamic security constraints | TODO | § 12 |
| RSTLPP.XXX | Linear piecewise security constraints | TODO | § 12 |

## Renewable Energy Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| EOLICA.XXX | Wind plant data and forecasts | TODO | § 13 |
| SOLAR.XXX | Solar plant data and forecasts | TODO | § 13 |
| BATERIA.XXX | Battery storage characteristics and operation | TODO | § 13 |

## Auxiliary Files

| File | Description | Status | Spec Section |
|------|-------------|--------|--------------|
| MLT.DAT | Long-term average flows (monthly) | TODO | § 14 |
| DEFLANT.XXX | Previous outflows (for travel time) | TODO | § 14 |
| COTASR11.XXX | Itaipu R11 gauge data | TODO | § 14 |
| CURVTVIAG.DAT | Travel time curves | TODO | § 14 |
| ILSTRI.DAT | Ilha Solteira - Três Irmãos channel data | TODO | § 14 |
| RAMPAS.DAT | Thermal unit ramp trajectories | TODO | § 14 |
| TOLPERD.XXX | Loss tolerance parameters | TODO | § 14 |
| RIVAR.DAT | Soft variation constraints | TODO | § 14 |

## Implementation Priority

Priority order for parser implementation based on complexity and dependencies:

### Phase 1: Simple Registry Files
**Goal**: Establish fixed-format parsing patterns
- [ ] **HIDR.DAT** - Hydroelectric plant registry (multiple record types, good learning case)
- [ ] **TERM.DAT** - Thermal plant registry (similar structure to HIDR.DAT)
- [ ] **AREACONT.DAT** - Control areas (simple fixed format)

### Phase 2: Core Configuration Files
**Goal**: Parse main system configuration
- [ ] **DESSEM.ARQ** - Index file (simple key-value format)
- [ ] **ENTDADOS.XXX** - General data (multiple record types: TM, SIST, UH, UT, DP, IA, CD, VR, RD, PD)
- [ ] **DADVAZ.XXX** - Case info and inflows (header + data section)
- [ ] **SIMUL.XXX** - Simulation data (block structure)

### Phase 3: Operational Constraints
**Goal**: Handle time-varying operational data
- [ ] **OPERUH.XXX** - Hydro constraints (REST, LIM, VAR records)
- [ ] **OPERUT.XXX** - Thermal operations (INIT, OPER blocks)
- [ ] **RESPOT.XXX** - Reserve requirements (time-varying)

### Phase 4: Electrical Network
**Goal**: Parse ANAREDE format network files
- [ ] **DESSELET.XXX** - Network index (references to case files)
- [ ] **Network cases** (leve.dat, media.dat, pesada.dat) - DBAR, DLIN, DGLT blocks

### Phase 5: Renewable & Auxiliary
**Goal**: Complete file coverage
- [ ] **EOLICA.XXX** - Wind generation
- [ ] **SOLAR.XXX** - Solar generation
- [ ] **BATERIA.XXX** - Battery storage
- [ ] **MLT.DAT** - Long-term flows
- [ ] **DEFLANT.XXX** - Previous outflows
- [ ] **CURVTVIAG.DAT** - Travel time curves
- [ ] Other auxiliary files

### Phase 6: Advanced Constraints & Integration
**Goal**: Handle complex/binary formats
- [ ] **MAPCUT.DEC** - DECOMP mapping (binary)
- [ ] **CORTES.DEC** - Benders cuts (binary)
- [ ] **INFOFCF.DEC** - FCF info (binary)
- [ ] **RESTSEG.XXX** - Security constraints (tabular)
- [ ] **RSTLPP.XXX** - Piecewise constraints

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
