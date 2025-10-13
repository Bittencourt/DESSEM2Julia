# DESSEM2Julia Type System

Comprehensive data model for all DESSEM input files.

## Overview

The type system is organized into **functional subsystems** that mirror the structure of the Brazilian power system optimization problem:

1. **Time Discretization** - Temporal structure of the study
2. **Power System** - Electrical subsystems, demand, reserves
3. **Hydro System** - Hydroelectric plants, reservoirs, operations
4. **Thermal System** - Thermal plants, units, operations
5. **Renewable System** - Wind and solar generation
6. **Network System** - Transmission network model
7. **Operational Constraints** - Ramps, LPP, security constraints
8. **DECOMP Interface** - Future cost function cuts
9. **Execution Options** - Solver and modeling configurations

All types are defined in `src/models/core_types.jl`.

## Architecture

### Three-Tier Hierarchy

```
DessemCase (Top-level container)
    ├── FileRegistry (dessem.arq - master index)
    ├── TimeDiscretization
    │   └── Vector{TimePeriod}
    ├── PowerSystem
    │   ├── Vector{Subsystem}
    │   ├── Vector{LoadDemand}
    │   └── Vector{PowerReserve}
    ├── HydroSystem
    │   ├── Vector{HydroPlant}
    │   ├── Vector{HydroReservoir}
    │   └── Vector{HydroOperation}
    ├── ThermalSystem
    │   ├── Vector{ThermalPlant}
    │   ├── Vector{ThermalUnit}
    │   └── Vector{ThermalOperation}
    ├── RenewableSystem
    │   ├── Vector{WindPlant}
    │   └── Vector{SolarPlant}
    ├── NetworkSystem
    │   ├── Vector{ElectricBus}
    │   └── Vector{TransmissionLine}
    ├── OperationalConstraints
    │   ├── Vector{RampConstraint}
    │   ├── Vector{LPPConstraint}
    │   ├── Vector{TableConstraint}
    │   └── Vector{FlowRampConstraint}
    ├── DecompCut
    │   └── Vector{FCFCut}
    └── ExecutionOptions
```

### Design Principles

1. **Hierarchical Organization**: Top-level container (`DessemCase`) contains subsystem containers (e.g., `HydroSystem`), which contain record vectors (e.g., `Vector{HydroPlant}`)

2. **Type Safety**: Strong typing with `Union{T, Nothing}` for optional fields

3. **Keyword Construction**: All structs use `@kwdef` for flexible, readable construction

4. **Documentation**: Comprehensive docstrings with field descriptions, units, and constraints

5. **Separation of Concerns**: Types separate from parsing logic (see `src/parser/`)

## Type Catalog

### 1. Time Discretization Types

#### `TimePeriod`
**File Source**: ENTDADOS.DAT (TM records)

Represents a single time step in the study.

```julia
TimePeriod(
    period_id = 1,
    day = 1,
    hour = 0,
    half_hour = 0,
    duration = 1.0,      # hours
    network_flag = 0,    # 0=no network, 1=network, 2=network+losses
    load_level = "PESADA"
)
```

**Fields**:
- `period_id::Int`: Sequential period number (1-based)
- `day::Int`: Calendar day
- `hour::Int`: Hour (0-23)
- `half_hour::Int`: Half-hour flag (0 or 1)
- `duration::Float64`: Period length in hours (typically 1.0 or 0.5)
- `network_flag::Int`: Network modeling flag
- `load_level::String`: Load level classification

#### `TimeDiscretization`
Container for all time periods.

```julia
TimeDiscretization(
    periods = [period1, period2, ...],
    num_periods = 168,
    total_hours = 168.0
)
```

### 2. Power System Types

#### `Subsystem`
**File Source**: ENTDADOS.DAT (SIST records)

Electrical subsystem definition (e.g., Southeast, South, Northeast, North).

```julia
Subsystem(
    number = 1,
    code = "SE",
    status = 0,
    name = "SUDESTE"
)
```

**Common Subsystems**:
- 1 = "SE" (Southeast)
- 2 = "S" (South)
- 3 = "NE" (Northeast)
- 4 = "N" (North)

#### `LoadDemand`
**File Source**: ENTDADOS.DAT (DP records)

Load demand for a subsystem in a time interval.

```julia
LoadDemand(
    subsystem = 1,
    start_day = 1,
    start_hour = 0,
    start_half = 0,
    end_day = "F",      # "F" = final period
    end_hour = 0,
    end_half = 0,
    demand_mw = 35000.0
)
```

#### `PowerReserve`
**File Sources**: AREACONT.DAT, RESPOT.DAT

Power reserve requirements for a reserve area.

```julia
PowerReserve(
    area_code = 1,
    area_name = "AREA_SE",
    subsystems = [1],
    reserve_requirement_mw = 5000.0,
    spinning_reserve_pct = 50.0
)
```

### 3. Hydro System Types

#### `HydroReservoir`
**File Sources**: ENTDADOS.DAT (UH records), HIDR.DAT

Reservoir characteristics and initial conditions.

```julia
HydroReservoir(
    plant_num = 6,
    plant_name = "FURNAS",
    subsystem = 1,
    initial_volume_pct = 65.0,    # % of useful volume
    volume_unit = 2,              # 1=hm³, 2=% useful
    min_volume = 5733.0,          # hm³
    max_volume = 22950.0,         # hm³
    initial_volume_abs = 17117.0, # hm³
    spillway_crest = nothing,
    diversion_crest = nothing,
    storage_capacity_hm3 = 22950.0,
    useful_volume_hm3 = 17217.0
)
```

**Key Plants** (examples):
- 1 = CAMARGOS
- 4 = EMBORCAÇÃO
- 6 = FURNAS
- 66 = ITAIPU

#### `HydroPlant`
**File Source**: HIDR.DAT (CADUSIH)

Hydro plant technical characteristics.

```julia
HydroPlant(
    plant_num = 6,
    plant_name = "FURNAS",
    subsystem = 1,
    status = 0,                        # 0=existing, 1=under construction
    installed_capacity_mw = 1216.0,
    num_units = 8,
    turbine_flow_m3s = 707.0,
    min_turbine_flow_m3s = 30.0,
    production_coefficient = 0.00518,  # MWh/hm³
    upstream_plant = 4,                # Emborcação
    downstream_plant = 169,            # Mascarenhas
    cascade_order = 2
)
```

#### `HydroOperation`
**File Source**: OPERUH.DAT

Operational constraints for hydro plants.

```julia
HydroOperation(
    plant_num = 6,
    constraint_type = "VAZMIN",        # Min turbine flow
    period_start = 1,
    period_end = 168,
    constraint_value = 100.0,
    unit = "m³/s"
)
```

**Constraint Types**:
- `"VAZMIN"`: Minimum turbine flow (m³/s)
- `"VAZMAX"`: Maximum turbine flow (m³/s)
- `"VMINP"`: Minimum volume (% or hm³)
- `"VMAXP"`: Maximum volume (% or hm³)
- `"GHMIN"`: Minimum generation (MW)
- `"GHMAX"`: Maximum generation (MW)

#### `HydroSystem`
Container for all hydro-related data.

```julia
HydroSystem(
    plants = [plant1, plant2, ...],
    reservoirs = [res1, res2, ...],
    operations = [op1, op2, ...],
    previous_outflows = Dict(6 => [100.0, 105.0, ...]),  # DEFLANT.DAT
    natural_inflows = Dict(6 => [500.0, 520.0, ...])     # DADVAZ.DAT
)
```

### 4. Thermal System Types

#### `ThermalPlant`
**File Source**: TERMDAT.DAT (CADUSIT records)

Thermal plant registry.

```julia
ThermalPlant(
    plant_num = 101,
    plant_name = "ANGRA1",
    subsystem = 1,
    commission_date = Date(1985, 4, 1),
    plant_class = 1,
    fuel_type = 5,          # Nuclear
    num_units = 1,
    heat_rate = 10800.0,    # kJ/kWh
    fuel_cost = 45.0        # BRL/unit
)
```

**Fuel Types**:
- 1 = Natural Gas
- 2 = Coal
- 3 = Diesel/Oil
- 4 = Biomass
- 5 = Nuclear
- 6 = Other

#### `ThermalUnit`
**File Source**: TERMDAT.DAT (CADUNIDT records)

Individual thermal generating unit.

```julia
ThermalUnit(
    plant_num = 101,
    unit_num = 1,
    unit_name = "ANGRA1_U1",
    commission_date = Date(1985, 4),
    capacity_mw = 640.0,
    min_generation_mw = 200.0,
    min_on_time_h = 8,
    min_off_time_h = 8,
    cold_startup_cost = 50000.0,
    hot_startup_cost = 10000.0,
    shutdown_cost = 5000.0,
    ramp_up_rate_mw_h = 80.0,
    ramp_down_rate_mw_h = 80.0,
    heat_curve_points = [(200.0, 11000.0), (400.0, 10800.0), (640.0, 10700.0)]
)
```

#### `ThermalOperation`
**File Sources**: ENTDADOS.DAT (UT records), OPERUT.DAT

Thermal unit operational configuration.

```julia
ThermalOperation(
    plant_num = 101,
    unit_num = 1,
    start_day = 1,
    start_hour = 0,
    start_half = 0,
    end_day = "F",
    end_hour = 0,
    end_half = 0,
    min_generation_mw = 0.0,
    max_generation_mw = 640.0,
    must_run = false,
    inflexibility_type = nothing
)
```

#### `ThermalSystem`
Container for thermal generation system.

```julia
ThermalSystem(
    plants = [plant1, plant2, ...],
    units = [unit1, unit2, ...],
    operations = [op1, op2, ...]
)
```

### 5. Renewable System Types

#### `WindPlant`
**File Source**: RENOVAVEIS.DAT (EOLICA)

Wind power plant with generation forecast.

```julia
WindPlant(
    plant_num = 501,
    plant_name = "PARQUE_EOLICO_1",
    subsystem = 3,
    installed_capacity_mw = 300.0,
    generation_forecast = [150.0, 180.0, 200.0, ...]  # MW per period
)
```

#### `SolarPlant`
**File Source**: RENOVAVEIS.DAT

Solar power plant with generation forecast.

```julia
SolarPlant(
    plant_num = 601,
    plant_name = "PARQUE_SOLAR_1",
    subsystem = 3,
    installed_capacity_mw = 200.0,
    generation_forecast = [0.0, 0.0, 100.0, 180.0, ...]  # MW per period
)
```

### 6. Network System Types

#### `ElectricBus`
**File Source**: DESSELET.DAT (INDELET)

Electrical bus in the network model.

```julia
ElectricBus(
    bus_num = 1001,
    bus_name = "SE_500kV",
    subsystem = 1,
    voltage_kv = 500.0,
    base_voltage_kv = 500.0
)
```

#### `TransmissionLine`
**File Source**: DESSELET.DAT

Transmission line between buses.

```julia
TransmissionLine(
    line_num = 1,
    from_bus = 1001,
    to_bus = 2001,
    line_name = "SE-S_500kV",
    resistance = 0.002,     # p.u.
    reactance = 0.05,       # p.u.
    susceptance = 0.001,    # p.u.
    capacity_mw = 2000.0,
    num_circuits = 2
)
```

### 7. Operational Constraints

#### `RampConstraint`
**File Source**: RAMPAS.DAT

Generation trajectory constraints.

```julia
RampConstraint(
    unit_type = "H",        # "H"=hydro, "T"=thermal
    unit_num = 6,
    period = 10,
    min_generation_mw = 500.0,
    max_generation_mw = 800.0,
    target_generation_mw = 650.0
)
```

#### `LPPConstraint`
**File Source**: RSTLPP.DAT

Linear piecewise constraints.

```julia
LPPConstraint(
    constraint_id = 1,
    constraint_name = "CONSTRAINT_SE_RESERVE",
    sense = ">=",
    rhs = 1000.0,
    coefficients = Dict(
        ("H", 6) => 1.0,
        ("H", 4) => 1.0,
        ("T", 101) => 1.0
    )
)
```

### 8. DECOMP Interface

#### `FCFCut`
**File Source**: CORTDECO.RV0

Future cost function cut from DECOMP.

```julia
FCFCut(
    cut_id = 1,
    stage = 1,
    scenario = 1,
    intercept = 1500000.0,
    coefficients = Dict(
        1 => 2500.0,    # SE subsystem coefficient
        2 => 1800.0,    # S subsystem coefficient
        3 => 1200.0,    # NE subsystem coefficient
        4 => 900.0      # N subsystem coefficient
    )
)
```

### 9. Execution Options

#### `ExecutionOptions`
**File Source**: DESSOPC.DAT

DESSEM solver and modeling configuration.

```julia
ExecutionOptions(
    solver = "CPLEX",
    max_iterations = 1000,
    convergence_tolerance = 1e-4,
    output_level = 1,
    enable_network = true,
    enable_losses = true,
    enable_security = false,
    parallel_threads = 4
)
```

## File Registry

### `FileRegistry`
**File Source**: dessem.arq

Master file index mapping logical names to physical files.

```julia
FileRegistry(
    caso = "DAT",
    titulo = "PMO - OUTUBRO/25 - REV 0",
    vazoes = "dadvaz.dat",
    dadger = "entdados.dat",
    mapfcf = "mapcut.rv0",
    cortfcf = "cortdeco.rv0",
    cadusih = "hidr.dat",
    operuh = "operuh.dat",
    deflant = "deflant.dat",
    cadterm = "termdat.dat",
    operut = "operut.dat",
    # ... 20+ more fields
)
```

## Unified Container

### `DessemCase`
Top-level container for complete DESSEM case.

```julia
case = DessemCase(
    case_name = "PMO_OCT2025",
    case_title = "PMO - OUTUBRO/25 - REV 0",
    base_directory = "/path/to/case",
    file_registry = FileRegistry(...),
    time_discretization = TimeDiscretization(...),
    power_system = PowerSystem(...),
    hydro_system = HydroSystem(...),
    thermal_system = ThermalSystem(...),
    renewable_system = RenewableSystem(...),
    network_system = NetworkSystem(...),
    operational_constraints = OperationalConstraints(...),
    decomp_cuts = DecompCut(...),
    execution_options = ExecutionOptions(...),
    metadata = Dict(
        "parse_time" => now(),
        "parser_version" => "0.1.0"
    )
)
```

## Usage Examples

### Access Patterns

```julia
# Load complete case
case = load_dessem_case("/path/to/case")

# Query basic info
println("Case: $(case.case_name)")
println("Study periods: $(case.time_discretization.num_periods)")
println("Total hours: $(case.time_discretization.total_hours)")

# Access subsystem data
se_subsystem = first(s for s in case.power_system.subsystems if s.code == "SE")
println("Subsystem: $(se_subsystem.name)")

# Get hydro plants
furnas = first(p for p in case.hydro_system.plants if p.plant_num == 6)
println("Furnas capacity: $(furnas.installed_capacity_mw) MW")

# Get thermal units
angra_units = filter(u -> u.plant_num == 101, case.thermal_system.units)
println("Angra has $(length(angra_units)) unit(s)")

# Access initial conditions
furnas_reservoir = first(r for r in case.hydro_system.reservoirs if r.plant_num == 6)
println("Furnas initial volume: $(furnas_reservoir.initial_volume_pct)%")

# Check execution options
if case.execution_options.enable_network
    println("Network modeling enabled")
    println("Number of buses: $(length(case.network_system.buses))")
end
```

### Filtering Examples

```julia
# All hydro plants in SE subsystem
se_hydro = filter(p -> p.subsystem == 1, case.hydro_system.plants)

# All thermal units with capacity > 500 MW
large_thermal = filter(u -> u.capacity_mw > 500.0, case.thermal_system.units)

# All operational constraints for a specific plant
furnas_ops = filter(op -> op.plant_num == 6, case.hydro_system.operations)

# All wind plants
wind_plants = case.renewable_system.wind_plants

# All time periods with network modeling
network_periods = filter(p -> p.network_flag > 0, case.time_discretization.periods)
```

### DataFrame Export (Future)

```julia
using DataFrames

# Convert to DataFrames for analysis
hydro_df = DataFrame(case.hydro_system.plants)
thermal_df = DataFrame(case.thermal_system.units)
demands_df = DataFrame(case.power_system.demands)

# Analyze
using Statistics
mean_capacity = mean(hydro_df.installed_capacity_mw)
total_thermal_capacity = sum(thermal_df.capacity_mw)
```

## File Coverage

### Complete Coverage (2/32)
✅ **TERMDAT.DAT** - `ThermalSystem` (plants, units, heat curves)  
✅ **ENTDADOS.DAT** - `TimeDiscretization`, `PowerSystem` (partial), `HydroReservoir` (partial)

### High Priority (5 files) - Types Defined
✅ **HIDR.DAT** - `HydroPlant` (CADUSIH)  
✅ **OPERUH.DAT** - `HydroOperation`  
✅ **OPERUT.DAT** - `ThermalOperation` (expanded)  
✅ **DADVAZ.DAT** - `HydroSystem.natural_inflows`  
✅ **DEFLANT.DAT** - `HydroSystem.previous_outflows`

### Medium Priority (8 files) - Types Defined
✅ **RESPOT.DAT** - `PowerReserve`  
✅ **RENOVAVEIS.DAT** - `WindPlant`, `SolarPlant`  
✅ **DESSOPC.DAT** - `ExecutionOptions`  
✅ **AREACONT.DAT** - `PowerReserve`  
✅ **MLT.DAT** - Future (FPHA data)  
✅ **CURVTVIAG.DAT** - Future (TVIAG propagation)  
✅ **PTOPER.DAT** - Future (GNL operating point)  
✅ **INFOFCF.DAT** - `DecompCut` (partial)

### Lower Priority (7 files) - Types Defined
✅ **RAMPAS.DAT** - `RampConstraint`  
✅ **RSTLPP.DAT** - `LPPConstraint`  
✅ **RESTSEG.DAT** - `TableConstraint`  
✅ **RESPOTELE.DAT** - Network reserve (TBD)  
✅ **ILS_TRI.DAT** - Canal data (TBD)  
✅ **COTASR11.DAT** - R11 quotas (TBD)  
✅ **RMPFLX.DAT** - `FlowRampConstraint`

### Special Files
✅ **DESSELET.DAT** - `NetworkSystem` (buses, lines)  
✅ **MAPCUT.RV0** - Binary cut map (partial)  
✅ **CORTDECO.RV0** - `FCFCut` (binary format)  
✅ **INDICE.CSV** - LIBS index (TBD)

## Next Steps

1. **Parser Implementation**: Create parsers for each file type that populate these structures
2. **Validation**: Add validation functions to check data consistency
3. **Access Helpers**: Implement filtering and query functions
4. **DataFrame Export**: Add `to_dataframe()` methods for analysis
5. **Binary Parsers**: Implement MAPCUT.RV0 and CORTDECO.RV0 readers
6. **Documentation**: Add usage examples for each file type

## References

- **Architecture**: `docs/idessem_comparison.md`
- **File Formats**: `docs/file_formats.md`
- **DESSEM Specs**: `docs/dessem-complete-specs.md`
- **Implementation**: `src/models/core_types.jl`
- **Existing Parsers**: `src/parser/termdat.jl`, `src/parser/entdados.jl`
