"""
Core data types for DESSEM input files.

This module defines the complete type hierarchy for all DESSEM input files based on:
1. dessem.arq file structure (32 files)
2. idessem Python library architecture
3. Our existing TERMDAT and ENTDADOS parsers

Organization:
- Master file index types
- Hydro-related types
- Thermal-related types
- Network-related types
- Operational constraint types
- System configuration types
- Unified container types

Reference: docs/idessem_comparison.md
"""
module CoreTypes

using Dates

export DessemCase, FileRegistry
export HydroSystem, HydroPlant, HydroOperation, HydroReservoir
export ThermalSystem, ThermalPlant, ThermalUnit, ThermalOperation
export PowerSystem, Subsystem, LoadDemand, PowerReserve
export NetworkSystem, ElectricBus, TransmissionLine
export OperationalConstraints,
    RampConstraint, LPPConstraint, TableConstraint, FlowRampConstraint
export RmpflxRest, RmpflxLimi, RmpflxData
export ModifRecord, ModifData
export PtoperRecord, PtoperData
export MltRecord, MltData
export RenewableSystem, WindPlant, SolarPlant
export TimeDiscretization, TimePeriod
export CutInfo, FCFCut, DecompCut
export InfofcfRecord, InfofcfData
export MapcutRecord, MapcutData
export CortesRecord, CortesData
export MltRecord, MltData

# ============================================================================
# TIME DISCRETIZATION TYPES
# ============================================================================

"""
    TimePeriod

Represents a time discretization period in the DESSEM study.

Based on TM records from ENTDADOS.DAT.

# Fields
- `period_id::Int`: Sequential period identifier (1-based)
- `day::Int`: Calendar day number
- `hour::Int`: Hour (0-23)
- `half_hour::Int`: Half-hour flag (0 or 1)
- `duration::Float64`: Period duration in hours (≥ 0.5, default 1.0)
- `network_flag::Int`: Network modeling flag (0=no network, 1=network no losses, 2=network with losses)
- `load_level::String`: Load level name (e.g., "LEVE", "MEDIA", "PESADA")
"""
Base.@kwdef struct TimePeriod
    period_id::Int
    day::Int
    hour::Int
    half_hour::Int = 0
    duration::Float64 = 1.0
    network_flag::Int
    load_level::String = ""
end

"""
    TimeDiscretization

Container for all time period definitions in the study.

# Fields
- `periods::Vector{TimePeriod}`: All time periods in chronological order
- `num_periods::Int`: Total number of periods
- `total_hours::Float64`: Total study duration in hours
"""
Base.@kwdef struct TimeDiscretization
    periods::Vector{TimePeriod} = TimePeriod[]
    num_periods::Int = 0
    total_hours::Float64 = 0.0
end

# ============================================================================
# POWER SYSTEM TYPES (ENTDADOS.DAT - SIST, DP records)
# ============================================================================

"""
    Subsystem

Electrical subsystem definition (SIST records).

# Fields
- `number::Int`: Subsystem number (1-99)
- `code::String`: Subsystem mnemonic (2 characters, e.g., "SE", "S", "NE")
- `status::Int`: Status flag (default 0)
- `name::String`: Subsystem name (10 characters max)
"""
Base.@kwdef struct Subsystem
    number::Int
    code::String
    status::Int = 0
    name::String = ""
end

"""
    LoadDemand

Load demand data for a subsystem in a time period (DP records).

# Fields
- `subsystem::Int`: Subsystem number
- `start_day::Int`: Initial day
- `start_hour::Int`: Initial hour (0-23)
- `start_half::Int`: Initial half-hour (0 or 1)
- `end_day::Union{Int, String}`: Final day or "F" for final
- `end_hour::Int`: Final hour (0-23)
- `end_half::Int`: Final half-hour (0 or 1)
- `demand_mw::Float64`: Demand in MW (≥ 0)
"""
Base.@kwdef struct LoadDemand
    subsystem::Int
    start_day::Int
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String}
    end_hour::Int = 0
    end_half::Int = 0
    demand_mw::Float64
end

"""
    PowerReserve

Power reserve requirements (AREACONT.DAT, RESPOT.DAT).

# Fields
- `area_code::Int`: Reserve area code
- `area_name::String`: Reserve area name
- `subsystems::Vector{Int}`: Subsystems in this reserve area
- `reserve_requirement_mw::Float64`: Required reserve in MW
- `spinning_reserve_pct::Float64`: Spinning reserve as % of total
"""
Base.@kwdef struct PowerReserve
    area_code::Int
    area_name::String = ""
    subsystems::Vector{Int} = Int[]
    reserve_requirement_mw::Float64 = 0.0
    spinning_reserve_pct::Float64 = 0.0
end

"""
    PowerSystem

Complete power system configuration.

# Fields
- `subsystems::Vector{Subsystem}`: All subsystem definitions
- `demands::Vector{LoadDemand}`: All demand records
- `reserves::Vector{PowerReserve}`: Power reserve requirements
"""
Base.@kwdef struct PowerSystem
    subsystems::Vector{Subsystem} = Subsystem[]
    demands::Vector{LoadDemand} = LoadDemand[]
    reserves::Vector{PowerReserve} = PowerReserve[]
end

# ============================================================================
# HYDRO SYSTEM TYPES (ENTDADOS.DAT UH, HIDR.DAT, OPERUH.DAT, DEFLANT.DAT)
# ============================================================================

"""
    HydroReservoir

Hydroelectric reservoir characteristics (UH records, HIDR.DAT).

# Fields
- `plant_num::Int`: Plant number (1-320)
- `plant_name::String`: Plant name (12 characters max)
- `subsystem::Int`: Subsystem number
- `initial_volume_pct::Float64`: Initial volume as % useful (0-100)
- `volume_unit::Int`: Volume unit (1=hm³, 2=% useful)
- `min_volume::Union{Float64, Nothing}`: Minimum volume
- `max_volume::Union{Float64, Nothing}`: Maximum volume
- `initial_volume_abs::Union{Float64, Nothing}`: Initial volume (absolute)
- `spillway_crest::Union{Float64, Nothing}`: Spillway crest volume
- `diversion_crest::Union{Float64, Nothing}`: Diversion crest volume
- `storage_capacity_hm3::Union{Float64, Nothing}`: Storage capacity in hm³
- `useful_volume_hm3::Union{Float64, Nothing}`: Useful volume in hm³
"""
Base.@kwdef struct HydroReservoir
    plant_num::Int
    plant_name::String
    subsystem::Int
    initial_volume_pct::Float64
    volume_unit::Int = 2
    min_volume::Union{Float64,Nothing} = nothing
    max_volume::Union{Float64,Nothing} = nothing
    initial_volume_abs::Union{Float64,Nothing} = nothing
    spillway_crest::Union{Float64,Nothing} = nothing
    diversion_crest::Union{Float64,Nothing} = nothing
    storage_capacity_hm3::Union{Float64,Nothing} = nothing
    useful_volume_hm3::Union{Float64,Nothing} = nothing
end

"""
    HydroPlant

Hydroelectric plant characteristics (HIDR.DAT, CADUSIH).

# Fields
- `plant_num::Int`: Plant identification number
- `plant_name::String`: Plant name
- `subsystem::Int`: Subsystem number
- `status::Int`: Plant status (0=existing, 1=under construction)
- `installed_capacity_mw::Float64`: Total installed capacity in MW
- `num_units::Int`: Number of generating units
- `turbine_flow_m3s::Union{Float64, Nothing}`: Maximum turbine flow in m³/s
- `min_turbine_flow_m3s::Union{Float64, Nothing}`: Minimum turbine flow in m³/s
- `production_coefficient::Union{Float64, Nothing}`: Production coefficient
- `upstream_plant::Union{Int, Nothing}`: Upstream plant number
- `downstream_plant::Union{Int, Nothing}`: Downstream plant number
- `cascade_order::Union{Int, Nothing}`: Position in cascade
"""
Base.@kwdef struct HydroPlant
    plant_num::Int
    plant_name::String
    subsystem::Int
    status::Int = 0
    installed_capacity_mw::Float64
    num_units::Int = 1
    turbine_flow_m3s::Union{Float64,Nothing} = nothing
    min_turbine_flow_m3s::Union{Float64,Nothing} = nothing
    production_coefficient::Union{Float64,Nothing} = nothing
    upstream_plant::Union{Int,Nothing} = nothing
    downstream_plant::Union{Int,Nothing} = nothing
    cascade_order::Union{Int,Nothing} = nothing
end

"""
    HydroOperation

Hydraulic operational constraints (OPERUH.DAT).

# Fields
- `plant_num::Int`: Plant number
- `constraint_type::String`: Type of constraint (e.g., "VAZMIN", "VAZMAX", "VMINP")
- `period_start::Union{Int, Nothing}`: Start period
- `period_end::Union{Int, Nothing}`: End period
- `constraint_value::Float64`: Constraint value
- `unit::String`: Value unit (m³/s, MW, hm³, etc.)
"""
Base.@kwdef struct HydroOperation
    plant_num::Int
    constraint_type::String
    period_start::Union{Int,Nothing} = nothing
    period_end::Union{Int,Nothing} = nothing
    constraint_value::Float64
    unit::String = ""
end

"""
    HydroSystem

Complete hydroelectric system configuration.

# Fields
- `plants::Vector{HydroPlant}`: All hydro plant definitions
- `reservoirs::Vector{HydroReservoir}`: Reservoir configurations
- `operations::Vector{HydroOperation}`: Operational constraints
- `previous_outflows::Dict{Int, Vector{Float64}}`: Previous outflows (DEFLANT.DAT)
- `natural_inflows::Dict{Int, Vector{Float64}}`: Natural inflows (DADVAZ.DAT)
"""
Base.@kwdef struct HydroSystem
    plants::Vector{HydroPlant} = HydroPlant[]
    reservoirs::Vector{HydroReservoir} = HydroReservoir[]
    operations::Vector{HydroOperation} = HydroOperation[]
    previous_outflows::Dict{Int,Vector{Float64}} = Dict{Int,Vector{Float64}}()
    natural_inflows::Dict{Int,Vector{Float64}} = Dict{Int,Vector{Float64}}()
end

# ============================================================================
# THERMAL SYSTEM TYPES (TERMDAT.DAT, OPERUT.DAT, UT records)
# ============================================================================

"""
    ThermalPlant

Thermal plant registry (CADUSIT from TERMDAT.DAT).

# Fields
- `plant_num::Int`: Plant identification number (1-999)
- `plant_name::String`: Plant name (12 characters max)
- `subsystem::Int`: Subsystem number
- `commission_date::Union{Date, Nothing}`: Date of commissioning
- `plant_class::Int`: Plant class code
- `fuel_type::Int`: Fuel type code (1=gas, 2=coal, 3=oil, etc.)
- `num_units::Int`: Number of units (1-120)
- `heat_rate::Float64`: Heat rate in kJ/kWh
- `fuel_cost::Float64`: Fuel cost in BRL/unit
"""
Base.@kwdef struct ThermalPlant
    plant_num::Int
    plant_name::String
    subsystem::Int
    commission_date::Union{Date,Nothing} = nothing
    plant_class::Int = 0
    fuel_type::Int = 0
    num_units::Int
    heat_rate::Float64 = 0.0
    fuel_cost::Float64 = 0.0
end

"""
    ThermalUnit

Thermal generating unit characteristics (CADUNIDT from TERMDAT.DAT).

# Fields
- `plant_num::Int`: Plant number
- `unit_num::Int`: Unit number within plant (1-120)
- `unit_name::Union{String, Nothing}`: Unit name
- `commission_date::Union{Date, Nothing}`: Commission date
- `capacity_mw::Float64`: Unit capacity in MW
- `min_generation_mw::Float64`: Minimum generation in MW
- `min_on_time_h::Int`: Minimum on time in hours
- `min_off_time_h::Int`: Minimum off time in hours
- `cold_startup_cost::Float64`: Cold startup cost in BRL
- `hot_startup_cost::Float64`: Hot startup cost in BRL
- `shutdown_cost::Float64`: Shutdown cost in BRL
- `ramp_up_rate_mw_h::Float64`: Ramp up rate in MW/h
- `ramp_down_rate_mw_h::Float64`: Ramp down rate in MW/h
- `heat_curve_points::Vector{Tuple{Float64, Float64}}`: (generation_mw, heat_rate) pairs
"""
Base.@kwdef struct ThermalUnit
    plant_num::Int
    unit_num::Int
    unit_name::Union{String,Nothing} = nothing
    commission_date::Union{Date,Nothing} = nothing
    capacity_mw::Float64
    min_generation_mw::Float64 = 0.0
    min_on_time_h::Int = 0
    min_off_time_h::Int = 0
    cold_startup_cost::Float64 = 0.0
    hot_startup_cost::Float64 = 0.0
    shutdown_cost::Float64 = 0.0
    ramp_up_rate_mw_h::Float64 = Inf
    ramp_down_rate_mw_h::Float64 = Inf
    heat_curve_points::Vector{Tuple{Float64,Float64}} = Tuple{Float64,Float64}[]
end

"""
    ThermalOperation

Thermal unit operational configuration (UT records from ENTDADOS, OPERUT.DAT).

# Fields
- `plant_num::Int`: Plant number
- `unit_num::Union{Int, Nothing}`: Unit number (if specified)
- `start_day::Int`: Start day for operation
- `start_hour::Int`: Start hour (0-23)
- `start_half::Int`: Start half-hour (0 or 1)
- `end_day::Union{Int, String}`: End day or "F" for final
- `end_hour::Int`: End hour (0-23)
- `end_half::Int`: End half-hour (0 or 1)
- `min_generation_mw::Float64`: Minimum generation in MW
- `max_generation_mw::Float64`: Maximum generation/capacity in MW
- `must_run::Bool`: Must-run flag
- `inflexibility_type::Union{Int, Nothing}`: Inflexibility type code
"""
Base.@kwdef struct ThermalOperation
    plant_num::Int
    unit_num::Union{Int,Nothing} = nothing
    start_day::Int
    start_hour::Int
    start_half::Int
    end_day::Union{Int,String}
    end_hour::Int = 0
    end_half::Int = 0
    min_generation_mw::Float64 = 0.0
    max_generation_mw::Float64
    must_run::Bool = false
    inflexibility_type::Union{Int,Nothing} = nothing
end

"""
    ThermalSystem

Complete thermal generation system configuration.

# Fields
- `plants::Vector{ThermalPlant}`: All thermal plant definitions
- `units::Vector{ThermalUnit}`: All thermal unit definitions
- `operations::Vector{ThermalOperation}`: Operational configurations
"""
Base.@kwdef struct ThermalSystem
    plants::Vector{ThermalPlant} = ThermalPlant[]
    units::Vector{ThermalUnit} = ThermalUnit[]
    operations::Vector{ThermalOperation} = ThermalOperation[]
end

# ============================================================================
# RENEWABLE SYSTEM TYPES (RENOVAVEIS.DAT - EOLICA)
# ============================================================================

"""
    WindPlant

Wind power plant configuration (RENOVAVEIS.DAT).

# Fields
- `plant_num::Int`: Plant identification number
- `plant_name::String`: Plant name
- `subsystem::Int`: Subsystem number
- `installed_capacity_mw::Float64`: Installed capacity in MW
- `generation_forecast::Vector{Float64}`: Generation forecast by period (MW)
"""
Base.@kwdef struct WindPlant
    plant_num::Int
    plant_name::String
    subsystem::Int
    installed_capacity_mw::Float64
    generation_forecast::Vector{Float64} = Float64[]
end

"""
    SolarPlant

Solar power plant configuration (RENOVAVEIS.DAT).

# Fields
- `plant_num::Int`: Plant identification number
- `plant_name::String`: Plant name
- `subsystem::Int`: Subsystem number
- `installed_capacity_mw::Float64`: Installed capacity in MW
- `generation_forecast::Vector{Float64}`: Generation forecast by period (MW)
"""
Base.@kwdef struct SolarPlant
    plant_num::Int
    plant_name::String
    subsystem::Int
    installed_capacity_mw::Float64
    generation_forecast::Vector{Float64} = Float64[]
end

"""
    RenewableSystem

Renewable energy system configuration.

# Fields
- `wind_plants::Vector{WindPlant}`: All wind plants
- `solar_plants::Vector{SolarPlant}`: All solar plants
"""
Base.@kwdef struct RenewableSystem
    wind_plants::Vector{WindPlant} = WindPlant[]
    solar_plants::Vector{SolarPlant} = SolarPlant[]
end

# ============================================================================
# NETWORK TYPES (DESSELET.DAT - INDELET, RESPOTELE.DAT)
# ============================================================================

"""
    ElectricBus

Electrical bus in the network model (DESSELET.DAT).

# Fields
- `bus_num::Int`: Bus identification number
- `bus_name::String`: Bus name
- `subsystem::Int`: Subsystem number
- `voltage_kv::Float64`: Voltage level in kV
- `base_voltage_kv::Float64`: Base voltage in kV
"""
Base.@kwdef struct ElectricBus
    bus_num::Int
    bus_name::String = ""
    subsystem::Int
    voltage_kv::Float64
    base_voltage_kv::Float64 = 0.0
end

"""
    TransmissionLine

Transmission line in the network model (DESSELET.DAT).

# Fields
- `line_num::Int`: Line identification number
- `from_bus::Int`: Origin bus number
- `to_bus::Int`: Destination bus number
- `line_name::String`: Line name
- `resistance::Float64`: Resistance in p.u.
- `reactance::Float64`: Reactance in p.u.
- `susceptance::Float64`: Susceptance in p.u.
- `capacity_mw::Float64`: Line capacity in MW
- `num_circuits::Int`: Number of circuits
"""
Base.@kwdef struct TransmissionLine
    line_num::Int
    from_bus::Int
    to_bus::Int
    line_name::String = ""
    resistance::Float64
    reactance::Float64
    susceptance::Float64 = 0.0
    capacity_mw::Float64 = Inf
    num_circuits::Int = 1
end

"""
    NetworkSystem

Electrical network representation.

# Fields
- `buses::Vector{ElectricBus}`: All buses in the network
- `lines::Vector{TransmissionLine}`: All transmission lines
- `network_enabled::Bool`: Whether network modeling is enabled
- `include_losses::Bool`: Whether to model transmission losses
"""
Base.@kwdef struct NetworkSystem
    buses::Vector{ElectricBus} = ElectricBus[]
    lines::Vector{TransmissionLine} = TransmissionLine[]
    network_enabled::Bool = false
    include_losses::Bool = false
end

# ============================================================================
# OPERATIONAL CONSTRAINTS (RAMPAS.DAT, RSTLPP.DAT, RESTSEG.DAT, RMPFLX.DAT)
# ============================================================================

"""
    RampConstraint

Trajectory/ramp constraints for generation units (RAMPAS.DAT).

# Fields
- `unit_type::String`: Unit type ("H" for hydro, "T" for thermal)
- `unit_num::Int`: Unit identification number
- `period::Int`: Time period
- `min_generation_mw::Float64`: Minimum generation in MW
- `max_generation_mw::Float64`: Maximum generation in MW
- `target_generation_mw::Union{Float64, Nothing}`: Target generation in MW
"""
Base.@kwdef struct RampConstraint
    unit_type::String
    unit_num::Int
    period::Int
    min_generation_mw::Float64
    max_generation_mw::Float64
    target_generation_mw::Union{Float64,Nothing} = nothing
end

"""
    LPPConstraint

Linear piecewise constraints (RSTLPP.DAT).

# Fields
- `constraint_id::Int`: Constraint identification
- `constraint_name::String`: Constraint name
- `period::Int`: Time period (0 for all?)
- `segment::Int`: Segment number
- `sense::String`: Constraint sense ("<=", ">=", "=")
- `rhs::Float64`: Right-hand side value (Linear Coefficient)
- `coefficients::Dict{Tuple{String, Int}, Float64}`: (unit_type, unit_num) => coefficient
"""
Base.@kwdef struct LPPConstraint
    constraint_id::Int
    constraint_name::String = ""
    period::Int = 0
    segment::Int = 0
    sense::String = "<="
    rhs::Float64
    coefficients::Dict{Tuple{String,Int},Float64} = Dict{Tuple{String,Int},Float64}()
end

"""
    TableConstraint

Table-based constraints (RESTSEG.DAT).

# Fields
- `table_id::Int`: Table identification
- `table_name::String`: Table name
- `num_dimensions::Int`: Number of dimensions
- `dimension_vars::Vector{String}`: Variable names for each dimension
- `constraint_points::Vector{Vector{Float64}}`: Constraint boundary points
"""
Base.@kwdef struct TableConstraint
    table_id::Int
    table_name::String = ""
    num_dimensions::Int
    dimension_vars::Vector{String} = String[]
    constraint_points::Vector{Vector{Float64}} = Vector{Float64}[]
end

"""
    FlowRampConstraint

Flow ramp constraints for transmission (RMPFLX.DAT).

# Fields
- `line_num::Int`: Transmission line number
- `max_increase_mw::Float64`: Maximum flow increase per period (MW)
- `max_decrease_mw::Float64`: Maximum flow decrease per period (MW)
"""
Base.@kwdef struct FlowRampConstraint
    line_num::Int
    max_increase_mw::Float64
    max_decrease_mw::Float64
end

"""
    RmpflxRest

Initial condition or reference value for flow ramp constraint (RMPFLX.DAT).

# Fields
- `constraint_id::Int`: Constraint identifier (DREF)
- `initial_value::Float64`: Initial value or reference value
- `status::Union{Int, Nothing}`: Optional status flag
"""
Base.@kwdef struct RmpflxRest
    constraint_id::Int
    initial_value::Float64
    status::Union{Int,Nothing} = nothing
end

"""
    RmpflxLimi

Flow ramp limit definition (RMPFLX.DAT).

# Fields
- `constraint_id::Int`: Constraint identifier (DREF)
- `start_day::Union{Int, String}`: Start day or "I"
- `start_hour::Int`: Start hour (0-23)
- `start_half::Int`: Start half-hour (0 or 1)
- `end_day::Union{Int, String}`: End day or "F"
- `end_hour::Int`: End hour (0-23)
- `end_half::Int`: End half-hour (0 or 1)
- `ramp_down::Float64`: Maximum ramp down (decrease)
- `ramp_up::Float64`: Maximum ramp up (increase)
- `status::Union{Int, Nothing}`: Optional status flag
"""
Base.@kwdef struct RmpflxLimi
    constraint_id::Int
    start_day::Union{Int,String}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String}
    end_hour::Int = 0
    end_half::Int = 0
    ramp_down::Float64
    ramp_up::Float64
    status::Union{Int,Nothing} = nothing
end

"""
    RmpflxData

Container for RMPFLX.DAT data (flow ramp constraints).

# Fields
- `rest_records::Vector{RmpflxRest}`: Initial conditions
- `limi_records::Vector{RmpflxLimi}`: Limit definitions
"""
Base.@kwdef struct RmpflxData
    rest_records::Vector{RmpflxRest} = RmpflxRest[]
    limi_records::Vector{RmpflxLimi} = RmpflxLimi[]
end

# ============================================================================
# OPERATING POINT TYPES (PTOPER.DAT)
# ============================================================================

"""
    PtoperRecord

Operating point record (PTOPER.DAT).

# Fields
- `mnemonic::String`: Record mnemonic ("PTOPER")
- `element_type::String`: Element type (e.g., "USIT")
- `element_id::Int`: Element identification number
- `variable::String`: Variable name (e.g., "GERA")
- `start_day::Union{Int, String}`: Start day or "I"
- `start_hour::Int`: Start hour (0-23)
- `start_half::Int`: Start half-hour (0 or 1)
- `end_day::Union{Int, String}`: End day or "F"
- `end_hour::Int`: End hour (0-23)
- `end_half::Int`: End half-hour (0 or 1)
- `value::Float64`: Operating point value
"""
Base.@kwdef struct PtoperRecord
    mnemonic::String = "PTOPER"
    element_type::String
    element_id::Int
    variable::String
    start_day::Union{Int,String}
    start_hour::Int
    start_half::Int
    end_day::Union{Int,String}
    end_hour::Int
    end_half::Int
    value::Float64
end

"""
    PtoperData

Container for PTOPER.DAT data.

# Fields
- `records::Vector{PtoperRecord}`: List of operating point records
"""
Base.@kwdef struct PtoperData
    records::Vector{PtoperRecord} = PtoperRecord[]
end

"""
    OperationalConstraints

All operational constraints for the study.

# Fields
- `ramp_constraints::Vector{RampConstraint}`: Trajectory constraints
- `lpp_constraints::Vector{LPPConstraint}`: Linear piecewise constraints
- `table_constraints::Vector{TableConstraint}`: Table-based constraints
- `flow_ramps::Vector{FlowRampConstraint}`: Transmission flow ramps
"""
Base.@kwdef struct OperationalConstraints
    ramp_constraints::Vector{RampConstraint} = RampConstraint[]
    lpp_constraints::Vector{LPPConstraint} = LPPConstraint[]
    table_constraints::Vector{TableConstraint} = TableConstraint[]
    flow_ramps::Vector{FlowRampConstraint} = FlowRampConstraint[]
end

# ============================================================================
# DECOMP INTERFACE TYPES (MAPCUT.RV0, CORTDECO.RV0, INFOFCF.DAT)
# ============================================================================

"""
    InfofcfRecord

Record from INFOFCF.DEC (Binary).
Placeholder for now.
"""
struct InfofcfRecord
    # TODO: Define fields based on binary spec
    raw_data::Vector{UInt8}
end

"""
    InfofcfData

Container for INFOFCF.DEC data.
"""
Base.@kwdef struct InfofcfData
    records::Vector{InfofcfRecord} = InfofcfRecord[]
end

"""
    MapcutRecord

Record from MAPCUT.DEC (Binary).
Placeholder for now.
"""
struct MapcutRecord
    # TODO: Define fields based on binary spec
    raw_data::Vector{UInt8}
end

"""
    MapcutData

Container for MAPCUT.DEC data.
"""
Base.@kwdef struct MapcutData
    records::Vector{MapcutRecord} = MapcutRecord[]
end

"""
    CortesRecord

Record from CORTES.DEC (Binary).
Placeholder for now.
"""
struct CortesRecord
    # TODO: Define fields based on binary spec
    raw_data::Vector{UInt8}
end

"""
    CortesData

Container for CORTES.DEC data.
"""
Base.@kwdef struct CortesData
    records::Vector{CortesRecord} = CortesRecord[]
end

"""
    FCFCut

Future cost function cut from DECOMP (CORTDECO.RV0).

# Fields
- `cut_id::Int`: Cut identification number
- `stage::Int`: Stage number
- `scenario::Int`: Scenario number
- `intercept::Float64`: Cut intercept value
- `coefficients::Dict{Int, Float64}`: Subsystem => coefficient mapping
"""
Base.@kwdef struct FCFCut
    cut_id::Int
    stage::Int
    scenario::Int
    intercept::Float64
    coefficients::Dict{Int,Float64} = Dict{Int,Float64}()
end

"""
    DecompCut

DECOMP cut information.

# Fields
- `cuts::Vector{FCFCut}`: All FCF cuts
- `cut_map::Union{String, Nothing}`: Cut map file path (MAPCUT.RV0)
- `cut_info::Union{String, Nothing}`: Cut information file path (INFOFCF.DAT)
"""
Base.@kwdef struct DecompCut
    cuts::Vector{FCFCut} = FCFCut[]
    cut_map::Union{String,Nothing} = nothing
    cut_info::Union{String,Nothing} = nothing
end

# ============================================================================
# SYSTEM CONFIGURATION (DESSOPC.DAT, MLT.DAT, CURVTVIAG.DAT, COTASR11.DAT, etc.)
# ============================================================================

"""
    MltRecord

Record from MLT.DAT (FPHA).
Placeholder for now.
"""
Base.@kwdef struct MltRecord
    # TODO: Define fields based on MLT spec
    raw_line::String = ""
end

"""
    MltData

Container for MLT.DAT data.
"""
Base.@kwdef struct MltData
    records::Vector{MltRecord} = MltRecord[]
end

"""
    ExecutionOptions

DESSEM execution configuration (DESSOPC.DAT).

# Fields
- `solver::String`: Optimization solver to use
- `max_iterations::Int`: Maximum solver iterations
- `convergence_tolerance::Float64`: Convergence tolerance
- `output_level::Int`: Output detail level (0-3)
- `enable_network::Bool`: Enable network modeling
- `enable_losses::Bool`: Enable loss modeling
- `enable_security::Bool`: Enable security constraints
- `parallel_threads::Int`: Number of parallel threads
"""
Base.@kwdef struct ExecutionOptions
    solver::String = "CPLEX"
    max_iterations::Int = 1000
    convergence_tolerance::Float64 = 1e-4
    output_level::Int = 1
    enable_network::Bool = false
    enable_losses::Bool = false
    enable_security::Bool = false
    parallel_threads::Int = 1
end

# ============================================================================
# FILE REGISTRY TYPE (from dessem.arq)
# ============================================================================

"""
    FileRegistry

Registry of all input files for a DESSEM case (from dessem.arq).

This is the parsed representation of the dessem.arq master index file.

# Fields
All fields are optional (Union{String, Nothing}) as files may not be present:
- `caso::Union{String, Nothing}`: Case name file
- `titulo::Union{String, Nothing}`: Study title
- `vazoes::Union{String, Nothing}`: Natural flows (DADVAZ.DAT)
- `dadger::Union{String, Nothing}`: General data (ENTDADOS.DAT)
- `mapfcf::Union{String, Nothing}`: DECOMP cuts map (MAPCUT.RV0)
- `cortfcf::Union{String, Nothing}`: DECOMP cuts (CORTDECO.RV0)
- `cadusih::Union{String, Nothing}`: Hydro plant registry (HIDR.DAT)
- `operuh::Union{String, Nothing}`: Hydro operations (OPERUH.DAT)
- `deflant::Union{String, Nothing}`: Previous outflows (DEFLANT.DAT)
- `cadterm::Union{String, Nothing}`: Thermal registry (TERMDAT.DAT)
- `operut::Union{String, Nothing}`: Thermal operations (OPERUT.DAT)
- `indelet::Union{String, Nothing}`: Network index (DESSELET.DAT)
- `ilstri::Union{String, Nothing}`: Pereira Barreto canal (ILS_TRI.DAT)
- `cotasr11::Union{String, Nothing}`: R11 previous levels (COTASR11.DAT)
- `simul::Union{String, Nothing}`: Simulation data
- `areacont::Union{String, Nothing}`: Power reserve registry (AREACONT.DAT)
- `respot::Union{String, Nothing}`: Power reserve study (RESPOT.DAT)
- `mlt::Union{String, Nothing}`: FPHA data (MLT.DAT)
- `tolperd::Union{String, Nothing}`: Loss tolerances
- `curvtviag::Union{String, Nothing}`: TVIAG propagation curve (CURVTVIAG.DAT)
- `ptoper::Union{String, Nothing}`: GNL operating point (PTOPER.DAT)
- `infofcf::Union{String, Nothing}`: FCF cuts information (INFOFCF.DAT)
- `meta::Union{String, Nothing}`: Goal restrictions (METAS.DAT)
- `ree::Union{String, Nothing}`: Equivalent reservoirs (usually ENTDADOS.DAT)
- `eolica::Union{String, Nothing}`: Wind plants (RENOVAVEIS.DAT)
- `rampas::Union{String, Nothing}`: Trajectory file (RAMPAS.DAT)
- `rstlpp::Union{String, Nothing}`: LPP restrictions (RSTLPP.DAT)
- `restseg::Union{String, Nothing}`: Table restrictions (RESTSEG.DAT)
- `respotele::Union{String, Nothing}`: Network power reserve (RESPOTELE.DAT)
- `ilibs::Union{String, Nothing}`: LIBS functionalities (INDICE.CSV)
- `dessopc::Union{String, Nothing}`: Execution options (DESSOPC.DAT)
- `rmpflx::Union{String, Nothing}`: Flow ramp (RMPFLX.DAT)

Reference: src/parser/dessemarq.jl
"""
Base.@kwdef struct FileRegistry
    caso::Union{String,Nothing} = nothing
    titulo::Union{String,Nothing} = nothing
    vazoes::Union{String,Nothing} = nothing
    dadger::Union{String,Nothing} = nothing
    mapfcf::Union{String,Nothing} = nothing
    cortfcf::Union{String,Nothing} = nothing
    cadusih::Union{String,Nothing} = nothing
    operuh::Union{String,Nothing} = nothing
    deflant::Union{String,Nothing} = nothing
    cadterm::Union{String,Nothing} = nothing
    operut::Union{String,Nothing} = nothing
    indelet::Union{String,Nothing} = nothing
    ilstri::Union{String,Nothing} = nothing
    cotasr11::Union{String,Nothing} = nothing
    simul::Union{String,Nothing} = nothing
    areacont::Union{String,Nothing} = nothing
    respot::Union{String,Nothing} = nothing
    mlt::Union{String,Nothing} = nothing
    tolperd::Union{String,Nothing} = nothing
    curvtviag::Union{String,Nothing} = nothing
    ptoper::Union{String,Nothing} = nothing
    infofcf::Union{String,Nothing} = nothing
    meta::Union{String,Nothing} = nothing
    ree::Union{String,Nothing} = nothing
    eolica::Union{String,Nothing} = nothing
    rampas::Union{String,Nothing} = nothing
    rstlpp::Union{String,Nothing} = nothing
    restseg::Union{String,Nothing} = nothing
    respotele::Union{String,Nothing} = nothing
    ilibs::Union{String,Nothing} = nothing
    dessopc::Union{String,Nothing} = nothing
    rmpflx::Union{String,Nothing} = nothing
end

# ============================================================================
# MODIFICATIONS (MODIF.DAT)
# ============================================================================

"""
    ModifRecord

Modification record (MODIF.DAT).

# Fields
- `line::String`: Raw line content (placeholder until format is known)
"""
Base.@kwdef struct ModifRecord
    line::String
end

"""
    ModifData

Container for MODIF.DAT data.

# Fields
- `records::Vector{ModifRecord}`: List of modification records
"""
Base.@kwdef struct ModifData
    records::Vector{ModifRecord} = ModifRecord[]
end

# ============================================================================
# UNIFIED CONTAINER TYPE
# ============================================================================

"""
    DessemCase

Complete DESSEM case data - unified container for all input data.

This is the top-level structure that holds all parsed DESSEM input files
organized by functional subsystem.

# Fields
- `case_name::String`: Case identification name
- `case_title::String`: Study title/description
- `base_directory::String`: Base directory for input files
- `file_registry::FileRegistry`: Master file index (from dessem.arq)
- `time_discretization::TimeDiscretization`: Time period definitions
- `power_system::PowerSystem`: Electrical system configuration
- `hydro_system::HydroSystem`: Hydroelectric generation system
- `thermal_system::ThermalSystem`: Thermal generation system
- `renewable_system::RenewableSystem`: Renewable generation system
- `network_system::NetworkSystem`: Transmission network model
- `operational_constraints::OperationalConstraints`: All operational constraints
- `decomp_cuts::DecompCut`: Future cost function cuts from DECOMP
- `execution_options::ExecutionOptions`: DESSEM execution configuration
- `metadata::Dict{String, Any}`: Additional metadata (parse time, version, etc.)

# Example
```julia
case = DessemCase(
    case_name="PMO_OCT2025",
    case_title="PMO - OUTUBRO/25 - REV 0",
    base_directory="/path/to/case",
    file_registry=parse_dessemarq("dessem.arq"),
    # ... other fields populated by parsers
)

# Access data
num_periods = case.time_discretization.num_periods
thermal_plants = case.thermal_system.plants
hydro_ops = case.hydro_system.operations
```
"""
Base.@kwdef struct DessemCase
    case_name::String = ""
    case_title::String = ""
    base_directory::String = ""
    file_registry::FileRegistry = FileRegistry()
    time_discretization::TimeDiscretization = TimeDiscretization()
    power_system::PowerSystem = PowerSystem()
    hydro_system::HydroSystem = HydroSystem()
    thermal_system::ThermalSystem = ThermalSystem()
    renewable_system::RenewableSystem = RenewableSystem()
    network_system::NetworkSystem = NetworkSystem()
    operational_constraints::OperationalConstraints = OperationalConstraints()
    decomp_cuts::DecompCut = DecompCut()
    execution_options::ExecutionOptions = ExecutionOptions()
    metadata::Dict{String,Any} = Dict{String,Any}()
end

end # module
