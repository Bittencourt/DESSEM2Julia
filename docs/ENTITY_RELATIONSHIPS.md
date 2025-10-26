# DESSEM Entity Relationship Model

> **📚 Part of**: [DESSEM2Julia Documentation](INDEX.md) | **📖 Also see**: [HIDR Entity Diagram](HIDR_ENTITY_DIAGRAM.md), [HIDR Quick Reference](HIDR_QUICK_REFERENCE.md), [Type System](type_system.md)

This document describes the relational structure of DESSEM input files, treating them as a distributed database where entities across different files are connected through foreign key relationships.

## Table of Contents
1. [Core Entities Overview](#core-entities-overview)
2. [Entity Relationship Diagram](#entity-relationship-diagram)
3. [Detailed Relationships](#detailed-relationships)
4. [Hierarchical Structures](#hierarchical-structures)
5. [Cross-File References](#cross-file-references)
6. [Temporal Relationships](#temporal-relationships)

---

## Core Entities Overview

### Master Entities (Primary Keys)

| Entity | Primary Key | Files | Description |
|--------|-------------|-------|-------------|
| **Subsystem** | `subsystem_num` | ENTDADOS (SIST), DESSEM.ARQ | Electrical subsystem/market |
| **Hydro Plant** | `plant_num` | ENTDADOS (UH), HIDR.DAT, DADVAZ | Hydroelectric power plant |
| **Thermal Plant** | `plant_num` | ENTDADOS (UT), TERM.DAT (CADUSIT), OPERUT | Thermal power plant |
| **Thermal Unit** | `(plant_num, unit_num)` | TERM.DAT (CADUNIDT), OPERUT | Individual thermal generating unit |
| **Hydro Unit Set** | `(plant_num, set_num)` | HIDR.DAT (CADCONJ), UCH | Group of identical hydro units |
| **Hydro Unit** | `(plant_num, set_num, unit_num)` | UCH, HIDR.DAT | Individual hydro generating unit |
| **Time Period** | `(day, hour, half_hour)` | ENTDADOS (TM), SIMUL, all operational files | Temporal discretization |
| **Bus** | `bus_num` | Network files (.pwf), AREACONT | Electrical network node |
| **Restriction** | `restriction_num` | ENTDADOS (RE), OPERUH, RESTSEG | Operational constraint |
| **Pump Station** | `plant_num` | ENTDADOS (USIE) | Pumped storage/reversible hydro |
| **Energy Reservoir (REE)** | `ree_code` | ENTDADOS (REE) | Equivalent energy reservoir group |
| **Renewable Plant** | `plant_num` | RENOVAVEIS.DAT (EOLICA) | Wind/solar generation plant |
| **Energy Contract** | `contract_num` | ENTDADOS (CE, CI) | Import/export energy contract |
| **Special Demand** | `demand_code` | ENTDADOS (DE) | Special load/demand |

---

## Entity Relationship Diagram

```
┌─────────────────┐
│   SUBSYSTEM     │ ◄──────────────┐
│  subsystem_num  │                │
└────────┬────────┘                │
         │ 1                       │
         │                         │
         │ *                       │ *
┌────────┴────────────────┐  ┌────┴─────────────┐
│   HYDRO PLANT           │  │  THERMAL PLANT   │
│  plant_num (PK)         │  │  plant_num (PK)  │
│  subsystem (FK)         │  │  subsystem (FK)  │
│  downstream_plant (FK)  │  │                  │
└────────┬────────────────┘  └────┬─────────────┘
         │ 1                      │ 1
         │                        │
         │ *                      │ *
┌────────┴─────────────┐   ┌──────┴────────────────┐
│   HYDRO UNIT SET     │   │   THERMAL UNIT        │
│  (plant_num, set_num)│   │  (plant_num, unit_num)│
│  plant_num (FK)      │   │  plant_num (FK)       │
└────────┬─────────────┘   └──────┬────────────────┘
         │ 1                      │ 1
         │                        │
         │ *                      │ *
┌────────┴─────────────┐   ┌──────┴────────────────┐
│   HYDRO UNIT         │   │   THERMAL OPER        │
│  (plant, set, unit)  │   │  (plant, unit, time)  │
│  set_num (FK)        │   │  unit (FK)            │
└──────────────────────┘   │  time (FK)            │
                           └───────────────────────┘

┌─────────────────────────────────────────────────┐
│   TIME PERIOD                                   │
│  (day, hour, half_hour)                         │
└────────┬────────────────────────────────────────┘
         │ 1
         │
         │ *
┌────────┴────────────────────┐
│   OPERATIONAL DATA           │
│  All time-varying records    │
│  time (FK)                   │
└──────────────────────────────┘

┌──────────────────────┐
│   NETWORK BUS        │
│  bus_num (PK)        │
│  subsystem (FK)      │
└────────┬─────────────┘
         │ 1
         │
         │ *
┌────────┴──────────────────┐
│   PLANT-BUS CONNECTION    │
│  plant_num (FK)           │
│  bus_num (FK)             │
└───────────────────────────┘
```

---

## Detailed Relationships

### 1. Subsystem Relationships

**Entity**: `SUBSYSTEM`
- **Primary Key**: `subsystem_num`
- **Defined in**: ENTDADOS.XXX (SIST records)

**One-to-Many Relationships**:
```
SUBSYSTEM (1) ──► (*) HYDRO_PLANT
                     UH.subsystem → SIST.subsystem_num

SUBSYSTEM (1) ──► (*) THERMAL_PLANT
                     UT.subsystem → SIST.subsystem_num
                     CADUSIT.subsystem → SIST.subsystem_num

SUBSYSTEM (1) ──► (*) DEMAND
                     DP.subsystem → SIST.subsystem_num

SUBSYSTEM (1) ──► (*) INTERCHANGE
                     IA.from_subsystem → SIST.subsystem_num
                     IA.to_subsystem → SIST.subsystem_num

SUBSYSTEM (1) ──► (*) NETWORK_BUS
                     Bus.subsystem → SIST.subsystem_num

SUBSYSTEM (1) ──► (*) DEFICIT_COST
                     CD.subsystem → SIST.subsystem_num
```

### 2. Hydroelectric Plant Relationships

**Entity**: `HYDRO_PLANT`
- **Primary Key**: `plant_num`
- **Defined in**: ENTDADOS.XXX (UH), HIDR.DAT (CADUSIH), DADVAZ.XXX
- **Parser Implementation**: `src/parser/hidr.jl`, `src/parser/hidr_binary.jl`

**Foreign Keys**:
- `subsystem` → `SUBSYSTEM.subsystem_num`
- `downstream_plant` → `HYDRO_PLANT.plant_num` (self-reference for cascade topology)
- `diversion_plant` → `HYDRO_PLANT.plant_num` (self-reference for diversion channel)

**HIDR.DAT Format Support**:
- ✅ **Text Format** (7 record types): CADUSIH, USITVIAG, POLCOT, POLARE, POLJUS, COEFEVA, CADCONJ
- ✅ **Binary Format** (792 bytes/plant): Complete plant registry from ONS/CCEE official data
- 🔄 **Auto-detection**: `parse_hidr()` automatically detects and routes to appropriate parser

**Relationships**:
```
SUBSYSTEM (1) ──► (*) HYDRO_PLANT
                     UH.subsystem → SIST.subsystem_num
                     CADUSIH.subsystem → SIST.subsystem_num

HYDRO_PLANT (1) ──► (*) HYDRO_UNIT_SET
                       CADCONJ.plant_num → CADUSIH.plant_num

HYDRO_PLANT (1) ──► (*) INFLOW_DATA
                       DADVAZ.plant_num → CADUSIH.plant_num

HYDRO_PLANT (1) ──► (*) OPERUH_CONSTRAINTS
                       OPERUH.plant_num → CADUSIH.plant_num

HYDRO_PLANT (1) ──► (0..1) TRAVEL_TIME
                       USITVIAG.from_plant → CADUSIH.plant_num
                       USITVIAG.to_plant → CADUSIH.plant_num

HYDRO_PLANT (1) ──► (*) VOLUME_ELEVATION_CURVE
                       POLCOT.plant_num → CADUSIH.plant_num

HYDRO_PLANT (1) ──► (*) VOLUME_AREA_CURVE
                       POLARE.plant_num → CADUSIH.plant_num

HYDRO_PLANT (1) ──► (*) TAILRACE_ELEVATION_CURVE
                       POLJUS.plant_num → CADUSIH.plant_num

HYDRO_PLANT (1) ──► (*) EVAPORATION_COEFFICIENTS
                       COEFEVA.plant_num → CADUSIH.plant_num

HYDRO_PLANT (1) ──► (*) WITHDRAWAL_RATE
                       DA.plant_num → UH.plant_num

HYDRO_PLANT (0..1) ◄──► (0..1) HYDRO_PLANT  (cascade topology)
                       CADUSIH.downstream_plant → CADUSIH.plant_num
                       (forms directed acyclic graph of reservoir cascade)
```

**Cascade Topology**:
The `downstream_plant` field creates a tree structure representing water flow:
```
Reservoir 1 (upstream)
    ├─► Reservoir 2 (intermediate)
    │       ├─► Reservoir 5 (downstream)
    │       └─► Reservoir 6 (downstream)
    └─► Reservoir 3 (intermediate)
            └─► Reservoir 7 (downstream)
```

**Example from ONS Sample (DS_ONS_102025_RV2D11/hidr.dat)**:
- **185 hydro plants** parsed from binary format
- **Total capacity**: 24,218 MW
- **Longest cascade**: Paranapanema River (11 plants)
  - A.A. LAYDNER → PIRAJU → PARANAPANEMA → CHAVANTES → OURINHOS → 
    L.N. GARCEZ → CANOAS II → CANOAS I → CAPIVARA → TAQUARUCU → ROSANA

**Binary Format Details** (792 bytes/plant):
- **111 fields** per record (Int32, Int64, Float32, fixed strings)
- Fields mapped to CADUSIH struct (14 fields used)
- Format detection via file size (multiple of 792) + posto field validation
- Reference implementation: IDESSEM (rjmalves/idessem)

### 3. Thermal Plant Relationships

**Entity**: `THERMAL_PLANT`
- **Primary Key**: `plant_num`
- **Defined in**: ENTDADOS.XXX (UT), TERM.DAT (CADUSIT)

**Foreign Keys**:
- `subsystem` → `SUBSYSTEM.subsystem_num`

**Relationships**:
```
SUBSYSTEM (1) ──► (*) THERMAL_PLANT
                     CADUSIT.subsystem → SIST.subsystem_num

THERMAL_PLANT (1) ──► (*) THERMAL_UNIT
                         CADUNIDT.plant_num → CADUSIT.plant_num

THERMAL_PLANT (1) ──► (*) HEAT_RATE_CURVE
                         CURVACOMB.plant_num → CADUSIT.plant_num

THERMAL_PLANT (1) ──► (*) COMBINED_CYCLE_CONFIG
                         CADCONF.plant_num → CADUSIT.plant_num

THERMAL_PLANT (1) ──► (*) OPERUT_INIT
                         INIT.plant_num → CADUSIT.plant_num

THERMAL_PLANT (1) ──► (*) OPERUT_OPER
                         OPER.plant_num → CADUSIT.plant_num
```

### 4. Thermal Unit Relationships

**Entity**: `THERMAL_UNIT`
- **Composite Primary Key**: `(plant_num, unit_num)`
- **Defined in**: TERM.DAT (CADUNIDT)

**Foreign Keys**:
- `plant_num` → `THERMAL_PLANT.plant_num`

**Relationships**:
```
THERMAL_PLANT (1) ──► (*) THERMAL_UNIT
                         CADUNIDT.plant_num → CADUSIT.plant_num

THERMAL_UNIT (1) ──► (*) HEAT_RATE_POINTS
                        CURVACOMB.(plant_num, unit_num) → CADUNIDT.(plant_num, unit_num)

THERMAL_UNIT (1) ──► (*) OPERUT_INIT
                        INIT.(plant_num, unit_num) → CADUNIDT.(plant_num, unit_num)

THERMAL_UNIT (1) ──► (*) OPERUT_OPER
                        OPER.(plant_num, unit_num) → CADUNIDT.(plant_num, unit_num)

THERMAL_UNIT (1) ──► (*) UNIT_MAINTENANCE
                        MT.(plant_num, unit_num) → CADUNIDT.(plant_num, unit_num)

THERMAL_UNIT (*) ──► (1) TIME_PERIOD
                        OPER.(day, hour, half) → TM.(day, hour, half)
```

### 5. Hydro Unit Hierarchy

**Three-Level Hierarchy**:
```
HYDRO_PLANT (1) ──► (*) HYDRO_UNIT_SET (1) ──► (*) HYDRO_UNIT
plant_num           (plant_num, set_num)         (plant_num, set_num, unit_num)
```

**Entities**:

1. **HYDRO_UNIT_SET**
   - **Composite Primary Key**: `(plant_num, set_num)`
   - **Defined in**: HIDR.DAT (CADCONJ)
   - **Parser**: `src/parser/hidr.jl` (text format only)
   - **Foreign Keys**: `plant_num` → `HYDRO_PLANT.plant_num`
   - **Note**: Binary HIDR format does NOT include CADCONJ records

2. **HYDRO_UNIT**
   - **Composite Primary Key**: `(plant_num, set_num, unit_num)`
   - **Defined in**: UCH file
   - **Parser**: Not yet implemented
   - **Foreign Keys**: `(plant_num, set_num)` → `HYDRO_UNIT_SET.(plant_num, set_num)`

**Relationships**:
```
HYDRO_PLANT (1) ──► (*) HYDRO_UNIT_SET
                       CADCONJ.plant_num → CADUSIH.plant_num

HYDRO_UNIT_SET (1) ──► (*) HYDRO_UNIT
                          UCH.(plant_num, set_num) → CADCONJ.(plant_num, set_num)

HYDRO_UNIT (1) ──► (*) UCH_TON_TOFF
                      UCH_TON_TOFF.(plant, set, unit) → HYDRO_UNIT.(plant, set, unit)

HYDRO_UNIT (1) ──► (*) UCH_GMIN_GMAX
                      UCH_GMIN_GMAX.(plant, set, unit) → HYDRO_UNIT.(plant, set, unit)

HYDRO_UNIT (1) ──► (*) UCH_INITIAL_CONDITION
                      UCH_INITIAL.(plant, set, unit) → HYDRO_UNIT.(plant, set, unit)
```

**Data Source Implications**:
- **Text HIDR.DAT**: Contains full hierarchy (CADUSIH → CADCONJ → UCH reference)
- **Binary HIDR.DAT**: Contains only CADUSIH (plant registry), unit sets must come from UCH or be derived

### 6. Time Period Relationships

**Entity**: `TIME_PERIOD`
- **Composite Primary Key**: `(day, hour, half_hour)`
- **Defined in**: ENTDADOS.XXX (TM records)

**Referenced by (all time-varying data)**:
```
TIME_PERIOD (1) ──► (*) DEMAND
                       DP.(start_day, start_hour, start_half) → TM.(day, hour, half)

TIME_PERIOD (1) ──► (*) INTERCHANGE_LIMITS
                       IA.(start_day, start_hour, start_half) → TM.(day, hour, half)

TIME_PERIOD (1) ──► (*) THERMAL_OPER
                       OPER.(day, hour, half) → TM.(day, hour, half)

TIME_PERIOD (1) ──► (*) HYDRO_CONSTRAINTS
                       OPERUH.(start_day, start_hour, start_half) → TM.(day, hour, half)

TIME_PERIOD (1) ──► (*) WITHDRAWAL_RATE
                       DA.(start_day, start_hour, start_half) → TM.(day, hour, half)

TIME_PERIOD (1) ──► (*) FLOOD_CONTROL
                       VE.(start_day, start_hour, start_half) → TM.(day, hour, half)

TIME_PERIOD (1) ──► (*) MAINTENANCE
                       MH/MT/ME.(start_day, start_hour, start_half) → TM.(day, hour, half)
```

### 7. Network Relationships

**Entity**: `NETWORK_BUS`
- **Primary Key**: `bus_num`
- **Defined in**: Network files (leve.pwf, media.pwf, pesada.pwf - DBAR records)

**Foreign Keys**:
- `subsystem` → `SUBSYSTEM.subsystem_num`

**Relationships**:
```
SUBSYSTEM (1) ──► (*) NETWORK_BUS
                     DBAR.subsystem → SIST.subsystem_num

NETWORK_BUS (1) ──► (*) TRANSMISSION_LINE
                       DLIN.from_bus → DBAR.bus_num
                       DLIN.to_bus → DBAR.bus_num

NETWORK_BUS (1) ──► (*) PLANT_CONNECTION
                       HYDRO_PLANT.bus → DBAR.bus_num
                       THERMAL_PLANT.bus → DBAR.bus_num

NETWORK_BUS (1) ──► (*) LOAD
                       DBAR.load_bus → DBAR.bus_num
```

### 8. Pump Station Relationships

**Entity**: `PUMP_STATION`
- **Primary Key**: `plant_code`
- **Defined in**: ENTDADOS.XXX (USIE records)
- **Parser Implementation**: `src/parser/entdados.jl`

**Foreign Keys**:
- `subsystem_code` → `SUBSYSTEM.subsystem_num`
- `upstream_plant` → `HYDRO_PLANT.plant_num`
- `downstream_plant` → `HYDRO_PLANT.plant_num`

**Relationships**:
```
SUBSYSTEM (1) ──► (*) PUMP_STATION
                     USIE.subsystem_code → SIST.subsystem_num

HYDRO_PLANT (1) ──► (*) PUMP_STATION (upstream)
                       USIE.upstream_plant → UH.plant_num

HYDRO_PLANT (1) ──► (*) PUMP_STATION (downstream)
                       USIE.downstream_plant → UH.plant_num

PUMP_STATION (1) ──► (*) PUMPING_CONSTRAINTS
                        PE.plant_code → USIE.plant_code
```

**Purpose**: Represents reversible hydro plants that can pump water from downstream to upstream reservoirs, consuming energy to increase upstream storage.

### 9. Energy Reservoir Equivalent (REE) Relationships

**Entity**: `ENERGY_RESERVOIR_EQUIVALENT`
- **Primary Key**: `ree_code`
- **Defined in**: ENTDADOS.XXX (REE records)
- **Parser Implementation**: `src/parser/entdados.jl`

**Foreign Keys**:
- `subsystem_code` → `SUBSYSTEM.subsystem_num`

**Relationships**:
```
SUBSYSTEM (1) ──► (*) REE
                     REE.subsystem_code → SIST.subsystem_num

REE (1) ──► (*) HYDRO_PLANT
               UH.ree_code → REE.ree_code (optional grouping)
```

**Purpose**: Groups hydroelectric plants into equivalent energy reservoirs for coupled operation in medium/long-term planning.

### 10. Renewable Plant Relationships

**Entity**: `RENEWABLE_PLANT`
- **Primary Key**: `plant_num`
- **Defined in**: RENOVAVEIS.DAT (EOLICA, EOLICABARRA, EOLICASUBM, EOLICAGERACAO records)
- **Parser Implementation**: Not yet implemented (TODO)

**Foreign Keys**:
- `subsystem` → `SUBSYSTEM.subsystem_num`
- `bus_num` → `NETWORK_BUS.bus_num` (EOLICABARRA)

**Relationships**:
```
SUBSYSTEM (1) ──► (*) RENEWABLE_PLANT
                     EOLICA.subsystem → SIST.subsystem_num

RENEWABLE_PLANT (1) ──► (*) GENERATION_FORECAST
                           EOLICAGERACAO.plant_num → EOLICA.plant_num

NETWORK_BUS (1) ──► (*) RENEWABLE_PLANT
                       EOLICABARRA.bus_num → DBAR.bus_num
```

**Purpose**: Wind and solar generation plants with time-varying forecasts.

### 11. Energy Contract Relationships

**Entity**: `ENERGY_CONTRACT`
- **Primary Key**: `contract_num`
- **Defined in**: ENTDADOS.XXX (CE records for export, CI records for import)
- **Parser Implementation**: `src/parser/entdados.jl`

**Foreign Keys**:
- `submkt_code` → `SUBSYSTEM.subsystem_num`

**Relationships**:
```
SUBSYSTEM (1) ──► (*) EXPORT_CONTRACT
                     CE.submkt_code → SIST.subsystem_num

SUBSYSTEM (1) ──► (*) IMPORT_CONTRACT
                     CI.submkt_code → SIST.subsystem_num

ENERGY_CONTRACT (*) ──► (*) RESTRICTION
                           FC.(restriction_num, contract_num)
```

**Contract Types**:
- **CE**: Export contracts (energy sold outside system)
- **CI**: Import contracts (energy purchased from outside)

### 12. Special Demand Relationships

**Entity**: `SPECIAL_DEMAND`
- **Primary Key**: `demand_code`
- **Defined in**: ENTDADOS.XXX (DE records)
- **Parser Implementation**: `src/parser/entdados.jl`

**Relationships**:
```
SPECIAL_DEMAND (*) ──► (*) RESTRICTION
                          FC.(restriction_num, load_code)
```

**Purpose**: Special loads that can participate in electrical constraints (e.g., large industrial loads).

### 13. Itaipu Binational Plant Relationships

**Entity**: `ITAIPU_CONSTRAINT`
- **Primary Key**: (time period)
- **Defined in**: ENTDADOS.XXX (RI records for restrictions, IT records for binational data, PQ records for reactive power)
- **Parser Implementation**: `src/parser/entdados.jl`

**Relationships**:
```
TIME_PERIOD (1) ──► (*) ITAIPU_RESTRICTION
                       RI.(start_day, start_hour, start_half) → TM.(day, hour, half)

ITAIPU_PLANT ──► BINATIONAL_CONSTRAINTS
                   IT: Binational agreement parameters
                   PQ: Reactive power constraints
```

**Purpose**: Special constraints for Itaipu binational hydroelectric plant (Brazil-Paraguay).

### 14. Restriction/Constraint Relationships

**Entity**: `RESTRICTION`
- **Primary Key**: `restriction_num`
- **Defined in**: ENTDADOS.XXX (RE records), OPERUH, RESTSEG

**Many-to-Many Relationships** (via coefficient records):
```
RESTRICTION (*) ◄──► (*) HYDRO_PLANT
                        FH.(restriction_num, plant_num)

RESTRICTION (*) ◄──► (*) THERMAL_PLANT
                        FT.(restriction_num, plant_num)

RESTRICTION (*) ◄──► (*) HYDRO_UNIT_SET
                        FH.(restriction_num, plant_num, set_num)

RESTRICTION (*) ◄──► (*) SUBSYSTEM
                        FI.(restriction_num, subsystem_from, subsystem_to)

RESTRICTION (*) ◄──► (*) PUMP_STATION
                        FE.(restriction_num, plant_num)

RESTRICTION (*) ◄──► (*) RENEWABLE_PLANT
                        FR.(restriction_num, plant_num)

RESTRICTION (*) ◄──► (*) ENERGY_CONTRACT
                        FC.(restriction_num, contract_num)

RESTRICTION (*) ◄──► (*) SPECIAL_DEMAND
                        FC.(restriction_num, load_code)
```

**Constraint Coefficients**:
- **FH**: Hydro generation coefficients in restriction
- **FT**: Thermal generation coefficients in restriction
- **FI**: Interchange coefficients in restriction
- **FE**: Pumping coefficients in restriction (for pump stations)
- **FR**: Renewable generation coefficients in restriction
- **FC**: Contract/special load coefficients in restriction

---

### 15. Plant Configuration Adjustment Relationships (AC Records)

**Entity**: `PLANT_ADJUSTMENT`
- **Primary Key**: `(plant_code, ac_type)`
- **Defined in**: ENTDADOS.XXX (AC records - multiple types)
- **Parser Implementation**: `src/parser/entdados.jl`

**AC Record Types**:
- **ACVOLMAX**: Volume maximum adjustment
- **ACVOLMIN**: Volume minimum adjustment
- **ACVSVERT**: Spillway volume adjustment
- **ACVMDESV**: Diversion volume adjustment
- **ACCOTVAZ**: Head-flow polynomial adjustment
- **ACCOTVOL**: Head-volume polynomial adjustment
- **ACCOTTAR**: Tailrace polynomial adjustment
- **ACNUMCON**: Number of machine sets adjustment
- **ACNUMJUS**: Downstream plant adjustment
- **ACNUMPOS**: Station number adjustment
- **ACJUSENA**: Downstream elevation adjustment
- **ACJUSMED**: Average tailrace adjustment
- **ACCOFEVA**: Evaporation coefficient adjustment
- **ACNUMMAQ**: Number of machines adjustment
- **ACPOTEFE**: Effective power adjustment
- **ACDESVIO**: Diversion adjustment

**Relationships**:
```
HYDRO_PLANT (1) ──► (*) PLANT_ADJUSTMENT
                       AC.plant_code → UH.plant_num

PLANT_ADJUSTMENT ──► HIDR.DAT (overrides)
                       AC records override CADUSIH/polynomial values
```

**Purpose**: Allows temporary or permanent adjustments to plant characteristics defined in HIDR.DAT without modifying the master registry.

### 16. Network Iteration Control (NI)

**Entity**: `NETWORK_ITERATION`
- **Primary Key**: (singleton record)
- **Defined in**: ENTDADOS.XXX (NI record)
- **Parser Implementation**: `src/parser/entdados.jl`

**Fields**:
- `tipo_limite`: Iteration limit type (0=maximum, 1=fixed)
- `iteracoes`: Number of iterations

**Purpose**: Controls the number of power flow iterations when solving the network model with iterative methods (e.g., PDD - Primal-Dual Decomposition).

## Hierarchical Structures

### 0. HIDR.DAT Record Hierarchy

**Complete HIDR.DAT Structure** (Text Format):
```
HidrData
    ├─► CADUSIH[] (Plant Registry)
    │       ├─► plant_num (PK)
    │       ├─► plant_name
    │       ├─► subsystem (FK → SIST)
    │       ├─► downstream_plant (FK → CADUSIH, self-reference)
    │       ├─► min_volume, max_volume (hm³)
    │       ├─► installed_capacity (MW)
    │       └─► productivity (MW/m³/s)
    │
    ├─► USITVIAG[] (Travel Times)
    │       ├─► from_plant (FK → CADUSIH)
    │       ├─► to_plant (FK → CADUSIH)
    │       └─► travel_time (hours)
    │
    ├─► POLCOT[] (Volume-Elevation Polynomials)
    │       ├─► plant_num (FK → CADUSIH)
    │       └─► coefficients[5] (polynomial a₀ + a₁V + a₂V² + ...)
    │
    ├─► POLARE[] (Volume-Area Polynomials)
    │       ├─► plant_num (FK → CADUSIH)
    │       └─► coefficients[5]
    │
    ├─► POLJUS[] (Tailrace Elevation Polynomials)
    │       ├─► plant_num (FK → CADUSIH)
    │       └─► coefficients[5]
    │
    ├─► COEFEVA[] (Evaporation Coefficients)
    │       ├─► plant_num (FK → CADUSIH)
    │       └─► coefficients[12] (monthly evaporation rates)
    │
    └─► CADCONJ[] (Unit Set Registry)
            ├─► plant_num (FK → CADUSIH)
            ├─► set_num (part of composite PK)
            ├─► num_units (number of identical units)
            ├─► unit_capacity (MW per unit)
            └─► Referenced by: UCH.(plant_num, set_num)
```

**Binary Format Limitations**:
```
Binary HIDR.DAT (792 bytes/plant)
    └─► CADUSIH[] ONLY
            ├─► 111 fields available in binary
            ├─► 14 fields mapped to CADUSIH struct
            └─► Missing: USITVIAG, POLCOT, POLARE, POLJUS, COEFEVA, CADCONJ
                        (must be obtained from other sources or derived)
```

**Cascade Topology from HIDR.DAT**:
```
River Basin Network (from downstream_plant field)
    └─► Plant A (upstream, downstream_plant = NULL)
            └─► Plant B (downstream_plant = A)
                    ├─► Plant C (downstream_plant = B)
                    │       └─► Plant E (downstream_plant = C)
                    └─► Plant D (downstream_plant = B)
                            └─► Plant F (downstream_plant = D)
```

**Example Query: Build Complete Cascade**
```julia
# Using parsed HidrData
function build_cascade_tree(root_plant_num, hidr_data)
    plant = findfirst(p -> p.plant_num == root_plant_num, hidr_data.plants)
    downstream_plants = filter(p -> p.downstream_plant == root_plant_num, hidr_data.plants)
    
    tree = Dict(
        "plant" => plant,
        "downstream" => [build_cascade_tree(p.plant_num, hidr_data) for p in downstream_plants]
    )
    
    return tree
end
```

### 1. Geographical/Electrical Hierarchy
```
SYSTEM (Brazil)
    └─► SUBSYSTEM (SE, S, NE, N) [SIST]
            ├─► HYDRO_PLANT [UH, CADUSIH]
            │       └─► HYDRO_UNIT_SET [CADCONJ]
            │               └─► HYDRO_UNIT [UCH]
            │
            ├─► THERMAL_PLANT [UT, CADUSIT]
            │       └─► THERMAL_UNIT [CADUNIDT]
            │
            └─► NETWORK_BUS [DBAR]
                    ├─► TRANSMISSION_LINE [DLIN]
                    └─► LOAD [DBAR]
```

### 2. Cascade Topology (River Basin)

**Implementation**: Defined in HIDR.DAT via `downstream_plant` field

```
RIVER_BASIN (e.g., Paranapanema River - Southeast Brazil)
    └─► A.A. LAYDNER (#47, upstream) [downstream_plant = NULL]
            └─► PIRAJU (#48) [downstream_plant = 47]
                    └─► PARANAPANEMA (#53) [downstream_plant = 48]
                            └─► CHAVANTES (#49) [downstream_plant = 53]
                                    └─► OURINHOS (#249) [downstream_plant = 49]
                                            └─► L.N. GARCEZ (#50) [downstream_plant = 249]
                                                    └─► CANOAS II (#51) [downstream_plant = 50]
                                                            └─► CANOAS I (#52) [downstream_plant = 51]
                                                                    └─► CAPIVARA (#61) [downstream_plant = 52]
                                                                            └─► TAQUARUCU (#62) [downstream_plant = 61]
                                                                                    └─► ROSANA (#63) [downstream_plant = 62]
                                                                                            └─► (final discharge)
```

**Real-World Example** (from DS_ONS_102025_RV2D11 sample):
- **Paranaíba River Cascade** (6 plants, ~1,785 MW total):
  ```
  BOCAINA (#20, 75 MW, 2186-9010 hm³)
    → EMBORCACAO (#24, 298 MW, 4669-17725 hm³)
      → ITUMBIARA (#31, 347 MW, 4573-17027 hm³)
        → CACH.DOURADA (#32, 260 MW, 460 hm³)
          → SAO SIMAO (#33, 285 MW, 7000-12540 hm³)
            → I. SOLTEIRA (#34, 520 MW, 8232-21060 hm³)
  ```

**Key Fields**:
- `CADUSIH.downstream_plant`: Direct downstream plant (FK to plant_num)
- `CADUSIH.diversion_plant`: Diversion channel downstream plant (alternative path)
- `USITVIAG.travel_time`: Water travel time between plants (hours)
- `USITVIAG.from_plant` → `to_plant`: Explicit travel time relationship

**Cascade Properties**:
- Forms **Directed Acyclic Graph (DAG)**
- Root nodes: `downstream_plant = NULL` or `0`
- Leaf nodes: No other plant references this plant as downstream
- Can have **branching** (multiple plants flow into one downstream)
- **Diversion channels** create alternative flow paths

**Traversal Algorithms**:
```julia
# Downstream traversal (recursive)
function traverse_downstream(plant_num, hidr_data)
    plant = get_plant(plant_num, hidr_data)
    if plant.downstream_plant !== nothing && plant.downstream_plant > 0
        downstream = traverse_downstream(plant.downstream_plant, hidr_data)
        return [plant, downstream...]
    else
        return [plant]  # Leaf node
    end
end

# Upstream traversal (find all plants flowing into this one)
function find_upstream(plant_num, hidr_data)
    return filter(p -> p.downstream_plant == plant_num, hidr_data.plants)
end

# Find cascade roots (plants with no upstream)
function find_cascade_roots(hidr_data)
    downstream_set = Set(p.downstream_plant for p in hidr_data.plants 
                         if p.downstream_plant !== nothing && p.downstream_plant > 0)
    return filter(p -> p.plant_num ∉ downstream_set, hidr_data.plants)
end
```

**Water Balance Implications**:
```
Plant i water balance:
    V(i,t+1) = V(i,t) + Δt * [
        Q_inflow(i,t)                          # Natural inflows
        + ∑(Q_turbine(j,t-τⱼᵢ))                # Upstream plant discharges
          j∈upstream(i)                        # (delayed by travel time τⱼᵢ)
        - Q_turbine(i,t)                       # This plant's turbine discharge
        - Q_spill(i,t)                         # This plant's spillage
        - Q_evap(i,t)                          # Evaporation losses
        + Q_lateral(i,t)                       # Incremental lateral inflows
    ]
```

### 3. Combined-Cycle Configuration
```
THERMAL_PLANT
    ├─► CONFIGURATION_1 (Gas Turbine)
    │       ├─► UNIT_1 [CADCONF]
    │       └─► UNIT_2 [CADCONF]
    │
    └─► CONFIGURATION_2 (Steam Turbine - dependent on GT)
            └─► UNIT_3 [CADCONF, requires CADMIN]
```

**Key Tables**:
- **CADCONF**: Defines units in each equivalent configuration
- **CADMIN**: Defines dependency (minimum units needed to activate configuration)

---

## Cross-File References

### File Dependencies and Foreign Key Paths

```
DESSEM.ARQ (Index)
    └─► References all input files

ENTDADOS.XXX (Master Configuration)
    ├─► SIST.subsystem_num
    │       ├─► Referenced by: UH.subsystem
    │       ├─► Referenced by: UT.subsystem
    │       ├─► Referenced by: DP.subsystem
    │       ├─► Referenced by: USIE.subsystem_code
    │       ├─► Referenced by: REE.subsystem_code
    │       ├─► Referenced by: CE/CI.submkt_code
    │       ├─► Referenced by: EOLICA.subsystem
    │       └─► Referenced by: Network DBAR.subsystem
    │
    ├─► REE.ree_code
    │       └─► Referenced by: UH.ree_code (optional grouping)
    │
    ├─► UH.plant_num
    │       ├─► Referenced by: HIDR.CADUSIH.plant_num
    │       ├─► Referenced by: DADVAZ.plant_num
    │       ├─► Referenced by: OPERUH.plant_num
    │       ├─► Referenced by: DA.plant_num
    │       ├─► Referenced by: VE.plant_num
    │       ├─► Referenced by: AC.plant_code
    │       └─► Referenced by: USIE.upstream_plant, USIE.downstream_plant
    │
    ├─► UT.plant_num
    │       ├─► Referenced by: TERM.CADUSIT.plant_num
    │       └─► Referenced by: OPERUT.plant_num
    │
    ├─► USIE.plant_code
    │       └─► Referenced by: PE.plant_code
    │
    ├─► DE.demand_code
    │       └─► Referenced by: FC.load_code
    │
    ├─► CE/CI.contract_num
    │       └─► Referenced by: FC.contract_code
    │
    └─► TM.(day, hour, half_hour)
            ├─► Referenced by: All time-varying records
            ├─► Referenced by: SIMUL.DISC
            ├─► Referenced by: RI (Itaipu restrictions)
            ├─► Referenced by: IT (Itaipu binational)
            └─► Referenced by: EOLICAGERACAO (renewable forecasts)

HIDR.DAT (Hydro Registry)
    ├─► Format Detection: Auto-detect binary (792 bytes) or text format
    │   └─► Parser: src/parser/hidr.jl, src/parser/hidr_binary.jl
    │
    ├─► CADUSIH.plant_num → UH.plant_num (FK)
    │       └─► Referenced by: CADCONJ.plant_num
    │
    ├─► USITVIAG.(from_plant, to_plant) → CADUSIH.plant_num (FK)
    │       └─► Defines water travel times between plants
    │
    ├─► POLCOT.plant_num → CADUSIH.plant_num (FK)
    │       └─► Volume-elevation polynomial coefficients
    │
    ├─► POLARE.plant_num → CADUSIH.plant_num (FK)
    │       └─► Volume-area polynomial coefficients
    │
    ├─► POLJUS.plant_num → CADUSIH.plant_num (FK)
    │       └─► Tailrace elevation polynomial coefficients
    │
    ├─► COEFEVA.plant_num → CADUSIH.plant_num (FK)
    │       └─► Evaporation coefficients
    │
    └─► CADCONJ.(plant_num, set_num)
            └─► Referenced by: UCH.(plant_num, set_num)
            └─► Note: Only in text format, NOT in binary format

**Binary Format Notes**:
- Binary HIDR contains only plant registry (CADUSIH equivalent)
- 111 fields per 792-byte record (see HIDR_BINARY_COMPLETE.md)
- Auxiliary data (travel times, polynomials, unit sets) must come from:
  * Separate text files
  * Derived from binary fields
  * UCH file for unit configuration

TERM.DAT (Thermal Registry)
    ├─► CADUSIT.plant_num → UT.plant_num (FK)
    │       ├─► Referenced by: CADUNIDT.plant_num
    │       ├─► Referenced by: CADCONF.plant_num
    │       └─► Referenced by: CADMIN.plant_num
    │
    └─► CADUNIDT.(plant_num, unit_num)
            ├─► Referenced by: OPERUT.INIT.(plant_num, unit_num)
            ├─► Referenced by: OPERUT.OPER.(plant_num, unit_num)
            └─► Referenced by: CURVACOMB.(plant_num, unit_num)

DADVAZ.XXX (Inflows)
    └─► plant_num → UH.plant_num (FK)

OPERUH.XXX (Hydro Constraints)
    └─► plant_num → UH.plant_num (FK)

OPERUT.XXX (Thermal Operations)
    ├─► INIT.(plant_num, unit_num) → CADUNIDT.(plant_num, unit_num) (FK)
    └─► OPER.(plant_num, unit_num) → CADUNIDT.(plant_num, unit_num) (FK)

UCH (Hydro Unit Commitment)
    └─► (plant_num, set_num, unit_num) → CADCONJ.(plant_num, set_num) (FK)

Network Files (.pwf)
    ├─► DBAR.bus_num (PK)
    │       ├─► Referenced by: DLIN.from_bus, DLIN.to_bus
    │       └─► Referenced by: Plant connections
    │
    └─► DBAR.subsystem → SIST.subsystem_num (FK)
```

---

## Temporal Relationships

### Time-Varying Data Patterns

**1. Period-Based (Start/End Time)**
```
Records with time ranges: (start_day, start_hour, start_half) → (end_day, end_hour, end_half)

- ENTDADOS.DP (Demand)
- ENTDADOS.IA (Interchange)
- ENTDADOS.DA (Withdrawal)
- ENTDADOS.VE (Flood control)
- OPERUH constraints
- Maintenance records (MH, MT, ME)
```

**2. Instant-Based (Single Time Point)**
```
Records at specific time: (day, hour, half_hour)

- ENTDADOS.TM (Time discretization)
- OPERUT.OPER (Operating costs and limits)
- SIMUL.DISC (Simulation periods)
```

**3. Initial Conditions (Study Start)**
```
Records at t=0:

- UH.initial_volume (Hydro initial volume)
- OPERUT.INIT (Thermal initial status)
- UCH.INITIAL_CONDITION (Hydro unit status)
- SIMUL.VOLI (Simulation initial volumes)
```

---

## Referential Integrity Rules

### Mandatory Foreign Keys (NOT NULL)
```sql
-- All plants must belong to a subsystem
UH.subsystem → SIST.subsystem_num (NOT NULL)
UT.subsystem → SIST.subsystem_num (NOT NULL)
CADUSIT.subsystem → SIST.subsystem_num (NOT NULL)

-- All units must belong to a plant
CADUNIDT.plant_num → CADUSIT.plant_num (NOT NULL)
CADCONJ.plant_num → CADUSIH.plant_num (NOT NULL)

-- All operational data must reference existing plants/units
OPER.(plant_num, unit_num) → CADUNIDT.(plant_num, unit_num) (NOT NULL)
DADVAZ.plant_num → CADUSIH.plant_num (NOT NULL)

-- All time-varying data must reference valid time periods
*.start_time → TM.(day, hour, half) (NOT NULL)
```

### Optional Foreign Keys (NULL allowed)
```sql
-- Cascade topology (upstream plants have NULL)
CADUSIH.downstream_plant → CADUSIH.plant_num (NULL for upstream)
CADUSIH.diversion_plant → CADUSIH.plant_num (NULL if no diversion)

-- Optional configurations
CADCONF.plant_num → CADUSIT.plant_num (NULL if not combined-cycle)
```

### Cascade Delete Rules
```sql
-- Deleting a subsystem should fail if plants exist
DELETE SIST WHERE subsystem_num = X
  → RESTRICT if exists UH/UT with subsystem = X

-- Deleting a plant should cascade to units
DELETE CADUSIT WHERE plant_num = X
  → CASCADE delete CADUNIDT where plant_num = X

-- Deleting a plant should cascade to operational data
DELETE CADUSIH WHERE plant_num = X
  → CASCADE delete OPERUH where plant_num = X
  → CASCADE delete DADVAZ where plant_num = X
```

---

## Query Examples

### HIDR.DAT Queries

#### Parse HIDR file (auto-detect format)
```julia
using DESSEM2Julia

# Auto-detects binary or text format
hidr_data = parse_hidr("path/to/hidr.dat")

# Check format
if isempty(hidr_data.travel_times)
    println("Binary format (plant registry only)")
else
    println("Text format (complete with auxiliary records)")
end
```

#### Find plants in subsystem
```julia
# Get all Southeast plants (subsystem 1)
se_plants = filter(p -> p.subsystem == 1, hidr_data.plants)

total_capacity = sum(p.installed_capacity for p in se_plants if p.installed_capacity !== nothing)
println("Southeast capacity: $(round(total_capacity, digits=1)) MW")
```

#### Build complete cascade from root
```julia
# Find cascade starting points (no upstream plants)
function find_cascade_roots(hidr_data)
    downstream_set = Set(p.downstream_plant for p in hidr_data.plants 
                         if p.downstream_plant !== nothing && p.downstream_plant > 0)
    roots = filter(p -> p.plant_num > 0 && p.plant_num ∉ downstream_set, hidr_data.plants)
    return roots
end

# Traverse downstream from root
function print_cascade(plant_num, hidr_data, indent=0)
    plant = findfirst(p -> p.plant_num == plant_num, hidr_data.plants)
    if plant === nothing
        return
    end
    
    println("  "^indent * "$(plant.plant_name) (#$(plant.plant_num)) - $(plant.installed_capacity) MW")
    
    if plant.downstream_plant !== nothing && plant.downstream_plant > 0
        print_cascade(plant.downstream_plant, hidr_data, indent + 1)
    end
end

# Print all cascades
roots = find_cascade_roots(hidr_data)
for root in roots
    println("\nCascade starting at: $(root.plant_name)")
    print_cascade(root.plant_num, hidr_data)
end
```

#### Get travel times between plants
```julia
# Find travel time from plant A to plant B
function get_travel_time(from_plant, to_plant, hidr_data)
    travel = findfirst(t -> t.from_plant == from_plant && t.to_plant == to_plant, 
                      hidr_data.travel_times)
    if travel !== nothing
        return travel.travel_time  # hours
    else
        return nothing  # No explicit travel time defined
    end
end
```

#### Get volume-elevation polynomial
```julia
# Calculate reservoir elevation from volume
function calculate_elevation(plant_num, volume_hm3, hidr_data)
    polcot = findfirst(p -> p.plant_num == plant_num, hidr_data.volume_elevation)
    if polcot === nothing
        return nothing
    end
    
    # Elevation = a₀ + a₁*V + a₂*V² + a₃*V³ + a₄*V⁴
    coeffs = polcot.coefficients
    elevation = coeffs[1] + 
                coeffs[2] * volume_hm3 + 
                coeffs[3] * volume_hm3^2 + 
                coeffs[4] * volume_hm3^3 + 
                coeffs[5] * volume_hm3^4
    
    return elevation  # meters
end
```

#### Calculate cascade storage capacity
```julia
# Get total storage capacity of entire cascade
function cascade_storage_capacity(root_plant_num, hidr_data)
    total_min = 0.0
    total_max = 0.0
    
    function accumulate_storage(plant_num)
        plant = findfirst(p -> p.plant_num == plant_num, hidr_data.plants)
        if plant === nothing
            return
        end
        
        if plant.min_volume !== nothing
            total_min += plant.min_volume
        end
        if plant.max_volume !== nothing
            total_max += plant.max_volume
        end
        
        # Recurse downstream
        if plant.downstream_plant !== nothing && plant.downstream_plant > 0
            accumulate_storage(plant.downstream_plant)
        end
    end
    
    accumulate_storage(root_plant_num)
    return (min=total_min, max=total_max, useful=total_max - total_min)
end
```

### Find All Plants in a Subsystem
```julia
# Given subsystem_num = 1 (SE)
hydro_plants = filter(p -> p.subsystem == 1, entdados.hydro_plants)
thermal_plants = filter(p -> p.subsystem == 1, entdados.thermal_plants)
```

### Traverse Cascade Topology (Downstream)
```julia
# Find all downstream plants from a given plant
function find_downstream_cascade(plant_num, hidr_data)
    downstream = filter(p -> p.downstream_plant == plant_num, hidr_data.plants)
    result = [plant_num]
    for d in downstream
        append!(result, find_downstream_cascade(d.plant_num, hidr_data))
    end
    return result
end
```

### Join Thermal Plant with Operating Costs
```julia
# Get thermal units with their operating costs for a time period
for unit in termdat.units
    plant = filter(p -> p.plant_num == unit.plant_num, termdat.plants)[1]
    oper_costs = filter(o -> o.plant_num == unit.plant_num && 
                              o.unit_num == unit.unit_num, 
                        operut.oper_records)
    
    println("Plant: $(plant.plant_name), Unit: $(unit.unit_num)")
    for cost in oper_costs
        println("  Period $(cost.day)/$(cost.hour): $(cost.operating_cost) R\$/MWh")
    end
end
```

### Find All Units in Hydro Plant
```julia
# Get hierarchy: Plant → Unit Sets → Units
function get_hydro_units(plant_num, hidr_data, uch_data)
    unit_sets = filter(s -> s.plant_num == plant_num, hidr_data.unit_sets)
    
    for set in unit_sets
        units = filter(u -> u.plant_num == plant_num && 
                           u.set_num == set.set_num, 
                      uch_data.units)
        println("Set $(set.set_num): $(length(units)) units")
    end
end
```

### Time-Based Queries
```julia
# Get all demand for a subsystem in a time range
function get_demand_profile(subsystem_num, start_day, end_day, entdados)
    demands = filter(d -> d.subsystem == subsystem_num &&
                         d.start_day >= start_day &&
                         d.end_day <= end_day,
                    entdados.demand_records)
    return demands
end
```

---

## Database Schema Equivalence

If DESSEM files were implemented as a relational database:

```sql
-- Core Entities

CREATE TABLE subsystems (
    subsystem_num INT PRIMARY KEY,
    subsystem_code CHAR(2) NOT NULL,
    subsystem_name VARCHAR(10),
    status INT DEFAULT 0
);

CREATE TABLE hydro_plants (
    plant_num INT PRIMARY KEY,
    plant_name VARCHAR(12) NOT NULL,
    subsystem INT NOT NULL,
    downstream_plant INT NULL,
    diversion_plant INT NULL,
    status INT DEFAULT 0,
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num),
    FOREIGN KEY (downstream_plant) REFERENCES hydro_plants(plant_num),
    FOREIGN KEY (diversion_plant) REFERENCES hydro_plants(plant_num)
);

CREATE TABLE thermal_plants (
    plant_num INT PRIMARY KEY,
    plant_name VARCHAR(12) NOT NULL,
    subsystem INT NOT NULL,
    num_units INT NOT NULL,
    status INT DEFAULT 0,
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num)
);

CREATE TABLE thermal_units (
    plant_num INT,
    unit_num INT,
    unit_capacity REAL NOT NULL,
    min_generation REAL DEFAULT 0.0,
    cold_startup_cost REAL DEFAULT 0.0,
    hot_startup_cost REAL DEFAULT 0.0,
    PRIMARY KEY (plant_num, unit_num),
    FOREIGN KEY (plant_num) REFERENCES thermal_plants(plant_num)
        ON DELETE CASCADE
);

CREATE TABLE hydro_unit_sets (
    plant_num INT,
    set_num INT,
    num_units INT NOT NULL,
    unit_capacity REAL NOT NULL,
    PRIMARY KEY (plant_num, set_num),
    FOREIGN KEY (plant_num) REFERENCES hydro_plants(plant_num)
        ON DELETE CASCADE
);

CREATE TABLE hydro_units (
    plant_num INT,
    set_num INT,
    unit_num INT,
    PRIMARY KEY (plant_num, set_num, unit_num),
    FOREIGN KEY (plant_num, set_num) 
        REFERENCES hydro_unit_sets(plant_num, set_num)
        ON DELETE CASCADE
);

-- Time Periods

CREATE TABLE time_periods (
    day INT,
    hour INT,
    half_hour INT,
    duration REAL DEFAULT 1.0,
    network_flag INT,
    PRIMARY KEY (day, hour, half_hour)
);

-- Operational Data

CREATE TABLE thermal_operations (
    plant_num INT,
    unit_num INT,
    day INT,
    hour INT,
    half_hour INT,
    operating_cost REAL,
    min_generation REAL,
    max_generation REAL,
    PRIMARY KEY (plant_num, unit_num, day, hour, half_hour),
    FOREIGN KEY (plant_num, unit_num) 
        REFERENCES thermal_units(plant_num, unit_num),
    FOREIGN KEY (day, hour, half_hour)
        REFERENCES time_periods(day, hour, half_hour)
);

CREATE TABLE inflows (
    plant_num INT,
    day INT,
    hour INT,
    half_hour INT,
    inflow_rate REAL NOT NULL,
    inflow_type INT,
    PRIMARY KEY (plant_num, day, hour, half_hour),
    FOREIGN KEY (plant_num) REFERENCES hydro_plants(plant_num),
    FOREIGN KEY (day, hour, half_hour)
        REFERENCES time_periods(day, hour, half_hour)
);

-- Restrictions (Many-to-Many)

CREATE TABLE restrictions (
    restriction_num INT PRIMARY KEY,
    lower_limit REAL,
    upper_limit REAL
);

CREATE TABLE restriction_hydro_coefficients (
    restriction_num INT,
    plant_num INT,
    set_num INT NULL,
    coefficient REAL NOT NULL,
    PRIMARY KEY (restriction_num, plant_num, set_num),
    FOREIGN KEY (restriction_num) REFERENCES restrictions(restriction_num),
    FOREIGN KEY (plant_num) REFERENCES hydro_plants(plant_num)
);

CREATE TABLE restriction_thermal_coefficients (
    restriction_num INT,
    plant_num INT,
    coefficient REAL NOT NULL,
    PRIMARY KEY (restriction_num, plant_num),
    FOREIGN KEY (restriction_num) REFERENCES restrictions(restriction_num),
    FOREIGN KEY (plant_num) REFERENCES thermal_plants(plant_num)
);
```

---

## Summary

The DESSEM input file system represents a complex relational database distributed across multiple text files:

1. **Master-Detail Relationships**: Subsystems contain plants, plants contain units
2. **Graph Structures**: Cascade topology forms directed acyclic graph
3. **Time-Series Data**: Operational data indexed by time periods
4. **Many-to-Many Relationships**: Restrictions connect to multiple plants via coefficient tables
5. **Hierarchical Constraints**: Three-level hierarchy for hydro units (plant → set → unit)
6. **Cross-File Integrity**: Foreign keys span multiple files requiring coordinated parsing

### Complete Entity Catalog

**Power System Entities** (8):
- Subsystem (SIST)
- Energy Reservoir Equivalent (REE)
- Load Demand (DP)
- Special Demand (DE)
- Deficit Cost (CD)
- Interchange Limits (IA)
- Export Contract (CE)
- Import Contract (CI)

**Hydroelectric Entities** (7):
- Hydro Plant (UH, CADUSIH)
- Hydro Unit Set (CADCONJ)
- Hydro Unit (UCH)
- Pump Station (USIE)
- Travel Time (USITVIAG, TVIAG)
- Water Withdrawal (DA)
- Flood Control Volume (VE)

**Thermal Entities** (4):
- Thermal Plant (UT, CADUSIT)
- Thermal Unit (CADUNIDT)
- Combined-Cycle Configuration (CADCONF)
- Simple-Cycle Configuration (CADMIN)

**Renewable Entities** (4):
- Wind Plant (EOLICA)
- Wind Plant Bus Connection (EOLICABARRA)
- Wind Plant Subsystem (EOLICASUBM)
- Wind Generation Forecast (EOLICAGERACAO)

**Network Entities** (3):
- Network Bus (DBAR)
- Transmission Line (DLIN)
- Area Control (AREACONT)

**Operational Constraint Entities** (17):
- Electrical Restriction (RE)
- Restriction Limits (LU)
- Hydro Coefficient (FH)
- Thermal Coefficient (FT)
- Interchange Coefficient (FI)
- Pumping Coefficient (FE)
- Renewable Coefficient (FR)
- Contract/Load Coefficient (FC)
- Hydro Operation Restriction (OPERUH REST)
- Hydro Operation Element (OPERUH ELEM)
- Hydro Operation Limit (OPERUH LIM)
- Hydro Operation Variation (OPERUH VAR)
- Thermal Ramp (OPERUT RAMP)
- LPP Constraint (RSTLPP)
- Security Constraint (RESTSEG)
- Flow Ramp (RMPFLX)
- Trajectory Constraint (RAMPAS)

**Temporal Entities** (2):
- Time Period (TM)
- Simulation Period (SIMUL DISC)

**Maintenance Entities** (3):
- Hydro Maintenance (MH)
- Thermal Maintenance (MT)
- Pump Maintenance (PE)

**Special Constraint Entities** (5):
- Itaipu Restriction (RI)
- Itaipu Binational (IT)
- Itaipu Reactive Power (PQ)
- Gauge 11 Constraint (R11)
- Production Function Parameter (FP)

**River Section Entities** (2):
- River Section (SECR)
- Section Head-Flow Polynomial (CR)

**Plant Adjustment Entities** (16 AC types):
- Volume Maximum (ACVOLMAX)
- Volume Minimum (ACVOLMIN)
- Spillway Volume (ACVSVERT)
- Diversion Volume (ACVMDESV)
- Head-Flow Polynomial (ACCOTVAZ)
- Head-Volume Polynomial (ACCOTVOL)
- Tailrace Polynomial (ACCOTTAR)
- Number of Sets (ACNUMCON)
- Downstream Plant (ACNUMJUS)
- Station Number (ACNUMPOS)
- Downstream Elevation (ACJUSENA)
- Average Tailrace (ACJUSMED)
- Evaporation Coefficient (ACCOFEVA)
- Number of Machines (ACNUMMAQ)
- Effective Power (ACPOTEFE)
- Diversion (ACDESVIO)

**Miscellaneous Entities** (4):
- Discount Rate (TX)
- Coupling Volume (EZ)
- Network Iteration Control (NI)
- Convergence Gap (GP)

**Total**: **76+ distinct entity types** across 32 DESSEM input files

### Key Implementation Notes

**HIDR.DAT Parser** (`src/parser/hidr.jl`, `src/parser/hidr_binary.jl`):
- ✅ **Binary format support**: 792 bytes/plant (ONS/CCEE official format)
  - 111 fields per record (Int32, Int64, Float32, fixed strings)
  - Auto-detection via file size and posto field validation
  - Successfully parses 185+ plants from ONS samples
  - Reference: IDESSEM (rjmalves/idessem)
  
- ✅ **Text format support**: 7 record types
  - CADUSIH (plant registry)
  - USITVIAG (travel times)
  - POLCOT (volume-elevation polynomials)
  - POLARE (volume-area polynomials)
  - POLJUS (tailrace elevation polynomials)
  - COEFEVA (evaporation coefficients)
  - CADCONJ (unit set configuration)

- 🔄 **Format auto-detection**: Single `parse_hidr()` function routes to appropriate parser

**Binary Format Limitations**:
- Contains only plant registry (CADUSIH equivalent)
- Missing: travel times, polynomials, unit sets, evaporation data
- These must be obtained from:
  - Separate text HIDR files
  - UCH file (for unit configuration)
  - Derived from other binary fields
  - Default values/models

**Cascade Topology**:
- Implemented via `downstream_plant` field (self-referencing FK)
- Creates directed acyclic graph of reservoir network
- Real-world cascades can be 11+ plants long
- Example: Paranapanema River (A.A. LAYDNER → ... → ROSANA, 11 plants, ~923 MW)

Understanding these relationships is crucial for:
- Validating input data consistency
- Building efficient data structures
- Implementing queries across multiple files
- Ensuring referential integrity during parsing
- Optimizing model construction for DESSEM solver
- Analyzing hydroelectric cascade operations
