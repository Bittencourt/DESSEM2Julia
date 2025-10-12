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
    ThermalRegistry

Container for all thermal plant registry data from TERM.DAT.

# Fields
- `plants::Vector{CADUSIT}`: All CADUSIT plant records
- `units::Vector{CADUNIDT}`: All CADUNIDT unit records
- `heat_curves::Vector{CURVACOMB}`: All CURVACOMB heat rate curve points
"""
Base.@kwdef struct ThermalRegistry
    plants::Vector{CADUSIT} = CADUSIT[]
    units::Vector{CADUNIDT} = CADUNIDT[]
    heat_curves::Vector{CURVACOMB} = CURVACOMB[]
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
