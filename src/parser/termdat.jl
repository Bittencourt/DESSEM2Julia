"""
Parser for TERM.DAT (Thermal Plant Registry) files.

This module parses thermal plant registry data including:
- CADUSIT: Plant information
- CADUNIDT: Unit characteristics  
- CURVACOMB: Heat rate curves
"""
module TermdatParser

using ..ParserCommon
using ..Types: CADUSIT, CADUNIDT, CURVACOMB, CADCONF, CADMIN, ThermalRegistry
using Dates

export parse_termdat

# ============================================================================
# Parser Functions
# ============================================================================

"""
    parse_cadusit(line::AbstractString, file::String, line_num::Int) -> CADUSIT

Parse a CADUSIT record (thermal plant information).

# Format
Columns 1-7: Record type "CADUSIT"
Columns 9-11: Plant number
Columns 13-24: Plant name
Columns 26-27: Subsystem
Columns 29-32: Commission year
Columns 34-35: Commission month
Columns 37-38: Commission day
Column 40: Plant class
Column 42: Fuel type
Columns 44-46: Number of units
Columns 48-57: Heat rate (kJ/kWh)
Columns 59-63: Fuel cost (BRL/unit)
"""
function parse_cadusit(line::AbstractString, file::String, line_num::Int)
    # Note: Actual format differs from documentation
    # Documentation says num_units at 44-46, but real files have it at 44-48 (right-aligned)
    # Optional fields (heat_rate, fuel_cost) may or may not be present depending on file version

    # Base fields always present
    specs = [
        FieldSpec(:record_type, 1, 7, String; required = true),
        FieldSpec(:plant_num, 9, 11, Int; required = true),
        FieldSpec(:plant_name, 13, 24, String; required = true),
        FieldSpec(:subsystem, 26, 27, Int; required = true),
        FieldSpec(:commission_year, 29, 32, Int),
        FieldSpec(:commission_month, 34, 35, Int),
        FieldSpec(:commission_day, 37, 38, Int),
        FieldSpec(:plant_class, 40, 40, Int; default = 0),
        FieldSpec(:fuel_type, 42, 42, Int; default = 0),
        FieldSpec(:num_units, 44, 48, Int; required = true),  # Right-aligned in columns 44-48
    ]

    # Optional fields only if line is long enough
    if length(line) >= 57
        push!(specs, FieldSpec(:heat_rate, 48, 57, Float64; default = 0.0))
    end
    if length(line) >= 63
        push!(specs, FieldSpec(:fuel_cost, 59, 63, Float64; default = 0.0))
    end

    data = extract_fields(line, specs, file = file, line_num = line_num)

    # Validate record type
    if data.record_type != "CADUSIT"
        throw(
            ParserError(
                "Expected CADUSIT record, got $(data.record_type)",
                file,
                line_num,
                line,
            ),
        )
    end

    # Validate plant number
    validate_range(data.plant_num, 1, 999, "plant_num", file = file, line_num = line_num)

    # Validate subsystem
    validate_positive(data.subsystem, "subsystem", file = file, line_num = line_num)

    # Validate number of units
    validate_range(data.num_units, 1, 120, "num_units", file = file, line_num = line_num)

    # Validate optional fields
    if !isnothing(data.commission_month)
        validate_range(data.commission_month, 1, 12, "commission_month", file = file, line_num = line_num)
    end
    if !isnothing(data.commission_day)
        validate_range(data.commission_day, 1, 31, "commission_day", file = file, line_num = line_num)
    end

    # Validate optional numeric fields if present
    heat_rate = hasfield(typeof(data), :heat_rate) ? data.heat_rate : 0.0
    fuel_cost = hasfield(typeof(data), :fuel_cost) ? data.fuel_cost : 0.0

    if heat_rate != 0.0
        validate_positive(heat_rate, "heat_rate", file = file, line_num = line_num)
    end
    validate_nonnegative(fuel_cost, "fuel_cost", file = file, line_num = line_num)

    return CADUSIT(
        plant_num = data.plant_num,
        plant_name = data.plant_name,
        subsystem = data.subsystem,
        commission_year = data.commission_year,
        commission_month = data.commission_month,
        commission_day = data.commission_day,
        plant_class = data.plant_class,
        fuel_type = data.fuel_type,
        num_units = data.num_units,
        heat_rate = heat_rate,
        fuel_cost = fuel_cost,
    )
end

"""
    parse_cadunidt(line::AbstractString, file::String, line_num::Int) -> CADUNIDT

Parse a CADUNIDT record (thermal unit characteristics).

# Format (Actual format in sample files - differs from documentation)
Columns 1-8: Record type "CADUNIDT"
Columns 10-12: Plant number
Columns 14-16: Unit number
Columns 17-20: Commission year (4 digits, not 2!)
Columns 22-23: Commission month
Columns 25-26: Commission day
Columns 28-29: Commission hour
Columns 31: Unit class/status code
Columns 33-43: Unit capacity (MW)
Columns 45-54: Minimum generation (MW)
Columns 56-60: Minimum on time (hours)
Columns 62-66: Minimum off time (hours)
# Optional fields (may not be present in all files):
Columns 63-72: Cold startup cost
Columns 74-83: Hot startup cost
Columns 85-94: Shutdown cost
Columns 96-105: Ramp up rate
Columns 107-116: Ramp down rate
"""
function parse_cadunidt(line::AbstractString, file::String, line_num::Int)
    # Base fields always present in sample files
    specs = [
        FieldSpec(:record_type, 1, 8, String; required = true),
        FieldSpec(:plant_num, 10, 12, Int; required = true),
        FieldSpec(:unit_num, 14, 16, Int; required = true),
        FieldSpec(:commission_year, 17, 20, Int),
        FieldSpec(:commission_month, 22, 23, Int),
        FieldSpec(:commission_day, 25, 26, Int),
        FieldSpec(:commission_hour, 28, 29, Int),
        FieldSpec(:unit_class, 31, 31, Int; default = 0),
        FieldSpec(:unit_capacity, 33, 43, Float64; required = true),
        FieldSpec(:min_generation, 45, 54, Float64; default = 0.0),
        FieldSpec(:min_on_time, 56, 60, Int; default = 0),
        FieldSpec(:min_off_time, 62, 66, Int; default = 0),
    ]

    # Optional fields only if line extends beyond basic format (>70 chars suggests extended format)
    # Note: Sample files are 66 chars; documentation shows extended format with more fields
    if length(line) > 70
        push!(specs, FieldSpec(:cold_startup_cost, 68, 77, Float64; default = 0.0))
        if length(line) >= 85
            push!(specs, FieldSpec(:hot_startup_cost, 79, 88, Float64; default = 0.0))
        end
        if length(line) >= 96
            push!(specs, FieldSpec(:shutdown_cost, 90, 99, Float64; default = 0.0))
        end
        if length(line) >= 107
            push!(specs, FieldSpec(:ramp_up_rate, 101, 110, Float64; default = Inf))
        end
        if length(line) >= 118
            push!(specs, FieldSpec(:ramp_down_rate, 112, 121, Float64; default = Inf))
        end
    end

    data = extract_fields(line, specs, file = file, line_num = line_num)

    # Validate record type
    if data.record_type != "CADUNIDT"
        throw(
            ParserError(
                "Expected CADUNIDT record, got $(data.record_type)",
                file,
                line_num,
                line,
            ),
        )
    end

    # Validate plant and unit numbers
    validate_range(data.plant_num, 1, 999, "plant_num", file = file, line_num = line_num)
    validate_range(data.unit_num, 1, 120, "unit_num", file = file, line_num = line_num)

    # Validate capacity and generation
    validate_positive(data.unit_capacity, "unit_capacity", file = file, line_num = line_num)
    validate_nonnegative(data.min_generation, "min_generation", file = file, line_num = line_num)

    if data.min_generation > data.unit_capacity
        throw(
            ParserError(
                "Minimum generation ($(data.min_generation) MW) exceeds unit capacity ($(data.unit_capacity) MW)",
                file,
                line_num,
                line,
            ),
        )
    end

    # Validate time constraints
    validate_nonnegative(data.min_on_time, "min_on_time", file = file, line_num = line_num)
    validate_nonnegative(data.min_off_time, "min_off_time", file = file, line_num = line_num)

    # Validate optional fields if present
    if !isnothing(data.commission_month)
        validate_range(data.commission_month, 1, 12, "commission_month", file = file, line_num = line_num)
    end
    if !isnothing(data.commission_day)
        validate_range(data.commission_day, 1, 31, "commission_day", file = file, line_num = line_num)
    end
    if !isnothing(data.commission_hour)
        validate_range(data.commission_hour, 0, 23, "commission_hour", file = file, line_num = line_num)
    end

    # Extract optional fields with defaults if not present
    cold_startup_cost =
        hasfield(typeof(data), :cold_startup_cost) ? data.cold_startup_cost : 0.0
    hot_startup_cost =
        hasfield(typeof(data), :hot_startup_cost) ? data.hot_startup_cost : 0.0
    shutdown_cost = hasfield(typeof(data), :shutdown_cost) ? data.shutdown_cost : 0.0
    ramp_up_rate = hasfield(typeof(data), :ramp_up_rate) ? data.ramp_up_rate : Inf
    ramp_down_rate = hasfield(typeof(data), :ramp_down_rate) ? data.ramp_down_rate : Inf

    # Validate costs if present
    validate_nonnegative(cold_startup_cost, "cold_startup_cost", file = file, line_num = line_num)
    validate_nonnegative(hot_startup_cost, "hot_startup_cost", file = file, line_num = line_num)
    validate_nonnegative(shutdown_cost, "shutdown_cost", file = file, line_num = line_num)

    # Validate ramp rates if not infinite
    if !isinf(ramp_up_rate)
        validate_nonnegative(ramp_up_rate, "ramp_up_rate", file = file, line_num = line_num)
    end
    if !isinf(ramp_down_rate)
        validate_nonnegative(ramp_down_rate, "ramp_down_rate", file = file, line_num = line_num)
    end

    return CADUNIDT(
        plant_num = data.plant_num,
        unit_num = data.unit_num,
        commission_year = data.commission_year,
        commission_month = data.commission_month,
        unit_capacity = data.unit_capacity,
        min_generation = data.min_generation,
        min_on_time = data.min_on_time,
        min_off_time = data.min_off_time,
        cold_startup_cost = cold_startup_cost,
        hot_startup_cost = hot_startup_cost,
        shutdown_cost = shutdown_cost,
        ramp_up_rate = ramp_up_rate,
        ramp_down_rate = ramp_down_rate,
    )
end

"""
    parse_curvacomb(line::AbstractString, file::String, line_num::Int) -> CURVACOMB

Parse a CURVACOMB record (heat rate curve point).

# Format
Columns 1-9: Record type "CURVACOMB"
Columns 11-13: Plant number
Columns 15-17: Unit number
Columns 19-23: Heat rate (kJ/kWh)
Columns 25-34: Generation point (MW)
"""
function parse_curvacomb(line::AbstractString, file::String, line_num::Int)
    specs = [
        FieldSpec(:record_type, 1, 9, String; required = true),
        FieldSpec(:plant_num, 11, 13, Int; required = true),
        FieldSpec(:unit_num, 15, 17, Int; required = true),
        FieldSpec(:heat_rate, 19, 23, Int; required = true),
        FieldSpec(:generation, 25, 34, Float64; required = true),
    ]

    data = extract_fields(line, specs, file = file, line_num = line_num)

    # Validate record type
    if data.record_type != "CURVACOMB"
        throw(
            ParserError(
                "Expected CURVACOMB record, got $(data.record_type)",
                file,
                line_num,
                line,
            ),
        )
    end

    # Validate identifiers
    validate_range(data.plant_num, 1, 999, "plant_num"; file = file, line_num = line_num, line = line)
    validate_range(data.unit_num, 1, 120, "unit_num"; file = file, line_num = line_num, line = line)

    # Validate heat rate and generation
    validate_positive(data.heat_rate, "heat_rate"; file = file, line_num = line_num, line = line)
    validate_nonnegative(data.generation, "generation"; file = file, line_num = line_num, line = line)

    return CURVACOMB(
        plant_num = data.plant_num,
        unit_num = data.unit_num,
        heat_rate = data.heat_rate,
        generation = data.generation,
    )
end

"""
    parse_cadconf(line, file, line_num) -> CADCONF

Parse a CADCONF record (combined-cycle configuration membership).
"""
function parse_cadconf(line::AbstractString, file::String, line_num::Int)
    parts = split(line)

    if isempty(parts)
        throw(ParserError("Empty CADCONF record", file, line_num, line))
    end

    record_type = parts[1]

    if record_type != "CADCONF"
        throw(
            ParserError(
                "Expected CADCONF record, got $(record_type)",
                file,
                line_num,
                line,
            ),
        )
    end

    if length(parts) < 4
        throw(
            ParserError(
                "CADCONF record must include plant, configuration, and unit identifiers",
                file,
                line_num,
                line,
            ),
        )
    end

    plant_num = try
        parse_int(parts[2])
    catch err
        throw(
            ParserError(
                "Invalid plant number in CADCONF record: $(parts[2])",
                file,
                line_num,
                line,
            ),
        )
    end

    configuration = try
        parse_int(parts[3])
    catch err
        throw(
            ParserError(
                "Invalid configuration number in CADCONF record: $(parts[3])",
                file,
                line_num,
                line,
            ),
        )
    end

    unit_num = try
        parse_int(parts[4])
    catch err
        throw(
            ParserError(
                "Invalid unit number in CADCONF record: $(parts[4])",
                file,
                line_num,
                line,
            ),
        )
    end

    validate_range(plant_num, 1, 999, "plant_num")
    validate_range(configuration, 1, 999, "configuration")
    validate_range(unit_num, 1, 999, "unit_num")

    return CADCONF(
        plant_num = plant_num,
        configuration = configuration,
        unit_num = unit_num,
    )
end

"""
    parse_cadmin(line, file, line_num) -> CADMIN

Parse a CADMIN record (simple-cycle dependent configuration membership).
"""
function parse_cadmin(line::AbstractString, file::String, line_num::Int)
    parts = split(line)

    if isempty(parts)
        throw(ParserError("Empty CADMIN record", file, line_num, line))
    end

    record_type = parts[1]

    if record_type != "CADMIN"
        throw(
            ParserError("Expected CADMIN record, got $(record_type)", file, line_num, line),
        )
    end

    if length(parts) < 4
        throw(
            ParserError(
                "CADMIN record must include plant, configuration, and unit identifiers",
                file,
                line_num,
                line,
            ),
        )
    end

    plant_num = try
        parse_int(parts[2])
    catch err
        throw(
            ParserError(
                "Invalid plant number in CADMIN record: $(parts[2])",
                file,
                line_num,
                line,
            ),
        )
    end

    configuration = try
        parse_int(parts[3])
    catch err
        throw(
            ParserError(
                "Invalid configuration number in CADMIN record: $(parts[3])",
                file,
                line_num,
                line,
            ),
        )
    end

    unit_num = try
        parse_int(parts[4])
    catch err
        throw(
            ParserError(
                "Invalid unit number in CADMIN record: $(parts[4])",
                file,
                line_num,
                line,
            ),
        )
    end

    validate_range(plant_num, 1, 999, "plant_num")
    validate_range(configuration, 1, 999, "configuration")
    validate_range(unit_num, 1, 999, "unit_num")

    return CADMIN(plant_num = plant_num, configuration = configuration, unit_num = unit_num)
end

"""
    parse_termdat(filepath::AbstractString) -> ThermalRegistry

Parse a TERM.DAT file and return a ThermalRegistry object.

# Arguments
- `filepath`: Path to the TERM.DAT file

# Returns
- `ThermalRegistry`: Container with all parsed thermal plant data

# Example
```julia
registry = parse_termdat("termdat.dat")
println("Parsed ", length(registry.plants), " plants")
println("Parsed ", length(registry.units), " units")
```
"""
function parse_termdat(filepath::AbstractString)
    plants = CADUSIT[]
    units = CADUNIDT[]
    heat_curves = CURVACOMB[]
    combined_configs = CADCONF[]
    simple_configs = CADMIN[]

    filename = basename(filepath)
    lines = read_nonblank_lines(filepath, skip_comments = true)

    for (line_num, line) in enumerate(lines)
        # Determine record type from first word
        # CADUSIT is 7 chars, CADUNIDT is 8 chars, CURVACOMB is 9 chars
        record_type = strip(extract_field(line, 1, 9))

        try
            if startswith(record_type, "CADUSIT")
                push!(plants, parse_cadusit(line, filename, line_num))
            elseif startswith(record_type, "CADUNIDT")
                push!(units, parse_cadunidt(line, filename, line_num))
            elseif startswith(record_type, "CURVACOMB")
                push!(heat_curves, parse_curvacomb(line, filename, line_num))
            elseif startswith(record_type, "CADCONF")
                push!(combined_configs, parse_cadconf(line, filename, line_num))
            elseif startswith(record_type, "CADMIN")
                push!(simple_configs, parse_cadmin(line, filename, line_num))
            elseif startswith(record_type, "CONFGEST") ||
                   startswith(record_type, "RESTRICOES")
                # These record types not yet implemented - skip for now
                continue
            else
                # Unknown record type - could be a comment or future record type
                # Log warning but don't fail
                @warn "Unknown record type in $filename line $line_num: $record_type"
            end
        catch e
            if e isa ParserError
                # Re-throw parser errors as-is
                rethrow(e)
            else
                # Wrap other errors with context
                throw(
                    ParserError(
                        "Error parsing $record_type record: $(sprint(showerror, e))",
                        filename,
                        line_num,
                        line,
                    ),
                )
            end
        end
    end

    return ThermalRegistry(
        plants = plants,
        units = units,
        heat_curves = heat_curves,
        combined_cycle_configs = combined_configs,
        simple_cycle_configs = simple_configs,
    )
end

end # module
