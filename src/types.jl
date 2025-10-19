module Types

using Dates

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
    commission_year::Union{Int, Nothing} = nothing
    commission_month::Union{Int, Nothing} = nothing
    commission_day::Union{Int, Nothing} = nothing
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
    unit_name::Union{String, Nothing} = nothing
    commission_year::Union{Int, Nothing} = nothing
    commission_month::Union{Int, Nothing} = nothing
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
    min_volume::Union{Float64, Nothing} = nothing
    max_volume::Union{Float64, Nothing} = nothing
    initial_volume_abs::Union{Float64, Nothing} = nothing
    spillway_crest::Union{Float64, Nothing} = nothing
    diversion_crest::Union{Float64, Nothing} = nothing
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
    end_day::Union{Int, String}
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
    start_day::Union{Int, String, Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int, String, Nothing}
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
    start_day::Union{Int, String, Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int, String, Nothing}
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
    start_day::Union{Int, String, Nothing}
    start_hour::Int = 0
    start_half::Int = 0
    end_day::Union{Int, String, Nothing}
    end_hour::Int = 0
    end_half::Int = 0
    available_flag::Int = 0
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
"""
Base.@kwdef struct GeneralData
    time_periods::Vector{TMRecord} = TMRecord[]
    subsystems::Vector{SISTRecord} = SISTRecord[]
    hydro_plants::Vector{UHRecord} = UHRecord[]
    thermal_plants::Vector{UTRecord} = UTRecord[]
    demands::Vector{DPRecord} = DPRecord[]
    diversions::Vector{DARecord} = DARecord[]
    hydro_maintenance::Vector{MHRecord} = MHRecord[]
    thermal_maintenance::Vector{MTRecord} = MTRecord[]
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
    start_day::Union{Int, String}
    start_hour::Union{Int, Nothing} = nothing
    start_half_hour::Union{Int, Nothing} = nothing
    end_day::Union{Int, String}
    end_hour::Union{Int, Nothing} = nothing
    end_half_hour::Union{Int, Nothing} = nothing
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
    metadata::Dict{String, Any} = Dict{String, Any}()
end

# ============================================================================
# Hydro Operational Constraints (OPERUH.DAT) Types
# ============================================================================

"""
    HydroConstraintREST

Hydro constraint definition record from OPERUH.DAT.

# Fields
- `constraint_id::Int`: Unique constraint identifier
- `type_flag::String`: Constraint type (L=limit, V=variation)
- `variable_code::String`: Variable being constrained (RHQ=flow, RHV=volume, etc.)
- `initial_value::Union{Float64, Nothing}`: Initial value for variation constraints
"""
Base.@kwdef struct HydroConstraintREST
    constraint_id::Int
    type_flag::String
    variable_code::String
    initial_value::Union{Float64, Nothing} = nothing
end

"""
    HydroConstraintELEM

Hydro constraint element (plant participation) record from OPERUH.DAT.

# Fields
- `constraint_id::Int`: Constraint identifier (links to REST record)
- `plant_num::Int`: Hydroelectric plant number
- `plant_name::String`: Plant name
- `variable_code::Int`: Variable code (1-65, see documentation)
- `participation_factor::Float64`: Plant's participation factor in constraint
"""
Base.@kwdef struct HydroConstraintELEM
    constraint_id::Int
    plant_num::Int
    plant_name::String
    variable_code::Int
    participation_factor::Float64
end

"""
    HydroConstraintLIM

Hydro operational limits record from OPERUH.DAT.

# Fields
- `constraint_id::Int`: Constraint identifier (links to REST record)
- `start_day::String`: Initial day (I=initial, F=final, or day number)
- `start_hour::Union{Int, Nothing}`: Initial hour (0-23)
- `start_half::Union{Int, Nothing}`: Initial half-hour (0-1)
- `end_day::String`: Final day (F=final or day number)
- `end_hour::Union{Int, Nothing}`: Final hour (0-23)
- `end_half::Union{Int, Nothing}`: Final half-hour (0-1)
- `lower_limit::Union{Float64, Nothing}`: Lower bound
- `upper_limit::Union{Float64, Nothing}`: Upper bound
"""
Base.@kwdef struct HydroConstraintLIM
    constraint_id::Int
    start_day::String
    start_hour::Union{Int, Nothing} = nothing
    start_half::Union{Int, Nothing} = nothing
    end_day::String
    end_hour::Union{Int, Nothing} = nothing
    end_half::Union{Int, Nothing} = nothing
    lower_limit::Union{Float64, Nothing} = nothing
    upper_limit::Union{Float64, Nothing} = nothing
end

"""
    HydroConstraintVAR

Hydro variation/ramp constraint record from OPERUH.DAT.

# Fields
- `constraint_id::Int`: Constraint identifier
- `start_day::String`: Initial day
- `start_hour::Union{Int, Nothing}`: Initial hour (0-23)
- `start_half::Union{Int, Nothing}`: Initial half-hour (0-1)
- `end_day::String`: Final day
- `end_hour::Union{Int, Nothing}`: Final hour (0-23)
- `end_half::Union{Int, Nothing}`: Final half-hour (0-1)
- `lower_ramp::Union{Float64, Nothing}`: Lower ramp limit
- `upper_ramp::Union{Float64, Nothing}`: Upper ramp limit
"""
Base.@kwdef struct HydroConstraintVAR
    constraint_id::Int
    start_day::String
    start_hour::Union{Int, Nothing} = nothing
    start_half::Union{Int, Nothing} = nothing
    end_day::String
    end_hour::Union{Int, Nothing} = nothing
    end_half::Union{Int, Nothing} = nothing
    lower_ramp::Union{Float64, Nothing} = nothing
    upper_ramp::Union{Float64, Nothing} = nothing
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
"""
Base.@kwdef struct OperutData
    init_records::Vector{INITRecord} = INITRecord[]
    oper_records::Vector{OPERRecord} = OPERRecord[]
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
    files::Dict{String, Any} = Dict{String, Any}()
    metadata::Dict{String, Any} = Dict{String, Any}()
end

end # module
