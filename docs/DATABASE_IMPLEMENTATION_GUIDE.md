# DESSEM2Julia Database Implementation Guide

> **Complete guide for converting DESSEM2Julia data structures to a normalized relational database**
>
> **Version**: 1.0
> **Last Updated**: 2026-01-01
> **Author**: DESSEM2Julia Project

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Database Design Decisions](#database-design-decisions)
4. [ENUM Type Definitions](#enum-type-definitions)
5. [Complete Database Schema](#complete-database-schema)
6. [Entity-Relationship Diagram](#entity-relationship-diagram)
7. [Step-by-Step Implementation](#step-by-step-implementation)
8. [Handling Nested Structures](#handling-nested-structures)
9. [Caveats and Tricky Parts](#caveats-and-tricky-parts)
10. [Data Migration Scripts](#data-migration-scripts)
11. [Query Examples](#query-examples)
12. [Performance Optimization](#performance-optimization)
13. [Validation and Integrity](#validation-and-integrity)

---

## Overview

This guide provides a complete roadmap for implementing a relational database to store DESSEM input data, converting from Julia data structures to a properly normalized SQL schema.

### Key Objectives

- ✅ Convert Julia structs to normalized SQL tables
- ✅ Preserve all entity relationships and foreign keys
- ✅ Handle nested structures and time-series data
- ✅ Maintain referential integrity
- ✅ Optimize for query performance
- ✅ Support cascade topology and network modeling

### Database Platforms Supported

- PostgreSQL 14+ (recommended, full feature support)
- SQLite 3.35+ (lightweight, good for development)
- MySQL/MariaDB 8.0+ (production alternative)

**Note**: Examples use PostgreSQL syntax. Platform-specific notes provided where applicable.

---

## Prerequisites

### Software Requirements

```bash
# Julia packages
using DESSEM2Julia
using JLD2
using DataFrames
using LibPQ      # PostgreSQL driver
using SQLite     # SQLite driver
using MySQL      # MySQL driver (if needed)

# OR database command-line tools
# PostgreSQL: psql
# SQLite: sqlite3
# MySQL: mysql
```

### Data Requirements

- Parsed DESSEM data in JLD2 format (e.g., `ons_sample.jld2`)
- Entity relationships documentation (`ENTITY_RELATIONSHIPS.md`)
- Type system documentation (`type_system.md`)

---

## Database Design Decisions

### 1. Naming Conventions

**Table Names**: Plural, snake_case
```sql
hydro_plants        -- NOT hydro_plant
thermal_units       -- NOT thermal_unit
time_periods        -- NOT time_period
```

**Column Names**: snake_case
```sql
plant_num           -- NOT plantNum
subsystem_code      -- NOT subsystemCode
downstream_plant    -- NOT downstreamPlant
```

**Primary Keys**: `{table}_id` (surrogate) or natural key
```sql
-- Surrogate key (preferred)
period_id SERIAL PRIMARY KEY

-- Natural key (composite)
PRIMARY KEY (plant_num, unit_num)
```

**Foreign Keys**: `{referenced_table}_{column}_fk`
```sql
subsystem_fk  -- References subsystems.subsystem_num
plant_fk      -- References hydro_plants.plant_num
period_fk     -- References time_periods.period_id
```

### 2. Data Type Mapping (Julia → SQL)

| Julia Type | PostgreSQL | SQLite | Notes |
|------------|------------|--------|-------|
| `Int` | `INTEGER` | `INTEGER` | 32-bit integer |
| `Int64` | `BIGINT` | `INTEGER` | 64-bit integer |
| `Float64` | `DOUBLE PRECISION` | `REAL` | Double precision |
| `Float32` | `REAL` | `REAL` | Single precision |
| `String` | `VARCHAR(n)` or `TEXT` | `TEXT` | Variable length |
| `Bool` | `BOOLEAN` | `INTEGER` | 0/1 in SQLite |
| `DateTime` | `TIMESTAMP` | `TEXT` | ISO8601 string in SQLite |
| `Union{T,Nothing}` | `type NULL` | `type NULL` | Nullable column |
| `Vector{T}` | Separate table | Separate table | Normalize! |

### 3. Normalization Strategy

**Target**: Third Normal Form (3NF) with proper relationships

- ✅ Eliminate repeating groups (vectors → separate tables)
- ✅ Remove partial dependencies (all non-key attributes depend on full PK)
- ✅ Remove transitive dependencies (all non-key attributes depend only on PK)
- ✅ Handle many-to-many relationships with junction tables
- ✅ Self-referencing relationships (cascade topology)

### 4. Temporal Data Handling

**Two approaches**:

**A. Temporal Tables (Recommended)**
```sql
CREATE TABLE demand_series (
    subsystem INT NOT NULL,
    period_id INT NOT NULL,
    demand_mw REAL NOT NULL,
    PRIMARY KEY (subsystem, period_id),
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num),
    FOREIGN KEY (period_id) REFERENCES time_periods(period_id)
);
```

**B. Validity Periods (Range-based)**
```sql
CREATE TABLE operational_constraints (
    constraint_id SERIAL PRIMARY KEY,
    constraint_type VARCHAR(20),
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    value REAL,
    CHECK (valid_from < valid_to)
);
```

**Recommendation**: Use **Temporal Tables** approach for DESSEM (aligns with study period structure).

---

## ENUM Type Definitions

### PostgreSQL ENUMs (Recommended)

```sql
-- ============================================
-- ENUM TYPE DEFINITIONS
-- ============================================

-- Load level classification
CREATE TYPE load_level_enum AS ENUM (
    'LEVE',      -- Light load
    'MEDIA',     -- Medium load
    'PESADA'     -- Heavy/peak load
);

-- Fuel types for thermal plants
CREATE TYPE fuel_type_enum AS ENUM (
    'GAS',       -- Natural gas
    'COAL',      -- Coal
    'OIL',       -- Diesel/fuel oil
    'BIOMASS',   -- Biomass/bagasse
    'NUCLEAR',   -- Nuclear
    'OTHER'      -- Other fuels
);

-- Plant status
CREATE TYPE plant_status_enum AS ENUM (
    'EXISTING',  -- Operational plant
    'CONSTRUCT'  -- Under construction
);

-- Plant type (renewable/thermal/hydro)
CREATE TYPE plant_type_enum AS ENUM (
    'HYDRO',
    'THERMAL',
    'WIND',
    'SOLAR',
    'BIOMASS',
    'PUMPED_STORAGE'
);

-- Constraint type (hydro operations)
CREATE TYPE hydro_constraint_enum AS ENUM (
    'VAZMIN',    -- Minimum turbine flow
    'VAZMAX',    -- Maximum turbine flow
    'VMINP',     -- Minimum volume
    'VMAXP',     -- Maximum volume
    'GHMIN',     -- Minimum generation
    'GHMAX',     -- Maximum generation
    'RAMPMAX',   -- Maximum ramp rate
    'RAMPMIN'    -- Minimum ramp rate
);

-- Thermal unit status
CREATE TYPE unit_status_enum AS ENUM (
    'OFF',
    'ON'
);

-- Network flag
CREATE TYPE network_flag_enum AS ENUM (
    'NONE',       -- No network modeling
    'NETWORK',    -- Network without losses
    'LOSSES'      -- Network with losses
);

-- Restriction sense
CREATE TYPE restriction_sense_enum AS ENUM (
    'LESS_EQUAL',    -- <=
    'GREATER_EQUAL', -- >=
    'EQUAL'          -- =
);

-- Inflow type
CREATE TYPE inflow_type_enum AS ENUM (
    'INCREMENTAL',  -- Incremental inflow
    'TOTAL',        -- Total inflow
    'REGULARIZED'   -- Regularized inflow
);

-- Configuration type (AC records)
CREATE TYPE ac_type_enum AS ENUM (
    'ACVOLMAX',     -- Volume maximum
    'ACVOLMIN',     -- Volume minimum
    'ACVSVERT',     -- Spillway volume
    'ACVMDESV',     -- Diversion volume
    'ACCOTVAZ',     -- Head-flow polynomial
    'ACCOTVOL',     -- Head-volume polynomial
    'ACCOTTAR',     -- Tailrace polynomial
    'ACNUMCON',     -- Number of machine sets
    'ACNUMJUS',     -- Downstream plant
    'ACNUMPOS',     -- Station number
    'ACJUSENA',     -- Downstream elevation
    'ACJUSMED',     -- Average tailrace
    'ACCOFEVA',     -- Evaporation coefficient
    'ACNUMMAQ',     -- Number of machines
    'ACPOTEFE',     -- Effective power
    'ACDESVIO'      -- Diversion
);

-- COMMENT on ENUMs
COMMENT ON ENUM TYPE load_level_enum IS 'Load level classification for time periods';
COMMENT ON ENUM TYPE fuel_type_enum IS 'Fuel types for thermal generation';
COMMENT ON ENUM TYPE plant_status_enum IS 'Plant operational status';
COMMENT ON ENUM TYPE hydro_constraint_enum IS 'Hydro operational constraint types';
```

### MySQL ENUMs (Alternative)

```sql
-- MySQL uses ENUM differently (inline in column definition)
CREATE TABLE thermal_plants (
    plant_num INT PRIMARY KEY,
    fuel_type ENUM('GAS', 'COAL', 'OIL', 'BIOMASS', 'NUCLEAR', 'OTHER') NOT NULL,
    status ENUM('EXISTING', 'CONSTRUCT') DEFAULT 'EXISTING',
    ...
);
```

### SQLite ENUMs (Workaround)

```sql
-- SQLite doesn't support ENUM, use TEXT with CHECK constraint
CREATE TABLE thermal_plants (
    plant_num INTEGER PRIMARY KEY,
    fuel_type TEXT NOT NULL CHECK(fuel_type IN ('GAS', 'COAL', 'OIL', 'BIOMASS', 'NUCLEAR', 'OTHER')),
    status TEXT NOT NULL CHECK(status IN ('EXISTING', 'CONSTRUCT')) DEFAULT 'EXISTING',
    ...
);
```

---

## Complete Database Schema

### Schema Overview

```
dessem_db
├── Core Entities (6 tables)
│   ├── subsystems
│   ├── time_periods
│   ├── energy_reservoirs
│   ├── pump_stations
│   ├── network_buses
│   └── electrical_restrictions
│
├── Hydro System (8 tables)
│   ├── hydro_plants
│   ├── hydro_unit_sets
│   ├── hydro_units
│   ├── hydro_reservoirs
│   ├── hydro_inflows
│   ├── hydro_operations
│   ├── hydro_travel_times
│   └── hydro_polynomials
│
├── Thermal System (5 tables)
│   ├── thermal_plants
│   ├── thermal_units
│   ├── thermal_operations
│   ├── thermal_heat_curves
│   └── thermal_configurations
│
├── Renewable System (3 tables)
│   ├── renewable_plants
│   ├── renewable_subsystems
│   ├── renewable_generation
│
├── Network System (4 tables)
│   ├── transmission_lines
│   ├── plant_bus_connections
│   ├── network_topologies
│   └── area_controls
│
├── Demand & Contracts (4 tables)
│   ├── demand_series
│   ├── interchange_limits
│   ├── export_contracts
│   └── import_contracts
│
├── Constraints (7 tables)
│   ├── restriction_limits
│   ├── restriction_hydro_coeff
│   ├── restriction_thermal_coeff
│   ├── restriction_interchange_coeff
│   ├── restriction_renewable_coeff
│   ├── restriction_contract_coeff
│   └── table_constraints
│
└── Maintenance & Operations (5 tables)
    ├── hydro_maintenance
    ├── thermal_maintenance
    ├── ramp_constraints
    ├── power_reserves
    └── deficit_costs
```

### Table Definitions (PostgreSQL)

```sql
-- ============================================
-- DROP EXISTING SCHEMA
-- ============================================
DROP SCHEMA IF EXISTS dessem CASCADE;
CREATE SCHEMA dessem;
SET search_path TO dessem, public;

-- ============================================
-- 1. CORE ENTITIES
-- ============================================

-- 1.1 Subsystems (master lookup table)
CREATE TABLE subsystems (
    subsystem_num INT PRIMARY KEY,
    subsystem_code CHAR(2) NOT NULL UNIQUE,
    subsystem_name VARCHAR(30),
    status INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE subsystems IS 'Electrical subsystems (SE, S, NE, N)';

-- 1.2 Time periods (temporal dimension)
CREATE TABLE time_periods (
    period_id SERIAL PRIMARY KEY,
    day INT NOT NULL,
    hour INT NOT NULL CHECK (hour BETWEEN 0 AND 23),
    half_hour INT NOT NULL CHECK (half_hour IN (0, 1)),
    duration_hours REAL DEFAULT 1.0 CHECK (duration_hours > 0),
    network_flag network_flag_enum DEFAULT 'NONE',
    load_level load_level_enum,
    UNIQUE(day, hour, half_hour)
);

CREATE INDEX idx_time_periods_day ON time_periods(day);
CREATE INDEX idx_time_periods_network ON time_periods(network_flag);

COMMENT ON TABLE time_periods IS 'Time discretization for study periods';

-- 1.3 Energy Reservoir Equivalents (REE)
CREATE TABLE energy_reservoirs (
    ree_code INT PRIMARY KEY,
    ree_name VARCHAR(50) NOT NULL,
    subsystem INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num),
    UNIQUE(ree_code, subsystem)
);

COMMENT ON TABLE energy_reservoirs IS 'Equivalent energy reservoir groups for coupled operation';

-- 1.4 Pump Stations (Pumped Storage)
CREATE TABLE pump_stations (
    plant_num INT PRIMARY KEY,
    plant_name VARCHAR(20) NOT NULL,
    subsystem INT NOT NULL,
    upstream_plant INT,
    downstream_plant INT,
    min_pump_flow REAL NOT NULL,
    max_pump_flow REAL NOT NULL,
    consumption_rate REAL NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num),
    FOREIGN KEY (upstream_plant) REFERENCES pump_stations(plant_num),
    FOREIGN KEY (downstream_plant) REFERENCES pump_stations(plant_num)
);

COMMENT ON TABLE pump_stations IS 'Pumped storage / reversible hydro plants';

-- 1.5 Network Buses
CREATE TABLE network_buses (
    bus_num INT PRIMARY KEY,
    bus_name VARCHAR(50),
    subsystem INT NOT NULL,
    voltage_kv REAL,
    base_mva REAL DEFAULT 100.0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num)
);

COMMENT ON TABLE network_buses IS 'Electrical network buses (nodes)';

-- 1.6 Electrical Restrictions (master table)
CREATE TABLE electrical_restrictions (
    restriction_num INT PRIMARY KEY,
    restriction_name VARCHAR(100),
    sense restriction_sense_enum DEFAULT 'LESS_EQUAL',
    lower_limit REAL,
    upper_limit REAL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE electrical_restrictions IS 'Electrical network constraints';

-- ============================================
-- 2. HYDRO SYSTEM
-- ============================================

-- 2.1 Hydro Plants (master table)
CREATE TABLE hydro_plants (
    plant_num INT PRIMARY KEY,
    plant_name VARCHAR(20) NOT NULL,
    subsystem INT NOT NULL,
    status plant_status_enum DEFAULT 'EXISTING',
    downstream_plant INT,  -- Self-reference for cascade topology
    diversion_plant INT,   -- Alternative flow path
    installed_capacity_mw REAL DEFAULT 0.0,
    max_turbine_flow_m3s REAL DEFAULT 0.0,
    min_turbine_flow_m3s REAL DEFAULT 0.0,
    productivity REAL DEFAULT 0.0,  -- MW/(m³/s)/m
    initial_volume_pct REAL DEFAULT 0.0,
    volume_unit INT DEFAULT 2,  -- 1=hm³, 2=% useful
    min_volume_hm3 REAL,
    max_volume_hm3 REAL,
    spillway_crest_hm3 REAL,
    diversion_crest_hm3 REAL,
    ree_code INT,  -- Energy reservoir group
    commissioned_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num),
    FOREIGN KEY (downstream_plant) REFERENCES hydro_plants(plant_num),
    FOREIGN KEY (diversion_plant) REFERENCES hydro_plants(plant_num),
    FOREIGN KEY (ree_code) REFERENCES energy_reservoirs(ree_code)
);

CREATE INDEX idx_hydro_plants_subsystem ON hydro_plants(subsystem);
CREATE INDEX idx_hydro_plants_downstream ON hydro_plants(downstream_plant);
CREATE INDEX idx_hydro_plants_ree ON hydro_plants(ree_code);

COMMENT ON TABLE hydro_plants IS 'Hydroelectric plant registry';

-- 2.2 Hydro Unit Sets (groups of identical units)
CREATE TABLE hydro_unit_sets (
    plant_num INT NOT NULL,
    set_num INT NOT NULL,
    num_units INT NOT NULL CHECK (num_units > 0),
    unit_capacity_mw REAL NOT NULL,
    min_generation_mw REAL DEFAULT 0.0,
    max_turbine_flow_m3s REAL DEFAULT 0.0,
    PRIMARY KEY (plant_num, set_num),
    FOREIGN KEY (plant_num) REFERENCES hydro_plants(plant_num) ON DELETE CASCADE
);

COMMENT ON TABLE hydro_unit_sets IS 'Hydro unit sets (groups of identical machines)';

-- 2.3 Hydro Units (individual machines)
CREATE TABLE hydro_units (
    plant_num INT NOT NULL,
    set_num INT NOT NULL,
    unit_num INT NOT NULL,
    unit_name VARCHAR(20),
    PRIMARY KEY (plant_num, set_num, unit_num),
    FOREIGN KEY (plant_num, set_num) REFERENCES hydro_unit_sets(plant_num, set_num) ON DELETE CASCADE
);

COMMENT ON TABLE hydro_units IS 'Individual hydroelectric generating units';

-- 2.4 Hydro Reservoirs (detailed volume data)
CREATE TABLE hydro_reservoirs (
    plant_num INT PRIMARY KEY,
    initial_volume_hm3 REAL,
    storage_capacity_hm3 REAL,
    useful_volume_hm3 REAL,
    min_elevation_m REAL,
    max_elevation_m REAL,
    surface_area_km2 REAL,
    FOREIGN KEY (plant_num) REFERENCES hydro_plants(plant_num) ON DELETE CASCADE
);

COMMENT ON TABLE hydro_reservoirs IS 'Detailed reservoir characteristics';

-- 2.5 Hydro Inflows (time series)
CREATE TABLE hydro_inflows (
    plant_num INT NOT NULL,
    period_id INT NOT NULL,
    inflow_m3s REAL NOT NULL,
    inflow_type inflow_type_enum DEFAULT 'INCREMENTAL',
    PRIMARY KEY (plant_num, period_id),
    FOREIGN KEY (plant_num) REFERENCES hydro_plants(plant_num) ON DELETE CASCADE,
    FOREIGN KEY (period_id) REFERENCES time_periods(period_id) ON DELETE CASCADE
);

CREATE INDEX idx_hydro_inflows_plant ON hydro_inflows(plant_num);
CREATE INDEX idx_hydro_inflows_period ON hydro_inflows(period_id);

COMMENT ON TABLE hydro_inflows IS 'Natural inflow time series for hydro plants';

-- 2.6 Hydro Operations (constraints by period)
CREATE TABLE hydro_operations (
    plant_num INT NOT NULL,
    period_id INT NOT NULL,
    constraint_type hydro_constraint_enum NOT NULL,
    min_value REAL,
    max_value REAL,
    PRIMARY KEY (plant_num, period_id, constraint_type),
    FOREIGN KEY (plant_num) REFERENCES hydro_plants(plant_num) ON DELETE CASCADE,
    FOREIGN KEY (period_id) REFERENCES time_periods(period_id) ON DELETE CASCADE
);

CREATE INDEX idx_hydro_operations_plant ON hydro_operations(plant_num);

COMMENT ON TABLE hydro_operations IS 'Time-varying hydro operational constraints';

-- 2.7 Hydro Travel Times (water propagation delays)
CREATE TABLE hydro_travel_times (
    from_plant INT NOT NULL,
    to_plant INT NOT NULL,
    element_type VARCHAR(10) NOT NULL,  -- 'H' (hydro) or 'S' (section)
    travel_time_hours REAL NOT NULL CHECK (travel_time_hours >= 0),
    travel_type INT DEFAULT 1,  -- 1=translation, 2=propagation
    PRIMARY KEY (from_plant, to_plant),
    FOREIGN KEY (from_plant) REFERENCES hydro_plants(plant_num) ON DELETE CASCADE,
    FOREIGN KEY (to_plant) REFERENCES hydro_plants(plant_num) ON DELETE CASCADE
);

COMMENT ON TABLE hydro_travel_times IS 'Water travel times between hydro plants';

-- 2.8 Hydro Polynomials (volume-elevation-area curves)
CREATE TABLE hydro_polynomials (
    plant_num INT NOT NULL,
    polynomial_type VARCHAR(20) NOT NULL,  -- 'VOLUME_ELEVATION', 'VOLUME_AREA', 'TAILRACE'
    polynomial_degree INT NOT NULL CHECK (polynomial_degree BETWEEN 1 AND 5),
    coef0 REAL NOT NULL,
    coef1 REAL DEFAULT 0.0,
    coef2 REAL DEFAULT 0.0,
    coef3 REAL DEFAULT 0.0,
    coef4 REAL DEFAULT 0.0,
    coef5 REAL DEFAULT 0.0,
    PRIMARY KEY (plant_num, polynomial_type),
    FOREIGN KEY (plant_num) REFERENCES hydro_plants(plant_num) ON DELETE CASCADE
);

COMMENT ON TABLE hydro_polynomials IS 'Polynomial coefficients for reservoir curves';

-- ============================================
-- 3. THERMAL SYSTEM
-- ============================================

-- 3.1 Thermal Plants (master table)
CREATE TABLE thermal_plants (
    plant_num INT PRIMARY KEY,
    plant_name VARCHAR(20) NOT NULL,
    subsystem INT NOT NULL,
    status plant_status_enum DEFAULT 'EXISTING',
    fuel_type fuel_type_enum NOT NULL,
    num_units INT NOT NULL CHECK (num_units > 0),
    heat_rate_kj_kwh REAL DEFAULT 0.0,
    fuel_cost_brl_unit REAL DEFAULT 0.0,
    plant_class INT DEFAULT 0,
    commissioned_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num)
);

CREATE INDEX idx_thermal_plants_subsystem ON thermal_plants(subsystem);
CREATE INDEX idx_thermal_plants_fuel ON thermal_plants(fuel_type);

COMMENT ON TABLE thermal_plants IS 'Thermal power plant registry';

-- 3.2 Thermal Units (individual machines)
CREATE TABLE thermal_units (
    plant_num INT NOT NULL,
    unit_num INT NOT NULL,
    unit_name VARCHAR(20),
    capacity_mw REAL NOT NULL CHECK (capacity_mw > 0),
    min_generation_mw REAL DEFAULT 0.0,
    min_on_time_hours INT DEFAULT 0 CHECK (min_on_time_hours >= 0),
    min_off_time_hours INT DEFAULT 0 CHECK (min_off_time_hours >= 0),
    cold_startup_cost REAL DEFAULT 0.0,
    hot_startup_cost REAL DEFAULT 0.0,
    shutdown_cost REAL DEFAULT 0.0,
    ramp_up_rate_mw_h REAL,  -- NULL = infinite
    ramp_down_rate_mw_h REAL,  -- NULL = infinite
    PRIMARY KEY (plant_num, unit_num),
    FOREIGN KEY (plant_num) REFERENCES thermal_plants(plant_num) ON DELETE CASCADE
);

CREATE INDEX idx_thermal_units_plant ON thermal_units(plant_num);

COMMENT ON TABLE thermal_units IS 'Individual thermal generating units';

-- 3.3 Thermal Operations (time-varying constraints)
CREATE TABLE thermal_operations (
    plant_num INT NOT NULL,
    unit_num INT NOT NULL,
    period_id INT NOT NULL,
    initial_status unit_status_enum,
    initial_generation_mw REAL DEFAULT 0.0,
    hours_in_state INT DEFAULT 0,
    operating_cost_brl_mwh REAL,
    min_generation_mw REAL,
    max_generation_mw REAL,
    must_run BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (plant_num, unit_num, period_id),
    FOREIGN KEY (plant_num, unit_num) REFERENCES thermal_units(plant_num, unit_num) ON DELETE CASCADE,
    FOREIGN KEY (period_id) REFERENCES time_periods(period_id) ON DELETE CASCADE
);

CREATE INDEX idx_thermal_operations_plant ON thermal_operations(plant_num);

COMMENT ON TABLE thermal_operations IS 'Time-varying thermal unit operational data';

-- 3.4 Thermal Heat Curves (generation vs heat rate)
CREATE TABLE thermal_heat_curves (
    plant_num INT NOT NULL,
    unit_num INT NOT NULL,
    generation_mw REAL NOT NULL CHECK (generation_mw >= 0),
    heat_rate_kj_kwh REAL NOT NULL,
    PRIMARY KEY (plant_num, unit_num, generation_mw),
    FOREIGN KEY (plant_num, unit_num) REFERENCES thermal_units(plant_num, unit_num) ON DELETE CASCADE
);

CREATE INDEX idx_heat_curves_unit ON thermal_heat_curves(plant_num, unit_num);

COMMENT ON TABLE thermal_heat_curves IS 'Heat rate curve points (generation vs efficiency)';

-- 3.5 Thermal Configurations (combined-cycle)
CREATE TABLE thermal_configurations (
    plant_num INT NOT NULL,
    configuration_num INT NOT NULL,
    unit_num INT NOT NULL,
    configuration_type VARCHAR(20) NOT NULL,  -- 'COMBINED' or 'SIMPLE'
    PRIMARY KEY (plant_num, configuration_num, unit_num),
    FOREIGN KEY (plant_num, unit_num) REFERENCES thermal_units(plant_num, unit_num) ON DELETE CASCADE
);

COMMENT ON TABLE thermal_configurations IS 'Combined-cycle and simple-cycle configuration mappings';

-- ============================================
-- 4. RENEWABLE SYSTEM
-- ============================================

-- 4.1 Renewable Plants (master table)
CREATE TABLE renewable_plants (
    plant_num INT PRIMARY KEY,
    plant_name VARCHAR(50) NOT NULL,
    plant_type plant_type_enum NOT NULL,
    subsystem INT NOT NULL,
    installed_capacity_mw REAL DEFAULT 0.0,
    capacity_factor REAL DEFAULT 1.0 CHECK (capacity_factor BETWEEN 0 AND 1),
    is_registered BOOLEAN DEFAULT FALSE,
    bus_num INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num),
    FOREIGN KEY (bus_num) REFERENCES network_buses(bus_num)
);

CREATE INDEX idx_renewable_plants_type ON renewable_plants(plant_type);
CREATE INDEX idx_renewable_plants_subsystem ON renewable_plants(subsystem);

COMMENT ON TABLE renewable_plants IS 'Wind, solar, and other renewable generation plants';

-- 4.2 Renewable Subsystems (market mappings)
CREATE TABLE renewable_subsystems (
    plant_num INT NOT NULL,
    subsystem INT NOT NULL,
    PRIMARY KEY (plant_num, subsystem),
    FOREIGN KEY (plant_num) REFERENCES renewable_plants(plant_num) ON DELETE CASCADE,
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num) ON DELETE CASCADE
);

COMMENT ON TABLE renewable_subsystems IS 'Renewable plant to subsystem mappings';

-- 4.3 Renewable Generation (time series forecasts)
CREATE TABLE renewable_generation (
    plant_num INT NOT NULL,
    period_id INT NOT NULL,
    generation_mw REAL NOT NULL CHECK (generation_mw >= 0),
    availability_pct REAL DEFAULT 100.0 CHECK (availability_pct BETWEEN 0 AND 100),
    PRIMARY KEY (plant_num, period_id),
    FOREIGN KEY (plant_num) REFERENCES renewable_plants(plant_num) ON DELETE CASCADE,
    FOREIGN KEY (period_id) REFERENCES time_periods(period_id) ON DELETE CASCADE
);

CREATE INDEX idx_renewable_generation_plant ON renewable_generation(plant_num);

COMMENT ON TABLE renewable_generation IS 'Renewable generation forecast time series';

-- ============================================
-- 5. NETWORK SYSTEM
-- ============================================

-- 5.1 Transmission Lines
CREATE TABLE transmission_lines (
    line_id SERIAL PRIMARY KEY,
    from_bus INT NOT NULL,
    to_bus INT NOT NULL,
    circuit_num INT DEFAULT 1,
    line_name VARCHAR(50),
    from_subsystem VARCHAR(10),
    to_subsystem VARCHAR(10),
    resistance_pu REAL DEFAULT 0.0,
    reactance_pu REAL DEFAULT 0.0,
    susceptance_pu REAL DEFAULT 0.0,
    capacity_mw REAL,
    num_circuits INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_bus) REFERENCES network_buses(bus_num),
    FOREIGN KEY (to_bus) REFERENCES network_buses(bus_num),
    CHECK (from_bus != to_bus)
);

CREATE INDEX idx_transmission_lines_from ON transmission_lines(from_bus);
CREATE INDEX idx_transmission_lines_to ON transmission_lines(to_bus);

COMMENT ON TABLE transmission_lines IS 'Electrical transmission network lines';

-- 5.2 Plant-Bus Connections (many-to-many)
CREATE TABLE plant_bus_connections (
    plant_num INT NOT NULL,
    plant_type plant_type_enum NOT NULL,
    bus_num INT NOT NULL,
    connection_type VARCHAR(20),  -- 'GENERATION', 'LOAD', 'BOTH'
    PRIMARY KEY (plant_num, plant_type),
    FOREIGN KEY (bus_num) REFERENCES network_buses(bus_num) ON DELETE CASCADE
);

COMMENT ON TABLE plant_bus_connections IS 'Plant connections to electrical network buses';

-- 5.3 Network Topologies (study scenarios)
CREATE TABLE network_topologies (
    topology_id SERIAL PRIMARY KEY,
    topology_name VARCHAR(50) NOT NULL,
    base_case_name VARCHAR(50),  -- 'leve', 'media', 'pesada'
    load_level load_level_enum,
    period_id INT NOT NULL,
    CONSTRAINT unique_topologies UNIQUE (topology_name, period_id),
    FOREIGN KEY (period_id) REFERENCES time_periods(period_id)
);

COMMENT ON TABLE network_topologies IS 'Network configuration scenarios by time period';

-- 5.4 Area Controls (reserve areas)
CREATE TABLE area_controls (
    area_code INT PRIMARY KEY,
    area_name VARCHAR(50) NOT NULL,
    subsystem INT
);

COMMENT ON TABLE area_controls IS 'Control areas for power reserve requirements';

-- ============================================
-- 6. DEMAND & CONTRACTS
-- ============================================

-- 6.1 Demand Series (time series)
CREATE TABLE demand_series (
    subsystem INT NOT NULL,
    period_id INT NOT NULL,
    demand_mw REAL NOT NULL CHECK (demand_mw >= 0),
    PRIMARY KEY (subsystem, period_id),
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num) ON DELETE CASCADE,
    FOREIGN KEY (period_id) REFERENCES time_periods(period_id) ON DELETE CASCADE
);

CREATE INDEX idx_demand_series_subsystem ON demand_series(subsystem);
CREATE INDEX idx_demand_series_period ON demand_series(period_id);

COMMENT ON TABLE demand_series IS 'Load demand time series by subsystem';

-- 6.2 Interchange Limits (between subsystems)
CREATE TABLE interchange_limits (
    from_subsystem INT NOT NULL,
    to_subsystem INT NOT NULL,
    period_id INT NOT NULL,
    capacity_from_to_mw REAL NOT NULL CHECK (capacity_from_to_mw >= 0),
    capacity_to_from_mw REAL NOT NULL CHECK (capacity_to_from_mw >= 0),
    PRIMARY KEY (from_subsystem, to_subsystem, period_id),
    FOREIGN KEY (from_subsystem) REFERENCES subsystems(subsystem_num),
    FOREIGN KEY (to_subsystem) REFERENCES subsystems(subsystem_num),
    FOREIGN KEY (period_id) REFERENCES time_periods(period_id) ON DELETE CASCADE,
    CHECK (from_subsystem != to_subsystem)
);

COMMENT ON TABLE interchange_limits IS 'Interchange capacity limits between subsystems';

-- 6.3 Export Contracts
CREATE TABLE export_contracts (
    contract_num INT PRIMARY KEY,
    contract_name VARCHAR(50) NOT NULL,
    contract_year INT NOT NULL,
    subsystem INT NOT NULL,
    start_day INT NOT NULL,
    start_hour INT NOT NULL,
    start_half_hour INT NOT NULL,
    end_day INT NOT NULL,
    end_hour INT NOT NULL,
    end_half_hour INT NOT NULL,
    modulation_flag INT DEFAULT 0,
    min_value_mw REAL DEFAULT 0.0,
    max_value_mw REAL,
    inflexibility_mw REAL DEFAULT 0.0,
    priority_mw REAL DEFAULT 0.0,
    availability_flag INT DEFAULT 1,
    cost_brl_mwh REAL DEFAULT 0.0,
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num)
);

COMMENT ON TABLE export_contracts IS 'Energy export contracts';

-- 6.4 Import Contracts
CREATE TABLE import_contracts (
    contract_num INT PRIMARY KEY,
    contract_name VARCHAR(50) NOT NULL,
    contract_year INT NOT NULL,
    subsystem INT NOT NULL,
    start_day INT NOT NULL,
    start_hour INT NOT NULL,
    start_half_hour INT NOT NULL,
    end_day INT NOT NULL,
    end_hour INT NOT NULL,
    end_half_hour INT NOT NULL,
    modulation_flag INT DEFAULT 0,
    min_value_mw REAL DEFAULT 0.0,
    max_value_mw REAL,
    inflexibility_mw REAL DEFAULT 0.0,
    priority_mw REAL DEFAULT 0.0,
    availability_flag INT DEFAULT 1,
    cost_brl_mwh REAL DEFAULT 0.0,
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num)
);

COMMENT ON TABLE import_contracts IS 'Energy import contracts';

-- ============================================
-- 7. CONSTRAINTS (Many-to-Many)
-- ============================================

-- 7.1 Restriction Limits (time-varying)
CREATE TABLE restriction_limits (
    restriction_num INT NOT NULL,
    period_id INT NOT NULL,
    lower_limit REAL,
    upper_limit REAL,
    PRIMARY KEY (restriction_num, period_id),
    FOREIGN KEY (restriction_num) REFERENCES electrical_restrictions(restriction_num) ON DELETE CASCADE,
    FOREIGN KEY (period_id) REFERENCES time_periods(period_id) ON DELETE CASCADE
);

COMMENT ON TABLE restriction_limits IS 'Time-varying electrical restriction limits';

-- 7.2 Restriction-Hydro Coefficients
CREATE TABLE restriction_hydro_coeff (
    restriction_num INT NOT NULL,
    plant_num INT NOT NULL,
    set_num INT,  -- NULL for plant-level coefficient
    coefficient REAL NOT NULL,
    PRIMARY KEY (restriction_num, plant_num, set_num),
    FOREIGN KEY (restriction_num) REFERENCES electrical_restrictions(restriction_num) ON DELETE CASCADE,
    FOREIGN KEY (plant_num, set_num) REFERENCES hydro_unit_sets(plant_num, set_num) ON DELETE CASCADE
);

COMMENT ON TABLE restriction_hydro_coeff IS 'Hydro plant coefficients in electrical restrictions';

-- 7.3 Restriction-Thermal Coefficients
CREATE TABLE restriction_thermal_coeff (
    restriction_num INT NOT NULL,
    plant_num INT NOT NULL,
    coefficient REAL NOT NULL,
    PRIMARY KEY (restriction_num, plant_num),
    FOREIGN KEY (restriction_num) REFERENCES electrical_restrictions(restriction_num) ON DELETE CASCADE,
    FOREIGN KEY (plant_num) REFERENCES thermal_plants(plant_num) ON DELETE CASCADE
);

COMMENT ON TABLE restriction_thermal_coeff IS 'Thermal plant coefficients in electrical restrictions';

-- 7.4 Restriction-Interchange Coefficients
CREATE TABLE restriction_interchange_coeff (
    restriction_num INT NOT NULL,
    from_subsystem VARCHAR(2) NOT NULL,
    to_subsystem VARCHAR(2) NOT NULL,
    coefficient REAL NOT NULL,
    PRIMARY KEY (restriction_num, from_subsystem, to_subsystem),
    FOREIGN KEY (restriction_num) REFERENCES electrical_restrictions(restriction_num) ON DELETE CASCADE,
    CHECK (from_subsystem != to_subsystem)
);

COMMENT ON TABLE restriction_interchange_coeff IS 'Interchange coefficients in electrical restrictions';

-- 7.5 Restriction-Renewable Coefficients
CREATE TABLE restriction_renewable_coeff (
    restriction_num INT NOT NULL,
    plant_num INT NOT NULL,
    coefficient REAL NOT NULL,
    PRIMARY KEY (restriction_num, plant_num),
    FOREIGN KEY (restriction_num) REFERENCES electrical_restrictions(restriction_num) ON DELETE CASCADE,
    FOREIGN KEY (plant_num) REFERENCES renewable_plants(plant_num) ON DELETE CASCADE
);

COMMENT ON TABLE restriction_renewable_coeff IS 'Renewable plant coefficients in electrical restrictions';

-- 7.6 Restriction-Contract Coefficients
CREATE TABLE restriction_contract_coeff (
    restriction_num INT NOT NULL,
    contract_num INT NOT NULL,
    is_export BOOLEAN NOT NULL,  -- TRUE for export, FALSE for import
    coefficient REAL NOT NULL,
    PRIMARY KEY (restriction_num, contract_num, is_export),
    FOREIGN KEY (restriction_num) REFERENCES electrical_restrictions(restriction_num) ON DELETE CASCADE
);

COMMENT ON TABLE restriction_contract_coeff IS 'Energy contract coefficients in electrical restrictions';

-- 7.7 Table Constraints (RESTSEG)
CREATE TABLE table_constraints (
    constraint_id SERIAL PRIMARY KEY,
    constraint_name VARCHAR(50) NOT NULL,
    table_index INT NOT NULL,
    variable_type VARCHAR(20) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE table_constraints IS 'Table-based constraints (RESTSEG)';

-- ============================================
-- 8. MAINTENANCE & OPERATIONS
-- ============================================

-- 8.1 Hydro Maintenance
CREATE TABLE hydro_maintenance (
    plant_num INT NOT NULL,
    set_num INT,
    unit_num INT,
    start_day INT NOT NULL,
    start_hour INT NOT NULL,
    start_half_hour INT NOT NULL,
    end_day INT NOT NULL,
    end_hour INT NOT NULL,
    end_half_hour INT NOT NULL,
    available_flag INT DEFAULT 0,  -- 0=unavailable, 1=available
    PRIMARY KEY (plant_num, start_day, start_hour, start_half_hour),
    FOREIGN KEY (plant_num) REFERENCES hydro_plants(plant_num) ON DELETE CASCADE
);

COMMENT ON TABLE hydro_maintenance IS 'Hydro unit maintenance windows';

-- 8.2 Thermal Maintenance
CREATE TABLE thermal_maintenance (
    plant_num INT NOT NULL,
    unit_num INT NOT NULL,
    start_day INT NOT NULL,
    start_hour INT NOT NULL,
    start_half_hour INT NOT NULL,
    end_day INT NOT NULL,
    end_hour INT NOT NULL,
    end_half_hour INT NOT NULL,
    available_flag INT DEFAULT 0,
    PRIMARY KEY (plant_num, unit_num, start_day, start_hour, start_half_hour),
    FOREIGN KEY (plant_num, unit_num) REFERENCES thermal_units(plant_num, unit_num) ON DELETE CASCADE
);

COMMENT ON TABLE thermal_maintenance IS 'Thermal unit maintenance windows';

-- 8.3 Ramp Constraints (thermal unit trajectories)
CREATE TABLE ramp_constraints (
    plant_num INT NOT NULL,
    unit_num INT NOT NULL,
    configuration VARCHAR(10) NOT NULL,  -- 'S' (simple) or 'C' (combined)
    ramp_type VARCHAR(10) NOT NULL,  -- 'A' (ascending) or 'D' (descending)
    power_mw REAL NOT NULL,
    time_minutes INT NOT NULL CHECK (time_minutes >= 0),
    half_hour_flag INT NOT NULL CHECK (half_hour_flag IN (0, 1)),
    PRIMARY KEY (plant_num, unit_num, configuration, ramp_type, power_mw, time_minutes),
    FOREIGN KEY (plant_num, unit_num) REFERENCES thermal_units(plant_num, unit_num) ON DELETE CASCADE
);

COMMENT ON TABLE ramp_constraints IS 'Thermal unit ramp trajectory constraints';

-- 8.4 Power Reserves
CREATE TABLE power_reserves (
    area_code INT NOT NULL,
    period_id INT NOT NULL,
    reserve_type VARCHAR(20) NOT NULL,  -- 'SPINNING', 'OPERATING', etc.
    reserve_requirement_mw REAL NOT NULL CHECK (reserve_requirement_mw >= 0),
    PRIMARY KEY (area_code, period_id, reserve_type),
    FOREIGN KEY (area_code) REFERENCES area_controls(area_code) ON DELETE CASCADE,
    FOREIGN KEY (period_id) REFERENCES time_periods(period_id) ON DELETE CASCADE
);

COMMENT ON TABLE power_reserves IS 'Power reserve requirements by area';

-- 8.5 Deficit Costs
CREATE TABLE deficit_costs (
    subsystem INT NOT NULL,
    period_id INT NOT NULL,
    deficit_level INT NOT NULL,  -- Cost tier
    cost_brl_mwh REAL NOT NULL CHECK (cost_brl_mwh >= 0),
    upper_limit_mw REAL NOT NULL CHECK (upper_limit_mw >= 0),
    PRIMARY KEY (subsystem, period_id, deficit_level),
    FOREIGN KEY (subsystem) REFERENCES subsystems(subsystem_num) ON DELETE CASCADE,
    FOREIGN KEY (period_id) REFERENCES time_periods(period_id) ON DELETE CASCADE
);

COMMENT ON TABLE deficit_costs IS 'Deficit cost curves by subsystem';

-- ============================================
-- 9. METADATA AND AUDIT
-- ============================================

-- 9.1 Dessem Cases (metadata)
CREATE TABLE dessem_cases (
    case_id SERIAL PRIMARY KEY,
    case_name VARCHAR(100) NOT NULL UNIQUE,
    case_title VARCHAR(200),
    base_directory TEXT,
    study_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE dessem_cases IS 'DESSEM study case metadata';

-- 9.2 Audit Log
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    operation VARCHAR(10) NOT NULL,  -- 'INSERT', 'UPDATE', 'DELETE'
    record_id INT NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(50) DEFAULT CURRENT_USER
);

CREATE INDEX idx_audit_log_table ON audit_log(table_name);
CREATE INDEX idx_audit_log_time ON audit_log(changed_at);

COMMENT ON TABLE audit_log IS 'Audit trail for data changes';

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Composite indexes for common query patterns
CREATE INDEX idx_hydro_inflows_plant_period ON hydro_inflows(plant_num, period_id);
CREATE INDEX idx_thermal_operations_unit_period ON thermal_operations(plant_num, unit_num, period_id);
CREATE INDEX idx_renewable_generation_plant_period ON renewable_generation(plant_num, period_id);
CREATE INDEX idx_demand_series_subsystem_period ON demand_series(subsystem, period_id);
CREATE INDEX idx_restriction_hydro_restrict_plant ON restriction_hydro_coeff(restriction_num, plant_num);

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

-- View: Complete hydro plant information
CREATE VIEW v_hydro_plants_complete AS
SELECT
    hp.plant_num,
    hp.plant_name,
    hp.subsystem,
    s.subsystem_code,
    hp.status::TEXT,
    hp.installed_capacity_mw,
    hp.max_turbine_flow_m3s,
    hp.downstream_plant,
    dp.plant_name AS downstream_plant_name,
    hp.initial_volume_pct,
    hp.min_volume_hm3,
    hp.max_volume_hm3
FROM hydro_plants hp
LEFT JOIN subsystems s ON hp.subsystem = s.subsystem_num
LEFT JOIN hydro_plants dp ON hp.downstream_plant = dp.plant_num;

COMMENT ON VIEW v_hydro_plants_complete IS 'Complete hydro plant information with subsystem names';

-- View: Complete thermal plant information
CREATE VIEW v_thermal_plants_complete AS
SELECT
    tp.plant_num,
    tp.plant_name,
    tp.subsystem,
    s.subsystem_code,
    tp.fuel_type::TEXT,
    tp.status::TEXT,
    tp.num_units,
    tp.heat_rate_kj_kwh,
    COUNT(tu.unit_num) AS unit_count,
    SUM(tu.capacity_mw) AS total_capacity_mw
FROM thermal_plants tp
LEFT JOIN subsystems s ON tp.subsystem = s.subsystem_num
LEFT JOIN thermal_units tu ON tp.plant_num = tu.plant_num
GROUP BY tp.plant_num, tp.plant_name, tp.subsystem, s.subsystem_code,
         tp.fuel_type, tp.status, tp.num_units, tp.heat_rate_kj_kwh;

COMMENT ON VIEW v_thermal_plants_complete IS 'Complete thermal plant information with unit counts';

-- View: Hydro cascade topology
CREATE VIEW v_hydro_cascade AS
WITH RECURSIVE cascade_tree AS (
    -- Root plants (no downstream)
    SELECT
        plant_num,
        plant_name,
        downstream_plant,
        1 AS level_num,
        ARRAY[plant_num] AS path
    FROM hydro_plants
    WHERE downstream_plant IS NULL OR downstream_plant = 0

    UNION ALL

    -- Recursively find downstream plants
    SELECT
        hp.plant_num,
        hp.plant_name,
        hp.downstream_plant,
        ct.level_num + 1,
        ct.path || hp.plant_num
    FROM hydro_plants hp
    JOIN cascade_tree ct ON hp.downstream_plant = ct.plant_num
)
SELECT * FROM cascade_tree ORDER BY path, level_num;

COMMENT ON VIEW v_hydro_cascade IS 'Hydro plant cascade topology tree';

-- ============================================
-- TRIGGERS FOR DATA INTEGRITY
-- ============================================

-- Trigger: Prevent cycles in hydro cascade
CREATE OR REPLACE FUNCTION prevent_cascade_cycles()
RETURNS TRIGGER AS $$
DECLARE
    has_cycle BOOLEAN;
BEGIN
    -- Check if creating a cycle
    WITH RECURSIVE cascade_check AS (
        SELECT plant_num, downstream_plant
        FROM hydro_plants
        WHERE plant_num = NEW.downstream_plant

        UNION ALL

        SELECT hp.plant_num, hp.downstream_plant
        FROM hydro_plants hp
        JOIN cascade_check cc ON hp.plant_num = cc.downstream_plant
        WHERE cc.downstream_plant IS NOT NULL
    )
    SELECT EXISTS(
        SELECT 1 FROM cascade_check WHERE plant_num = NEW.plant_num
    ) INTO has_cycle;

    IF has_cycle THEN
        RAISE EXCEPTION 'Cannot create cycle in hydro cascade: plant % would reference itself', NEW.plant_num;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prevent_cascade_cycles
BEFORE INSERT OR UPDATE OF downstream_plant ON hydro_plants
FOR EACH ROW
EXECUTE FUNCTION prevent_cascade_cycles();

-- Trigger: Update timestamp on record modification
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to relevant tables
CREATE TRIGGER trg_update_hydro_plants
BEFORE UPDATE ON hydro_plants
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_update_thermal_plants
BEFORE UPDATE ON thermal_plants
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- ============================================
-- STORED PROCEDURES
-- ============================================

-- Procedure: Calculate total subsystem capacity
CREATE OR REPLACE FUNCTION calculate_subsystem_capacity(p_subsystem INT)
RETURNS TABLE (
    hydro_capacity_mw REAL,
    thermal_capacity_mw REAL,
    renewable_capacity_mw REAL,
    total_capacity_mw REAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(hp.installed_capacity_mw), 0) AS hydro_capacity_mw,
        COALESCE(SUM(tu.capacity_mw), 0) AS thermal_capacity_mw,
        COALESCE(SUM(rp.installed_capacity_mw), 0) AS renewable_capacity_mw,
        COALESCE(SUM(hp.installed_capacity_mw), 0) +
        COALESCE(SUM(tu.capacity_mw), 0) +
        COALESCE(SUM(rp.installed_capacity_mw), 0) AS total_capacity_mw
    FROM (SELECT 1) dummy
    LEFT JOIN hydro_plants hp ON hp.subsystem = p_subsystem
    LEFT JOIN thermal_units tu ON tu.plant_num IN (
        SELECT tp.plant_num FROM thermal_plants tp WHERE tp.subsystem = p_subsystem
    )
    LEFT JOIN renewable_plants rp ON rp.subsystem = p_subsystem;
END;
$$ LANGUAGE plpgsql;

-- Procedure: Get cascade storage capacity
CREATE OR REPLACE FUNCTION get_cascade_storage(p_root_plant INT)
RETURNS TABLE (
    total_min_volume_hm3 REAL,
    total_max_volume_hm3 REAL,
    total_useful_volume_hm3 REAL,
    num_plants INT
) AS $$
DECLARE
    cascade_plants INT[];
BEGIN
    -- Get all plants in cascade using recursive CTE
    WITH RECURSIVE cascade AS (
        SELECT plant_num, min_volume_hm3, max_volume_hm3
        FROM hydro_plants
        WHERE plant_num = p_root_plant

        UNION ALL

        SELECT hp.plant_num, hp.min_volume_hm3, hp.max_volume_hm3
        FROM hydro_plants hp
        JOIN cascade c ON hp.downstream_plant = c.plant_num
        WHERE hp.downstream_plant IS NOT NULL
    )
    SELECT
        ARRAY_AGG(plant_num) INTO cascade_plants
    FROM cascade;

    RETURN QUERY
    SELECT
        COALESCE(SUM(min_volume_hm3), 0) AS total_min_volume_hm3,
        COALESCE(SUM(max_volume_hm3), 0) AS total_max_volume_hm3,
        COALESCE(SUM(max_volume_hm3) - SUM(min_volume_hm3), 0) AS total_useful_volume_hm3,
        COUNT(plant_num) AS num_plants
    FROM hydro_plants
    WHERE plant_num = ANY(cascade_plants);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_cascade_storage(INT) IS 'Calculate total storage capacity of hydro cascade';

-- ============================================
-- GRANT PERMISSIONS (PostgreSQL)
-- ============================================

-- Create read-only user
-- CREATE ROLE dessem_readonly WITH LOGIN PASSWORD 'readonly_password';
-- GRANT CONNECT ON DATABASE dessem_db TO dessem_readonly;
-- GRANT USAGE ON SCHEMA dessem TO dessem_readonly;
-- GRANT SELECT ON ALL TABLES IN SCHEMA dessem TO dessem_readonly;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA dessem GRANT SELECT ON TABLES TO dessem_readonly;

-- Create read-write user
-- CREATE ROLE dessem_readwrite WITH LOGIN PASSWORD 'readwrite_password';
-- GRANT CONNECT ON DATABASE dessem_db TO dessem_readwrite;
-- GRANT USAGE ON SCHEMA dessem TO dessem_readwrite;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA dessem TO dessem_readwrite;
-- ALTER DEFAULT PRIVILEGES IN SCHEMA dessem GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO dessem_readwrite;

-- ============================================
-- END OF SCHEMA
-- ============================================
---

## Entity-Relationship Diagram

### Mermaid ERD (Complete Schema)

```mermaid
erDiagram
    %% ========================================
    %% CORE ENTITIES
    %% ========================================
    SUBSYSTEMS ||--o{ HYDRO_PLANTS : "contains"
    SUBSYSTEMS ||--o{ THERMAL_PLANTS : "contains"
    SUBSYSTEMS ||--o{ RENEWABLE_PLANTS : "contains"
    SUBSYSTEMS ||--o{ NETWORK_BUSES : "has"
    SUBSYSTEMS ||--o{ DEMAND_SERIES : "has"
    SUBSYSTEMS ||--o{ ENERGY_RESERVOIRS : "groups"

    TIME_PERIODS ||--o{ HYDRO_INFLOWS : "has"
    TIME_PERIODS ||--o{ HYDRO_OPERATIONS : "defines"
    TIME_PERIODS ||--o{ THERMAL_OPERATIONS : "defines"
    TIME_PERIODS ||--o{ RENEWABLE_GENERATION : "forecasts"
    TIME_PERIODS ||--o{ DEMAND_SERIES : "has"
    TIME_PERIODS ||--o{ RESTRICTION_LIMITS : "limits"

    %% ========================================
    %% HYDRO SYSTEM
    %% ========================================
    HYDRO_PLANTS ||--o{ HYDRO_UNIT_SETS : "has"
    HYDRO_PLANTS ||--o{ HYDRO_RESERVOIRS : "details"
    HYDRO_PLANTS ||--o{ HYDRO_INFLOWS : "receives"
    HYDRO_PLANTS ||--o{ HYDRO_OPERATIONS : "constrained by"
    HYDRO_PLANTS ||--o{ HYDRO_TRAVEL_TIMES : "sends water to"
    HYDRO_PLANTS ||--o{ HYDRO_POLYNOMIALS : "curved by"
    HYDRO_PLANTS ||--o{ HYDRO_MAINTENANCE : "maintained"
    HYDRO_PLANTS ||--o| HYDRO_PLANTS : "downstream"
    HYDRO_PLANTS }o--o{ HYDRO_TRAVEL_TIMES : "from"

    HYDRO_UNIT_SETS ||--o{ HYDRO_UNITS : "contains"
    HYDRO_UNIT_SETS ||--o{ HYDRO_MAINTENANCE : "maintained"
    HYDRO_UNIT_SETS ||--o{ RESTRICTION_HYDRO_COEFF : "in"

    %% ========================================
    %% THERMAL SYSTEM
    %% ========================================
    THERMAL_PLANTS ||--o{ THERMAL_UNITS : "has"
    THERMAL_PLANTS ||--o{ THERMAL_CONFIGURATIONS : "configured"
    THERMAL_PLANTS ||--o{ RESTRICTION_THERMAL_COEFF : "in"

    THERMAL_UNITS ||--o{ THERMAL_OPERATIONS : "operates"
    THERMAL_UNITS ||--o{ THERMAL_HEAT_CURVES : "curved by"
    THERMAL_UNITS ||--o{ THERMAL_MAINTENANCE : "maintained"
    THERMAL_UNITS ||--o{ THERMAL_CONFIGURATIONS : "in"
    THERMAL_UNITS ||--o{ RAMP_CONSTRAINTS : "constrained by"

    %% ========================================
    %% RENEWABLE SYSTEM
    %% ========================================
    RENEWABLE_PLANTS ||--o{ RENEWABLE_SUBSYSTEMS : "in"
    RENEWABLE_PLANTS ||--o{ RENEWABLE_GENERATION : "generates"
    RENEWABLE_PLANTS ||--o{ RESTRICTION_RENEWABLE_COEFF : "in"
    RENEWABLE_PLANTS }o--|| NETWORK_BUSES : "connected to"

    %% ========================================
    %% NETWORK SYSTEM
    %% ========================================
    NETWORK_BUSES ||--o{ TRANSMISSION_LINES : "from"
    NETWORK_BUSES ||--o{ TRANSMISSION_LINES : "to"
    NETWORK_BUSES ||--o{ PLANT_BUS_CONNECTIONS : "connects"

    %% ========================================
    %% CONSTRAINTS
    %% ========================================
    ELECTRICAL_RESTRICTIONS ||--o{ RESTRICTION_LIMITS : "time-varying"
    ELECTRICAL_RESTRICTIONS ||--o{ RESTRICTION_HYDRO_COEFF : "has"
    ELECTRICAL_RESTRICTIONS ||--o{ RESTRICTION_THERMAL_COEFF : "has"
    ELECTRICAL_RESTRICTIONS ||--o{ RESTRICTION_INTERCHANGE_COEFF : "has"
    ELECTRICAL_RESTRICTIONS ||--o{ RESTRICTION_RENEWABLE_COEFF : "has"
    ELECTRICAL_RESTRICTIONS ||--o{ RESTRICTION_CONTRACT_COEFF : "has"

    %% ========================================
    %% CONTRACTS
    %% ========================================
    EXPORT_CONTRACTS ||--o{ RESTRICTION_CONTRACT_COEFF : "in"
    IMPORT_CONTRACTS ||--o{ RESTRICTION_CONTRACT_COEFF : "in"

    %% ========================================
    %% ENTITY DEFINITIONS
    %% ========================================
    SUBSYSTEMS {
        int subsystem_num PK
        string subsystem_code UK
        string subsystem_name
        int status
    }

    TIME_PERIODS {
        int period_id PK
        int day
        int hour
        int half_hour
        float duration_hours
        enum network_flag
        enum load_level
    }

    HYDRO_PLANTS {
        int plant_num PK
        string plant_name
        int subsystem FK
        enum status
        int downstream_plant FK
        int diversion_plant FK
        float installed_capacity_mw
        float max_turbine_flow_m3s
        float initial_volume_pct
        float min_volume_hm3
        float max_volume_hm3
        int ree_code FK
    }

    THERMAL_PLANTS {
        int plant_num PK
        string plant_name
        int subsystem FK
        enum fuel_type
        int num_units
        float heat_rate_kj_kwh
        float fuel_cost_brl_unit
    }

    THERMAL_UNITS {
        int plant_num FK
        int unit_num
        float capacity_mw
        float min_generation_mw
        int min_on_time_hours
        int min_off_time_hours
        float cold_startup_cost
        float hot_startup_cost
    }

    RENEWABLE_PLANTS {
        int plant_num PK
        string plant_name
        enum plant_type
        int subsystem FK
        float installed_capacity_mw
        int bus_num FK
    }

    NETWORK_BUSES {
        int bus_num PK
        string bus_name
        int subsystem FK
        float voltage_kv
    }

    TRANSMISSION_LINES {
        int line_id PK
        int from_bus FK
        int to_bus FK
        int circuit_num
        float reactance_pu
        float capacity_mw
    }

    ELECTRICAL_RESTRICTIONS {
        int restriction_num PK
        string restriction_name
        enum sense
        float lower_limit
        float upper_limit
    }
```

### Key Relationships Summary

| Relationship | Type | Description |
|--------------|------|-------------|
| `subsystems.subsystem_num` → `hydro_plants.subsystem` | 1:N | One subsystem has many hydro plants |
| `hydro_plants.plant_num` → `hydro_plants.downstream_plant` | Self-reference 1:0..1 | Cascade topology (DAG) |
| `hydro_plants.plant_num` → `hydro_unit_sets.plant_num` | 1:N | Plant has multiple unit sets |
| `hydro_unit_sets.(plant_num,set_num)` → `hydro_units.(plant_num,set_num)` | 1:N | Unit set has multiple units |
| `thermal_plants.plant_num` → `thermal_units.(plant_num,unit_num)` | 1:N | Plant has multiple units |
| `electrical_restrictions.restriction_num` → `restriction_hydro_coeff` | Many-to-Many | Junction table for hydro coefficients |
| `time_periods.period_id` → All time-series tables | 1:N | Temporal dimension |
| `network_buses.bus_num` → `transmission_lines.from_bus/to_bus` | 1:N | Bus connectivity |

---

## Step-by-Step Implementation

### Phase 1: Database Setup (5 minutes)

#### Step 1.1: Create Database

**PostgreSQL:**
```bash
# Create database
createdb dessem_db

# Or via psql
psql -U postgres
CREATE DATABASE dessem_db
    WITH ENCODING='UTF8'
    LC_COLLATE='en_US.UTF-8'
    LC_CTYPE='en_US.UTF-8'
    TEMPLATE=template0;
```

**SQLite:**
```bash
# Create database file
sqlite3 dessem_db.db ".quit"
```

**MySQL:**
```bash
# Create database
mysql -u root -p
CREATE DATABASE dessem_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'dessem_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON dessem_db.* TO 'dessem_user'@'localhost';
FLUSH PRIVILEGES;
```

#### Step 1.2: Execute Schema SQL

```bash
# PostgreSQL
psql -U postgres -d dessem_db -f schema.sql

# SQLite
sqlite3 dessem_db.db < schema.sql

# MySQL
mysql -u dessem_user -p dessem_db < schema.sql
```

### Phase 2: Load Core Data (15 minutes)

#### Step 2.1: Load Subsystems

```julia
using JLD2
using DataFrames
using LibPQ  # or SQLite, MySQL

# Load JLD2 data
data = JLD2.load("ons_sample.jld2")
dessem_data = data["data"]
entdados = dessem_data.files["entdados.dat"]
hidr_data = dessem_data.files["hidr.dat"]
termdat = dessem_data.files["termdat.dat"]

# Connect to database
conn = LibPQ.Connection("host=localhost port=5432 dbname=dessem_db user=postgres")

# Load subsystems
subsystems_df = DataFrame([
    (subsystem_num = s.numero,
     subsystem_code = s.codigo,
     subsystem_name = s.nome,
     status = s.estado)
    for s in entdados.subsystems
])

LibPQ.execute!(
    conn,
    "INSERT INTO subsystems (subsystem_num, subsystem_code, subsystem_name, status) VALUES (\$1, \$2, \$3, \$4)",
    subsystems_df
)

println("✅ Loaded $(nrow(subsystems_df)) subsystems")
```

#### Step 2.2: Load Time Periods

```julia
# Load time periods
time_periods_df = DataFrame([
    (day = tm.dia,
     hour = tm.hora,
     half_hour = tm.meia_hora,
     duration_hours = 1.0,
     network_flag = tm.rede > 0 ? "NETWORK" : "NONE",
     load_level = tm.patamar)
    for tm in entdados.time_periods
])

# Assign sequential period_id
time_periods_df.period_id = 1:nrow(time_periods_df)

LibPQ.execute!(
    conn,
    "INSERT INTO time_periods (period_id, day, hour, half_hour, duration_hours, network_flag, load_level) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7)",
    time_periods_df
)

println("✅ Loaded $(nrow(time_periods_df)) time periods")
```

#### Step 2.3: Load Hydro Plants

```julia
# Load hydro plants
hydro_plants_df = DataFrame([
    (plant_num = plant.plant_num,
     plant_name = plant.plant_name,
     subsystem = plant.subsystem,
     status = plant.estado == 0 ? "EXISTING" : "CONSTRUCT",
     downstream_plant = plant.jusante,
     diversion_plant = plant.desvio,
     installed_capacity_mw = plant.potencia,
     max_turbine_flow_m3s = plant.vazao_maxima,
     productivity = plant.produtividade,
     initial_volume_pct = plant.volume_initial_perc,
     min_volume_hm3 = plant.volume_minimo,
     max_volume_hm3 = plant.volume_maximo)
    for plant in hidr_data.records
])

LibPQ.execute!(
    conn,
    "INSERT INTO hydro_plants (plant_num, plant_name, subsystem, status, downstream_plant, diversion_plant, installed_capacity_mw, max_turbine_flow_m3s, productivity, initial_volume_pct, min_volume_hm3, max_volume_hm3) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11, \$12)",
    hydro_plants_df
)

println("✅ Loaded $(nrow(hydro_plants_df)) hydro plants")
```

#### Step 2.4: Load Thermal Plants

```julia
# Load thermal plants
thermal_plants_df = DataFrame([
    (plant_num = plant.plant_num,
     plant_name = plant.plant_name,
     subsystem = plant.subsystem,
     fuel_type = get_fuel_type(plant.fuel_type),  # Map Int to enum
     num_units = plant.num_units,
     heat_rate_kj_kwh = plant.heat_rate,
     fuel_cost_brl_unit = plant.fuel_cost)
    for plant in termdat.plants
])

# Helper function to map fuel types
function get_fuel_type(code::Int)::String
    fuel_map = Dict(
        1 => "GAS",
        2 => "COAL",
        3 => "OIL",
        4 => "BIOMASS",
        5 => "NUCLEAR",
        6 => "OTHER"
    )
    return get(fuel_map, code, "OTHER")
end

LibPQ.execute!(
    conn,
    "INSERT INTO thermal_plants (plant_num, plant_name, subsystem, fuel_type, num_units, heat_rate_kj_kwh, fuel_cost_brl_unit) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7)",
    thermal_plants_df
)

println("✅ Loaded $(nrow(thermal_plants_df)) thermal plants")
```

#### Step 2.5: Load Thermal Units

```julia
# Load thermal units
thermal_units_df = DataFrame([
    (plant_num = unit.plant_num,
     unit_num = unit.unit_num,
     unit_name = unit.unit_name,
     capacity_mw = unit.capacity,
     min_generation_mw = unit.min_generation,
     min_on_time_hours = unit.min_on_time,
     min_off_time_hours = unit.min_off_time,
     cold_startup_cost = unit.cold_startup_cost,
     hot_startup_cost = unit.hot_startup_cost,
     ramp_up_rate_mw_h = unit.ramp_up_rate,
     ramp_down_rate_mw_h = unit.ramp_down_rate)
    for unit in termdat.units
])

LibPQ.execute!(
    conn,
    "INSERT INTO thermal_units (plant_num, unit_num, unit_name, capacity_mw, min_generation_mw, min_on_time_hours, min_off_time_hours, cold_startup_cost, hot_startup_cost, ramp_up_rate_mw_h, ramp_down_rate_mw_h) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9, \$10, \$11)",
    thermal_units_df
)

println("✅ Loaded $(nrow(thermal_units_df)) thermal units")
```

### Phase 3: Load Time-Series Data (20 minutes)

#### Step 3.1: Load Hydro Inflows

```julia
# Load natural inflows (DADVAZ.DAT)
dadvaz = dessem_data.files["dadvaz.dat"]

# Create period lookup map
period_map = Dict(
    (tm.dia, tm.hora, tm.meia_hora) => tm.period_id
    for tm in entdados.time_periods
)

hydro_inflows_rows = []
for (plant_num, inflow_series) in dadvaz.inflows
    for (day, hour, half_hour, inflow) in inflow_series
        period_id = get(period_map, (day, hour, half_hour), nothing)
        if period_id !== nothing
            push!(hydro_inflows_rows,
                (plant_num = plant_num,
                 period_id = period_id,
                 inflow_m3s = inflow,
                 inflow_type = "INCREMENTAL"))
        end
    end
end

hydro_inflows_df = DataFrame(hydro_inflows_rows)

LibPQ.execute!(
    conn,
    "INSERT INTO hydro_inflows (plant_num, period_id, inflow_m3s, inflow_type) VALUES (\$1, \$2, \$3, \$4)",
    hydro_inflows_df
)

println("✅ Loaded $(nrow(hydro_inflows_df)) hydro inflow records")
```

#### Step 3.2: Load Demand Series

```julia
# Load demand data
demand_rows = []
for dp in entdados.demand_records
    # Find all periods in the range [start_day, start_hour] to [end_day, end_hour]
    periods_in_range = filter(tm -> tm.dia >= dp.start_day && tm.hora >= dp.start_hour,
                             entdados.time_periods)

    for tm in periods_in_range
        period_id = get(period_map, (tm.dia, tm.hora, tm.meia_hora), nothing)
        if period_id !== nothing
            push!(demand_rows,
                (subsystem = dp.subsystem,
                 period_id = period_id,
                 demand_mw = dp.demand))
        end
    end
end

demand_df = DataFrame(demand_rows)

LibPQ.execute!(
    conn,
    "INSERT INTO demand_series (subsystem, period_id, demand_mw) VALUES (\$1, \$2, \$3)",
    demand_df
)

println("✅ Loaded $(nrow(demand_df)) demand records")
```

#### Step 3.3: Load Thermal Operations

```julia
# Load thermal operations (OPERUT.DAT)
operut = dessem_data.files["operut.dat"]

thermal_ops_rows = []
for oper in operut.oper_records
    period_id = get(period_map, (oper.day, oper.hour, oper.half), nothing)
    if period_id !== nothing
        push!(thermal_ops_rows,
            (plant_num = oper.plant_num,
             unit_num = oper.unit_num,
             period_id = period_id,
             initial_status = oper.initial_status > 0 ? "ON" : "OFF",
             initial_generation_mw = oper.initial_generation,
             operating_cost_brl_mwh = oper.operating_cost,
             min_generation_mw = oper.min_generation,
             max_generation_mw = oper.max_generation))
    end
end

thermal_ops_df = DataFrame(thermal_ops_rows)

LibPQ.execute!(
    conn,
    "INSERT INTO thermal_operations (plant_num, unit_num, period_id, initial_status, initial_generation_mw, operating_cost_brl_mwh, min_generation_mw, max_generation_mw) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8)",
    thermal_ops_df
)

println("✅ Loaded $(nrow(thermal_ops_df)) thermal operation records")
```

### Phase 4: Load Network Data (10 minutes)

#### Step 4.1: Load Network Buses

```julia
# Load network topology from DESSELET.DAT
desselet = dessem_data.files["desselet.dat"]

network_buses_df = DataFrame([
    (bus_num = bus.bus_num,
     bus_name = bus.bus_name,
     subsystem = bus.subsystem,
     voltage_kv = bus.voltage,
     base_mva = 100.0)
    for bus in desselet.buses
])

LibPQ.execute!(
    conn,
    "INSERT INTO network_buses (bus_num, bus_name, subsystem, voltage_kv, base_mva) VALUES (\$1, \$2, \$3, \$4, \$5)",
    network_buses_df
)

println("✅ Loaded $(nrow(network_buses_df)) network buses")
```

#### Step 4.2: Load Transmission Lines

```julia
transmission_lines_df = DataFrame([
    (from_bus = line.from_bus,
     to_bus = line.to_bus,
     circuit_num = line.circuit_num,
     line_name = line.line_name,
     resistance_pu = line.resistance,
     reactance_pu = line.reactance,
     susceptance_pu = line.susceptance,
     capacity_mw = line.capacity,
     num_circuits = line.num_circuits)
    for line in desselet.lines
])

LibPQ.execute!(
    conn,
    "INSERT INTO transmission_lines (from_bus, to_bus, circuit_num, line_name, resistance_pu, reactance_pu, susceptance_pu, capacity_mw, num_circuits) VALUES (\$1, \$2, \$3, \$4, \$5, \$6, \$7, \$8, \$9)",
    transmission_lines_df
)

println("✅ Loaded $(nrow(transmission_lines_df)) transmission lines")
```

### Phase 5: Load Constraint Data (15 minutes)

#### Step 5.1: Load Electrical Restrictions

```julia
# Load restrictions from ENTDADOS.DAT (RE records)
restrictions_df = DataFrame([
    (restriction_num = re.restriction_num,
     restriction_name = re.name,
     sense = get_sense_enum(re.sense),
     lower_limit = re.lower_limit,
     upper_limit = re.upper_limit)
    for re in entdados.restrictions
])

LibPQ.execute!(
    conn,
    "INSERT INTO electrical_restrictions (restriction_num, restriction_name, sense, lower_limit, upper_limit) VALUES (\$1, \$2, \$3, \$4, \$5)",
    restrictions_df
)

println("✅ Loaded $(nrow(restrictions_df)) electrical restrictions")
```

#### Step 5.2: Load Restriction Coefficients

```julia
# Load hydro coefficients (FH records)
hydro_coeff_rows = []
for fh in entdados.fh_records
    set_num_val = isnothing(fh.set_num) ? missing : fh.set_num
    push!(hydro_coeff_rows,
        (restriction_num = fh.restriction_num,
         plant_num = fh.plant_num,
         set_num = set_num_val,
         coefficient = fh.coefficient))
end

hydro_coeff_df = DataFrame(hydro_coeff_rows)

LibPQ.execute!(
    conn,
    "INSERT INTO restriction_hydro_coeff (restriction_num, plant_num, set_num, coefficient) VALUES (\$1, \$2, \$3, \$4)",
    hydro_coeff_df
)

println("✅ Loaded $(nrow(hydro_coeff_df)) hydro restriction coefficients")
```

### Phase 6: Verification and Cleanup (10 minutes)

#### Step 6.1: Validate Referential Integrity

```julia
# Check for orphaned records
function check_referential_integrity(conn)
    # Orphaned hydro plants (no subsystem)
    result = LibPQ.execute(conn, """
        SELECT COUNT(*) AS orphan_count
        FROM hydro_plants hp
        LEFT JOIN subsystems s ON hp.subsystem = s.subsystem_num
        WHERE s.subsystem_num IS NULL
    """)
    println("Orphaned hydro plants: ", first(result).orphan_count)

    # Orphaned thermal units (no plant)
    result = LibPQ.execute(conn, """
        SELECT COUNT(*) AS orphan_count
        FROM thermal_units tu
        LEFT JOIN thermal_plants tp ON tu.plant_num = tp.plant_num
        WHERE tp.plant_num IS NULL
    """)
    println("Orphaned thermal units: ", first(result).orphan_count)

    # Cascade cycles
    result = LibPQ.execute(conn, """
        SELECT EXISTS(
            WITH RECURSIVE cascade AS (
                SELECT plant_num, downstream_plant
                FROM hydro_plants
                WHERE downstream_plant IS NOT NULL

                UNION ALL

                SELECT hp.plant_num, hp.downstream_plant
                FROM hydro_plants hp
                JOIN cascade c ON hp.plant_num = c.downstream_plant
            )
            SELECT 1 FROM cascade WHERE plant_num = downstream_plant
        ) AS has_cycle
    """)
    println("Cascade cycles detected: ", first(result).has_cycle)
end

check_referential_integrity(conn)
```

#### Step 6.2: Create Summary Statistics

```sql
-- Create summary view
CREATE OR REPLACE VIEW v_database_summary AS
SELECT
    'Subsystems' AS entity_type,
    COUNT(*) AS record_count
FROM subsystems
UNION ALL
SELECT 'Hydro Plants', COUNT(*) FROM hydro_plants
UNION ALL
SELECT 'Thermal Plants', COUNT(*) FROM thermal_plants
UNION ALL
SELECT 'Thermal Units', COUNT(*) FROM thermal_units
UNION ALL
SELECT 'Time Periods', COUNT(*) FROM time_periods
UNION ALL
SELECT 'Network Buses', COUNT(*) FROM network_buses
UNION ALL
SELECT 'Transmission Lines', COUNT(*) FROM transmission_lines
UNION ALL
SELECT 'Electrical Restrictions', COUNT(*) FROM electrical_restrictions
UNION ALL
SELECT 'Hydro Inflows', COUNT(*) FROM hydro_inflows
UNION ALL
SELECT 'Demand Records', COUNT(*) FROM demand_series
UNION ALL
SELECT 'Thermal Operations', COUNT(*) FROM thermal_operations;

-- View summary
SELECT * FROM v_database_summary ORDER BY record_count DESC;
```

---

## Handling Nested Structures

### Problem: Julia Vectors in Structs

**Current Julia Structure:**
```julia
struct ThermalRegistry
    plants::Vector{CADUSIT}       # Embedded vector
    units::Vector{CADUNIDT}        # Should be separate table
    heat_curves::Vector{CURVACOMB} # Junction table needed
end
```

### Solution: Normalize to Separate Tables

#### Pattern 1: One-to-Many (Plant → Units)

**Julia:**
```julia
struct ThermalRegistry
    plants::Vector{CADUSIT}
    units::Vector{CADUNIDT}
end
```

**Database:**
```sql
-- Parent table
CREATE TABLE thermal_plants (
    plant_num INT PRIMARY KEY,
    plant_name VARCHAR(20),
    ...
);

-- Child table (normalized)
CREATE TABLE thermal_units (
    plant_num INT NOT NULL,
    unit_num INT NOT NULL,
    unit_capacity REAL,
    PRIMARY KEY (plant_num, unit_num),
    FOREIGN KEY (plant_num) REFERENCES thermal_plants(plant_num)
);
```

**Migration Code:**
```julia
# Extract parent records
plants_df = DataFrame([
    (plant_num = p.plant_num,
     plant_name = p.plant_name,
     subsystem = p.subsystem)
    for p in termdat.plants
])

# Extract child records
units_df = DataFrame([
    (plant_num = u.plant_num,
     unit_num = u.unit_num,
     unit_capacity = u.capacity)
    for u in termdat.units
])

# Load parent first
LibPQ.execute!(conn, "INSERT INTO thermal_plants ...", plants_df)

# Load children (FK constraint validated)
LibPQ.execute!(conn, "INSERT INTO thermal_units ...", units_df)
```

#### Pattern 2: Many-to-Many (Restrictions ↔ Plants)

**Julia:**
```julia
struct ElectricalRestrictions
    restrictions::Vector{RERecord}
    hydro_coefficients::Vector{FHRecord}  # Junction data
    thermal_coefficients::Vector{FTRecord}
end
```

**Database:**
```sql
-- Master table
CREATE TABLE electrical_restrictions (
    restriction_num INT PRIMARY KEY,
    restriction_name VARCHAR(100),
    ...
);

-- Junction table 1: Hydro coefficients
CREATE TABLE restriction_hydro_coeff (
    restriction_num INT NOT NULL,
    plant_num INT NOT NULL,
    coefficient REAL NOT NULL,
    PRIMARY KEY (restriction_num, plant_num),
    FOREIGN KEY (restriction_num) REFERENCES electrical_restrictions(restriction_num),
    FOREIGN KEY (plant_num) REFERENCES hydro_plants(plant_num)
);

-- Junction table 2: Thermal coefficients
CREATE TABLE restriction_thermal_coeff (
    restriction_num INT NOT NULL,
    plant_num INT NOT NULL,
    coefficient REAL NOT NULL,
    PRIMARY KEY (restriction_num, plant_num),
    FOREIGN KEY (restriction_num) REFERENCES electrical_restrictions(restriction_num),
    FOREIGN KEY (plant_num) REFERENCES thermal_plants(plant_num)
);
```

**Migration Code:**
```julia
# Load master table first
restrictions_df = DataFrame([
    (restriction_num = r.restriction_num,
     restriction_name = r.name)
    for r in entdados.restrictions
])

LibPQ.execute!(conn, "INSERT INTO electrical_restrictions ...", restrictions_df)

# Load junction tables
hydro_coeff_df = DataFrame([
    (restriction_num = fh.restriction_num,
     plant_num = fh.plant_num,
     coefficient = fh.coefficient)
    for fh in entdados.fh_records
])

thermal_coeff_df = DataFrame([
    (restriction_num = ft.restriction_num,
     plant_num = ft.plant_num,
     coefficient = ft.coefficient)
    for ft in entdados.ft_records
])

LibPQ.execute!(conn, "INSERT INTO restriction_hydro_coeff ...", hydro_coeff_df)
LibPQ.execute!(conn, "INSERT INTO restriction_thermal_coeff ...", thermal_coeff_df)
```

#### Pattern 3: Self-Referencing (Cascade Topology)

**Julia:**
```julia
struct CADUSIH
    plant_num::Int
    downstream_plant::Union{Int,Nothing}  # Self-reference
    diversion_plant::Union{Int,Nothing}
end
```

**Database:**
```sql
CREATE TABLE hydro_plants (
    plant_num INT PRIMARY KEY,
    downstream_plant INT NULL,  -- Self-reference FK
    diversion_plant INT NULL,
    FOREIGN KEY (downstream_plant) REFERENCES hydro_plants(plant_num),
    FOREIGN KEY (diversion_plant) REFERENCES hydro_plants(plant_num)
);

-- Trigger to prevent cycles (shown in schema)
```

**Migration Code:**
```julia
# Load in topological order (roots first)
function get_topological_order(plants)
    # Separate roots and children
    roots = filter(p -> p.downstream_plant === nothing || p.downstream_plant == 0, plants)
    children = filter(p -> p.downstream_plant !== nothing && p.downstream_plant > 0, plants)

    # Load roots first, then children
    return vcat(roots, children)
end

plants_ordered = get_topological_order(hidr_data.records)

hydro_plants_df = DataFrame([
    (plant_num = p.plant_num,
     downstream_plant = p.downstream_plant == 0 ? nothing : p.downstream_plant,
     ...)
    for p in plants_ordered
])

LibPQ.execute!(conn, "INSERT INTO hydro_plants ...", hydro_plants_df)
```

#### Pattern 4: Time-Series Data

**Julia:**
```julia
struct DadvazData
    inflows::Dict{Int,Vector{Tuple{Int,Int,Int,Float64}}}
    # plant_num => [(day, hour, half_hour, inflow), ...]
end
```

**Database:**
```sql
CREATE TABLE time_periods (
    period_id SERIAL PRIMARY KEY,
    day INT NOT NULL,
    hour INT NOT NULL,
    half_hour INT NOT NULL,
    UNIQUE(day, hour, half_hour)
);

CREATE TABLE hydro_inflows (
    plant_num INT NOT NULL,
    period_id INT NOT NULL,
    inflow_m3s REAL NOT NULL,
    PRIMARY KEY (plant_num, period_id),
    FOREIGN KEY (plant_num) REFERENCES hydro_plants(plant_num),
    FOREIGN KEY (period_id) REFERENCES time_periods(period_id)
);
```

**Migration Code:**
```julia
# Build period lookup
period_map = Dict(
    (tm.dia, tm.hora, tm.meia_hora) => period_id
    for (period_id, tm) in enumerate(entdados.time_periods)
)

# Insert periods first
periods_df = DataFrame([
    (period_id = pid,
     day = tm.dia,
     hour = tm.hora,
     half_hour = tm.meia_hosa)
    for (pid, tm) in enumerate(entdados.time_periods)
])

LibPQ.execute!(conn, "INSERT INTO time_periods ...", periods_df)

# Then insert time-series data with period_id FK
inflows_rows = []
for (plant_num, series) in dadvaz.inflows
    for (day, hour, half, inflow) in series
        period_id = get(period_map, (day, hour, half), nothing)
        if period_id !== nothing
            push!(inflows_rows,
                (plant_num = plant_num,
                 period_id = period_id,
                 inflow_m3s = inflow))
        end
    end
end

inflows_df = DataFrame(inflows_rows)
LibPQ.execute!(conn, "INSERT INTO hydro_inflows ...", inflows_df)
```

---

## Caveats and Tricky Parts

### 1. Cascade Cycle Detection ⚠️ **CRITICAL**

**Problem**: Self-referencing `downstream_plant` can create cycles, breaking cascade traversal.

**Solution**: Use trigger to prevent cycles (already in schema).

```sql
-- Trigger implementation provided in schema
CREATE TRIGGER trg_prevent_cascade_cycles
BEFORE INSERT OR UPDATE OF downstream_plant ON hydro_plants
FOR EACH ROW
EXECUTE FUNCTION prevent_cascade_cycles();
```

**Detection Query**:
```sql
-- Find cycles in existing data
WITH RECURSIVE cascade_path AS (
    SELECT plant_num, downstream_plant, ARRAY[plant_num] AS path
    FROM hydro_plants
    WHERE downstream_plant IS NOT NULL

    UNION ALL

    SELECT hp.plant_num, hp.downstream_plant, cp.path || hp.plant_num
    FROM hydro_plants hp
    JOIN cascade_path cp ON hp.plant_num = cp.downstream_plant
    WHERE hp.plant_num != ALL(cp.path)
)
SELECT * FROM cascade_path WHERE plant_num = ANY(path[1:array_length(path)-1]);
```

### 2. Time Period Mapping ⚠️ **DATA LOSS RISK**

**Problem**: Julia uses `(day, hour, half_hour)` tuples, database uses surrogate `period_id`. Mismatch can cause orphaned time-series records.

**Solution**: Always build lookup map before insertion.

```julia
# GOOD: Build lookup map
period_map = Dict(
    (tm.dia, tm.hora, tm.meia_hora) => period_id
    for (period_id, tm) in enumerate(entdados.time_periods)
)

# Use map for all time-series inserts
for (day, hour, half, value) in time_series_data
    period_id = get(period_map, (day, hour, half), nothing)
    if period_id === nothing
        @warn "Period not found: ($day, $hour, $half)"
        continue  # Skip orphaned record
    end
    # Insert with period_id FK
end

# BAD: Direct lookup without validation (slow and error-prone)
# period_id = LibPQ.execute(conn, "SELECT period_id FROM time_periods WHERE day=$1 AND hour=$2 AND half_hour=$3", [day, hour, half])
```

### 3. Composite Primary Keys ⚠️ **PERFORMANCE**

**Problem**: Composite PKs like `(plant_num, unit_num)` can be slow for joins if not indexed properly.

**Solution**: Always create indexes on FK columns.

```sql
-- Composite PK automatically indexed
PRIMARY KEY (plant_num, unit_num)

-- Add additional index for reverse lookup
CREATE INDEX idx_thermal_units_plant ON thermal_units(plant_num);

-- Now both queries are fast
-- Query 1: By PK (uses primary key index)
SELECT * FROM thermal_units WHERE plant_num=101 AND unit_num=1;

-- Query 2: By FK only (uses additional index)
SELECT * FROM thermal_units WHERE plant_num=101;
```

### 4. ENUM Type Changes ⚠️ **MIGRATION HELL**

**Problem**: Adding/removing ENUM values requires locking the entire table in PostgreSQL.

**Solution**: Use `ALTER TYPE` with transaction.

```sql
-- GOOD: Add new ENUM value (PostgreSQL 9.1+)
BEGIN;
ALTER TYPE fuel_type_enum ADD VALUE 'HYDROGEN' AFTER 'NUCLEAR';
COMMIT;

-- BAD: Remove ENUM value (requires rewriting table)
-- ALTER TYPE fuel_type_enum REMOVE VALUE 'OTHER';  -- NOT SUPPORTED

-- WORKAROUND: Update dependent columns first
BEGIN;
-- Update all 'OTHER' records to 'GAS'
UPDATE thermal_plants SET fuel_type='GAS' WHERE fuel_type='OTHER';
-- Now drop and recreate ENUM (not recommended in production)
COMMIT;
```

**Better Solution**: Use `TEXT` columns with `CHECK` constraints for frequently-changing enums.

```sql
-- Flexible alternative to ENUM
CREATE TABLE thermal_plants (
    ...
    fuel_type TEXT NOT NULL CHECK(fuel_type IN ('GAS', 'COAL', 'OIL', 'BIOMASS', 'NUCLEAR', 'OTHER', 'HYDROGEN'))
);
```

### 5. Large Time-Series Tables ⚠️ **PERFORMANCE**

**Problem**: Tables like `hydro_inflows` can have millions of records (plants × periods).

**Solutions**:

**A. Partitioning (PostgreSQL)**
```sql
-- Partition by month or year
CREATE TABLE hydro_inflows (
    plant_num INT NOT NULL,
    period_id INT NOT NULL,
    inflow_m3s REAL NOT NULL,
    PRIMARY KEY (plant_num, period_id)
) PARTITION BY RANGE (period_id);

-- Create partitions
CREATE TABLE hydro_inflows_2025_01 PARTITION OF hydro_inflows
    FOR VALUES FROM (1) TO (10000);

CREATE TABLE hydro_inflows_2025_02 PARTITION OF hydro_inflows
    FOR VALUES FROM (10001) TO (20000);
```

**B. Partial Indexes**
```sql
-- Index only recent periods (most queries)
CREATE INDEX idx_hydro_inflows_recent
ON hydro_inflows(plant_num, period_id)
WHERE period_id > (SELECT MAX(period_id) - 1000 FROM time_periods);
```

**C. Materialized Views**
```sql
-- Pre-aggregate common queries
CREATE MATERIALIZED VIEW mv_hydro_inflows_weekly AS
SELECT
    plant_num,
    date_trunc('week', tp.day) AS week_start,
    AVG(inflow_m3s) AS avg_inflow,
    SUM(inflow_m3s) AS total_inflow
FROM hydro_inflows hi
JOIN time_periods tp ON hi.period_id = tp.period_id
GROUP BY plant_num, date_trunc('week', tp.day);

-- Refresh periodically
REFRESH MATERIALIZED VIEW mv_hydro_inflows_weekly;
```

### 6. Missing Foreign Keys ⚠️ **INTEGRITY**

**Problem**: Some relationships in DESSEM files are implicit (e.g., `operut.plant_num` references `termdat.plants` but no formal constraint).

**Solution**: Always add explicit FK constraints.

```sql
-- Even if not enforced in original format
ALTER TABLE thermal_operations
ADD CONSTRAINT fk_thermal_operations_unit
FOREIGN KEY (plant_num, unit_num)
REFERENCES thermal_units(plant_num, unit_num)
ON DELETE CASCADE;
```

### 7. Text Format vs Binary Format ⚠️ **DATA COMPLETENESS**

**Problem**: Binary HIDR.DAT contains only plant registry, missing unit sets and polynomials.

**Solution**: Use `LEFT JOIN` and handle `NULL` values.

```sql
-- Query must handle missing unit sets
SELECT
    hp.plant_name,
    COALESCE(hus.num_units, 0) AS unit_set_count,
    COALESCE(hus.unit_capacity_mw, hp.installed_capacity_mw) AS capacity
FROM hydro_plants hp
LEFT JOIN hydro_unit_sets hus ON hp.plant_num = hus.plant_num
WHERE hp.subsystem = 1;
```

---

## Data Migration Scripts

### Complete Migration Script

```julia
"""
Complete migration script: JLD2 → PostgreSQL

Usage:
    julia migrate_to_db.jl ons_sample.jld2 postgresql://user:pass@localhost/dessem_db
"""

using JLD2
using LibPQ
using DataFrames
using ArgParse

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "input"
            help = "Input JLD2 file"
            required = true
        "connection"
            help = "Database connection string"
            default = "postgresql://postgres@localhost/dessem_db"
    end
    return parse_args(s)
end

function main()
    args = parse_commandline()

    println("="^80)
    println("DESSEM2Julia → PostgreSQL Migration")
    println("="^80)
    println()

    # Load JLD2 data
    println("📂 Loading JLD2 file: $(args.input)")
    data = JLD2.load(args.input)
    dessem_data = data["data"]
    println("✅ JLD2 file loaded")
    println()

    # Connect to database
    println("🔌 Connecting to database...")
    conn = LibPQ.Connection(args.connection)
    println("✅ Connected to database")
    println()

    # Start transaction
    LibPQ.execute(conn, "BEGIN")

    try
        # Phase 1: Core data
        println("⏳ Phase 1/5: Loading core data...")
        load_subsystems(conn, dessem_data)
        load_time_periods(conn, dessem_data)
        load_hydro_plants(conn, dessem_data)
        load_thermal_plants(conn, dessem_data)
        load_thermal_units(conn, dessem_data)
        println("✅ Phase 1 complete")
        println()

        # Phase 2: Time-series data
        println("⏳ Phase 2/5: Loading time-series data...")
        load_hydro_inflows(conn, dessem_data)
        load_demand_series(conn, dessem_data)
        load_thermal_operations(conn, dessem_data)
        load_renewable_generation(conn, dessem_data)
        println("✅ Phase 2 complete")
        println()

        # Phase 3: Network data
        println("⏳ Phase 3/5: Loading network data...")
        load_network_buses(conn, dessem_data)
        load_transmission_lines(conn, dessem_data)
        println("✅ Phase 3 complete")
        println()

        # Phase 4: Constraint data
        println("⏳ Phase 4/5: Loading constraint data...")
        load_electrical_restrictions(conn, dessem_data)
        load_restriction_coefficients(conn, dessem_data)
        println("✅ Phase 4 complete")
        println()

        # Phase 5: Validation
        println("⏳ Phase 5/5: Validating referential integrity...")
        validate_integrity(conn)
        println("✅ Phase 5 complete")
        println()

        # Commit transaction
        LibPQ.execute(conn, "COMMIT")

        println("="^80)
        println("✅ MIGRATION COMPLETE!")
        println("="^80)

    catch e
        # Rollback on error
        LibPQ.execute(conn, "ROLLBACK")
        println("="^80)
        println("❌ MIGRATION FAILED!")
        println("="^80)
        println("Error: $e")
        rethrow(e)
    finally
        close(conn)
    end
end

# Implement each load_* function (shown in previous sections)
# ...

main()
```

---

## Query Examples

### 1. Find All Plants in Subsystem

```sql
-- Hydro plants in Southeast (SE)
SELECT
    hp.plant_num,
    hp.plant_name,
    hp.installed_capacity_mw,
    COUNT(DISTINCT hus.set_num) AS unit_set_count
FROM hydro_plants hp
LEFT JOIN hydro_unit_sets hus ON hp.plant_num = hus.plant_num
WHERE hp.subsystem = 1  -- 1 = SE
GROUP BY hp.plant_num, hp.plant_name, hp.installed_capacity_mw
ORDER BY hp.plant_num;
```

### 2. Traverse Hydro Cascade

```sql
-- Recursive CTE: Find all downstream plants
WITH RECURSIVE cascade AS (
    -- Root plant (e.g., Furnas)
    SELECT plant_num, plant_name, downstream_plant, 1 AS level_num
    FROM hydro_plants
    WHERE plant_num = 6  -- Furnas

    UNION ALL

    -- Downstream plants
    SELECT hp.plant_num, hp.plant_name, hp.downstream_plant, c.level_num + 1
    FROM hydro_plants hp
    JOIN cascade c ON hp.plant_num = c.downstream_plant
    WHERE hp.downstream_plant IS NOT NULL
)
SELECT
    level_num,
    plant_num,
    plant_name,
    installed_capacity_mw
FROM cascade
ORDER BY level_num, plant_num;
```

### 3. Calculate Subsystem Capacity

```sql
-- Total installed capacity by subsystem and type
WITH hydro_capacity AS (
    SELECT subsystem, SUM(installed_capacity_mw) AS capacity_mw
    FROM hydro_plants
    GROUP BY subsystem
),
thermal_capacity AS (
    SELECT tp.subsystem, SUM(tu.capacity_mw) AS capacity_mw
    FROM thermal_plants tp
    JOIN thermal_units tu ON tp.plant_num = tu.plant_num
    GROUP BY tp.subsystem
),
renewable_capacity AS (
    SELECT subsystem, SUM(installed_capacity_mw) AS capacity_mw
    FROM renewable_plants
    GROUP BY subsystem
)
SELECT
    s.subsystem_code,
    s.subsystem_name,
    COALESCE(hc.capacity_mw, 0) AS hydro_capacity_mw,
    COALESCE(tc.capacity_mw, 0) AS thermal_capacity_mw,
    COALESCE(rc.capacity_mw, 0) AS renewable_capacity_mw,
    COALESCE(hc.capacity_mw, 0) +
    COALESCE(tc.capacity_mw, 0) +
    COALESCE(rc.capacity_mw, 0) AS total_capacity_mw
FROM subsystems s
LEFT JOIN hydro_capacity hc ON s.subsystem_num = hc.subsystem
LEFT JOIN thermal_capacity tc ON s.subsystem_num = tc.subsystem
LEFT JOIN renewable_capacity rc ON s.subsystem_num = rc.subsystem
ORDER BY total_capacity_mw DESC;
```

### 4. Thermal Units with Operating Costs

```sql
-- Find units sorted by operating cost
SELECT
    tp.plant_name,
    tu.unit_num,
    tu.capacity_mw,
    TO.operating_cost_brl_mwh,
    TO.max_generation_mw
FROM thermal_units tu
JOIN thermal_plants tp ON tu.plant_num = tp.plant_num
JOIN thermal_operations TO ON tu.plant_num = TO.plant_num AND tu.unit_num = TO.unit_num
WHERE TO.period_id = 1  -- First period
ORDER BY TO.operating_cost_brl_mwh ASC
LIMIT 20;
```

### 5. Network Connectivity Analysis

```sql
-- Find buses with most connections
SELECT
    b.bus_num,
    b.bus_name,
    b.subsystem,
    s.subsystem_code,
    COUNT(DISTINCT tl.from_bus) + COUNT(DISTINCT tl.to_bus) AS connection_count
FROM network_buses b
LEFT JOIN subsystems s ON b.subsystem = s.subsystem_num
LEFT JOIN transmission_lines tl ON b.bus_num = tl.from_bus OR b.bus_num = tl.to_bus
GROUP BY b.bus_num, b.bus_name, b.subsystem, s.subsystem_code
ORDER BY connection_count DESC
LIMIT 10;
```

### 6. Demand Profile by Subsystem

```sql
-- Average demand by load level
SELECT
    s.subsystem_code,
    tp.load_level,
    AVG(ds.demand_mw) AS avg_demand_mw,
    MIN(ds.demand_mw) AS min_demand_mw,
    MAX(ds.demand_mw) AS max_demand_mw,
    COUNT(*) AS period_count
FROM demand_series ds
JOIN subsystems s ON ds.subsystem = s.subsystem_num
JOIN time_periods tp ON ds.period_id = tp.period_id
GROUP BY s.subsystem_code, tp.load_level
ORDER BY s.subsystem_code, avg_demand_mw DESC;
```

### 7. Plants with Highest Inflows

```sql
-- Top 10 plants by average inflow
SELECT
    hp.plant_num,
    hp.plant_name,
    AVG(hi.inflow_m3s) AS avg_inflow_m3s,
    SUM(hi.inflow_m3s) AS total_inflow_m3s,
    STDDEV(hi.inflow_m3s) AS inflow_stddev
FROM hydro_plants hp
JOIN hydro_inflows hi ON hp.plant_num = hi.plant_num
GROUP BY hp.plant_num, hp.plant_name
ORDER BY avg_inflow_m3s DESC
LIMIT 10;
```

---

## Performance Optimization

### Index Strategy

**Critical Indexes** (create these first):
```sql
-- Foreign key indexes
CREATE INDEX idx_hydro_plants_subsystem ON hydro_plants(subsystem);
CREATE INDEX idx_hydro_plants_downstream ON hydro_plants(downstream_plant);
CREATE INDEX idx_thermal_units_plant ON thermal_units(plant_num);
CREATE INDEX idx_thermal_operations_plant_period ON thermal_operations(plant_num, period_id);
CREATE INDEX idx_hydro_inflows_plant_period ON hydro_inflows(plant_num, period_id);
CREATE INDEX idx_demand_series_subsystem_period ON demand_series(subsystem, period_id);
CREATE INDEX idx_transmission_lines_from ON transmission_lines(from_bus);
CREATE INDEX idx_transmission_lines_to ON transmission_lines(to_bus);
```

**Composite Indexes** (for specific query patterns):
```sql
-- Time-series queries by plant
CREATE INDEX idx_thermal_ops_unit_period ON thermal_operations(plant_num, unit_num, period_id);

-- Cascade traversal
CREATE INDEX idx_hydro_plants_downstream ON hydro_plants(downstream_plant) WHERE downstream_plant IS NOT NULL;

-- Renewable generation queries
CREATE INDEX idx_renewable_gen_plant_period ON renewable_generation(plant_num, period_id);
```

**Partial Indexes** (for filtered queries):
```sql
-- Index only existing plants
CREATE INDEX idx_hydro_plants_existing
ON hydro_plants(plant_num, subsystem)
WHERE status = 'EXISTING';

-- Index only recent inflows (last 100 periods)
CREATE INDEX idx_hydro_inflows_recent
ON hydro_inflows(plant_num, inflow_m3s)
WHERE period_id > (SELECT MAX(period_id) - 100 FROM time_periods);
```

### Query Optimization Tips

**1. Use EXPLAIN ANALYZE**
```sql
EXPLAIN ANALYZE
SELECT hp.plant_name, hi.inflow_m3s
FROM hydro_plants hp
JOIN hydro_inflows hi ON hp.plant_num = hi.plant_num
WHERE hp.subsystem = 1;
```

**2. Avoid SELECT ***
```sql
-- BAD: Fetches all columns
SELECT * FROM hydro_plants;

-- GOOD: Fetch only needed columns
SELECT plant_num, plant_name, installed_capacity_mw
FROM hydro_plants;
```

**3. Use CTEs for complex queries**
```sql
-- Complex query broken into readable CTEs
WITH subsystem_capacities AS (
    SELECT subsystem, SUM(installed_capacity_mw) AS total_capacity
    FROM hydro_plants
    GROUP BY subsystem
),
max_capacities AS (
    SELECT MAX(total_capacity) AS max_cap
    FROM subsystem_capacities
)
SELECT sc.subsystem, sc.total_capacity
FROM subsystem_capacities sc
CROSS JOIN max_capacities mc
WHERE sc.total_capacity > mc.max_cap * 0.5;  -- Top 50%
```

**4. Partition large tables** (shown in Caveats section)

**5. Use materialized views for aggregations**
```sql
CREATE MATERIALIZED VIEW mv_plant_summary AS
SELECT
    hp.plant_num,
    hp.plant_name,
    hp.subsystem,
    COUNT(DISTINCT hi.period_id) AS inflow_count,
    AVG(hi.inflow_m3s) AS avg_inflow,
    SUM(COALESCE(tu.capacity_mw, 0)) AS total_thermal_capacity
FROM hydro_plants hp
LEFT JOIN hydro_inflows hi ON hp.plant_num = hi.plant_num
LEFT JOIN thermal_units tu ON hp.plant_num = tu.plant_num
GROUP BY hp.plant_num, hp.plant_name, hp.subsystem;

-- Refresh periodically (not in real-time)
REFRESH MATERIALIZED VIEW mv_plant_summary;
```

---

## Validation and Integrity

### Data Quality Checks

**1. Check for duplicate records**
```sql
-- Find duplicate plant numbers
SELECT plant_num, COUNT(*) AS count
FROM hydro_plants
GROUP BY plant_num
HAVING COUNT(*) > 1;
```

**2. Validate value ranges**
```sql
-- Check for negative values
SELECT table_name, column_name, COUNT(*) AS invalid_count
FROM (
    SELECT 'hydro_plants' AS table_name, 'installed_capacity_mw' AS column_name
    FROM hydro_plants WHERE installed_capacity_mw < 0

    UNION ALL

    SELECT 'thermal_units', 'capacity_mw'
    FROM thermal_units WHERE capacity_mw < 0

    UNION ALL

    SELECT 'hydro_inflows', 'inflow_m3s'
    FROM hydro_inflows WHERE inflow_m3s < 0
) invalid_records
GROUP BY table_name, column_name;
```

**3. Check orphaned records**
```sql
-- Thermal units without plants
SELECT COUNT(*) AS orphaned_units
FROM thermal_units tu
LEFT JOIN thermal_plants tp ON tu.plant_num = tp.plant_num
WHERE tp.plant_num IS NULL;
```

**4. Validate time series continuity**
```sql
-- Find missing periods in inflow series
SELECT
    hi.plant_num,
    tp.day,
    tp.hour,
    tp.half_hour
FROM time_periods tp
CROSS JOIN (SELECT DISTINCT plant_num FROM hydro_inflows) hi
LEFT JOIN hydro_inflows inflows ON inflows.plant_num = hi.plant_num AND inflows.period_id = tp.period_id
WHERE inflows.plant_num IS NULL
ORDER BY hi.plant_num, tp.day, tp.hour;
```

### Referential Integrity Validation

```sql
-- Complete integrity check script
DO $$
DECLARE
    orphan_count INT;
BEGIN
    -- Check hydro plants
    SELECT COUNT(*) INTO orphan_count
    FROM hydro_plants hp
    LEFT JOIN subsystems s ON hp.subsystem = s.subsystem_num
    WHERE s.subsystem_num IS NULL;

    IF orphan_count > 0 THEN
        RAISE WARNING 'Orphaned hydro plants: %', orphan_count;
    END IF;

    -- Check thermal units
    SELECT COUNT(*) INTO orphan_count
    FROM thermal_units tu
    LEFT JOIN thermal_plants tp ON tu.plant_num = tp.plant_num
    WHERE tp.plant_num IS NULL;

    IF orphan_count > 0 THEN
        RAISE WARNING 'Orphaned thermal units: %', orphan_count;
    END IF;

    -- Check cascade cycles
    -- (implement cycle detection query from Caveats section)
END $$;
```

---

## Summary

This comprehensive guide provides everything needed to implement a production-ready relational database for DESSEM input data:

✅ **Complete schema** with 42+ normalized tables
✅ **ENUM definitions** for type safety
✅ **Entity-Relationship diagram** (Mermaid)
✅ **Step-by-step migration scripts** (Julia → PostgreSQL)
✅ **Handling nested structures** (vectors, self-references, time-series)
✅ **Caveats and solutions** (cycles, performance, data loss risks)
✅ **Query examples** (cascade traversal, capacity calculations)
✅ **Performance optimization** (indexes, partitioning, materialized views)
✅ **Validation scripts** (data quality, referential integrity)

### Key Takeaways

1. **Normalize everything**: Vectors → separate tables
2. **Use surrogate keys**: `period_id` instead of `(day, hour, half_hour)`
3. **Index FK columns**: Critical for join performance
4. **Prevent cascade cycles**: Use triggers
5. **Validate continuously**: Check integrity after each migration phase
6. **Handle NULL gracefully**: Binary format may miss data
7. **Test with real data**: Use provided ONS/CCEE samples

### Platform-Specific Notes

**PostgreSQL**: Full support, recommended for production
- ENUM types supported
- Recursive CTEs for cascade traversal
- Partitioning for large tables
- Advanced triggers and constraints

**SQLite**: Good for development, testing
- No ENUM (use TEXT + CHECK)
- Limited recursive CTE support
- No partitioning
- Single-file database

**MySQL/MariaDB**: Production alternative
- ENUM supported (inline in column)
- Recursive CTEs supported (8.0+)
- Partitioning supported
- Different trigger syntax

---

**Document Version**: 1.0
**Last Updated**: 2026-01-01
**Maintained By**: DESSEM2Julia Project
