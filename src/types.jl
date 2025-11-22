module Types

using Dates

# ============================================================================
# Execution Options (DESSOPC.DAT) Types
# ============================================================================

"""
    DessOpcData

Execution options and solver configuration for DESSEM (DESSOPC.DAT).

# IDESSEM Reference
idessem/dessem/modelos/dessopc.py
idessem/dessem/dessopc.py

# Fields

## Parallel Processing
- `uctpar::Union{Int, Nothing}`: Number of threads for parallel processing

## Solution Methodology
- `ucterm::Union{Int, Nothing}`: Methodology for network inclusion and UCT (0-2)
- `pint::Bool`: Enable interior points methodology
- `uctbusloc::Bool`: Enable local search
- `uctheurfp::Union{Vector{Int}, Nothing}`: Feasibility Pump with local search parameters
- `uctesperto::Union{Int, Nothing}`: UCT expert mode flag

## Hydro Production Function
- `regranptv::Union{Vector{Int}, Nothing}`: Default values for hydraulic production function

## Output Control
- `avlcmo::Union{Int, Nothing}`: Print CMO evaluation files (0=no, 1=yes)
- `cplexlog::Bool`: Enable CPLEX solver log file

## Data Consistency
- `constdados::Union{Vector{Int}, Nothing}`: Data consistency checks [verification, correction]

## Future Cost Function
- `ajustefcf::Union{Vector{Int}, Nothing}`: FCF adjustment parameters

## Thermal Generation
- `trata_term_ton::Bool`: Handle thermal TON (minimum time on) constraints

## Network Constraints
- `tolerilh::Union{Int, Nothing}`: Island tolerance parameter
- `engolimento::Union{Int, Nothing}`: Consider maximum engulfment
- `trata_inviab_ilha::Union{Int, Nothing}`: Handle island infeasibility

## Crossover
- `crossover::Union{Vector{Int}, Nothing}`: Crossover after interior points [params...]

## Other Options
- `other_options::Dict{String, Any}`: Storage for unknown/future keywords
"""
Base.@kwdef mutable struct DessOpcData
    # Parallel processing
    uctpar::Union{Int,Nothing} = nothing

    # Solution methodology
    ucterm::Union{Int,Nothing} = nothing
    pint::Bool = false
    uctbusloc::Bool = false
    uctheurfp::Union{Vector{Int},Nothing} = nothing
    uctesperto::Union{Int,Nothing} = nothing

    # Hydro production
    regranptv::Union{Vector{Int},Nothing} = nothing

    # Output control
    avlcmo::Union{Int,Nothing} = nothing
    cplexlog::Bool = false

    # Data consistency
    constdados::Union{Vector{Int},Nothing} = nothing

    # Future cost function
    ajustefcf::Union{Vector{Int},Nothing} = nothing

    # Thermal generation
    trata_term_ton::Bool = false

    # Network constraints
    tolerilh::Union{Int,Nothing} = nothing
    engolimento::Union{Int,Nothing} = nothing
    trata_inviab_ilha::Union{Int,Nothing} = nothing

    # Crossover
    crossover::Union{Vector{Int},Nothing} = nothing

    # Extensibility
    other_options::Dict{String,Any} = Dict{String,Any}()
end

# ============================================================================
# Simulation Data (SIMUL.XXX) Types
# ============================================================================

"""
    SimulHeader

Header record from SIMUL.XXX containing simulation start date/time.

# Fields
- `start_day::Int`: Start day (calendar day)
- `start_hour::Int`: Start hour (0-23, default 0)
- `start_half_hour::Int`: Start half-hour flag (0 or 1, default 0)
- `start_month::Int`: Start month (1-12)
- `start_year::Int`: Start year
- `operuh_flag::Union{Int, Nothing}`: OPERUH constraints flag (0=exclude, 1=include)
"""
Base.@kwdef struct SimulHeader
    start_day::Int
    start_hour::Int = 0
    start_half_hour::Int = 0
    start_month::Int
    start_year::Int
    operuh_flag::Union{Int,Nothing} = nothing
end

"""
    DiscRecord

Time discretization record from DISC block in SIMUL.XXX.

# Fields
- `day::Int`: Day number (calendar day)
- `hour::Int`: Hour (0-23, default 0)
- `half_hour::Int`: Half-hour flag (0 or 1, default 0)
- `duration::Float64`: Period duration (hours)
- `constraints_flag::Union{Int, Nothing}`: Period constraints flag (0=exclude, 1=include)
"""
Base.@kwdef struct DiscRecord
    day::Int
    hour::Int = 0
    half_hour::Int = 0
    duration::Float64
    constraints_flag::Union{Int,Nothing} = nothing
end

"""
    VoliRecord

Initial reservoir volume record from VOLI block in SIMUL.XXX.

# Fields
- `plant_number::Int`: Plant number (per hydro registry)
- `plant_name::String`: Plant name (reference only)
- `initial_volume_percent::Float64`: Initial volume (% of useful volume, 0-100)
"""
Base.@kwdef struct VoliRecord
    plant_number::Int
    plant_name::String
    initial_volume_percent::Float64
end

"""
    OperRecord

Simulation operation data record from OPER block in SIMUL.XXX.

# Fields
- `plant_number::Int`: Plant number (per registry)
- `plant_type::String`: Plant type ("H"=hydro, "E"=pumping, default "H")
- `plant_name::String`: Plant name (reference only)
- `initial_day::Int`: Initial day (calendar day)
- `initial_hour::Int`: Initial hour (0-23, default 0)
- `initial_half_hour::Int`: Initial half-hour (0 or 1, default 0)
- `final_day::Int`: Final day (calendar day)
- `final_hour::Int`: Final hour (0-23, default 0)
- `final_half_hour::Int`: Final half-hour (0 or 1, default 0)
- `flow_type::Int`: Natural flow type (1=incremental, 2=total)
- `natural_inflow::Float64`: Natural inflow (m³/s)
- `withdrawal_type::Union{Int, Nothing}`: Withdrawal type (1=incremental, 2=total)
- `withdrawal_flow::Float64`: Withdrawal flow (m³/s, default 0.0)
- `generation_target::Union{Float64, Nothing}`: Generation target (MW)
"""
Base.@kwdef struct OperRecord
    plant_number::Int
    plant_type::String = "H"
    plant_name::String
    initial_day::Int
    initial_hour::Int = 0
    initial_half_hour::Int = 0
    final_day::Int
    final_hour::Int = 0
    final_half_hour::Int = 0
    flow_type::Int
    natural_inflow::Float64
    withdrawal_type::Union{Int,Nothing} = nothing
    withdrawal_flow::Float64 = 0.0
    generation_target::Union{Float64,Nothing} = nothing
end

"""
    SimulData

Container for SIMUL.XXX simulation data.

# Fields
- `header::SimulHeader`: Simulation start date/time and OPERUH flag
- `disc_records::Vector{DiscRecord}`: Time discretization periods
- `voli_records::Vector{VoliRecord}`: Initial reservoir volumes
- `oper_records::Vector{OperRecord}`: Simulation operation data
"""
Base.@kwdef struct SimulData
    header::SimulHeader
    disc_records::Vector{DiscRecord} = DiscRecord[]
    voli_records::Vector{VoliRecord} = VoliRecord[]
    oper_records::Vector{OperRecord} = OperRecord[]
end

# ============================================================================
# Control Areas (AREACONT.DAT) Types
# ============================================================================

"""
    AreaRecord

Area definition record from AREACONT.DAT.

# Fields
- `codigo_area::Int`: Area code
- `nome_area::String`: Area name
"""
Base.@kwdef struct AreaRecord
    codigo_area::Int
    nome_area::String
end

"""
    UsinaRecord

Plant/component in control area from AREACONT.DAT.

# Fields
- `codigo_area::Int`: Area code
- `tipo_componente::String`: Component type (H=hydro, T=thermal, etc.)
- `codigo_componente::Int`: Component code
- `nome_componente::String`: Component name
"""
Base.@kwdef struct UsinaRecord
    codigo_area::Int
    tipo_componente::String
    codigo_componente::Int
    nome_componente::String
end

"""
    AreaContData

Container for AREACONT.DAT data (control areas for power reserve).

# Fields
- `areas::Vector{AreaRecord}`: Area definitions
- `usinas::Vector{UsinaRecord}`: Plants/components in each area
"""
Base.@kwdef struct AreaContData
    areas::Vector{AreaRecord} = AreaRecord[]
    usinas::Vector{UsinaRecord} = UsinaRecord[]
end

# ============================================================================
# Itaipu R11 Gauge (COTASR11.DAT) Types
# ============================================================================

"""
    CotaR11Record

Itaipu R11 gauge level record from COTASR11.DAT.

# Fields
- `dia::Int`: Day
- `hora::Int`: Hour (0-23)
- `meia_hora::Int`: Half-hour (0 or 1)
- `cota::Float64`: Water level at R11 gauge (meters)
"""
Base.@kwdef struct CotaR11Record
    dia::Int
    hora::Int
    meia_hora::Int
    cota::Float64
end

"""
    CotasR11Data

Container for COTASR11.DAT data (historical R11 gauge levels before study).

# Fields
- `records::Vector{CotaR11Record}`: R11 gauge level records
"""
Base.@kwdef struct CotasR11Data
    records::Vector{CotaR11Record} = CotaR11Record[]
end

# ============================================================================
# Travel Time Curves (CURVTVIAG.DAT) Types
# ============================================================================

"""
    CurvTviagRecord

Travel time propagation curve record from CURVTVIAG.DAT.

# Fields
- `codigo_usina_montante::Int`: Upstream plant code
- `codigo_elemento_jusante::Int`: Downstream element code
- `tipo_elemento_jusante::String`: Downstream element type (S=section, H=plant)
- `hora::Int`: Hour in propagation curve
- `percentual_acumulado::Int`: Accumulated percentage (0-100)
"""
Base.@kwdef struct CurvTviagRecord
    codigo_usina_montante::Int
    codigo_elemento_jusante::Int
    tipo_elemento_jusante::String
    hora::Int
    percentual_acumulado::Int
end

"""
    CurvTviagData

Container for CURVTVIAG.DAT data (travel time propagation curves).

# Fields
- `records::Vector{CurvTviagRecord}`: Travel time curve records
"""
Base.@kwdef struct CurvTviagData
    records::Vector{CurvTviagRecord} = CurvTviagRecord[]
end

# ============================================================================
# Thermal Plant Registry (TERMDAT.DAT) Types
# ============================================================================

"""
    CADUSIT

Thermal plant information record from TERM.DAT.

# Fields
- `plant_num::Int`: Plant identification number (1-999)
- `plant_name::String`: Plant name (12 characters max)
- `subsystem::Int`: Subsystem number per SIST records
- `commission_year::Union{Int, Nothing}`: Year of commissioning (4 digits)
- `commission_month::Union{Int, Nothing}`: Month of commissioning (1-12)
- `commission_day::Union{Int, Nothing}`: Day of commissioning (1-31)
- `plant_class::Int`: Plant class code (default 0)
- `fuel_type::Int`: Fuel type code (default 0)
- `num_units::Int`: Number of units in plant (1-120)
- `heat_rate::Float64`: Heat rate in kJ/kWh (default 0.0)
- `fuel_cost::Float64`: Fuel cost in BRL/unit (default 0.0)
"""
Base.@kwdef struct CADUSIT
    plant_num::Int
    plant_name::String
    subsystem::Int
    commission_year::Union{Int,Nothing} = nothing
    commission_month::Union{Int,Nothing} = nothing
    commission_day::Union{Int,Nothing} = nothing
    plant_class::Int = 0
    fuel_type::Int = 0
    num_units::Int
    heat_rate::Float64 = 0.0
    fuel_cost::Float64 = 0.0
end

"""
    CADUNIDT

Thermal unit characteristics record from TERM.DAT.

# Fields
- `plant_num::Int`: Plant number per registry
- `unit_num::Int`: Unit number within plant (1-120)
- `unit_name::Union{String, Nothing}`: Unit name (10 characters max)
- `commission_year::Union{Int, Nothing}`: Commission year (2 digits)
- `commission_month::Union{Int, Nothing}`: Commission month (1-12)
- `unit_capacity::Float64`: Unit capacity in MW (> 0)
- `min_generation::Float64`: Minimum generation in MW (≥ 0, default 0.0)
- `min_on_time::Int`: Minimum on time in hours (≥ 0, default 0)
- `min_off_time::Int`: Minimum off time in hours (≥ 0, default 0)
- `cold_startup_cost::Float64`: Cold startup cost in BRL (≥ 0, default 0.0)
- `hot_startup_cost::Float64`: Hot startup cost in BRL (≥ 0, default 0.0)
- `shutdown_cost::Float64`: Shutdown cost in BRL (≥ 0, default 0.0)
- `ramp_up_rate::Float64`: Ramp up rate in MW/h (≥ 0, default Inf)
- `ramp_down_rate::Float64`: Ramp down rate in MW/h (≥ 0, default Inf)
"""
Base.@kwdef struct CADUNIDT
    plant_num::Int
    unit_num::Int
    unit_name::Union{String,Nothing} = nothing
    commission_year::Union{Int,Nothing} = nothing
    commission_month::Union{Int,Nothing} = nothing
    unit_capacity::Float64
    min_generation::Float64 = 0.0
    min_on_time::Int = 0
    min_off_time::Int = 0
    cold_startup_cost::Float64 = 0.0
    hot_startup_cost::Float64 = 0.0
    shutdown_cost::Float64 = 0.0
    ramp_up_rate::Float64 = Inf
    ramp_down_rate::Float64 = Inf
end

"""
    CURVACOMB

Heat rate curve point record from TERM.DAT.

# Fields
- `plant_num::Int`: Plant number per registry
- `unit_num::Int`: Unit number per plant
- `heat_rate::Int`: Heat rate at this generation point (kJ/kWh, > 0)
- `generation::Float64`: Generation point in MW (0 to unit capacity)
"""
Base.@kwdef struct CURVACOMB
    plant_num::Int
    unit_num::Int
    heat_rate::Int
    generation::Float64
end

"""
    CADCONF

Combined-cycle configuration record from TERM.DAT.

# Fields
- `plant_num::Int`: Thermal plant identifier (per CADUSIT)
- `configuration::Int`: Equivalent configuration identifier
- `unit_num::Int`: Unit that belongs to the configuration
"""
Base.@kwdef struct CADCONF
    plant_num::Int
    configuration::Int
    unit_num::Int
end

"""
    CADMIN

Simple-cycle dependent configuration record from TERM.DAT.

# Fields
- `plant_num::Int`: Thermal plant identifier (per CADUSIT)
- `configuration::Int`: Equivalent configuration identifier
- `unit_num::Int`: Unit that belongs to the configuration
"""
Base.@kwdef struct CADMIN
    plant_num::Int
    configuration::Int
    unit_num::Int
end

"""
    ThermalRegistry

Container for all thermal plant registry data from TERM.DAT.

# Fields
- `plants::Vector{CADUSIT}`: All CADUSIT plant records
- `units::Vector{CADUNIDT}`: All CADUNIDT unit records
- `heat_curves::Vector{CURVACOMB}`: All CURVACOMB heat rate curve points
- `combined_cycle_configs::Vector{CADCONF}`: Combined-cycle configuration memberships
- `simple_cycle_configs::Vector{CADMIN}`: Simple-cycle configuration memberships
"""
Base.@kwdef struct ThermalRegistry
    plants::Vector{CADUSIT} = CADUSIT[]
    units::Vector{CADUNIDT} = CADUNIDT[]
    heat_curves::Vector{CURVACOMB} = CURVACOMB[]
    combined_cycle_configs::Vector{CADCONF} = CADCONF[]
    simple_cycle_configs::Vector{CADMIN} = CADMIN[]
end

# ============================================================================
# General Data File (ENTDADOS.XXX) Types
# ============================================================================

"""
    TMRecord

Time discretization record from ENTDADOS.XXX.

# Fields
- `day::Int`: Calendar day number
- `hour::Int`: Hour (0-23)
- `half_hour::Int`: Half-hour flag (0 or 1)
- `duration::Float64`: Period duration in hours (≥ 0.5, default 1.0)
- `network_flag::Int`: Network modeling flag (0=no network, 1=network no losses, 2=network with losses)
- `load_level::String`: Load level name (e.g., "LEVE", "MEDIA", "PESADA")
"""
Base.@kwdef struct TMRecord
    day::Int
    hour::Int
    half_hour::Int = 0
    duration::Float64 = 1.0
    network_flag::Int
    load_level::String = ""
end

"""
    SISTRecord

Subsystem definition record from ENTDADOS.XXX.

# Fields
- `subsystem_num::Int`: Subsystem number (1-99)
- `subsystem_code::String`: Subsystem mnemonic (2 characters)
- `status::Int`: Status flag (default 0)
- `subsystem_name::String`: Subsystem name (10 characters max)
"""
Base.@kwdef struct SISTRecord
    subsystem_num::Int
    subsystem_code::String
    status::Int = 0
    subsystem_name::String = ""
end

"""
    REERecord

Energy reservoir equivalent (REE) definition record from ENTDADOS.XXX.

# IDESEM Reference
idessem/dessem/modelos/entdados.py - REE class

# Fields
- `ree_code::Int`: REE identifier (1-99)
- `subsystem_code::Int`: Associated subsystem number
- `ree_name::String`: REE name (10 characters max)
"""
Base.@kwdef struct REERecord
    ree_code::Int
    subsystem_code::Int
    ree_name::String
end

"""
    TVIAGRecord

Water travel time between plants record from ENTDADOS.XXX.

# IDESEM Reference
idessem/dessem/modelos/entdados.py - TVIAG class

# Fields
- `upstream_plant::Int`: Upstream plant code
- `downstream_element::Int`: Downstream element code
- `element_type::String`: Element type ("H" for hydro plant, "S" for river section)
- `duration::Int`: Travel time duration in hours
- `travel_type::Int`: Travel time type (1=translation, 2=propagation)
"""
Base.@kwdef struct TVIAGRecord
    upstream_plant::Int
    downstream_element::Int
    element_type::String
    duration::Int
    travel_type::Int
end

"""
    RIVARRecord

Variable restriction record from ENTDADOS.XXX.

# IDESEM Reference
idessem/dessem/modelos/entdados.py - RIVAR class

# Fields
- `entity_code::Int`: Entity code (hydro, thermal, pump, or interchange)
- `to_system::Union{Int,Nothing}`: Destination system for interchange restrictions
- `variable_type::Int`: Variable type code
- `penalty::Float64`: Penalty value for restrictions
"""
Base.@kwdef struct RIVARRecord
    entity_code::Int
    to_system::Union{Int,Nothing} = nothing
    variable_type::Int
    penalty::Union{Float64,Nothing} = nothing
end

"""
    USIERecord

Pump station (usina elevatória) configuration record from ENTDADOS.XXX.

# IDESEM Reference
idessem/dessem/modelos/entdados.py - USIE class

# Fields
- `plant_code::Int`: Pump station identifier
- `subsystem_code::Int`: Associated subsystem number
- `plant_name::String`: Station name (12 characters max)
- `upstream_plant::Int`: Upstream plant code (per UH record)
- `downstream_plant::Int`: Downstream plant code (per UH record)
- `min_pump_flow::Float64`: Minimum pumpable flow (m³/s)
- `max_pump_flow::Float64`: Maximum pumpable flow (m³/s)
- `consumption_rate::Float64`: Consumption rate (MWmed/m³/s)
"""
Base.@kwdef struct USIERecord
    plant_code::Int
    subsystem_code::Int
    plant_name::String
    upstream_plant::Int
    downstream_plant::Int
    min_pump_flow::Float64
    max_pump_flow::Float64
    consumption_rate::Float64
end

"""
    RDRecord

Electric network representation options record from ENTDADOS.XXX.

# IDESEM Reference
idessem/dessem/modelos/entdados.py - RD class

# Fields
- `slack_variables::Int`: Slack variable flag (0/1)
- `max_violated_circuits::Int`: Maximum violated circuits allowed
- `load_dbar_register::Int`: Load DBAR register flag (0/1)
- `ignore_bars::Int`: Ignore bars flag (0/1)
- `circuit_limits_drefs::Int`: Circuit and DREF limits flag (0/1)
- `consider_losses::Int`: Consider network losses flag (0/1)
- `network_file_format::Union{Int, Nothing}`: Network file format flag (0/1), optional
"""
Base.@kwdef struct RDRecord
    slack_variables::Int
    max_violated_circuits::Int
    load_dbar_register::Int
    ignore_bars::Union{Int,Nothing} = nothing
    circuit_limits_drefs::Union{Int,Nothing} = nothing
    consider_losses::Union{Int,Nothing} = nothing
    network_file_format::Union{Int,Nothing} = nothing
end

"""
    UHRecord

Hydroelectric plant configuration record from ENTDADOS.XXX.

# Fields
- `plant_num::Int`: Plant number (1-320)
- `plant_name::String`: Plant name (12 characters max)
- `status::Int`: Plant status (0=existing, 1=under construction, default 0)
- `subsystem::Int`: Subsystem number per SIST records
- `initial_volume_pct::Float64`: Initial volume as % useful (0-100)
- `volume_unit::Int`: Volume unit flag (1=hm³, 2=% useful, default 2)
- `min_volume::Union{Float64, Nothing}`: Minimum volume
- `max_volume::Union{Float64, Nothing}`: Maximum volume
- `initial_volume_abs::Union{Float64, Nothing}`: Initial volume (absolute)
- `spillway_crest::Union{Float64, Nothing}`: Spillway crest volume
- `diversion_crest::Union{Float64, Nothing}`: Diversion crest volume
"""
Base.@kwdef struct UHRecord
    plant_num::Int
    plant_name::String
    status::Int = 0
    subsystem::Int
    initial_volume_pct::Float64
    volume_unit::Int = 2
    min_volume::Union{Float64,Nothing} = nothing
    max_volume::Union{Float64,Nothing} = nothing
    initial_volume_abs::Union{Float64,Nothing} = nothing
    spillway_crest::Union{Float64,Nothing} = nothing
    diversion_crest::Union{Float64,Nothing} = nothing
end

"""
    UTRecord

Thermal plant configuration record from ENTDADOS.XXX.

# Fields
- `plant_num::Int`: Plant number (1-999)
- `plant_name::String`: Plant name (12 characters max)
- `status::Int`: Plant status (0=existing, 1=under construction, default 0)
- `subsystem::Int`: Subsystem number per SIST records
- `start_day::Int`: Start day for operation
- `start_hour::Int`: Start hour (0-23)
- `start_half::Int`: Start half-hour (0 or 1)
- `end_marker::String`: End marker ("F" for final)
- `min_generation::Float64`: Minimum generation in MW (≥ 0, default 0.0)
- `max_generation::Float64`: Maximum generation/capacity in MW (> 0)
"""
Base.@kwdef struct UTRecord
    plant_num::Int
    plant_name::String
    status::Int = 0
    subsystem::Int
    start_day::Int
    start_hour::Int
    start_half::Int
    end_marker::String
    min_generation::Float64 = 0.0
    max_generation::Float64
end

"""
    DPRecord

Demand data record from ENTDADOS.XXX.

# Fields
- `subsystem::Int`: Subsystem number per SIST records
- `start_day::Int`: Initial day
- `start_hour::Int`: Initial hour (0-23, default 0)
- `start_half::Int`: Initial half-hour (0 or 1, default 0)
- `end_day::Union{Int, String}`: Final day or "F" for final
- `end_hour::Int`: Final hour (0-23, default 0)
- `end_half::Int`: Final half-hour (0 or 1, default 0)
- `demand::Float64`: Demand in MW (≥ 0)
"""
Base.@kwdef struct DPRecord
    subsystem::Int
    start_day::Int
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String}
    end_hour::Int = 0
    end_half::Int = 0
    demand::Float64
end

"""
    DARecord

Water withdrawal rate (taxa de desvio de água) record from ENTDADOS.XXX.

# Fields
- `plant_num::Int`: Hydro plant identifier
- `start_day::Union{Int,String,Nothing}`: Initial day or special marker (e.g., "I")
- `start_hour::Int`: Initial hour (0-23, default 0)
- `start_half::Int`: Initial half-hour flag (0 or 1, default 0)
- `end_day::Union{Int,String,Nothing}`: Final day or special marker (e.g., "F")
- `end_hour::Int`: Final hour (0-23, default 0)
- `end_half::Int`: Final half-hour flag (0 or 1, default 0)
- `withdrawal_rate::Float64`: Withdrawal rate (m³/s)
"""
Base.@kwdef struct DARecord
    plant_num::Int
    start_day::Union{Int,String,Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String,Nothing}
    end_hour::Int = 0
    end_half::Int = 0
    withdrawal_rate::Float64
end

"""
    MHRecord

Hydro unit maintenance record from ENTDADOS.XXX.

# Fields
- `plant_num::Int`: Hydro plant identifier
- `group_code::Int`: Generator group code within the plant
- `unit_code::Int`: Unit identifier within the group
- `start_day::Union{Int,String,Nothing}`: Maintenance start day or special marker
- `start_hour::Int`: Start hour (0-23, default 0)
- `start_half::Int`: Start half-hour (0 or 1, default 0)
- `end_day::Union{Int,String,Nothing}`: Maintenance end day or special marker
- `end_hour::Int`: End hour (0-23, default 0)
- `end_half::Int`: End half-hour (0 or 1, default 0)
- `available_flag::Int`: Availability flag (0=unavailable, 1=available)
"""
Base.@kwdef struct MHRecord
    plant_num::Int
    group_code::Int
    unit_code::Int
    start_day::Union{Int,String,Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String,Nothing}
    end_hour::Int = 0
    end_half::Int = 0
    available_flag::Int = 0
end

"""
    MTRecord

Thermal unit maintenance record from ENTDADOS.XXX.

# Fields
- `plant_num::Int`: Thermal plant identifier
- `unit_code::Int`: Unit identifier
- `start_day::Union{Int,String,Nothing}`: Maintenance start day or special marker
- `start_hour::Int`: Start hour (0-23, default 0)
- `start_half::Int`: Start half-hour (0 or 1, default 0)
- `end_day::Union{Int,String,Nothing}`: Maintenance end day or special marker
- `end_hour::Int`: End hour (0-23, default 0)
- `end_half::Int`: End half-hour (0 or 1, default 0)
- `available_flag::Int`: Availability flag (0=unavailable, 1=available)
"""
Base.@kwdef struct MTRecord
    plant_num::Int
    unit_code::Int
    start_day::Union{Int,String,Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String,Nothing}
    end_hour::Int = 0
    end_half::Int = 0
    available_flag::Int = 0
end

"""
    RERecord

Electrical constraint definition record from ENTDADOS.XXX.

# Fields
- `constraint_code::Int`: Constraint identifier
- `start_day::Union{Int,String,Nothing}`: Start day or special marker
- `start_hour::Int`: Start hour (0-23, default 0)
- `start_half::Int`: Start half-hour (0 or 1, default 0)
- `end_day::Union{Int,String,Nothing}`: End day or special marker
- `end_hour::Int`: End hour (0-23, default 0)
- `end_half::Int`: End half-hour (0 or 1, default 0)
"""
Base.@kwdef struct RERecord
    constraint_code::Int
    start_day::Union{Int,String,Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String,Nothing}
    end_hour::Int = 0
    end_half::Int = 0
end

"""
    LURecord

Electrical constraint limits record from ENTDADOS.XXX.

# Fields
- `constraint_code::Int`: Constraint identifier (per RE record)
- `start_day::Union{Int,String,Nothing}`: Start day or special marker
- `start_hour::Int`: Start hour (0-23, default 0)
- `start_half::Int`: Start half-hour (0 or 1, default 0)
- `end_day::Union{Int,String,Nothing}`: End day or special marker
- `end_hour::Int`: End hour (0-23, default 0)
- `end_half::Int`: End half-hour (0 or 1, default 0)
- `lower_limit::Float64`: Lower limit for the constraint
- `upper_limit::Float64`: Upper limit for the constraint
"""
Base.@kwdef struct LURecord
    constraint_code::Int
    start_day::Union{Int,String,Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String,Nothing}
    end_hour::Int = 0
    end_half::Int = 0
    lower_limit::Union{Float64,Nothing} = nothing
    upper_limit::Union{Float64,Nothing} = nothing
end

"""
    FHRecord

Hydro plant coefficient in electrical constraint from ENTDADOS.XXX.

# Fields
- `constraint_code::Int`: Constraint identifier (per RE record)
- `start_day::Union{Int,String,Nothing}`: Start day or special marker
- `start_hour::Int`: Start hour (0-23, default 0)
- `start_half::Int`: Start half-hour (0 or 1, default 0)
- `end_day::Union{Int,String,Nothing}`: End day or special marker
- `end_hour::Int`: End hour (0-23, default 0)
- `end_half::Int`: End half-hour (0 or 1, default 0)
- `plant_code::Int`: Hydro plant identifier
- `group_code::Int`: Generator group code (default 0)
- `coefficient::Float64`: Participation coefficient
"""
Base.@kwdef struct FHRecord
    constraint_code::Int
    start_day::Union{Int,String,Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String,Nothing}
    end_hour::Int = 0
    end_half::Int = 0
    plant_code::Int
    group_code::Int = 0
    coefficient::Float64
end

"""
    FTRecord

Thermal plant coefficient in electrical constraint from ENTDADOS.XXX.

# Fields
- `constraint_code::Int`: Constraint identifier (per RE record)
- `start_day::Union{Int,String,Nothing}`: Start day or special marker
- `start_hour::Int`: Start hour (0-23, default 0)
- `start_half::Int`: Start half-hour (0 or 1, default 0)
- `end_day::Union{Int,String,Nothing}`: End day or special marker
- `end_hour::Int`: End hour (0-23, default 0)
- `end_half::Int`: End half-hour (0 or 1, default 0)
- `plant_code::Int`: Thermal plant identifier
- `coefficient::Float64`: Participation coefficient
"""
Base.@kwdef struct FTRecord
    constraint_code::Int
    start_day::Union{Int,String,Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String,Nothing}
    end_hour::Int = 0
    end_half::Int = 0
    plant_code::Int
    coefficient::Float64
end

"""
    FIRecord

Interchange flow coefficient in electrical constraint from ENTDADOS.XXX.

# Fields
- `constraint_code::Int`: Constraint identifier (per RE record)
- `start_day::Union{Int,String,Nothing}`: Start day or special marker
- `start_hour::Int`: Start hour (0-23, default 0)
- `start_half::Int`: Start half-hour (0 or 1, default 0)
- `end_day::Union{Int,String,Nothing}`: End day or special marker
- `end_hour::Int`: End hour (0-23, default 0)
- `end_half::Int`: End half-hour (0 or 1, default 0)
- `from_subsystem::String`: Origin subsystem code
- `to_subsystem::String`: Destination subsystem code
- `coefficient::Float64`: Participation coefficient
"""
Base.@kwdef struct FIRecord
    constraint_code::Int
    start_day::Union{Int,String,Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String,Nothing}
    end_hour::Int = 0
    end_half::Int = 0
    from_subsystem::String
    to_subsystem::String
    coefficient::Float64
end

"""
    FERecord

Energy contract coefficient in electrical constraint from ENTDADOS.XXX.

# Fields
- `constraint_code::Int`: Constraint identifier (per RE record)
- `start_day::Union{Int,String,Nothing}`: Start day or special marker
- `start_hour::Int`: Start hour (0-23, default 0)
- `start_half::Int`: Start half-hour (0 or 1, default 0)
- `end_day::Union{Int,String,Nothing}`: End day or special marker
- `end_hour::Int`: End hour (0-23, default 0)
- `end_half::Int`: End half-hour (0 or 1, default 0)
- `contract_code::Int`: Contract identifier
- `coefficient::Float64`: Participation coefficient
"""
Base.@kwdef struct FERecord
    constraint_code::Int
    start_day::Union{Int,String,Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String,Nothing}
    end_hour::Int = 0
    end_half::Int = 0
    contract_code::Int
    coefficient::Float64
end

"""
    FRRecord

Renewable plant coefficient in electrical constraint from ENTDADOS.XXX.

# Fields
- `constraint_code::Int`: Constraint identifier (per RE record)
- `start_day::Union{Int,String,Nothing}`: Start day or special marker
- `start_hour::Int`: Start hour (0-23, default 0)
- `start_half::Int`: Start half-hour (0 or 1, default 0)
- `end_day::Union{Int,String,Nothing}`: End day or special marker
- `end_hour::Int`: End hour (0-23, default 0)
- `end_half::Int`: End half-hour (0 or 1, default 0)
- `plant_code::Int`: Renewable plant identifier
- `coefficient::Float64`: Participation coefficient
"""
Base.@kwdef struct FRRecord
    constraint_code::Int
    start_day::Union{Int,String,Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String,Nothing}
    end_hour::Int = 0
    end_half::Int = 0
    plant_code::Int
    coefficient::Float64
end

"""
    FCRecord

Special load coefficient in electrical constraint from ENTDADOS.XXX.

# Fields
- `constraint_code::Int`: Constraint identifier (per RE record)
- `start_day::Union{Int,String,Nothing}`: Start day or special marker
- `start_hour::Int`: Start hour (0-23, default 0)
- `start_half::Int`: Start half-hour (0 or 1, default 0)
- `end_day::Union{Int,String,Nothing}`: End day or special marker
- `end_hour::Int`: End hour (0-23, default 0)
- `end_half::Int`: End half-hour (0 or 1, default 0)
- `load_code::Int`: Special load identifier
- `coefficient::Float64`: Participation coefficient
"""
Base.@kwdef struct FCRecord
    constraint_code::Int
    start_day::Union{Int,String,Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String,Nothing}
    end_hour::Int = 0
    end_half::Int = 0
    load_code::Int
    coefficient::Float64
end

"""
    TXRecord

Discount rate record from ENTDADOS.XXX (for FCF construction).

# Fields
- `rate::Float64`: Annual discount rate in percentage
"""
Base.@kwdef struct TXRecord
    rate::Float64
end

"""
    EZRecord

Maximum useful volume percentage for coupling from ENTDADOS.XXX.

# Fields
- `plant_code::Int`: Hydro plant identifier
- `volume_pct::Float64`: Volume percentage (% of maximum useful volume)
"""
Base.@kwdef struct EZRecord
    plant_code::Int
    volume_pct::Float64
end

"""
    R11Record

Gauge 11 level variation constraints from ENTDADOS.XXX.

# Fields
- `start_day::Union{Int,String,Nothing}`: Start day or special marker
- `start_hour::Int`: Start hour (0-23, default 0)
- `start_half::Int`: Start half-hour (0 or 1, default 0)
- `end_day::Union{Int,String,Nothing}`: End day or special marker
- `end_hour::Int`: End hour (0-23, default 0)
- `end_half::Int`: End half-hour (0 or 1, default 0)
- `initial_level::Float64`: Initial water level at Gauge 11 (m)
- `max_hourly_variation::Float64`: Maximum hourly level variation (m)
- `max_daily_variation::Float64`: Maximum daily level variation (m)
"""
Base.@kwdef struct R11Record
    start_day::Union{Int,String,Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int,String,Nothing}
    end_hour::Int = 0
    end_half::Int = 0
    initial_level::Float64
    max_hourly_variation::Float64
    max_daily_variation::Float64
end

"""
    FPRecord

Production function approximation parameters from ENTDADOS.XXX.

# Fields
- `plant_code::Int`: Hydro plant identifier
- `volume_treatment::Int`: Volume treatment type (1=linear, 2=3d envelope)
- `turbine_points::Int`: Number of discretization points for turbining
- `volume_points::Int`: Number of discretization points for volume
- `check_concavity::Int`: Flag to enable concavity check (0/1)
- `least_squares::Int`: Flag to enable least squares adjustment (0/1)
- `volume_window_pct::Float64`: Volume window length (% of useful volume)
- `deviation_tolerance::Float64`: Tolerance for production function deviation (%)
"""
Base.@kwdef struct FPRecord
    plant_code::Int
    volume_treatment::Int
    turbine_points::Int
    volume_points::Int
    check_concavity::Union{Int,Nothing} = nothing
    least_squares::Union{Int,Nothing} = nothing
    volume_window_pct::Union{Float64,Nothing} = nothing
    deviation_tolerance::Union{Float64,Nothing} = nothing
end

"""
    SECRRecord

River section definition record from ENTDADOS.XXX.

# Fields
- `section_code::Int`: Section identifier
- `section_name::String`: Section name
- `upstream_plant_1::Union{Int,Nothing}`: First upstream plant code
- `participation_1::Union{Float64,Nothing}`: First plant participation factor
- `upstream_plant_2::Union{Int,Nothing}`: Second upstream plant code
- `participation_2::Union{Float64,Nothing}`: Second plant participation factor
- `upstream_plant_3::Union{Int,Nothing}`: Third upstream plant code
- `participation_3::Union{Float64,Nothing}`: Third plant participation factor
- `upstream_plant_4::Union{Int,Nothing}`: Fourth upstream plant code
- `participation_4::Union{Float64,Nothing}`: Fourth plant participation factor
- `upstream_plant_5::Union{Int,Nothing}`: Fifth upstream plant code
- `participation_5::Union{Float64,Nothing}`: Fifth plant participation factor
"""
Base.@kwdef struct SECRRecord
    section_code::Int
    section_name::String
    upstream_plant_1::Union{Int,Nothing} = nothing
    participation_1::Union{Float64,Nothing} = nothing
    upstream_plant_2::Union{Int,Nothing} = nothing
    participation_2::Union{Float64,Nothing} = nothing
    upstream_plant_3::Union{Int,Nothing} = nothing
    participation_3::Union{Float64,Nothing} = nothing
    upstream_plant_4::Union{Int,Nothing} = nothing
    participation_4::Union{Float64,Nothing} = nothing
    upstream_plant_5::Union{Int,Nothing} = nothing
    participation_5::Union{Float64,Nothing} = nothing
end

"""
    CRRecord

River section head-flow polynomial record from ENTDADOS.XXX.

# Fields
- `section_code::Int`: Section identifier (per SECR record)
- `section_name::String`: Section name
- `polynomial_degree::Int`: Polynomial degree (0-7)
- `a0::Float64`: Constant coefficient
- `a1::Float64`: Linear coefficient
- `a2::Float64`: Quadratic coefficient
- `a3::Float64`: Cubic coefficient
- `a4::Float64`: Quartic coefficient
- `a5::Float64`: Quintic coefficient
- `a6::Float64`: Sextic coefficient
"""
Base.@kwdef struct CRRecord
    section_code::Int
    section_name::String
    polynomial_degree::Int
    a0::Float64 = 0.0
    a1::Float64 = 0.0
    a2::Float64 = 0.0
    a3::Float64 = 0.0
    a4::Float64 = 0.0
    a5::Float64 = 0.0
    a6::Float64 = 0.0
end

"""
    ACRecord

Generic hydro plant configuration adjustment record from ENTDADOS.XXX.
AC records modify various plant parameters (volumes, polynomials, etc.).

# Fields
- `plant_code::Int`: Hydro plant identifier
- `ac_type::String`: Type of adjustment (e.g., "VOLMAX", "VOLMIN", "VTFUGA")
- `int_value::Union{Int,Nothing}`: Integer parameter value
- `float_value::Union{Float64,Nothing}`: Float parameter value
- `int_value2::Union{Int,Nothing}`: Second integer parameter (for multi-param AC types)
"""
Base.@kwdef struct ACRecord
    plant_code::Int
    ac_type::String
    int_value::Union{Int,Nothing} = nothing
    float_value::Union{Float64,Nothing} = nothing
    int_value2::Union{Int,Nothing} = nothing
end

"""
    AGRecord

Generic aggregate/group record from ENTDADOS.XXX.
AG records are used for various grouping purposes.

# Fields
- `group_type::String`: Type of grouping
- `group_id::Int`: Group identifier
- `description::String`: Group description
"""
Base.@kwdef struct AGRecord
    group_type::String
    group_id::Union{Int,Nothing} = nothing
    description::String
end

"""
    IARecord

Interchange limits between subsystems from ENTDADOS.XXX (IA records).

# Fields
- `subsystem_from::String`: Origin subsystem mnemonic
- `subsystem_to::String`: Destination subsystem mnemonic
- `day_start::Union{Int,String}`: Initial day
- `hour_start::Int`: Initial hour (0-23)
- `half_hour_start::Int`: Initial half-hour (0 or 1)
- `day_end::Union{Int,String}`: Final day (or "F")
- `hour_end::Int`: Final hour (0-23)
- `half_hour_end::Int`: Final half-hour (0 or 1)
- `capacity_from_to::Float64`: Interchange capacity from→to (MW)
- `capacity_to_from::Float64`: Interchange capacity to→from (MW)
"""
Base.@kwdef struct IARecord
    subsystem_from::String
    subsystem_to::String
    day_start::Union{Int,String,Nothing}
    hour_start::Int = 0
    half_hour_start::Int = 0
    day_end::Union{Int,String,Nothing}
    hour_end::Int = 0
    half_hour_end::Int = 0
    capacity_from_to::Float64
    capacity_to_from::Float64
end

"""
    CDRecord

Deficit cost curve from ENTDADOS.XXX (CD records).

# Fields
- `subsystem::Int`: Subsystem number
- `curve_number::Int`: Deficit curve index
- `day_start::Union{Int,String}`: Initial day
- `hour_start::Int`: Initial hour (0-23)
- `half_hour_start::Int`: Initial half-hour (0 or 1)
- `day_end::Union{Int,String}`: Final day (or "F")
- `hour_end::Int`: Final hour (0-23)
- `half_hour_end::Int`: Final half-hour (0 or 1)
- `cost::Float64`: Deficit cost (R\$/MWh)
- `upper_limit::Float64`: Upper depth for this cost step (MW)
"""
Base.@kwdef struct CDRecord
    subsystem::Int
    curve_number::Int
    day_start::Union{Int,String,Nothing}
    hour_start::Int = 0
    half_hour_start::Int = 0
    day_end::Union{Int,String,Nothing}
    hour_end::Int = 0
    half_hour_end::Int = 0
    cost::Float64
    upper_limit::Float64
end

"""
    VERecord

Flood control volume (volume de espera) from ENTDADOS.XXX (VE records).

# Fields
- `plant_num::Int`: Hydroelectric plant number
- `day_start::Union{Int,String}`: Initial day
- `hour_start::Int`: Initial hour (0-23)
- `half_hour_start::Int`: Initial half-hour (0 or 1)
- `day_end::Union{Int,String}`: Final day (or "F")
- `hour_end::Int`: Final hour (0-23)
- `half_hour_end::Int`: Final half-hour (0 or 1)
- `volume::Float64`: Flood control volume (hm³ or % useful)
"""
Base.@kwdef struct VERecord
    plant_num::Int
    day_start::Union{Int,String,Nothing}
    hour_start::Int = 0
    half_hour_start::Int = 0
    day_end::Union{Int,String,Nothing}
    hour_end::Int = 0
    half_hour_end::Int = 0
    volume::Float64
end

"""
    RIRecord

Itaipu restriction from ENTDADOS.XXX (RI records).

# Fields
- `day_start::Union{Int,String}`: Initial day
- `hour_start::Int`: Initial hour (0-23)
- `half_hour_start::Int`: Initial half-hour (0 or 1)
- `day_end::Union{Int,String}`: Final day (or "F")
- `hour_end::Int`: Final hour (0-23)
- `half_hour_end::Int`: Final half-hour (0 or 1)
- `gen_min_50hz::Float64`: Minimum 50Hz generation (MW)
- `gen_max_50hz::Float64`: Maximum 50Hz generation (MW)
- `gen_min_60hz::Float64`: Minimum 60Hz generation (MW)
- `gen_max_60hz::Float64`: Maximum 60Hz generation (MW)
- `ande_load::Float64`: ANDE load (MW)
"""
Base.@kwdef struct RIRecord
    day_start::Union{Int,String,Nothing}
    hour_start::Int = 0
    half_hour_start::Int = 0
    day_end::Union{Int,String,Nothing}
    hour_end::Int = 0
    half_hour_end::Int = 0
    gen_min_50hz::Float64
    gen_max_50hz::Float64
    gen_min_60hz::Float64
    gen_max_60hz::Float64
    ande_load::Float64
end

"""
    CERecord

Export energy contract from ENTDADOS.XXX (CE records).

# Fields
- `contract_num::Int`: Contract number
- `contract_name::String`: Contract name
- `year::Int`: Contract year
- `submkt_code::Int`: Subsystem code
- `day_start::Union{Int,String}`: Initial day
- `hour_start::Int`: Initial hour (0-23)
- `half_hour_start::Int`: Initial half-hour (0 or 1)
- `day_end::Union{Int,String}`: Final day (or "F")
- `hour_end::Int`: Final hour (0-23)
- `half_hour_end::Int`: Final half-hour (0 or 1)
- `modulation_flag::Int`: Modulation flag
- `min_value::Float64`: Minimum value (MW)
- `max_value::Float64`: Maximum value (MW)
- `inflexibility::Float64`: Inflexibility (MW)
- `priority::Float64`: Priority value (MW)
- `availability_flag::Int`: Availability flag
- `cost::Float64`: Contract cost (R\$/MWh)
"""
Base.@kwdef struct CERecord
    contract_num::Int
    contract_name::String
    year::Int
    submkt_code::Int
    day_start::Union{Int,String,Nothing}
    hour_start::Int = 0
    half_hour_start::Int = 0
    day_end::Union{Int,String,Nothing}
    hour_end::Int = 0
    half_hour_end::Int = 0
    modulation_flag::Int
    min_value::Float64
    max_value::Float64
    inflexibility::Float64
    priority::Float64
    availability_flag::Int
    cost::Float64
end

"""
    CIRecord

Import energy contract from ENTDADOS.XXX (CI records).

Same structure as CERecord but for import contracts.
"""
Base.@kwdef struct CIRecord
    contract_num::Int
    contract_name::String
    year::Int
    submkt_code::Int
    day_start::Union{Int,String,Nothing}
    hour_start::Int = 0
    half_hour_start::Int = 0
    day_end::Union{Int,String,Nothing}
    hour_end::Int = 0
    half_hour_end::Int = 0
    modulation_flag::Int
    min_value::Float64
    max_value::Float64
    inflexibility::Float64
    priority::Float64
    availability_flag::Int
    cost::Float64
end

"""
    DERecord

Special demand from ENTDADOS.XXX (DE records).

# Fields
- `demand_code::Int`: Special demand code
- `description::String`: Demand description
"""
Base.@kwdef struct DERecord
    demand_code::Int
    description::String
end

"""
    NIRecord

Network configuration from ENTDADOS.XXX (NI records).
Contains network modeling options.

# Fields
- `option_text::String`: Configuration text
"""
Base.@kwdef struct NIRecord
    option_text::String
end

"""
    GPRecord

Convergence tolerance gaps for PDD or MILP methods (GP record).
From ENTDADOS.XXX - defines convergence criteria for optimization solvers.

# Fields
- `gap_pdd::Union{Float64,Nothing}`: Convergence gap for Dual Dynamic Programming (PDD) method
- `gap_milp::Union{Float64,Nothing}`: Convergence gap for Mixed Integer Linear Programming (MILP) method
"""
Base.@kwdef struct GPRecord
    gap_pdd::Union{Float64,Nothing} = nothing
    gap_milp::Union{Float64,Nothing} = nothing
end

"""
    GeneralData

Container for all general data from ENTDADOS.XXX.

# Fields
- `time_periods::Vector{TMRecord}`: Time discretization records
- `subsystems::Vector{SISTRecord}`: Subsystem definitions
- `hydro_plants::Vector{UHRecord}`: Hydroelectric plant configurations
- `thermal_plants::Vector{UTRecord}`: Thermal plant configurations
- `demands::Vector{DPRecord}`: Demand data by subsystem and period
- `diversions::Vector{DARecord}`: Water withdrawal rate records
- `hydro_maintenance::Vector{MHRecord}`: Hydro maintenance windows
- `thermal_maintenance::Vector{MTRecord}`: Thermal maintenance windows
- `electrical_constraints::Vector{RERecord}`: Electrical constraint definitions
- `constraint_limits::Vector{LURecord}`: Constraint limit specifications
- `hydro_coefficients::Vector{FHRecord}`: Hydro plant coefficients in constraints
- `thermal_coefficients::Vector{FTRecord}`: Thermal plant coefficients in constraints
- `interchange_coefficients::Vector{FIRecord}`: Interchange flow coefficients
- `contract_coefficients::Vector{FERecord}`: Energy contract coefficients
- `renewable_coefficients::Vector{FRRecord}`: Renewable plant coefficients
- `load_coefficients::Vector{FCRecord}`: Special load coefficients
- `discount_rate::Vector{TXRecord}`: Discount rate records
- `coupling_volumes::Vector{EZRecord}`: Coupling volume percentages
- `gauge11_constraints::Vector{R11Record}`: Gauge 11 variation constraints
- `fpha_parameters::Vector{FPRecord}`: Production function parameters
- `river_sections::Vector{SECRRecord}`: River section definitions
- `section_polynomials::Vector{CRRecord}`: River section head-flow polynomials
- `plant_adjustments::Vector{ACRecord}`: Plant configuration adjustments
- `aggregate_groups::Vector{AGRecord}`: Aggregate/group records
- `interchange_limits::Vector{IARecord}`: Interchange capacity limits between subsystems
- `deficit_costs::Vector{CDRecord}`: Deficit cost curves
- `flood_volumes::Vector{VERecord}`: Flood control volumes
- `itaipu_restrictions::Vector{RIRecord}`: Itaipu plant restrictions
- `export_contracts::Vector{CERecord}`: Export energy contracts
- `import_contracts::Vector{CIRecord}`: Import energy contracts
- `special_demands::Vector{DERecord}`: Special demand definitions
- `network_config::Vector{NIRecord}`: Network configuration options
- `tolerance_gaps::Vector{GPRecord}`: Convergence tolerance gaps (PDD/MILP)
- `energy_reservoirs::Vector{REERecord}`: Energy reservoir equivalents (REE)
- `travel_times::Vector{TVIAGRecord}`: Water travel times between plants
- `variable_restrictions::Vector{RIVARRecord}`: Variable restrictions with penalties
- `pump_stations::Vector{USIERecord}`: Pump stations (usinas elevatórias)
- `network_options::Vector{RDRecord}`: Electric network representation options
"""
Base.@kwdef struct GeneralData
    time_periods::Vector{TMRecord} = TMRecord[]
    subsystems::Vector{SISTRecord} = SISTRecord[]
    energy_reservoirs::Vector{REERecord} = REERecord[]
    hydro_plants::Vector{UHRecord} = UHRecord[]
    travel_times::Vector{TVIAGRecord} = TVIAGRecord[]
    thermal_plants::Vector{UTRecord} = UTRecord[]
    pump_stations::Vector{USIERecord} = USIERecord[]
    demands::Vector{DPRecord} = DPRecord[]
    diversions::Vector{DARecord} = DARecord[]
    hydro_maintenance::Vector{MHRecord} = MHRecord[]
    thermal_maintenance::Vector{MTRecord} = MTRecord[]
    electrical_constraints::Vector{RERecord} = RERecord[]
    constraint_limits::Vector{LURecord} = LURecord[]
    hydro_coefficients::Vector{FHRecord} = FHRecord[]
    thermal_coefficients::Vector{FTRecord} = FTRecord[]
    interchange_coefficients::Vector{FIRecord} = FIRecord[]
    contract_coefficients::Vector{FERecord} = FERecord[]
    renewable_coefficients::Vector{FRRecord} = FRRecord[]
    load_coefficients::Vector{FCRecord} = FCRecord[]
    discount_rate::Vector{TXRecord} = TXRecord[]
    coupling_volumes::Vector{EZRecord} = EZRecord[]
    gauge11_constraints::Vector{R11Record} = R11Record[]
    fpha_parameters::Vector{FPRecord} = FPRecord[]
    river_sections::Vector{SECRRecord} = SECRRecord[]
    section_polynomials::Vector{CRRecord} = CRRecord[]
    plant_adjustments::Vector{ACRecord} = ACRecord[]
    aggregate_groups::Vector{AGRecord} = AGRecord[]
    interchange_limits::Vector{IARecord} = IARecord[]
    deficit_costs::Vector{CDRecord} = CDRecord[]
    flood_volumes::Vector{VERecord} = VERecord[]
    itaipu_restrictions::Vector{RIRecord} = RIRecord[]
    export_contracts::Vector{CERecord} = CERecord[]
    import_contracts::Vector{CIRecord} = CIRecord[]
    special_demands::Vector{DERecord} = DERecord[]
    network_config::Vector{NIRecord} = NIRecord[]
    tolerance_gaps::Vector{GPRecord} = GPRecord[]
    variable_restrictions::Vector{RIVARRecord} = RIVARRecord[]
    network_options::Vector{RDRecord} = RDRecord[]
end

# ============================================================================
# HIDR.DAT - Hydroelectric Plant Registry
# ============================================================================

"""
    CADUSIH

Basic hydroelectric plant data from HIDR.DAT (CADUSIH records).

# Fields
- `plant_num::Int`: Plant number (1-320)
- `plant_name::String`: Plant name
- `subsystem::Int`: Subsystem number
- `commission_year::Union{Int,Nothing}`: Commission year
- `commission_month::Union{Int,Nothing}`: Commission month
- `commission_day::Union{Int,Nothing}`: Commission day
- `downstream_plant::Union{Int,Nothing}`: Downstream plant number (0 = none)
- `diversion_downstream::Union{Int,Nothing}`: Diversion downstream plant number
- `plant_type::Union{Int,Nothing}`: Plant type code
- `min_volume::Float64`: Minimum reservoir volume (hm³)
- `max_volume::Float64`: Maximum reservoir volume (hm³)
- `max_turbine_flow::Float64`: Maximum turbine flow (m³/s)
- `installed_capacity::Float64`: Installed capacity (MW)
- `productivity::Float64`: Productivity coefficient (MW/(m³/s)/m)
"""
Base.@kwdef struct CADUSIH
    plant_num::Int
    plant_name::String
    subsystem::Int
    commission_year::Union{Int,Nothing} = nothing
    commission_month::Union{Int,Nothing} = nothing
    commission_day::Union{Int,Nothing} = nothing
    downstream_plant::Union{Int,Nothing} = nothing
    diversion_downstream::Union{Int,Nothing} = nothing
    plant_type::Union{Int,Nothing} = nothing
    min_volume::Float64 = 0.0
    max_volume::Float64
    max_turbine_flow::Float64 = 0.0
    installed_capacity::Float64 = 0.0
    productivity::Float64 = 0.0
end

"""
    USITVIAG

Travel time data between hydroelectric plants from HIDR.DAT.

# Fields
- `plant_num::Int`: Plant number
- `downstream_plant::Int`: Downstream plant number
- `travel_time::Float64`: Travel time in hours
"""
Base.@kwdef struct USITVIAG
    plant_num::Int
    downstream_plant::Int
    travel_time::Float64 = 0.0
end

"""
    POLCOT

Volume-elevation polynomial from HIDR.DAT (POLCOT records).

# Fields
- `plant_num::Int`: Plant number
- `degree::Int`: Polynomial degree (1-5)
- `coef0::Float64`: Coefficient 0 (constant term)
- `coef1::Float64`: Coefficient 1
- `coef2::Float64`: Coefficient 2
- `coef3::Float64`: Coefficient 3
- `coef4::Float64`: Coefficient 4
- `coef5::Float64`: Coefficient 5
"""
Base.@kwdef struct POLCOT
    plant_num::Int
    degree::Int
    coef0::Float64
    coef1::Float64 = 0.0
    coef2::Float64 = 0.0
    coef3::Float64 = 0.0
    coef4::Float64 = 0.0
    coef5::Float64 = 0.0
end

"""
    POLARE

Volume-surface area polynomial from HIDR.DAT (POLARE records).

Same structure as POLCOT but for area calculation.
"""
Base.@kwdef struct POLARE
    plant_num::Int
    degree::Int
    coef0::Float64
    coef1::Float64 = 0.0
    coef2::Float64 = 0.0
    coef3::Float64 = 0.0
    coef4::Float64 = 0.0
    coef5::Float64 = 0.0
end

"""
    POLJUS

Tailrace elevation polynomial from HIDR.DAT (POLJUS records).

Same structure as POLCOT but for tailrace level calculation.
"""
Base.@kwdef struct POLJUS
    plant_num::Int
    degree::Int
    coef0::Float64
    coef1::Float64 = 0.0
    coef2::Float64 = 0.0
    coef3::Float64 = 0.0
    coef4::Float64 = 0.0
    coef5::Float64 = 0.0
end

"""
    COEFEVA

Monthly evaporation coefficients from HIDR.DAT (COEFEVA records).

# Fields
- `plant_num::Int`: Plant number
- `jan::Float64`: January coefficient
- `feb::Float64`: February coefficient
- `mar::Float64`: March coefficient
- `apr::Float64`: April coefficient
- `may::Float64`: May coefficient
- `jun::Float64`: June coefficient
- `jul::Float64`: July coefficient
- `aug::Float64`: August coefficient
- `sep::Float64`: September coefficient
- `oct::Float64`: October coefficient
- `nov::Float64`: November coefficient
- `dec::Float64`: December coefficient
"""
Base.@kwdef struct COEFEVA
    plant_num::Int
    jan::Float64 = 0.0
    feb::Float64 = 0.0
    mar::Float64 = 0.0
    apr::Float64 = 0.0
    may::Float64 = 0.0
    jun::Float64 = 0.0
    jul::Float64 = 0.0
    aug::Float64 = 0.0
    sep::Float64 = 0.0
    oct::Float64 = 0.0
    nov::Float64 = 0.0
    dec::Float64 = 0.0
end

"""
    CADCONJ

Unit set definition from HIDR.DAT (CADCONJ records).

# Fields
- `plant_num::Int`: Plant number
- `unit_set_num::Int`: Unit set number (1-5)
- `num_units::Int`: Number of units in set
- `unit_capacity::Float64`: Capacity per unit (MW)
- `min_generation::Float64`: Minimum generation per unit (MW)
- `max_turbine_flow::Float64`: Maximum turbine flow per unit (m³/s)
"""
Base.@kwdef struct CADCONJ
    plant_num::Int
    unit_set_num::Int
    num_units::Int
    unit_capacity::Float64
    min_generation::Float64 = 0.0
    max_turbine_flow::Float64 = 0.0
end

"""
    HidrData

Container for all hydroelectric plant registry data from HIDR.DAT.

# Fields
- `plants::Vector{CADUSIH}`: Basic plant data
- `travel_times::Vector{USITVIAG}`: Travel time data
- `volume_elevation::Vector{POLCOT}`: Volume-elevation polynomials
- `volume_area::Vector{POLARE}`: Volume-area polynomials
- `tailrace::Vector{POLJUS}`: Tailrace polynomials
- `evaporation::Vector{COEFEVA}`: Evaporation coefficients
- `unit_sets::Vector{CADCONJ}`: Unit set definitions
"""
Base.@kwdef struct HidrData
    plants::Vector{CADUSIH} = CADUSIH[]
    travel_times::Vector{USITVIAG} = USITVIAG[]
    volume_elevation::Vector{POLCOT} = POLCOT[]
    volume_area::Vector{POLARE} = POLARE[]
    tailrace::Vector{POLJUS} = POLJUS[]
    evaporation::Vector{COEFEVA} = COEFEVA[]
    unit_sets::Vector{CADCONJ} = CADCONJ[]
end

"""
    BinaryHidrRecord

Complete 792-byte binary HIDR.DAT plant record with all 111 fields from IDESSEM.

Based on `idessem/dessem/modelos/hidr.py` RegistroUHEHidr structure.

# Basic Identification (Fields 0-6)
- `nome::String`: Plant name (12 characters)
- `posto::Int`: Station code
- `posto_bdh::Int64`: BDH station code (8 bytes, special field)
- `subsistema::Int`: Subsystem code
- `empresa::Int`: Company/agent code
- `jusante::Int`: Downstream plant code
- `desvio::Int`: Diversion code

# Volume and Elevation Data (Fields 7-12)
- `volume_minimo::Float64`: Minimum volume (hm³)
- `volume_maximo::Float64`: Maximum volume (hm³)
- `volume_vertedouro::Float64`: Spillway volume (hm³)
- `volume_desvio::Float64`: Diversion volume (hm³)
- `cota_minima::Float64`: Minimum elevation (m)
- `cota_maxima::Float64`: Maximum elevation (m)

# Polynomial Coefficients (Fields 13-22)
- `polinomio_volume_cota::Vector{Float64}`: Volume-elevation polynomial (5 coefficients)
- `polinomio_cota_area::Vector{Float64}`: Elevation-area polynomial (5 coefficients)

# Evaporation Data (Fields 23-34)
- `evaporacao::Vector{Int}`: Monthly evaporation coefficients (12 months, mm)

# Machine Sets (Fields 35-55)
- `numero_conjuntos_maquinas::Int`: Number of machine sets
- `numero_maquinas_conjunto::Vector{Int}`: Machines per set (5 sets)
- `potef_conjunto::Vector{Float64}`: Nominal power per set (MW, 5 sets)
- `hef_conjunto::Vector{Float64}`: Nominal head per set (m, 5 sets)
- `qef_conjunto::Vector{Int}`: Nominal flow per set (m³/s, 5 sets)

# Performance Parameters (Fields 56-58)
- `produtibilidade_especifica::Float64`: Specific productivity
- `perdas::Float64`: Losses (MW)
- `numero_polinomios_jusante::Int`: Number of tailrace polynomial families

# Tailrace Polynomials (Fields 59-95)
- `polinomios_jusante::Vector{Float64}`: Tailrace polynomials (36 values = 6 families × 6 values)

# Operational Parameters (Fields 96-110)
- `canal_fuga_medio::Float64`: Average tailrace level (m)
- `influencia_vertimento_canal_fuga::Int`: Spillway influence on tailrace
- `fator_carga_maximo::Float64`: Maximum load factor
- `fator_carga_minimo::Float64`: Minimum load factor
- `vazao_minima_historica::Int`: Historical minimum flow
- `numero_unidades_base::Int`: Base number of units
- `tipo_turbina::Int`: Turbine type
- `representacao_conjunto::Int`: Set representation
- `teif::Float64`: Equivalent forced outage rate
- `ip::Float64`: Programmed outage
- `tipo_perda::Int`: Loss type
- `data_referencia::String`: Reference date (12 characters)
- `observacao::String`: Observation/notes (39 characters)
- `volume_referencia::Float64`: Reference volume (hm³)
- `tipo_regulacao::String`: Regulation type (1 character)

# Reference
IDESSEM: idessem/dessem/modelos/hidr.py RegistroUHEHidr
Binary format: 792 bytes per plant record
"""
Base.@kwdef struct BinaryHidrRecord
    # Basic identification (Fields 0-6)
    nome::String
    posto::Int
    posto_bdh::Int64
    subsistema::Int
    empresa::Int
    jusante::Int
    desvio::Int

    # Volume and elevation data (Fields 7-12)
    volume_minimo::Float64
    volume_maximo::Float64
    volume_vertedouro::Float64
    volume_desvio::Float64
    cota_minima::Float64
    cota_maxima::Float64

    # Polynomial coefficients (Fields 13-22)
    polinomio_volume_cota::Vector{Float64}  # 5 coefficients
    polinomio_cota_area::Vector{Float64}    # 5 coefficients

    # Evaporation data (Fields 23-34)
    evaporacao::Vector{Int}  # 12 months

    # Machine sets (Fields 35-55)
    numero_conjuntos_maquinas::Int
    numero_maquinas_conjunto::Vector{Int}    # 5 sets
    potef_conjunto::Vector{Float64}          # 5 sets (MW)
    hef_conjunto::Vector{Float64}            # 5 sets (m)
    qef_conjunto::Vector{Int}                # 5 sets (m³/s)

    # Performance parameters (Fields 56-58)
    produtibilidade_especifica::Float64
    perdas::Float64
    numero_polinomios_jusante::Int

    # Tailrace polynomials (Fields 59-95)
    polinomios_jusante::Vector{Float64}  # 36 values (6 families × 6 values)

    # Operational parameters (Fields 96-110)
    canal_fuga_medio::Float64
    influencia_vertimento_canal_fuga::Int
    fator_carga_maximo::Float64
    fator_carga_minimo::Float64
    vazao_minima_historica::Int
    numero_unidades_base::Int
    tipo_turbina::Int
    representacao_conjunto::Int
    teif::Float64
    ip::Float64
    tipo_perda::Int
    data_referencia::String  # 12 characters
    observacao::String       # 39 characters
    volume_referencia::Float64
    tipo_regulacao::String   # 1 character
end

"""
    BinaryHidrData

Container for binary HIDR.DAT records with all 111 fields per plant.

# Fields
- `records::Vector{BinaryHidrRecord}`: Complete plant records from binary file

# Example
```julia
data = parse_hidr_binary("hidr.dat")
println("Number of plants: ", length(data.records))
println("First plant: ", data.records[1].nome)
println("Volume-elevation polynomial: ", data.records[1].polinomio_volume_cota)
```
"""
Base.@kwdef struct BinaryHidrData
    records::Vector{BinaryHidrRecord} = BinaryHidrRecord[]
end

# ============================================================================
# DADVAZ.DAT - Natural Inflow Data
# ============================================================================

"""
    DadvazHeader

Metadata extracted from DADVAZ.DAT header.

# Fields
- `plant_count::Int`: Number of hydro plants listed in the file
- `plant_numbers::Vector{Int}`: Ordered list of plant identifiers
- `study_start::DateTime`: Study start instant (local time)
- `initial_day_code::Int`: Initial weekday code (1=Saturday ... 7=Friday)
- `fcf_week_index::Int`: Future cost function week index (1-6)
- `study_weeks::Int`: Number of study weeks (excluding simulation period)
- `simulation_flag::Int`: Simulation flag (0=no simulation, 1=with simulation)
"""
Base.@kwdef struct DadvazHeader
    plant_count::Int
    plant_numbers::Vector{Int}
    study_start::DateTime
    initial_day_code::Int
    fcf_week_index::Int
    study_weeks::Int
    simulation_flag::Int
end

"""
    DadvazInflowRecord

Natural inflow time-slice for a hydro plant.

# Fields
- `plant_num::Int`: Plant identifier (per hydro registry)
- `plant_name::String`: Plant name (12-character field)
- `inflow_type::Int`: Inflow type (1=incremental, 2=total, 3=regularized)
- `start_day::Union{Int, String}`: Initial day or "I" for study start
- `start_hour::Union{Int, Nothing}`: Initial hour (0-23) if provided
- `start_half_hour::Union{Int, Nothing}`: Initial half-hour (0 or 1)
- `end_day::Union{Int, String}`: Final day or "F" for study end
- `end_hour::Union{Int, Nothing}`: Final hour (0-23) if provided
- `end_half_hour::Union{Int, Nothing}`: Final half-hour (0 or 1)
- `flow_m3s::Float64`: Natural inflow value in cubic meters per second
"""
Base.@kwdef struct DadvazInflowRecord
    plant_num::Int
    plant_name::String
    inflow_type::Int
    start_day::Union{Int,String}
    start_hour::Union{Int,Nothing} = nothing
    start_half_hour::Union{Int,Nothing} = nothing
    end_day::Union{Int,String}
    end_hour::Union{Int,Nothing} = nothing
    end_half_hour::Union{Int,Nothing} = nothing
    flow_m3s::Float64
end

"""
    DadvazData

Container for all natural inflow information parsed from DADVAZ.DAT.

# Fields
- `header::DadvazHeader`: File-level metadata
- `records::Vector{DadvazInflowRecord}`: All inflow slices grouped by plant
"""
Base.@kwdef struct DadvazData
    header::DadvazHeader
    records::Vector{DadvazInflowRecord} = DadvazInflowRecord[]
end

# ============================================================================
# DESSELET.DAT - Network Case Mapping
# ============================================================================

"""
    DesseletBaseCase

Base network case reference from DESSELET.DAT.

# Fields
- `base_id::Int`: Identifier used by patamar entries
- `label::String`: Human readable label (e.g., "leve")
- `filename::String`: Base case filename (e.g., "leve.pwf")
"""
Base.@kwdef struct DesseletBaseCase
    base_id::Int
    label::String
    filename::String
end

"""
    DesseletPatamar

Network scenario definition referencing a base case.

# Fields
- `patamar_id::Int`: Sequential patamar identifier
- `name::String`: Scenario name (e.g., "Estagio01")
- `date::Date`: Calendar date for the snapshot
- `hour::Int`: Hour component (0-23)
- `minute::Int`: Minute component (usually 0 or 30)
- `duration_hours::Float64`: Duration in hours for the scenario
- `base_case_id::Int`: Linked base case identifier
- `filename::String`: Adjustment file (e.g., "pat01.afp")
"""
Base.@kwdef struct DesseletPatamar
    patamar_id::Int
    name::String
    date::Date
    hour::Int
    minute::Int
    duration_hours::Float64
    base_case_id::Int
    filename::String
end

"""
    DesseletData

Container for DESSELET.DAT content.

# Fields
- `base_cases::Vector{DesseletBaseCase}`: Base case definitions
- `patamares::Vector{DesseletPatamar}`: Scenario modifications referencing base cases
- `metadata::Dict{String, Any}`: Optional metadata (e.g., file path)
"""
Base.@kwdef struct DesseletData
    base_cases::Vector{DesseletBaseCase} = DesseletBaseCase[]
    patamares::Vector{DesseletPatamar} = DesseletPatamar[]
    metadata::Dict{String,Any} = Dict{String,Any}()
end

# ============================================================================
# Hydro Operational Constraints (OPERUH.DAT) Types
# ============================================================================

"""
    HydroConstraintREST

Hydro constraint definition record from OPERUH.DAT.

IDESEM Reference: idessem/dessem/modelos/operuh.py - REST register
Column positions: codigo_restricao (14-18), tipo_restricao (21), intervalo_aplicacao (23),
                 valor_inicial (40-49), tipo_restricao_variacao (51), duracao_janela (55-59)

# Fields
- `constraint_id::Int`: Unique constraint identifier (5 digits)
- `type_flag::String`: Constraint type (L=limit, V=variation) (1 char)
- `interval_type::String`: Interval application type (P, blank) (1 char)
- `variable_code::String`: Variable being constrained (RHQ=flow, RHV=volume, RHS=storage, etc.) (12 chars)
- `initial_value::Union{Float64, Nothing}`: Initial value for variation constraints (10.2 format)
- `variation_type::Union{Int, Nothing}`: Variation constraint type (1 digit)
- `window_duration::Union{Float64, Nothing}`: Window duration for variation (5.2 format)
"""
Base.@kwdef struct HydroConstraintREST
    constraint_id::Int
    type_flag::String  # L or V
    interval_type::String = ""  # P or blank
    variable_code::String  # RHQ, RHV, RHS, etc.
    initial_value::Union{Float64,Nothing} = nothing
    variation_type::Union{Int,Nothing} = nothing
    window_duration::Union{Float64,Nothing} = nothing
end

"""
    HydroConstraintELEM

Hydro constraint element (plant participation) record from OPERUH.DAT.

IDESEM Reference: idessem/dessem/modelos/operuh.py - ELEM register
Column positions: codigo_restricao (14-18), codigo_usina (20-22), nome_usina (24-35),
                 tipo (37), coeficiente (39-43)

# Fields
- `constraint_id::Int`: Constraint identifier (links to REST record) (5 digits)
- `plant_code::Int`: Hydroelectric plant code (3 digits)
- `plant_name::String`: Plant name (12 chars)
- `variable_type::Int`: Variable type code (1-65, see DESSEM manual) (1 digit)
- `coefficient::Float64`: Plant's coefficient in constraint equation (5.1 format)
"""
Base.@kwdef struct HydroConstraintELEM
    constraint_id::Int
    plant_code::Int
    plant_name::String
    variable_type::Int
    coefficient::Float64
end

"""
    HydroConstraintLIM

Hydro operational limits record from OPERUH.DAT.

IDESEM Reference: idessem/dessem/modelos/operuh.py - LIM register
Column positions: codigo_restricao (14-18), StageDateField(20) for start, StageDateField(28) for end,
                 limite_inferior (38-47), limite_superior (48-57)
StageDateField format: day (2 chars), hour (2 chars), half-hour (1 char) - special char 'I'/'F'

# Fields
- `constraint_id::Int`: Constraint identifier (links to REST record) (5 digits)
- `start_day::Union{String, Int}`: Initial day (I=initial, F=final, or day 1-31)
- `start_hour::Union{Int, Nothing}`: Initial hour (0-23)
- `start_half::Union{Int, Nothing}`: Initial half-hour (0-1)
- `end_day::Union{String, Int}`: Final day (F=final or day 1-31)
- `end_hour::Union{Int, Nothing}`: Final hour (0-23)
- `end_half::Union{Int, Nothing}`: Final half-hour (0 or 1)
- `lower_limit::Union{Float64, Nothing}`: Lower bound (10.2 format)
- `upper_limit::Union{Float64, Nothing}`: Upper bound (10.2 format)
"""
Base.@kwdef struct HydroConstraintLIM
    constraint_id::Int
    start_day::Union{String,Int}
    start_hour::Union{Int,Nothing} = nothing
    start_half::Union{Int,Nothing} = nothing
    end_day::Union{String,Int}
    end_hour::Union{Int,Nothing} = nothing
    end_half::Union{Int,Nothing} = nothing
    lower_limit::Union{Float64,Nothing} = nothing
    upper_limit::Union{Float64,Nothing} = nothing
end

"""
    HydroConstraintVAR

Hydro variation/ramp constraint record from OPERUH.DAT.

IDESEM Reference: idessem/dessem/modelos/operuh.py - VAR register
Column positions: codigo_restricao (14-18), StageDateField(19) for start, StageDateField(27) for end,
                 ramp fields at (37-46), (47-56), (57-66), (67-76) - all 10.2 format

# Fields
- `constraint_id::Int`: Constraint identifier (5 digits)
- `start_day::Union{String, Int}`: Initial day (I=initial, F=final, or day 1-31)
- `start_hour::Union{Int, Nothing}`: Initial hour (0-23)
- `start_half::Union{Int, Nothing}`: Initial half-hour (0-1)
- `end_day::Union{String, Int}`: Final day (F=final or day 1-31)
- `end_hour::Union{Int, Nothing}`: Final hour (0-23)
- `end_half::Union{Int, Nothing}`: Final half-hour (0 or 1)
- `ramp_down::Union{Float64, Nothing}`: Maximum decrease rate (10.2 format)
- `ramp_up::Union{Float64, Nothing}`: Maximum increase rate (10.2 format)
- `ramp_down_2::Union{Float64, Nothing}`: Secondary decrease rate (10.2 format)
- `ramp_up_2::Union{Float64, Nothing}`: Secondary increase rate (10.2 format)
"""
Base.@kwdef struct HydroConstraintVAR
    constraint_id::Int
    start_day::Union{String,Int}
    start_hour::Union{Int,Nothing} = nothing
    start_half::Union{Int,Nothing} = nothing
    end_day::Union{String,Int}
    end_hour::Union{Int,Nothing} = nothing
    end_half::Union{Int,Nothing} = nothing
    ramp_down::Union{Float64,Nothing} = nothing
    ramp_up::Union{Float64,Nothing} = nothing
    ramp_down_2::Union{Float64,Nothing} = nothing
    ramp_up_2::Union{Float64,Nothing} = nothing
end

"""
    OperuhData

Container for all OPERUH.DAT hydro operational constraints.

# Fields
- `rest_records::Vector{HydroConstraintREST}`: Constraint definitions
- `elem_records::Vector{HydroConstraintELEM}`: Plant participation in constraints
- `lim_records::Vector{HydroConstraintLIM}`: Operational limits
- `var_records::Vector{HydroConstraintVAR}`: Variation/ramp constraints
"""
Base.@kwdef struct OperuhData
    rest_records::Vector{HydroConstraintREST} = HydroConstraintREST[]
    elem_records::Vector{HydroConstraintELEM} = HydroConstraintELEM[]
    lim_records::Vector{HydroConstraintLIM} = HydroConstraintLIM[]
    var_records::Vector{HydroConstraintVAR} = HydroConstraintVAR[]
end

# ============================================================================
# OPERUT.DAT - Thermal Operational Data  
# ============================================================================

"""
Thermal unit initial conditions from OPERUT INIT block.

Fields (actual format from CCEE sample):
- `plant_num::Int`: Plant number (columns 1-3)
- `plant_name::String`: Plant name (columns 5-16)
- `unit_num::Int`: Unit number (columns 18-20)
- `initial_status::Int`: Initial status (0=off, 1=on) (column 22)
- `initial_generation::Float64`: Initial generation MW (columns 24-35)
- `hours_in_state::Int`: Hours in current state (columns 37-41)
- `mh_flag::Int`: MH flag (column 43)
- `ad_flag::Int`: A/D flag (column 45)
- `t_flag::Int`: T flag (column 47)
- `inflexible_limit::Float64`: Inflexible generation limit MW (columns 49-60)
"""
Base.@kwdef struct INITRecord
    plant_num::Int
    plant_name::String
    unit_num::Int
    initial_status::Int
    initial_generation::Float64
    hours_in_state::Int
    mh_flag::Int = 0
    ad_flag::Int = 0
    t_flag::Int = 0
    inflexible_limit::Float64 = 0.0
end

"""
Thermal unit operating parameters from OPERUT OPER block.

Fields (actual format from CCEE sample):
- `plant_num::Int`: Plant number (columns 1-3)
- `plant_name::String`: Plant name (columns 5-16)
- `unit_num::Int`: Unit number (columns 18-19)
- `start_day::Int`: Start day (columns 21-22)
- `start_hour::Int`: Start hour (columns 24-25)
- `start_half::Int`: Start half-hour (column 27)
- `end_day::Union{Int,String}`: End day or "F" for final (columns 29-30)
- `end_hour::Int`: End hour (columns 32-33, optional)
- `end_half::Int`: End half-hour (column 35, optional)
- `min_generation::Union{Float64,Nothing}`: Minimum generation MW (columns 37-47, optional)
- `max_generation::Union{Float64,Nothing}`: Maximum generation MW (columns 48-58, optional)
- `operating_cost::Float64`: Operating cost R\$/MWh (columns 59-70)
"""
Base.@kwdef struct OPERRecord
    plant_num::Int
    plant_name::String
    unit_num::Int
    start_day::Int
    start_hour::Int
    start_half::Int
    end_day::Union{Int,String}  # "F" for final
    end_hour::Int = 0
    end_half::Int = 0
    min_generation::Union{Float64,Nothing} = nothing
    max_generation::Union{Float64,Nothing} = nothing
    operating_cost::Float64
end

"""
Container for OPERUT.DAT parsed data.

Fields:
- `init_records::Vector{INITRecord}`: Unit initial conditions
- `oper_records::Vector{OPERRecord}`: Operating costs and limits
- `uctpar::Union{Int,Nothing}`: Parallel processing threads (UCTPAR block)
- `ucterm::Union{Int,Nothing}`: Unit commitment thermal methodology (UCTERM block)
- `pint::Union{Bool,Nothing}`: Interior points method flag (PINT block)
- `regranptv::Vector{Int}`: NPTV hydraulic production defaults (REGRANPTV block)
- `avlcmo::Union{Int,Nothing}`: CMO evaluation printing flag (AVLCMO block)
- `cplexlog::Union{Bool,Nothing}`: CPLEX logging flag (CPLEXLOG block)
- `uctbusloc::Union{Bool,Nothing}`: Local search flag (UCTBUSLOC block)
- `uctheurfp::Vector{Int}`: Feasibility Pump heuristic parameters (UCTHEURFP block)
- `constdados::Vector{Int}`: Data consistency parameters (CONSTDADOS block)
- `ajustefcf::Union{Bool,Nothing}`: FCF adjustments flag (AJUSTEFCF block)
- `tolerilh::Union{Int,Nothing}`: Island tolerance setting (TOLERILH block)
- `crossover::Vector{Int}`: Crossover method parameters (CROSSOVER block)
- `engolimento::Union{Int,Nothing}`: Swallowing method setting (ENGOLIMENTO block)
- `tratainviabilha::Union{Int,Nothing}`: Island infeasibility treatment (TRATA_INVIAB_ILHA block)
"""
Base.@kwdef struct OperutData
    init_records::Vector{INITRecord} = INITRecord[]
    oper_records::Vector{OPERRecord} = OPERRecord[]
    # Optimization configuration blocks
    uctpar::Union{Int,Nothing} = nothing
    ucterm::Union{Int,Nothing} = nothing
    pint::Union{Bool,Nothing} = nothing
    regranptv::Vector{Int} = Int[]
    avlcmo::Union{Int,Nothing} = nothing
    cplexlog::Union{Bool,Nothing} = nothing
    uctbusloc::Union{Bool,Nothing} = nothing
    uctheurfp::Vector{Int} = Int[]
    constdados::Vector{Int} = Int[]
    ajustefcf::Union{Bool,Nothing} = nothing
    tolerilh::Union{Int,Nothing} = nothing
    crossover::Vector{Int} = Int[]
    engolimento::Union{Int,Nothing} = nothing
    tratainviabilha::Union{Int,Nothing} = nothing
end

# ============================================================================
# Previous Flows (DEFLANT.DAT) Types
# ============================================================================

"""
    DeflantRecord

Represents a previous flow record (DEFANT) for water travel time modeling.

Previous flows define flow rates before the study period to account for 
water travel time delays between upstream and downstream elements.

# Fields
- `upstream_plant::Int`: Upstream plant code (1-999)
- `downstream_element::Int`: Downstream element code (1-999)
- `element_type::String`: Type of downstream element ("H" = hydro, "S" = river section)
- `initial_day::Union{String, Int}`: Initial day ("I" for inicio or 1-31)
- `initial_hour::Union{Int, Nothing}`: Initial hour (0-23)
- `initial_half::Union{Int, Nothing}`: Initial half-hour (0 or 1)
- `final_day::Union{String, Int}`: Final day ("F" for fim or 1-31)
- `final_hour::Union{Int, Nothing}`: Final hour (0-23)
- `final_half::Union{Int, Nothing}`: Final half-hour (0 or 1)
- `flow::Float64`: Flow rate in m³/s

# IDESEM Reference
idessem/dessem/modelos/deflant.py - DEFANT class
"""
Base.@kwdef struct DeflantRecord
    upstream_plant::Int
    downstream_element::Int
    element_type::String
    initial_day::Union{String,Int}
    initial_hour::Union{Int,Nothing} = nothing
    initial_half::Union{Int,Nothing} = nothing
    final_day::Union{String,Int}
    final_hour::Union{Int,Nothing} = nothing
    final_half::Union{Int,Nothing} = nothing
    flow::Float64
end

"""
    DeflantData

Container for all DEFLANT.DAT previous flow records.

# Fields
- `records::Vector{DeflantRecord}`: All DEFANT records

# IDESEM Reference
idessem/dessem/deflant.py - Deflant class
"""
Base.@kwdef struct DeflantData
    records::Vector{DeflantRecord} = DeflantRecord[]
end

# ============================================================================
# Network Topology Types (from PDO files)
# ============================================================================

"""
    NetworkBus

Bus (node) in the electrical network topology.

# Fields
- `bus_number::Int`: Bus identifier
- `name::String`: Bus name
- `subsystem::String`: Regional subsystem (SE, S, N, NE)
- `generation_mw::Union{Float64, Nothing}`: Total generation at bus (MW)
- `load_mw::Union{Float64, Nothing}`: Load at bus (MW)
- `voltage_kv::Union{Float64, Nothing}`: Nominal voltage (kV)
"""
Base.@kwdef struct NetworkBus
    bus_number::Int
    name::String = ""
    subsystem::String = ""
    generation_mw::Union{Float64,Nothing} = nothing
    load_mw::Union{Float64,Nothing} = nothing
    voltage_kv::Union{Float64,Nothing} = nothing
end

"""
    NetworkLine

Transmission line (edge) in the electrical network topology.

# Fields
- `from_bus::Int`: Origin bus number
- `to_bus::Int`: Destination bus number
- `circuit::Int`: Circuit identifier (1, 2, 3... for parallel lines)
- `flow_mw::Union{Float64, Nothing}`: Power flow (MW)
- `capacity_mw::Union{Float64, Nothing}`: Line capacity (MW)
- `constraint_name::String`: Associated constraint name
"""
Base.@kwdef struct NetworkLine
    from_bus::Int
    to_bus::Int
    circuit::Int
    flow_mw::Union{Float64,Nothing} = nothing
    capacity_mw::Union{Float64,Nothing} = nothing
    constraint_name::String = ""
end

"""
    NetworkTopology

Complete electrical network topology extracted from PDO output files.

# Fields
- `buses::Vector{NetworkBus}`: All network buses
- `lines::Vector{NetworkLine}`: All transmission lines
- `stage::Union{Int, Nothing}`: Time stage (1-48)
- `load_level::String`: Load level (LEVE, MEDIA, PESADA)
- `metadata::Dict{String, Any}`: Additional information
"""
Base.@kwdef struct NetworkTopology
    buses::Vector{NetworkBus} = NetworkBus[]
    lines::Vector{NetworkLine} = NetworkLine[]
    stage::Union{Int,Nothing} = nothing
    load_level::String = ""
    metadata::Dict{String,Any} = Dict{String,Any}()
end

# ============================================================================
# Main Container Type
# ============================================================================

"""
DessemData holds parsed DESSEM inputs aggregated by filename.

Fields
- files: Dict mapping filename (uppercase) -> parsed object (Any for now)
- metadata: Dict for auxiliary info (e.g., input_dir, timestamp, version)
"""
Base.@kwdef struct DessemData
    files::Dict{String,Any} = Dict{String,Any}()
    metadata::Dict{String,Any} = Dict{String,Any}()
end

# ============================================================================
# Renewable Energy (RENOVAVEIS.DAT) Types
# ============================================================================

"""
    RenovaveisRecord

Single renewable energy plant registration record.

# IDESSEM Reference
idessem/dessem/modelos/renovaveis.py - EOLICA class

# Fields
- `plant_code::Int`: Plant identification code (5 digits)
- `plant_name::String`: Plant name including bus and type (40 chars max)
- `pmax::Float64`: Maximum power capacity in MW
- `fcap::Float64`: Capacity factor (0.0 to 1.0)
- `cadastro::Int`: Registration flag (0 = not registered, 1 = registered)

# Format Notes
- Despite the name "EOLICA" (wind), this includes all renewable types:
  - UEE: Wind farms (Usina Eólica)
  - UFV: Solar farms (Usina Fotovoltaica)
  - UTE: Biomass/thermal
  - PCH/CGH: Small hydro plants
  - Others
- PMAX often set to 9999 as placeholder value
- FCAP represents expected capacity factor for generation forecasting
- Plant name format: "CODE _NAME_BUSNUM_TYPE"

# Example
```julia
RenovaveisRecord(
    plant_code=1,
    plant_name="5G260  _MMGD_F_260_00260_MGD",
    pmax=9999.0,
    fcap=1.0,
    cadastro=0
)
```
"""
Base.@kwdef struct RenovaveisRecord
    plant_code::Int
    plant_name::String
    pmax::Float64
    fcap::Float64
    cadastro::Int
end

"""
    RenovaveisSubsystemRecord

Maps a renewable plant to its subsystem/market.

# Fields
- `plant_code::Int`: 5-digit plant ID
- `subsystem::String`: Subsystem identifier (e.g., "SE", "S", "NE", "N")
"""
Base.@kwdef struct RenovaveisSubsystemRecord
    plant_code::Int
    subsystem::String
end

"""
    RenovaveisBusRecord

Maps a renewable plant to its electrical bus connection point.

# Fields
- `plant_code::Int`: 5-digit plant ID
- `bus_code::Int`: 5-digit bus ID where plant connects
"""
Base.@kwdef struct RenovaveisBusRecord
    plant_code::Int
    bus_code::Int
end

"""
    RenovaveisGenerationRecord

Time series forecast of available generation for renewable plants.

# Fields
- `plant_code::Int`: 5-digit plant ID
- `start_day::Int`: Day of validity start
- `start_hour::Int`: Hour of validity start (0-23)
- `start_half_hour::Int`: Half-hour flag: 0=:00, 1=:30
- `end_day::Int`: Day of validity end
- `end_hour::Int`: Hour of validity end (0-23)
- `end_half_hour::Int`: Half-hour flag: 0=:00, 1=:30
- `generation::Float64`: Generation forecast (MW)
"""
Base.@kwdef struct RenovaveisGenerationRecord
    plant_code::Int
    start_day::Int
    start_hour::Int
    start_half_hour::Int
    end_day::Int
    end_hour::Int
    end_half_hour::Int
    generation::Float64
end

"""
    RenovaveisData

Complete renewable energy plant registration data from RENOVAVEIS.DAT.

# IDESSEM Reference
idessem/dessem/modelos/renovaveis.py
idessem/dessem/renovaveis.py

# Fields
- `plants::Vector{RenovaveisRecord}`: Vector of renewable plant records
- `subsystem_mappings::Vector{RenovaveisSubsystemRecord}`: Plant-to-subsystem mappings
- `bus_mappings::Vector{RenovaveisBusRecord}`: Plant-to-bus electrical connections
- `generation_forecasts::Vector{RenovaveisGenerationRecord}`: Time series generation forecasts

# Purpose
This file registers all renewable energy sources in the system with their:
- Maximum generation capacity (PMAX)
- Expected capacity factor (FCAP)
- Registration status (CADASTRO)

Used by DESSEM for:
- Renewable generation forecasting
- Capacity availability modeling
- Integration with network model

# Statistics from Sample Data
- CCEE sample: 1,225 renewable plants
- ONS sample: ~330,000+ records (very large file!)
- Mix of wind, solar, biomass, small hydro
- Most have FCAP = 1.0 and PMAX = 9999 (placeholder values)

# Example Usage
```julia
data = parse_renovaveis("renovaveis.dat")
println("Total renewable plants: \$(length(data.plants))")

# Filter by type
wind_plants = filter(p -> occursin("UEE", p.plant_name), data.plants)
solar_plants = filter(p -> occursin("UFV", p.plant_name), data.plants)

# Find registered plants
registered = filter(p -> p.cadastro == 1, data.plants)
```
"""
Base.@kwdef struct RenovaveisData
    plants::Vector{RenovaveisRecord} = RenovaveisRecord[]
    subsystem_mappings::Vector{RenovaveisSubsystemRecord} = RenovaveisSubsystemRecord[]
    bus_mappings::Vector{RenovaveisBusRecord} = RenovaveisBusRecord[]
    generation_forecasts::Vector{RenovaveisGenerationRecord} = RenovaveisGenerationRecord[]
end

# Export new types
export DessOpcData
export SimulHeader, DiscRecord, VoliRecord, OperRecord, SimulData
export AreaRecord, UsinaRecord, AreaContData
export CotaR11Record, CotasR11Data
export CurvTviagRecord, CurvTviagData
export NetworkBus, NetworkLine, NetworkTopology
export RenovaveisRecord, RenovaveisData

# ============================================================================
# RESPOT.DAT (Power Reserve Requirements) Types
# ============================================================================

"""
    RespotRP

Reserve pool definition record (RP) from RESPOT.DAT.

Defines the control area and time window for power reserve requirements.

# IDESSEM Reference
idessem/dessem/modelos/respot.py - class RP

# Fields
- `codigo_area::Int`: Control area code (1-based)
- `dia_inicial::Union{Int, String}`: Initial day or "I"
- `hora_inicial::Union{Int, Nothing}`: Initial hour (0-23)
- `meia_hora_inicial::Union{Int, Nothing}`: Initial half-hour (0 or 1)
- `dia_final::Union{Int, String}`: Final day or "F"
- `hora_final::Union{Int, Nothing}`: Final hour (0-23)
- `meia_hora_final::Union{Int, Nothing}`: Final half-hour (0 or 1)
- `descricao::String`: Description of reserve requirement

# Format
Fixed-width columns per IDESEM:
- Columns 5-7 (I3): codigo_area
- Columns 10-16 (StageDateField): dia_inicial, hora_inicial, meia_hora_inicial
- Columns 18-24 (StageDateField): dia_final, hora_final, meia_hora_final
- Columns 31-70 (A40): descricao
"""
Base.@kwdef struct RespotRP
    codigo_area::Int
    dia_inicial::Union{Int,String}
    hora_inicial::Union{Int,Nothing} = nothing
    meia_hora_inicial::Union{Int,Nothing} = nothing
    dia_final::Union{Int,String}
    hora_final::Union{Int,Nothing} = nothing
    meia_hora_final::Union{Int,Nothing} = nothing
    descricao::String = ""
end

"""
    RespotLM

Reserve limit record (LM) from RESPOT.DAT.

Specifies the minimum power reserve requirement for a control area at a specific half-hour.

# IDESSEM Reference
idessem/dessem/modelos/respot.py - class LM

# Fields
- `codigo_area::Int`: Control area code (links to RP record)
- `dia_inicial::Union{Int, String}`: Initial day or "I"
- `hora_inicial::Union{Int, Nothing}`: Initial hour (0-23)
- `meia_hora_inicial::Union{Int, Nothing}`: Initial half-hour (0 or 1)
- `dia_final::Union{Int, String}`: Final day or "F"
- `hora_final::Union{Int, Nothing}`: Final hour (0-23)
- `meia_hora_final::Union{Int, Nothing}`: Final half-hour (0 or 1)
- `limite_inferior::Float64`: Minimum reserve requirement (MW)

# Format
Fixed-width columns per IDESEM:
- Columns 5-7 (I3): codigo_area
- Columns 10-16 (StageDateField): dia_inicial, hora_inicial, meia_hora_inicial
- Columns 18-24 (StageDateField): dia_final, hora_final, meia_hora_final
- Columns 26-35 (F10.2): limite_inferior
"""
Base.@kwdef struct RespotLM
    codigo_area::Int
    dia_inicial::Union{Int,String}
    hora_inicial::Union{Int,Nothing} = nothing
    meia_hora_inicial::Union{Int,Nothing} = nothing
    dia_final::Union{Int,String}
    hora_final::Union{Int,Nothing} = nothing
    meia_hora_final::Union{Int,Nothing} = nothing
    limite_inferior::Float64
end

"""
    RespotData

Complete RESPOT.DAT file data structure.

Contains power reserve requirements for control areas, organized as:
- RP records: Reserve pool definitions with time windows
- LM records: Half-hourly minimum reserve limits

# Purpose
Defines system reliability constraints by specifying minimum spinning reserve
requirements for each control area. Critical for ensuring system security and
handling unexpected generator outages.

# Structure
- Each RP record defines a reserve pool with a time window
- Multiple LM records (typically 48 per day) specify half-hourly requirements
- LM records link to RP via codigo_area

# Example
```julia
data = parse_respot("respot.dat")
println("Reserve pools: \$(length(data.rp_records))")
println("Limit records: \$(length(data.lm_records))")

# Find limits for area 1
area1_limits = filter(lm -> lm.codigo_area == 1, data.lm_records)
println("Area 1 has \$(length(area1_limits)) half-hourly limits")
```
"""
Base.@kwdef struct RespotData
    rp_records::Vector{RespotRP} = RespotRP[]
    lm_records::Vector{RespotLM} = RespotLM[]
end

# Export RESPOT types
export RespotRP, RespotLM, RespotData

# ============================================================================
# RESTSEG.DAT (Table constraints) Types
# ============================================================================

"""
    RestsegIndice

Index record for a RESTSEG table constraint block. Maps an index number to a
human-readable description.

# Example
TABSEG INDICE     7 Fluxo Ji-Paraná - Pimenta Bueno em função do back-to-back
"""
Base.@kwdef struct RestsegIndice
    indice::Int
    descricao::String
end

"""
    RestsegTabela

Table descriptor for a RESTSEG block. Defines the controlling and parameter
variables that the table depends on, plus an auxiliary numeric code.

# Example
TABSEG TABELA     7 CONTR  DREF    9004
"""
Base.@kwdef struct RestsegTabela
    indice::Int
    tipo1::String
    tipo2::String
    num::Union{Int,Nothing}
    pcarg::Union{Int,String,Nothing} = nothing
end

"""
    RestsegLimite

A table breakpoint entry (limit value) associated with an index. Multiple
limits form the rows/columns thresholds used in CELULA definitions.

# Example
TABSEG LIMITE     7        800
"""
Base.@kwdef struct RestsegLimite
    indice::Int
    limite::Int
end

"""
    RestsegCelula

Cell definition for a RESTSEG table. Associates a limit value to a range of the
parameter (Par.1) with optional flag column.

# Example
TABSEG CELULA     7        300             700         800
"""
Base.@kwdef struct RestsegCelula
    indice::Int
    limite::Int
    flag::Union{String,Nothing} = nothing
    par1_inf::Union{Int,Nothing} = nothing
    par1_sup::Union{Int,Nothing} = nothing
end

"""
    RestsegData

Container for all RESTSEG records in a file.
"""
Base.@kwdef struct RestsegData
    indices::Vector{RestsegIndice} = RestsegIndice[]
    tabelas::Vector{RestsegTabela} = RestsegTabela[]
    limites::Vector{RestsegLimite} = RestsegLimite[]
    celulas::Vector{RestsegCelula} = RestsegCelula[]
end

export RestsegIndice, RestsegTabela, RestsegLimite, RestsegCelula, RestsegData

# ============================================================================
# RAMPAS.DAT - Thermal Unit Ramp Trajectories
# ============================================================================

"""
    RampasRecord

Thermal unit ramp trajectory point from RAMPAS.DAT.

# Fields
- `usina::Int`: Plant identifier
- `unidade::Int`: Unit identifier
- `configuracao::String`: Configuration type ("S"=Simple, "C"=Combined)
- `tipo::String`: Ramp type ("A"=Ascending/Up, "D"=Descending/Down)
- `potencia::Float64`: Power output (MW)
- `tempo::Int`: Time elapsed (minutes)
- `flag_meia_hora::Int`: Half-hour flag (0 or 1)
"""
Base.@kwdef struct RampasRecord
    usina::Int
    unidade::Int
    configuracao::String
    tipo::String
    potencia::Float64
    tempo::Int
    flag_meia_hora::Int
end

"""
    RampasData

Container for RAMPAS.DAT data (thermal unit ramp trajectories).

# Fields
- `records::Vector{RampasRecord}`: Ramp trajectory points
"""
Base.@kwdef struct RampasData
    records::Vector{RampasRecord} = RampasRecord[]
end

end # module
