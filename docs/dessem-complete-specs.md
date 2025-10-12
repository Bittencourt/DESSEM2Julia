# DESSEM Complete Input File Specifications

This document provides comprehensive field-level descriptions for all DESSEM input files based on the official manual version 19.0.24.3.

## Table of Contents
1. [File Format Conventions](#file-format-conventions)
2. [Index File (DESSEM.ARQ)](#index-file-dessemarq)
3. [Case Information (DADVAZ.XXX)](#case-information-dadvazxxx)
4. [General Data File (ENTDADOS.XXX)](#general-data-file-entdadosxxx)
5. [Simulation Data (SIMUL.XXX)](#simulation-data-simulxxx)
6. [Hydroelectric Plant Registry (HIDR.DAT)](#hydroelectric-plant-registry-hidrdat)
7. [Thermal Plant Registry (TERM.DAT)](#thermal-plant-registry-termdat)
8. [Hydro Operational Constraints (OPERUH.XXX)](#hydro-operational-constraints-operuhxxx)
9. [Thermal Operational Data (OPERUT.XXX)](#thermal-operational-data-operutxxx)
10. [DECOMP Integration Files](#decomp-integration-files)
11. [Electrical Network Files](#electrical-network-files)
12. [Optional Constraint Files](#optional-constraint-files)
13. [Renewable Energy Files](#renewable-energy-files)
14. [Auxiliary Files](#auxiliary-files)

## File Format Conventions

### General Format Rules
- **Fixed-format columns** - NO TABS allowed, use spaces only
- **Comment lines** start with `*` (electrical network files use `C`)
- **Field formats**: 
  - `IX` = integer with X digits
  - `FX.Y` = float with X total digits, Y decimal places
  - `AX` = text with X characters
- **Data Identifier (DI)** fields use day/hour/half-hour format
- **Special DI values**: `I` = study start, `F` = study end

### Time Data Format
- **Day**: Calendar day number
- **Hour**: 24-hour format (0-23)  
- **Half-hour flag**: 0 = first half-hour, 1 = second half-hour

---

## Index File (DESSEM.ARQ)

**Purpose**: Contains case identification and references to all input files

**Format**: Fixed-format text with three fields per line

### Field Specifications

| Column | Format | Required | Description | Valid Values |
|--------|--------|----------|-------------|--------------|
| 1-9 | A9 | ✓ | File type mnemonic | CASO, TITULO, DADGER, etc. |
| 10-49 | A40 | | Description field | Free text |
| 50-129 | A80 | ✓ | Case name or file path | Path/filename |

### Mnemonic Reference Table

| Mnemonic | File Type | Section |
|----------|-----------|---------|
| CASO | Case name | - |
| TITULO | Case title | - |
| DADGER | General data file | III.4 |
| VAZOES | Case info and flows | III.2 |
| CADUSIH | Hydro plant registry | III.6 |
| CADTERM | Thermal plant registry | III.8.5 |
| OPERUH | Hydro constraints | III.8 |
| OPERUT | Thermal operations | III.10 |
| MAPFCF | DECOMP cut mapping | III.5.1 |
| CORTFCF | DECOMP cuts | III.5.3 |
| INDELET | Network index | III.12 |
| AREACONT | Control areas | III.11.1 |
| RESPOT | Power reserves | III.11.2 |
| SIMUL | Simulation data | III.3 |
| MLT | Long-term flows | III.17 |
| DEFLANT | Previous outflows | III.15 |
| COTASR11 | Itaipu R11 data | III.14 |
| CURVTVIAG | Travel time curves | III.16 |
| ILSTRI | IS-TI channel data | III.13 |
| RAMPAS | Thermal ramp data | III.23 |
| TOLPERD | Loss tolerances | III.18 |
| RESTSEG | Security constraints | III.19 |
| RMPFLX | Network ramp constraints | III.20 |
| RSTLPP | Linear piecewise constraints | III.20 |
| RESPOTELE | Network reserve constraints | III.22 |
| EOLICA | Wind plant data | III.24 |
| SOLAR | Solar plant data | III.25 |
| BATERIA | Battery storage data | III.26 |
| RIVAR | Soft variation constraints | - |
| VERSDECO | DECOMP version | - |

**Example**:
```
CASO     Case Study Name                    XXX
TITULO   DESSEM Case - January 2024         Daily Operation Planning  
DADGER   General Data File                  ENTDADOS.XXX
VAZOES   Flow Data File                     DADVAZ.XXX
```

---

## Case Information (DADVAZ.XXX)

**Purpose**: Contains case information and natural inflow data for hydroelectric plants

**Format**: Fixed-format text with header section followed by inflow data

### Header Section

**Records 1-9**: Free-form headers (user-defined)

**Record 10: Study Start Date**

| Column | Format | Required | Description | Valid Values |
|--------|--------|----------|-------------|--------------|
| 1-2 | I2 | ✓ | Start hour | 0-23 |
| 5-6 | I2 | ✓ | Start day | 1-31 |
| 9-10 | I2 | ✓ | Start month | 1-12 |
| 13-16 | I4 | ✓ | Start year | e.g., 2024 |

**Records 11-12**: Headers (user-defined)

**Record 13: Study Configuration**

| Column | Format | Required | Description | Valid Values |
|--------|--------|----------|-------------|--------------|
| 1 | I1 | ✓ | Initial day code | 1=Saturday, 2=Sunday, ..., 7=Friday |
| 3 | I1 | ✓ | FCF week index | 1-6 |
| 5 | I1 | ✓ | Study weeks count | Excluding simulation period |
| 7 | I1 | | Simulation flag | 0=no simulation, 1=with simulation |

**Records 14-16**: Headers (user-defined)

### Inflow Data Section (Record 17 onwards)

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-3 | I3 | ✓ | Plant number | Per hydro registry | - |
| 5-16 | A12 | ✓ | Plant name | Text identifier | - |
| 20 | I1 | ✓ | Inflow type | 1=incremental, 2=total, 3=regularized | - |
| 25-26 | I2 | ✓ | Initial day | Calendar day | - |
| 28-29 | I2 | | Initial hour | 0-23 | 0 |
| 31 | I1 | | Initial half-hour | 0 or 1 | 0 |
| 33-34 | I2 | ✓ | Final day | Calendar day | - |
| 36-37 | I2 | | Final hour | 0-23 | 0 |
| 39 | I1 | | Final half-hour | 0 or 1 | 0 |
| 45-53 | F9.0 | ✓ | Inflow rate (m³/s) | ≥ 0 | - |

**Special Notes**:
- Regularized flow (type 3) should be used when flow already considers upstream plant outflows
- Time periods can use `I` for study start, `F` for study end

---

## General Data File (ENTDADOS.XXX)

**Purpose**: Main configuration file containing system components, temporal discretization, and operational data

**Format**: Multiple record types identified by 2-character mnemonics

### TM Records - Time Discretization

**Purpose**: Define time periods for programming horizon

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-2 | A2 | ✓ | Record type | "TM" | - |
| 5-6 | I2 | ✓ | Day number | Calendar day | - |
| 10-11 | I2 | ✓ | Hour | 0-23 | - |
| 15 | I1 | | Half-hour flag | 0 or 1 | 0 |
| 20-24 | F5.0 | | Period duration (hours) | ≥ 0.5 | 1.0 |
| 30 | I1 | ✓ | Network flag | 0=no network, 1=network no losses, 2=network with losses | - |
| 34-39 | A6 | | Load level name | "leve", "media", "pesada" | blank |

### SIST Records - Subsystem Definition

**Purpose**: Define electrical subsystems (markets)

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-4 | A4 | ✓ | Record type | "SIST" | - |
| 8-9 | I2 | ✓ | Subsystem number | 1-99 | - |
| 11-12 | A2 | ✓ | Subsystem mnemonic | Unique code | - |

### UH Records - Hydroelectric Plant Configuration

**Purpose**: Define hydroelectric plants in the system

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-2 | A2 | ✓ | Record type | "UH" | - |
| 5-7 | I3 | ✓ | Plant number | 1-320 | - |
| 10-21 | A12 | ✓ | Plant name | Text identifier | - |
| 25 | I1 | | Plant status | 0=existing, 1=under construction | 0 |
| 27 | I1 | | Subsystem number | Per SIST records | - |
| 30-34 | F5.0 | | Initial volume (% useful) | 0-100 | - |
| 36 | I1 | | Volume unit flag | 1=hm³, 2=% useful | 2 |
| 40-49 | F10.0 | | Minimum volume | ≥ 0 | - |
| 55-64 | F10.0 | | Maximum volume | > min volume | - |
| 70-79 | F10.0 | | Initial volume (absolute) | min ≤ value ≤ max | - |
| 85-94 | F10.0 | | Spillway crest volume | ≥ min volume | - |
| 100-109 | F10.0 | | Diversion crest volume | ≥ min volume | - |

### UT Records - Thermal Plant Configuration

**Purpose**: Define thermal plants and their basic characteristics

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-2 | A2 | ✓ | Record type | "UT" | - |
| 5-7 | I3 | ✓ | Plant number | 1-999 | - |
| 10-21 | A12 | ✓ | Plant name | Text identifier | - |
| 25 | I1 | | Plant status | 0=existing, 1=under construction | 0 |
| 30 | I1 | ✓ | Subsystem number | Per SIST records | - |
| 35-39 | I5 | | Number of units | ≥ 1 | 1 |
| 45-54 | F10.0 | ✓ | Installed capacity (MW) | > 0 | - |
| 60-69 | F10.0 | | Minimum generation (MW) | ≥ 0 | 0 |
| 75-84 | F10.0 | | Operating cost (R$/MWh) | ≥ 0 | 0 |
| 90-99 | F10.0 | | Maximum ramp (MW/h) | ≥ 0 | No limit |

### DP Records - Demand Data

**Purpose**: Define electrical demand by subsystem and time period

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-2 | A2 | ✓ | Record type | "DP" | - |
| 5 | I1 | ✓ | Subsystem number | Per SIST records | - |
| 10-11 | I2 | ✓ | Initial day | Calendar day | - |
| 13-14 | I2 | | Initial hour | 0-23 | 0 |
| 16 | I1 | | Initial half-hour | 0 or 1 | 0 |
| 18-19 | I2 | ✓ | Final day | Calendar day or "F" | - |
| 21-22 | I2 | | Final hour | 0-23 | 0 |
| 24 | I1 | | Final half-hour | 0 or 1 | 0 |
| 30-39 | F10.0 | ✓ | Demand (MW) | ≥ 0 | - |

### IA Records - Interchange Limits

**Purpose**: Define transmission limits between subsystems

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-2 | A2 | ✓ | Record type | "IA" | - |
| 5 | I1 | ✓ | From subsystem | Per SIST records | - |
| 7 | I1 | ✓ | To subsystem | Per SIST records | - |
| 10-11 | I2 | ✓ | Initial day | Calendar day | - |
| 13-14 | I2 | | Initial hour | 0-23 | 0 |
| 16 | I1 | | Initial half-hour | 0 or 1 | 0 |
| 18-19 | I2 | ✓ | Final day | Calendar day or "F" | - |
| 21-22 | I2 | | Final hour | 0-23 | 0 |
| 24 | I1 | | Final half-hour | 0 or 1 | 0 |
| 30-39 | F10.0 | ✓ | Interchange limit (MW) | ≥ 0 | - |

### CD Records - Deficit Cost Curves

**Purpose**: Define load curtailment cost by depth

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-2 | A2 | ✓ | Record type | "CD" | - |
| 5 | I1 | ✓ | Subsystem number | Per SIST records | - |
| 10-19 | F10.0 | ✓ | Deficit depth (MW) | ≥ 0 | - |
| 25-34 | F10.0 | ✓ | Deficit cost (R$/MWh) | ≥ 0 | - |

### VR Records - Daylight Saving Time

**Purpose**: Handle daylight saving time transitions

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-2 | A2 | ✓ | Record type | "VR" | - |
| 5-6 | I2 | ✓ | Transition day | Calendar day | - |
| 10-12 | A3 | ✓ | Transition type | "INI" or "FIM" | - |

### RD Records - Network Options

**Purpose**: Configure electrical network modeling options

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-2 | A2 | ✓ | Record type | "RD" | - |
| 5 | I1 | | Slack variables flag | 0=no slack, 1=use slack | 1 |
| 9-12 | I4 | | Max violations per period | 0-ZFLGRD | 1500 |
| 15 | I1 | | No-network with bus loads | 0=DP loads, 1=bus loads | 0 |
| 17 | I1 | | Free transformer flows | 0=constrained, 1=free | 0 |
| 19 | I1 | | Free all flows | 0=constrained, 1=circuits, 2=all | 0 |
| 21 | I1 | | Loss calculation control | 0=all lines, 1=per DLIN/DGBT | 0 |
| 23 | I1 | | Bus numbering format | 0=5-digit, 1=4-digit | 0 |

### PD Records - Loss Tolerance

**Purpose**: Set tolerance for transmission loss representation

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-2 | A2 | ✓ | Record type | "PD" | - |
| 4-9 | F6.0 | | Percentage tolerance | ≥ 0.1 | 0.1 |
| 13-22 | F10.0 | | MW tolerance | ≥ 0.000001 | 0.000001 |

### Additional Record Types

**VE Records - Reservoir Flood Control**
- Define flood control volumes for reservoirs
- Time-varying operational volumes

**MH Records - Hydro Unit Maintenance**
- Scheduled maintenance for hydroelectric units
- Unit unavailability periods

**MT Records - Thermal Unit Maintenance**  
- Scheduled maintenance for thermal units
- Unit unavailability periods

**ME Records - Pumping Unit Maintenance**
- Scheduled maintenance for pumping stations
- Unit unavailability periods

**RE Records - Special Electrical Restrictions**
- Additional linear constraints on system operation
- Multi-plant or multi-subsystem constraints

**META Records - Weekly Targets**
- Weekly generation targets for thermal plants
- DECOMP coupling parameters

---

## Simulation Data (SIMUL.XXX)

**Purpose**: Contains data for simulation module execution

**Format**: Header followed by four main blocks: DISC, VOLI, OPER

### Header Section

**Records 1-2**: User-defined headers

**Record 3: Simulation Start**

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 5-6 | I2 | ✓ | Start day | Calendar day | - |
| 8-9 | I2 | | Start hour | 0-23 | 0 |
| 11 | I1 | | Start half-hour | 0 or 1 | 0 |
| 14-15 | I2 | ✓ | Start month | 1-12 | - |
| 18-21 | I4 | ✓ | Start year | e.g., 2024 | - |
| 23 | I1 | | OPERUH constraints flag | 0=exclude, 1=include | - |

### DISC Block - Time Discretization

**Block Identifier**: "DISC" in columns 1-4, terminated by "FIM" in columns 1-3

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 5-6 | I2 | ✓ | Day number | Calendar day | - |
| 8-9 | I2 | | Hour | 0-23 | 0 |
| 11 | I1 | | Half-hour flag | 0 or 1 | 0 |
| 15-19 | F5.0 | ✓ | Period duration (hours) | ≥ 0.0 | 0 |
| 21 | I1 | | Period constraints flag | 0=exclude, 1=include | - |

### VOLI Block - Initial Reservoir Volumes

**Block Identifier**: "VOLI" in columns 1-4, terminated by "FIM" in columns 1-3

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 5-7 | I3 | ✓ | Plant number | Per hydro registry | - |
| 10-21 | A12 | | Plant name | Reference only | - |
| 25-34 | F10.0 | ✓ | Initial volume (% useful) | 0-100 | - |

### OPER Block - Simulation Operation Data

**Block Identifier**: "OPER" in columns 1-5, terminated by "FIM" in columns 1-3

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 5-7 | I3 | ✓ | Plant number | Per registry | - |
| 8 | A1 | | Plant type | "H"=hydro, "E"=pumping | "H" |
| 10-22 | A12 | | Plant name | Reference only | - |
| 24-25 | I2 | ✓ | Initial day | Calendar day | - |
| 27-28 | I2 | | Initial hour | 0-23 | 0 |
| 30 | I1 | | Initial half-hour | 0 or 1 | 0 |
| 32-33 | I2 | ✓ | Final day | Calendar day | - |
| 35-36 | I2 | | Final hour | 0-23 | 0 |
| 38 | I1 | | Final half-hour | 0 or 1 | 0 |
| 40 | I1 | ✓ | Natural flow type | 1=incremental, 2=total | - |
| 42-51 | F10.0 | ✓ | Natural inflow (m³/s) | ≥ 0 | - |
| 53 | I1 | | Withdrawal type | 1=incremental, 2=total | - |
| 55-64 | F10.0 | | Withdrawal flow (m³/s) | ≥ 0 | 0 |
| 65-74 | F10.0 | | Generation target (MW) | ≥ 0 | - |

---

## Hydroelectric Plant Registry (HIDR.DAT)

**Purpose**: Complete hydroelectric plant characteristics and parameters

**Format**: Multiple record types for comprehensive plant definition

### CADUSIH Records - Basic Plant Data

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-7 | A7 | ✓ | Record type | "CADUSIH" | - |
| 9-11 | I3 | ✓ | Plant number | 1-320 | - |
| 13-24 | A12 | ✓ | Plant name | Text identifier | - |
| 26-27 | I2 | ✓ | Subsystem number | Per SIST records | - |
| 29-32 | I4 | | Commission year | e.g., 2024 | - |
| 34-35 | I2 | | Commission month | 1-12 | - |
| 37-38 | I2 | | Commission day | 1-31 | - |
| 40-41 | I2 | | Downstream plant | Plant number or 0 | 0 |
| 43-44 | I2 | | Diversion downstream | Plant number or 0 | 0 |
| 46 | I1 | | Plant type | Various codes | 0 |
| 48-57 | F10.0 | | Minimum volume (hm³) | ≥ 0 | 0 |
| 59-68 | F10.0 | ✓ | Maximum volume (hm³) | > min volume | - |
| 70-79 | F10.0 | | Maximum turbine flow (m³/s) | > 0 | - |
| 81-90 | F10.0 | | Installed capacity (MW) | > 0 | - |
| 92-101 | F10.0 | | Productivity (MW/(m³/s)/m) | > 0 | - |

### USITVIAG Records - Travel Time Data

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-8 | A8 | ✓ | Record type | "USITVIAG" | - |
| 10-12 | I3 | ✓ | Plant number | Per registry | - |
| 14-15 | I2 | | Downstream plant | Plant number | - |
| 17-21 | F5.0 | | Travel time (hours) | ≥ 0 | 0 |

### POLCOT Records - Volume-Elevation Polynomials

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-6 | A6 | ✓ | Record type | "POLCOT" | - |
| 8-10 | I3 | ✓ | Plant number | Per registry | - |
| 12-13 | I2 | ✓ | Polynomial degree | 1-5 | - |
| 15-24 | F10.0 | ✓ | Coefficient 0 | Any value | - |
| 26-35 | F10.0 | | Coefficient 1 | Any value | 0 |
| 37-46 | F10.0 | | Coefficient 2 | Any value | 0 |
| 48-57 | F10.0 | | Coefficient 3 | Any value | 0 |
| 59-68 | F10.0 | | Coefficient 4 | Any value | 0 |
| 70-79 | F10.0 | | Coefficient 5 | Any value | 0 |

### POLARE Records - Volume-Surface Area Polynomials

**Format**: Same as POLCOT records but for area calculation

### POLJUS Records - Tailrace Elevation Polynomials

**Format**: Same as POLCOT records but for tailrace level calculation

### COEFEVA Records - Evaporation Coefficients

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-7 | A7 | ✓ | Record type | "COEFEVA" | - |
| 9-11 | I3 | ✓ | Plant number | Per registry | - |
| 13-17 | F5.0 | | January coeff | ≥ 0 | 0 |
| 19-23 | F5.0 | | February coeff | ≥ 0 | 0 |
| 25-29 | F5.0 | | March coeff | ≥ 0 | 0 |
| 31-35 | F5.0 | | April coeff | ≥ 0 | 0 |
| 37-41 | F5.0 | | May coeff | ≥ 0 | 0 |
| 43-47 | F5.0 | | June coeff | ≥ 0 | 0 |
| 49-53 | F5.0 | | July coeff | ≥ 0 | 0 |
| 55-59 | F5.0 | | August coeff | ≥ 0 | 0 |
| 61-65 | F5.0 | | September coeff | ≥ 0 | 0 |
| 67-71 | F5.0 | | October coeff | ≥ 0 | 0 |
| 73-77 | F5.0 | | November coeff | ≥ 0 | 0 |
| 79-83 | F5.0 | | December coeff | ≥ 0 | 0 |

### CADCONJ Records - Unit Set Definition

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-7 | A7 | ✓ | Record type | "CADCONJ" | - |
| 9-11 | I3 | ✓ | Plant number | Per registry | - |
| 13-14 | I2 | ✓ | Unit set number | 1-5 | - |
| 16-17 | I2 | ✓ | Number of units | 1-20 | - |
| 19-28 | F10.0 | ✓ | Unit capacity (MW) | > 0 | - |
| 30-39 | F10.0 | | Minimum generation (MW) | ≥ 0 | 0 |
| 41-50 | F10.0 | | Maximum turbine flow (m³/s) | > 0 | - |

---

## Thermal Plant Registry (TERM.DAT)

**Purpose**: Complete thermal plant and unit characteristics

**Format**: Multiple record types for detailed thermal unit definition

### CADUSIT Records - Plant Information

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-7 | A7 | ✓ | Record type | "CADUSIT" | - |
| 9-11 | I3 | ✓ | Plant number | 1-999 | - |
| 13-24 | A12 | ✓ | Plant name | Text identifier | - |
| 26-27 | I2 | ✓ | Subsystem number | Per SIST records | - |
| 29-32 | I4 | | Commission year | e.g., 2024 | - |
| 34-35 | I2 | | Commission month | 1-12 | - |
| 37-38 | I2 | | Commission day | 1-31 | - |
| 40 | I1 | | Plant class | Various codes | 0 |
| 42 | I1 | | Fuel type | Various codes | 0 |
| 44-46 | I3 | ✓ | Number of units | 1-120 | - |
| 48-57 | F10.0 | | Heat rate (kJ/kWh) | > 0 | 0 |
| 59-63 | F5.0 | | Fuel cost (R$/unit) | ≥ 0 | 0 |

### CADUNIDT Records - Unit Characteristics

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-8 | A8 | ✓ | Record type | "CADUNIDT" | - |
| 10-12 | I3 | ✓ | Plant number | Per registry | - |
| 14-16 | I3 | ✓ | Unit number | 1-120 | - |
| 18-27 | A10 | | Unit name | Text identifier | - |
| 29-30 | I2 | | Commission year | Last 2 digits | - |
| 32-33 | I2 | | Commission month | 1-12 | - |
| 35-41 | F7.0 | ✓ | Unit capacity (MW) | > 0 | - |
| 43-49 | F7.0 | | Minimum generation (MW) | ≥ 0 | 0 |
| 51-55 | I5 | | Minimum on time (hours) | ≥ 0 | 0 |
| 57-61 | I5 | | Minimum off time (hours) | ≥ 0 | 0 |
| 63-72 | F10.0 | | Cold startup cost (R$) | ≥ 0 | 0 |
| 74-83 | F10.0 | | Hot startup cost (R$) | ≥ 0 | 0 |
| 85-94 | F10.0 | | Shutdown cost (R$) | ≥ 0 | 0 |
| 96-105 | F10.0 | | Ramp up rate (MW/h) | ≥ 0 | No limit |
| 107-116 | F10.0 | | Ramp down rate (MW/h) | ≥ 0 | No limit |

### CURVACOMB Records - Heat Rate Curves

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-9 | A9 | ✓ | Record type | "CURVACOMB" | - |
| 11-13 | I3 | ✓ | Plant number | Per registry | - |
| 15-17 | I3 | ✓ | Unit number | Per plant units | - |
| 19-23 | I5 | ✓ | Heat rate (kJ/kWh) | > 0 | - |
| 25-34 | F10.0 | ✓ | Generation point (MW) | 0 to unit capacity | - |

### Configuration Records

**CONFGEST Records** - Combined Cycle Configuration
- Define combined cycle plant operational modes
- Specify unit combinations and constraints

**RESTRICOES Records** - Unit Constraints
- Additional operational restrictions
- Interdependence between units

---

## Hydro Operational Constraints (OPERUH.XXX)

**Purpose**: Define time-varying operational constraints for hydroelectric plants

**Format**: Block structure with multiple constraint types

### Block Structure

Each constraint block starts with the constraint type identifier and ends with "FIM".

### REST Records - Constraint Definition

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-6 | A6 | ✓ | Block identifier | "OPERUH" | - |
| 8-12 | A5 | ✓ | Record type | "REST" | - |
| 14-18 | I5 | ✓ | Constraint ID | Unique identifier | - |
| 20-21 | I2 | ✓ | Variable code | See variable codes | - |
| 23-25 | I3 | ✓ | Plant number | Per hydro registry | - |
| 27-28 | I2 | | Unit set number | 1-5 | 0 |
| 30-39 | F10.0 | ✓ | Participation factor | Any value | - |

### Variable Codes Reference

| Code | Description | Units |
|------|-------------|-------|
| 1 | Turbined flow | m³/s |
| 2 | Stored volume | hm³ |
| 3 | Generation | MW |
| 4 | Spilled flow | m³/s |
| 5 | Diverted flow | m³/s |
| 11 | Final volume | hm³ |
| 12 | Pumped flow | m³/s |
| 13 | Pumping consumption | MW |
| 21 | Volume variation | hm³ |
| 65 | Water value | R$/hm³ |

### LIM Records - Operational Limits

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 8-12 | A5 | ✓ | Record type | "LIM" | - |
| 15-19 | I5 | ✓ | Constraint ID | Must match REST | - |
| 20-21 | I2 | ✓ | Initial day | Calendar day or "I" | - |
| 23-24 | I2 | | Initial hour | 0-23 | 0 |
| 26 | I1 | | Initial half-hour | 0 or 1 | 0 |
| 28-29 | I2 | ✓ | Final day | Calendar day or "F" | - |
| 31-32 | I2 | | Final hour | 0-23 | 0 |
| 34 | I1 | | Final half-hour | 0 or 1 | 0 |
| 38-47 | F10.0 | | Lower limit | ≥ 0 | -∞ |
| 48-57 | F10.0 | | Upper limit | ≥ lower limit | +∞ |

### VAR Records - Variation Constraints (Ramp Constraints)

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 8-12 | A5 | ✓ | Record type | "VAR" | - |
| 15-19 | I5 | ✓ | Constraint ID | Unique identifier | - |
| 20-21 | I2 | ✓ | Variable code | Per variable codes | - |
| 23-25 | I3 | ✓ | Plant number | Per hydro registry | - |
| 27-28 | I2 | | Unit set number | 1-5 | 0 |
| 30-39 | F10.0 | ✓ | Participation factor | Any value | - |
| 41-42 | I2 | ✓ | Initial day | Calendar day or "I" | - |
| 44-45 | I2 | | Initial hour | 0-23 | 0 |
| 47 | I1 | | Initial half-hour | 0 or 1 | 0 |
| 49-50 | I2 | ✓ | Final day | Calendar day or "F" | - |
| 52-53 | I2 | | Final hour | 0-23 | 0 |
| 55 | I1 | | Final half-hour | 0 or 1 | 0 |
| 59-68 | F10.0 | | Lower ramp limit | Any value | -∞ |
| 69-78 | F10.0 | | Upper ramp limit | ≥ lower limit | +∞ |

### Special Constraint Types

**Volume Constraints**
- Reservoir level management
- Flood control volumes
- Navigation requirements

**Generation Constraints**
- Power output limits
- Spinning reserve provision
- Environmental restrictions

**Flow Constraints**
- Minimum ecological flows
- Maximum turbine discharge
- Spillway operation rules

---

## Thermal Operational Data (OPERUT.XXX)

**Purpose**: Time-varying operational data and unit commitment for thermal plants

**Format**: Execution flags followed by multiple blocks

### Execution Flags

Before any data blocks, optional execution flags can be specified:

| Flag | Description |
|------|-------------|
| UCTERM | Enable unit commitment optimization |
| PERDITERINC | Generate detailed iteration reports |
| PINT | Use interior point method |
| ZERALIMUH | Zero hydro unit limits from UH file |

### INIT Block - Initial Conditions

**Block Identifier**: "INIT" terminated by "FIM"

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 5-7 | I3 | ✓ | Plant number | Per thermal registry | - |
| 10-12 | I3 | ✓ | Unit number | Per plant units | - |
| 15 | I1 | ✓ | Initial status | 0=off, 1=on | - |
| 17-21 | I5 | | Hours in current state | ≥ 0 | 0 |
| 23-32 | F10.0 | | Initial generation (MW) | 0 to unit capacity | 0 |

### OPER Block - Operating Costs and Limits

**Block Identifier**: "OPER" terminated by "FIM"

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 5-7 | I3 | ✓ | Plant number | Per thermal registry | - |
| 10-12 | I3 | ✓ | Unit number | Per plant units | - |
| 15-16 | I2 | ✓ | Initial day | Calendar day | - |
| 18-19 | I2 | | Initial hour | 0-23 | 0 |
| 21 | I1 | | Initial half-hour | 0 or 1 | 0 |
| 23-24 | I2 | ✓ | Final day | Calendar day or "F" | - |
| 26-27 | I2 | | Final hour | 0-23 | 0 |
| 29 | I1 | | Final half-hour | 0 or 1 | 0 |
| 35-44 | F10.0 | | Operating cost (R$/MWh) | ≥ 0 | 0 |
| 50-59 | F10.0 | | Maximum generation (MW) | 0 to unit capacity | Unit capacity |
| 65-74 | F10.0 | | Minimum generation (MW) | ≥ 0 | 0 |

### Additional Blocks

**RAMP Block** - Ramp Rate Constraints
- Define time-varying ramp limits
- Startup and shutdown trajectories

**CUSTO Block** - Cost Curve Segments
- Multi-segment cost functions
- Heat rate variations

**RESTR Block** - Unit Restrictions
- Operational limitations
- Environmental constraints

---

## DECOMP Integration Files

These files handle integration with the DECOMP model for multi-stage optimization.

### MAPCUT.DEC - Cut Mapping File

**Purpose**: Maps Benders cuts from DECOMP to DESSEM format

**Format**: Binary file (non-editable)

**Content**:
- Cut indices and reservoir mappings
- Temporal alignment information
- Variable coefficient structures

### CORTES.DEC - Benders Cuts File

**Purpose**: Contains future cost function cuts from DECOMP

**Format**: Binary file (non-editable)

**Content**:
- Cut coefficients for stored volumes
- Past spillage coefficients
- RHS values for cuts

### INFOFCF.DEC - Future Cost Function Information

**Purpose**: Additional information for future cost function

**Format**: Binary file (non-editable)

**Content**:
- Weekly indices
- Plant mappings
- Temporal discretization alignment

---

## Electrical Network Files

### DESSELET.XXX - Network Data Index

**Purpose**: References to network case files for each time period

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 5-6 | I2 | ✓ | Day | Calendar day | - |
| 10-11 | I2 | | Hour | 0-23 | 0 |
| 15 | I1 | | Half-hour flag | 0 or 1 | 0 |
| 20-24 | F5.0 | ✓ | Duration (hours) | > 0 | - |
| 30-69 | A40 | ✓ | Base case file name | ANAREDE file | - |

### Network Case Files (leve.dat, media.dat, pesada.dat)

**Purpose**: ANAREDE format electrical network data

**Format**: Multiple data blocks with specific identifiers

#### DBAR Block - Bus Data

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-5 | I5 | ✓ | Bus number | 1-99999 | - |
| 7-18 | A12 | | Bus name | Text identifier | - |
| 20-21 | I2 | | Area number | 1-999 | 0 |
| 23-27 | F5.0 | ✓ | Base voltage (kV) | > 0 | - |
| 28 | I1 | ✓ | Bus type | 0=PQ, 1=PV, 2=reference | - |
| 29-33 | F5.1 | | Voltage magnitude (p.u.) | > 0 | 1.0 |
| 34-38 | F5.1 | | Voltage angle (degrees) | -180 to +180 | 0 |
| 40-44 | F5.0 | | Active generation (MW) | Any value | 0 |
| 46-50 | F5.0 | | Reactive generation (MVAr) | Any value | 0 |
| 52-56 | F5.0 | | Active load (MW) | ≥ 0 | 0 |
| 58-62 | F5.0 | | Reactive load (MVAr) | Any value | 0 |
| 64-68 | F5.0 | | Shunt conductance (MW) | Any value | 0 |
| 70-74 | F5.0 | | Shunt susceptance (MVAr) | Any value | 0 |

#### DLIN Block - Line Data

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-5 | I5 | ✓ | From bus | Per DBAR | - |
| 7-11 | I5 | ✓ | To bus | Per DBAR | - |
| 13 | I1 | | Circuit ID | 1-9 | 1 |
| 15 | I1 | ✓ | Line status | 0=out, 1=in service | 1 |
| 17-22 | F6.5 | ✓ | Resistance (p.u.) | ≥ 0 | 0 |
| 23-28 | F6.5 | ✓ | Reactance (p.u.) | > 0 | - |
| 29-33 | F5.3 | | Susceptance (p.u.) | ≥ 0 | 0 |
| 35-39 | F5.0 | | Flow limit A-B (MVA) | ≥ 0 | 999999 |
| 41-45 | F5.0 | | Flow limit B-A (MVA) | ≥ 0 | 999999 |

#### DGLT Block - Generation Limits

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-5 | I5 | ✓ | Bus number | Per DBAR | - |
| 7-11 | F5.0 | ✓ | Minimum generation (MW) | ≥ 0 | 0 |
| 13-17 | F5.0 | ✓ | Maximum generation (MW) | ≥ min gen | - |

---

## Optional Constraint Files

### AREACONT.DAT - Control Area Definition

**Purpose**: Define control areas for power reserve constraints

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-2 | I2 | ✓ | Area number | 1-20 | - |
| 5 | I1 | ✓ | Plant type | "H"=hydro, "T"=thermal | - |
| 10-12 | I3 | ✓ | Plant number | Per registry | - |
| 15-19 | F5.0 | | Participation factor | 0-1 | 1.0 |

### RESPOT.XXX - Power Reserve Constraints

**Purpose**: Time-varying power reserve requirements by area

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-2 | I2 | ✓ | Area number | Per AREACONT | - |
| 5-6 | I2 | ✓ | Initial day | Calendar day | - |
| 8-9 | I2 | | Initial hour | 0-23 | 0 |
| 11 | I1 | | Initial half-hour | 0 or 1 | 0 |
| 13-14 | I2 | ✓ | Final day | Calendar day or "F" | - |
| 16-17 | I2 | | Final hour | 0-23 | 0 |
| 19 | I1 | | Final half-hour | 0 or 1 | 0 |
| 25-34 | F10.0 | ✓ | Reserve requirement (MW) | ≥ 0 | - |

### RESTSEG.XXX - Dynamic Security Constraints

**Purpose**: Tabular format security constraints

**Format**: Tabular constraint definitions with generation/flow sensitivities

### RSTLPP.XXX - Linear Piecewise Security Constraints

**Purpose**: Piecewise linear security constraint definition

**Format**: Multi-segment constraint specifications

---

## Renewable Energy Files

### EOLICA.XXX - Wind Plant Data

**Purpose**: Wind generation forecasts and characteristics

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-3 | I3 | ✓ | Wind plant number | 1-2000 | - |
| 5-16 | A12 | ✓ | Plant name | Text identifier | - |
| 20-21 | I2 | ✓ | Subsystem number | Per SIST records | - |
| 25-26 | I2 | ✓ | Initial day | Calendar day | - |
| 28-29 | I2 | | Initial hour | 0-23 | 0 |
| 31 | I1 | | Initial half-hour | 0 or 1 | 0 |
| 33-34 | I2 | ✓ | Final day | Calendar day or "F" | - |
| 36-37 | I2 | | Final hour | 0-23 | 0 |
| 39 | I1 | | Final half-hour | 0 or 1 | 0 |
| 45-54 | F10.0 | ✓ | Generation forecast (MW) | ≥ 0 | - |
| 60-69 | F10.0 | | Installed capacity (MW) | ≥ forecast | - |

### SOLAR.XXX - Solar Plant Data

**Purpose**: Solar generation forecasts and characteristics

**Format**: Similar structure to EOLICA.XXX with solar-specific parameters

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-3 | I3 | ✓ | Solar plant number | 1-2000 | - |
| 5-16 | A12 | ✓ | Plant name | Text identifier | - |
| 20-21 | I2 | ✓ | Subsystem number | Per SIST records | - |
| 25-26 | I2 | ✓ | Initial day | Calendar day | - |
| 28-29 | I2 | | Initial hour | 0-23 | 0 |
| 31 | I1 | | Initial half-hour | 0 or 1 | 0 |
| 33-34 | I2 | ✓ | Final day | Calendar day or "F" | - |
| 36-37 | I2 | | Final hour | 0-23 | 0 |
| 39 | I1 | | Final half-hour | 0 or 1 | 0 |
| 45-54 | F10.0 | ✓ | Generation forecast (MW) | ≥ 0 | - |
| 60-69 | F10.0 | | Installed capacity (MW) | ≥ forecast | - |

### BATERIA.XXX - Battery Storage Data

**Purpose**: Energy storage system characteristics and operation

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-3 | I3 | ✓ | Battery number | 1-999 | - |
| 5-16 | A12 | ✓ | Battery name | Text identifier | - |
| 20-21 | I2 | ✓ | Subsystem number | Per SIST records | - |
| 25-34 | F10.0 | ✓ | Charging capacity (MW) | > 0 | - |
| 40-49 | F10.0 | ✓ | Discharging capacity (MW) | > 0 | - |
| 55-64 | F10.0 | ✓ | Energy capacity (MWh) | > 0 | - |
| 70-79 | F10.0 | | Initial energy (MWh) | 0 to capacity | 0 |
| 85-94 | F10.0 | | Charging efficiency | 0-1 | 0.9 |
| 100-109 | F10.0 | | Discharging efficiency | 0-1 | 0.9 |

---

## Auxiliary Files

### MLT.DAT - Long-term Average Flows

**Purpose**: Historical average flows for water value calculation

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-3 | I3 | ✓ | Plant number | Per hydro registry | - |
| 5-16 | A12 | | Plant name | Reference only | - |
| 20-29 | F10.0 | ✓ | January flow (m³/s) | ≥ 0 | - |
| 31-40 | F10.0 | ✓ | February flow (m³/s) | ≥ 0 | - |
| 42-51 | F10.0 | ✓ | March flow (m³/s) | ≥ 0 | - |
| 53-62 | F10.0 | ✓ | April flow (m³/s) | ≥ 0 | - |
| 64-73 | F10.0 | ✓ | May flow (m³/s) | ≥ 0 | - |
| 75-84 | F10.0 | ✓ | June flow (m³/s) | ≥ 0 | - |
| 86-95 | F10.0 | ✓ | July flow (m³/s) | ≥ 0 | - |
| 97-106 | F10.0 | ✓ | August flow (m³/s) | ≥ 0 | - |
| 108-117 | F10.0 | ✓ | September flow (m³/s) | ≥ 0 | - |
| 119-128 | F10.0 | ✓ | October flow (m³/s) | ≥ 0 | - |
| 130-139 | F10.0 | ✓ | November flow (m³/s) | ≥ 0 | - |
| 141-150 | F10.0 | ✓ | December flow (m³/s) | ≥ 0 | - |

### DEFLANT.XXX - Previous Outflows

**Purpose**: Historical outflow data for travel time calculations

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-3 | I3 | ✓ | Plant number | Per hydro registry | - |
| 5-16 | A12 | | Plant name | Reference only | - |
| 20-21 | I2 | ✓ | Day | Calendar day | - |
| 25-26 | I2 | | Hour | 0-23 | 0 |
| 30 | I1 | | Half-hour flag | 0 or 1 | 0 |
| 35-44 | F10.0 | ✓ | Outflow (m³/s) | ≥ 0 | - |

### COTASR11.XXX - Itaipu R11 Gauge Data

**Purpose**: Water level data for Itaipu R11 gauge constraint

| Column | Format | Required | Description | Valid Values | Default |
|--------|--------|----------|-------------|--------------|---------|
| 1-2 | I2 | ✓ | Day | Calendar day | - |
| 5-6 | I2 | | Hour | 0-23 | 0 |
| 10 | I1 | | Half-hour flag | 0 or 1 | 0 |
| 15-24 | F10.0 | ✓ | Water level (m) | Any value | - |

### CURVTVIAG.DAT - Travel Time Curves

**Purpose**: Water travel time propagation data

**Format**: Tabular data defining travel time relationships

### ILSTRI.DAT - Ilha Solteira Channel Data

**Purpose**: Channel flow data between IS and TI reservoirs

**Format**: Flow limits based on reservoir level differences

### RAMPAS.DAT - Thermal Unit Ramp Trajectories

**Purpose**: Detailed startup/shutdown ramp curves

**Format**: Time-series generation trajectories for unit commitment

### TOLPERD.XXX - Loss Tolerance Parameters

**Purpose**: Transmission loss modeling tolerances

**Format**: Tolerance specifications for loss linearization

### RIVAR.DAT - Soft Variation Constraints

**Purpose**: Flexible constraint definitions with penalty costs

**Format**: Constraint definitions with violation penalties

---

## Model Capacity Limits

### Energy System Limits

| Parameter | Limit | Description |
|-----------|-------|-------------|
| ZUSIH | 220 | Maximum hydroelectric plants |
| ZUSIT | 150 | Maximum thermal plants |
| ZDIAS | 14 | Maximum study days |
| ZPAT | 48 | Maximum periods per day |
| ZUNH | 750 | Maximum hydro units |
| ZUNT | 450 | Maximum thermal units |
| ZSIS | 10 | Maximum subsystems |
| ZAREA | 20 | Maximum control areas |
| ZEOL | 2000 | Maximum wind plants |

### Electrical Network Limits

| Parameter | Limit | Description |
|-----------|-------|-------------|
| ZBUS | 9500 | Maximum buses |
| ZLIN | 13000 | Maximum transmission lines |
| ZARE | 999 | Maximum electrical areas |
| ZRAF | 800 | Maximum flow sum constraints |
| ZUSI | 1200 | Maximum unit-bus links |

### Constraint Limits

| Parameter | Limit | Description |
|-----------|-------|-------------|
| ZRLIM | 700 | Maximum limit constraints |
| ZRVAR | 200 | Maximum variation constraints |
| ZRESTLPP | 100 | Maximum LPP constraints |
| ZRESP | 400 | Maximum special electrical constraints |
| ZCDC | 500 | Maximum FCF cuts |

---

## Validation Guidelines

### Format Validation Checklist

1. **Column Positioning**
   - Verify exact column positions for each field
   - No tabs used - only spaces for field separation
   - Check alignment with format specifications

2. **Data Types**
   - Integer fields contain only digits
   - Float fields use proper decimal notation
   - Text fields within character limits

3. **Required Fields**
   - All mandatory fields (marked ✓) are filled
   - No blank values in required positions
   - Proper default values where applicable

4. **Value Ranges**
   - Numbers within specified minimum/maximum limits
   - Dates within study period
   - Plant numbers match registries

5. **Time Consistency**
   - Chronological order in time data
   - End times after start times
   - No overlapping periods where inappropriate

6. **Cross-Reference Validation**
   - Plant numbers consistent across files
   - Subsystem references valid
   - Unit numbers within plant capacity

### Common Format Errors

1. **Tab Characters**: Using tabs instead of spaces
2. **Column Misalignment**: Data in wrong columns
3. **Missing Mandatory Data**: Required fields left blank
4. **Invalid References**: Non-existent plant/unit numbers
5. **Time Sequence Errors**: End before start times
6. **Value Range Violations**: Numbers outside valid ranges

### File Preparation Best Practices

1. **Text Editor**: Use fixed-width font editors
2. **Character Encoding**: UTF-8 or ASCII
3. **Line Endings**: Consistent with target system
4. **Backup Strategy**: Version control all input files
5. **Incremental Testing**: Start simple, add complexity
6. **Validation Tools**: Use DESSEM's built-in error messages

---

## Contact Information

For questions about file formats or capacity limit increases, contact:

**CEPEL - Centro de Pesquisas de Energia Elétrica**
- Technical support for DESSEM model
- File format clarifications
- Capacity limit adjustments

This documentation is based on DESSEM User Manual version 19.0.24.3, March 2022.