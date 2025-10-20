# HIDR.DAT Entity Relationship Diagram

> **📚 Part of**: [DESSEM2Julia Documentation](INDEX.md) | **📖 Also see**: [HIDR Quick Reference](HIDR_QUICK_REFERENCE.md), [HIDR Binary Complete](HIDR_BINARY_COMPLETE.md), [Entity Relationships](ENTITY_RELATIONSHIPS.md)

## Complete Structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           HIDR.DAT FILE                                 │
│                                                                         │
│  Format Detection:                                                      │
│    - Binary: file_size % 792 == 0 && valid posto field                │
│    - Text: Line-based with record type codes                           │
│                                                                         │
│  Parser: parse_hidr(filepath) → HidrData                               │
└─────────────────────────────────────────────────────────────────────────┘
                                     │
                                     │ parses to
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          HidrData (struct)                              │
├─────────────────────────────────────────────────────────────────────────┤
│  plants::Vector{CADUSIH}              # Plant registry                  │
│  travel_times::Vector{USITVIAG}       # Water travel times              │
│  volume_elevation::Vector{POLCOT}     # V→h polynomials                 │
│  volume_area::Vector{POLARE}          # V→A polynomials                 │
│  tailrace::Vector{POLJUS}             # Q→h_tailrace polynomials        │
│  evaporation::Vector{COEFEVA}         # Monthly evaporation coeffs      │
│  unit_sets::Vector{CADCONJ}           # Hydro unit set configuration    │
└─────────────────────────────────────────────────────────────────────────┘
       │              │              │              │              │
       │ 1            │ *            │ *            │ *            │ *
       │              │              │              │              │
       ▼              ▼              ▼              ▼              ▼
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│ CADUSIH  │   │ USITVIAG │   │  POLCOT  │   │  POLARE  │   │ CADCONJ  │
│  (PK)    │   │   (FK)   │   │   (FK)   │   │   (FK)   │   │   (FK)   │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
     │                                                              │
     │ plant_num (PK)                                              │
     │ subsystem (FK → ENTDADOS.SIST)                              │
     │ downstream_plant (FK → CADUSIH.plant_num, self-ref)         │
     │                                                              │
     └──────────────────────────────────────────────────────────────┘
                                                                    │
                                                                    ▼
                                                            ┌──────────────┐
                                                            │     UCH      │
                                                            │  (FK to PK)  │
                                                            └──────────────┘
```

## Detailed Entity Relationships

### 1. CADUSIH (Hydroelectric Plant Registry)

**Primary Entity**: Plant
**Primary Key**: `plant_num`

```
CADUSIH
  ├─ plant_num (PK)
  ├─ plant_name
  ├─ subsystem (FK)              → ENTDADOS.SIST.subsystem_num
  ├─ downstream_plant (FK)       → CADUSIH.plant_num (self-reference)
  ├─ diversion_downstream (FK)   → CADUSIH.plant_num (self-reference)
  ├─ min_volume
  ├─ max_volume
  ├─ installed_capacity
  └─ productivity

Referenced by:
  ├─ USITVIAG.from_plant / to_plant
  ├─ POLCOT.plant_num
  ├─ POLARE.plant_num
  ├─ POLJUS.plant_num
  ├─ COEFEVA.plant_num
  ├─ CADCONJ.plant_num
  ├─ ENTDADOS.UH.plant_num
  ├─ DADVAZ.plant_num
  └─ OPERUH.plant_num
```

### 2. USITVIAG (Travel Times)

**Entity**: Water Travel Time Between Plants
**Composite Key**: `(from_plant, to_plant)`

```
USITVIAG
  ├─ from_plant (FK) → CADUSIH.plant_num
  ├─ to_plant (FK)   → CADUSIH.plant_num
  └─ travel_time (hours)

Relationship: MANY-TO-MANY (plants to plants)
Purpose: Define water flow delay in cascade
```

### 3. POLCOT (Volume-Elevation Polynomial)

**Entity**: Reservoir Volume to Elevation Curve
**Primary Key**: `plant_num`

```
POLCOT
  ├─ plant_num (FK) → CADUSIH.plant_num
  └─ coefficients[5] → [a₀, a₁, a₂, a₃, a₄]

Formula: h(V) = a₀ + a₁·V + a₂·V² + a₃·V³ + a₄·V⁴
  where: h = elevation (m), V = volume (hm³)

Relationship: ONE-TO-ONE (plant to polynomial)
```

### 4. POLARE (Volume-Area Polynomial)

**Entity**: Reservoir Volume to Surface Area Curve
**Primary Key**: `plant_num`

```
POLARE
  ├─ plant_num (FK) → CADUSIH.plant_num
  └─ coefficients[5] → [a₀, a₁, a₂, a₃, a₄]

Formula: A(V) = a₀ + a₁·V + a₂·V² + a₃·V³ + a₄·V⁴
  where: A = area (km²), V = volume (hm³)

Relationship: ONE-TO-ONE (plant to polynomial)
Purpose: Calculate evaporation losses
```

### 5. POLJUS (Tailrace Elevation Polynomial)

**Entity**: Discharge to Tailrace Elevation Curve
**Primary Key**: `plant_num`

```
POLJUS
  ├─ plant_num (FK) → CADUSIH.plant_num
  └─ coefficients[5] → [a₀, a₁, a₂, a₃, a₄]

Formula: h_tailrace(Q) = a₀ + a₁·Q + a₂·Q² + a₃·Q³ + a₄·Q⁴
  where: h_tailrace = elevation (m), Q = discharge (m³/s)

Relationship: ONE-TO-ONE (plant to polynomial)
Purpose: Calculate net head for generation
```

### 6. COEFEVA (Evaporation Coefficients)

**Entity**: Monthly Evaporation Rates
**Primary Key**: `plant_num`

```
COEFEVA
  ├─ plant_num (FK) → CADUSIH.plant_num
  └─ coefficients[12] → [Jan, Feb, ..., Dec]

Unit: mm/day for each month

Relationship: ONE-TO-ONE (plant to coefficients)
Purpose: Calculate monthly evaporation losses
```

### 7. CADCONJ (Hydro Unit Sets)

**Entity**: Group of Identical Generating Units
**Composite Primary Key**: `(plant_num, set_num)`

```
CADCONJ
  ├─ plant_num (FK) → CADUSIH.plant_num
  ├─ set_num (part of PK)
  ├─ num_units
  └─ unit_capacity

Relationship: ONE-TO-MANY (plant to sets)
Referenced by: UCH.(plant_num, set_num, unit_num)
Purpose: Define generating unit configuration
```

## Cascade Topology (Self-Referencing FK)

```
                     ┌───────────┐
                     │ CADUSIH   │
                     │ Plant A   │
                     │ #1        │
                     └─────┬─────┘
                           │ downstream_plant = 1
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
    ┌──────────┐     ┌──────────┐    ┌──────────┐
    │ CADUSIH  │     │ CADUSIH  │    │ CADUSIH  │
    │ Plant B  │     │ Plant C  │    │ Plant D  │
    │ #2       │     │ #3       │    │ #4       │
    └────┬─────┘     └────┬─────┘    └────┬─────┘
         │ d.p.=2         │ d.p.=3         │ d.p.=4
         ▼                ▼                ▼
    ┌──────────┐     ┌──────────┐    ┌──────────┐
    │ CADUSIH  │     │ CADUSIH  │    │ CADUSIH  │
    │ Plant E  │     │ Plant F  │    │ Plant G  │
    │ #5       │     │ #6       │    │ #7       │
    └──────────┘     └──────────┘    └──────────┘
    d.p. = NULL      d.p. = NULL     d.p. = NULL

Legend:
  d.p. = downstream_plant (FK to plant_num)
  NULL = Terminal plant (no downstream)
```

## Cross-File Relationships

```
┌──────────────┐
│ ENTDADOS.XXX │
├──────────────┤
│ SIST         │──────────────┐
│   subsystem_num (PK)        │
└──────────────┘              │ FK
                              │
                              ▼
┌──────────────┐        ┌──────────────┐
│  HIDR.DAT    │◄───────│ ENTDADOS.XXX │
├──────────────┤   FK   ├──────────────┤
│ CADUSIH      │        │ UH           │
│   plant_num (PK) ◄────┤   plant_num  │
│   subsystem (FK)      │   subsystem  │
└──────┬───────┘        └──────────────┘
       │ FK                    │
       │                       │
       │                       ▼
       │                ┌──────────────┐
       │                │  DADVAZ.XXX  │
       │                ├──────────────┤
       └───────────────►│   plant_num  │
                        └──────────────┘
       │                       │
       │                       ▼
       │                ┌──────────────┐
       │                │  OPERUH.XXX  │
       │                ├──────────────┤
       └───────────────►│   plant_num  │
                        └──────────────┘
       │
       │
       ▼
┌──────────────┐
│ UCH          │
├──────────────┤
│ plant_num    │◄────┐
│ set_num      │     │
│ unit_num     │     │
└──────────────┘     │
                     │ FK (composite)
                     │
              ┌──────┴───────┐
              │ CADCONJ      │
              ├──────────────┤
              │ plant_num    │
              │ set_num      │
              └──────────────┘
```

## Format Differences

### Text Format (Complete)
```
HIDR.DAT (text)
  ├─ CADUSIH (plants)               ✅
  ├─ USITVIAG (travel times)        ✅
  ├─ POLCOT (volume-elevation)      ✅
  ├─ POLARE (volume-area)           ✅
  ├─ POLJUS (tailrace)              ✅
  ├─ COEFEVA (evaporation)          ✅
  └─ CADCONJ (unit sets)            ✅
```

### Binary Format (Partial)
```
HIDR.DAT (binary, 792 bytes/plant)
  ├─ CADUSIH (plants)               ✅ (111 fields → 14 mapped)
  ├─ USITVIAG (travel times)        ❌ (must get from other source)
  ├─ POLCOT (volume-elevation)      ❌ (could derive from fields 13-17)
  ├─ POLARE (volume-area)           ❌ (could derive from fields 18-22)
  ├─ POLJUS (tailrace)              ❌ (could derive from fields 23-27)
  ├─ COEFEVA (evaporation)          ❌ (could derive from fields 28-39)
  └─ CADCONJ (unit sets)            ❌ (must get from UCH file)
```

## Data Flow

```
┌─────────────────┐
│  Data Source    │
│  hidr.dat       │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  Format Detection       │
│  - File size % 792      │
│  - Read posto field     │
└────────┬────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌───────┐  ┌─────────┐
│ Text  │  │ Binary  │
│ 7     │  │ 1       │
│ types │  │ type    │
└───┬───┘  └────┬────┘
    │           │
    │           │
    └─────┬─────┘
          │
          ▼
    ┌──────────┐
    │ HidrData │
    │ (struct) │
    └─────┬────┘
          │
          ▼
    ┌──────────────────────┐
    │  Application Usage   │
    │  - Cascade analysis  │
    │  - Water balance     │
    │  - Generation calc   │
    └──────────────────────┘
```

## Summary

**Total Entities**: 7 (1 primary + 6 dependent)
**Primary Key**: `plant_num`
**Self-References**: 1 (cascade topology via `downstream_plant`)
**Cross-File FKs**: 4 (ENTDADOS.SIST, ENTDADOS.UH, DADVAZ, OPERUH)
**Many-to-Many**: 1 (USITVIAG: plants ↔ plants)
**One-to-One**: 4 (POLCOT, POLARE, POLJUS, COEFEVA)
**One-to-Many**: 1 (CADCONJ: plant → sets)

**Parsers**:
- `src/parser/hidr.jl` (main, text format, 7 record types)
- `src/parser/hidr_binary.jl` (binary format, 792 bytes)
- Auto-detection: `parse_hidr()` routes to appropriate parser

**Real-World Scale** (ONS sample):
- 185 plants
- 24,218 MW total capacity
- 4 subsystems (SE, S, NE, N)
- Longest cascade: 11 plants (Paranapanema River)
