"""
ENTDADOS.XXX Parser

Parses the general data file containing system configuration, time discretization,
plant definitions, and demand data.

Record types supported:
- TM: Time discretization
- SIST: Subsystem definition
- UH: Hydroelectric plant configuration
- UT: Thermal plant configuration
- DP: Demand data
"""
module EntdadosParser

using ..Types
using ..ParserCommon

# Import types
import ..Types: TMRecord, SISTRecord, UHRecord, UTRecord, DPRecord, GeneralData

export parse_entdados

# ============================================================================
# Record Parsers
# ============================================================================

"""
    parse_tm(line::AbstractString, filename::AbstractString, line_num::Int) -> TMRecord

Parse TM record (time discretization).

Format columns:
- 1-2: "TM"
- 5-6: day (I2)
- 10-11: hour (I2)
- 15: half_hour (I1)
- 20-24: duration (F5.0)
- 30: network_flag (I1)
- 34-39: load_level (A6)
"""
function parse_tm(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:day, 5, 6, Int),
        FieldSpec(:hour, 10, 11, Int),
        FieldSpec(:half_hour, 15, 15, Int),
        FieldSpec(:duration, 20, 24, Float64),
        FieldSpec(:network_flag, 30, 30, Int),
        FieldSpec(:load_level, 34, 39, String),
    ]
    
    values = extract_fields(line, fields, file=filename, line_num=line_num)
    
    # Validations
    validate_range(values[:hour], 0, 23, "hour", file=filename, line_num=line_num)
    validate_range(values[:half_hour], 0, 1, "half_hour", file=filename, line_num=line_num)
    validate_positive(values[:duration], "duration", file=filename, line_num=line_num)
    validate_range(values[:network_flag], 0, 2, "network_flag", file=filename, line_num=line_num)
    
    return TMRecord(;
        day=values[:day],
        hour=values[:hour],
        half_hour=values[:half_hour],
        duration=values[:duration],
        network_flag=values[:network_flag],
        load_level=values[:load_level] === nothing ? "" : strip(values[:load_level])
    )
end

"""
    parse_sist(line::AbstractString, filename::AbstractString, line_num::Int) -> SISTRecord

Parse SIST record (subsystem definition).

Format columns:
- 1-4: "SIST"
- 8-9: subsystem_num (I2)
- 11-12: subsystem_code (A2)
- 14: status (I1)
- 16-25: subsystem_name (A10)
"""
function parse_sist(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:subsystem_num, 8, 9, Int),
        FieldSpec(:subsystem_code, 11, 12, String),
        FieldSpec(:status, 14, 14, Int),
        FieldSpec(:subsystem_name, 16, 25, String),
    ]
    
    values = extract_fields(line, fields, file=filename, line_num=line_num)
    
    # Validations
    validate_range(values[:subsystem_num], 1, 99, "subsystem_num", file=filename, line_num=line_num)
    
    return SISTRecord(;
        subsystem_num=values[:subsystem_num],
        subsystem_code=strip(values[:subsystem_code]),
        status=values[:status] === nothing ? 0 : values[:status],
        subsystem_name=strip(values[:subsystem_name])
    )
end

"""
    parse_uh(line::AbstractString, filename::AbstractString, line_num::Int) -> UHRecord

Parse UH record (hydroelectric plant configuration).

Format columns (verified against idessem - Python 0-indexed + 1 = Julia 1-indexed):
- 1-2: "UH"
- 5-7: plant_num (I3) - idessem: IntegerField(3, 4) -> Julia columns 5-7
- 10-21: plant_name (A12) - idessem: LiteralField(12, 9) -> Julia columns 10-21
- 25-26: subsystem/REE code (I2) - idessem: IntegerField(2, 24) -> Julia columns 25-26
- 30-39: initial_volume_pct (F10.2) - idessem: FloatField(10, 29, 2) -> Julia columns 30-39
- 40: evaporation flag (I1) - idessem: IntegerField(1, 39) -> Julia column 40
- 42+: StageDateField - idessem: starting_position=41 -> Julia column 42+
- Additional optional fields at 50, 65, 70 per idessem spec
"""
function parse_uh(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:plant_num, 5, 7, Int, required=true),  # IntegerField(3, 4) in idessem
        FieldSpec(:plant_name, 10, 21, String, required=true),  # LiteralField(12, 9)
        FieldSpec(:subsystem, 25, 26, Int, required=true),  # IntegerField(2, 24) - REE code
        FieldSpec(:initial_volume_pct, 30, 39, Float64, required=true),  # FloatField(10, 29, 2)
        FieldSpec(:volume_unit, 40, 40, Int, required=false),  # IntegerField(1, 39) - evaporation
        FieldSpec(:status, 42, 42, String, required=false),  # First char of StageDateField at 41
        FieldSpec(:min_volume, 50, 59, Float64, required=false),  # FloatField(10, 49, 2)
        FieldSpec(:max_volume, 65, 65, Int, required=false),  # IntegerField(1, 64)
        FieldSpec(:initial_volume_abs, 70, 70, Int, required=false),  # IntegerField(1, 69)
        FieldSpec(:spillway_crest, 80, 89, Float64, required=false),
        FieldSpec(:diversion_crest, 95, 104, Float64, required=false),
    ]
    
    values = extract_fields(line, fields, file=filename, line_num=line_num)
    
    # Validations
    validate_range(values[:plant_num], 1, 320, "plant_num", file=filename, line_num=line_num)
    validate_range(values[:initial_volume_pct], 0.0, 200.0, "initial_volume_pct", file=filename, line_num=line_num)
    if values[:volume_unit] !== nothing
        validate_range(values[:volume_unit], 0, 2, "volume_unit", file=filename, line_num=line_num)
    end
    
    # Convert status to Int if present, else use 0
    status_val = if values[:status] === nothing
        0
    else
        val_str = strip(values[:status])
        if isempty(val_str)
            0
        else
            # Try to parse as Int, otherwise map 'I' to 1
            try
                parse(Int, val_str)
            catch
                val_str == "I" ? 1 : 0
            end
        end
    end
    
    return UHRecord(;
        plant_num=values[:plant_num],
        plant_name=strip(values[:plant_name]),
        status=status_val,
        subsystem=values[:subsystem],
        initial_volume_pct=values[:initial_volume_pct],
        volume_unit=values[:volume_unit] === nothing ? 1 : values[:volume_unit],
        min_volume=values[:min_volume],
        max_volume=values[:max_volume],
        initial_volume_abs=values[:initial_volume_abs],
        spillway_crest=values[:spillway_crest],
        diversion_crest=values[:diversion_crest]
    )
end

"""
    parse_ut(line::AbstractString, filename::AbstractString, line_num::Int) -> UTRecord

Parse UT record (thermal plant configuration).

Format columns:
- 1-2: "UT"
- 5-7: plant_num (I3)
- 10-21: plant_name (A12)
- 25: status (I1)
- 27: subsystem (I1)
- 29-30: start_day (I2)
- 32-33: start_hour (I2)
- 35: start_half (I1)
- 37: end_marker (A1) - usually "F"
- 45-54: max_generation (F10.0) - installed capacity
- 60-69: min_generation (F10.0) - minimum generation
"""
function parse_ut(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:plant_num, 5, 7, Int),
        FieldSpec(:plant_name, 10, 21, String),
        FieldSpec(:status, 24, 24, Int),
        FieldSpec(:subsystem, 26, 26, Int),
        FieldSpec(:start_day, 28, 29, Int),
        FieldSpec(:start_hour, 32, 32, Int),
        FieldSpec(:start_half, 34, 34, Int),
        FieldSpec(:end_marker, 37, 37, String),
        FieldSpec(:min_generation, 47, 56, Float64),  # First numeric field - minimum generation (right-aligned, 10 chars)
        FieldSpec(:max_generation, 58, 67, Float64),  # Second numeric field - maximum generation (right-aligned, 10 chars)
    ]
    
    values = extract_fields(line, fields, file=filename, line_num=line_num)
    
    # Validations
    validate_range(values[:plant_num], 1, 999, "plant_num", file=filename, line_num=line_num)
    if values[:start_hour] !== nothing
        validate_range(values[:start_hour], 0, 23, "start_hour", file=filename, line_num=line_num)
    end
    if values[:start_half] !== nothing
        validate_range(values[:start_half], 0, 1, "start_half", file=filename, line_num=line_num)
    end
    if values[:min_generation] !== nothing
        validate_nonnegative(values[:min_generation], "min_generation", file=filename, line_num=line_num)
    end
    if values[:max_generation] !== nothing
        # Allow zero max_generation for offline/unavailable units in real data
        validate_nonnegative(values[:max_generation], "max_generation", file=filename, line_num=line_num)
    end
    
    return UTRecord(;
        plant_num=values[:plant_num],
        plant_name=strip(values[:plant_name]),
        status=values[:status],
        subsystem=values[:subsystem],
        start_day=values[:start_day],
        start_hour=values[:start_hour],
        start_half=values[:start_half],
        end_marker=strip(values[:end_marker]),
        min_generation=something(values[:min_generation], 0.0),
        max_generation=something(values[:max_generation], 0.0)  # Default to 0.0 for blank/offline units
    )
end

"""
    parse_dp(line::AbstractString, filename::AbstractString, line_num::Int) -> DPRecord

Parse DP record (demand data).

Format columns (verified against idessem and actual data):
- 1-2: "DP"
- 5-6: subsystem (I2) - idessem: IntegerField(2, 4) -> Julia columns 5-6
- 9-10: start_day (I2)
- 13: start_hour (I1-2)
- 15: start_half (I1)
- 18-19: end_day (I2 or 'F')
- 21-22: end_hour (I2)
- 24: end_half (I1)
- 25-34: demand (F10.1) - idessem: FloatField(10, 24, 1) -> Julia columns 25-34
"""
function parse_dp(line::AbstractString, filename::AbstractString, line_num::Int)
    # Parse subsystem (columns 5-6, 2 digits) - IntegerField(2, 4) in idessem
    subsystem_str = strip(extract_field(line, 5, 6))
    subsystem = parse_int(subsystem_str)
    
    # Parse start time
    start_day = parse_int(strip(extract_field(line, 9, 10)))
    start_hour = parse_int(strip(extract_field(line, 13, 13)), allow_blank=true)
    start_half = parse_int(strip(extract_field(line, 15, 15)), allow_blank=true)
    
    # Parse end time
    # First check for 'F' marker at position 18
    end_day_str = strip(extract_field(line, 18, 19))
    end_day = if end_day_str == "F" || end_day_str == "f"
        "F"
    elseif isempty(end_day_str)
        nothing
    else
        parse_int(end_day_str, allow_blank=true)
    end
    
    end_hour = parse_int(strip(extract_field(line, 21, 22)), allow_blank=true)
    end_half = parse_int(strip(extract_field(line, 24, 24)), allow_blank=true)
    
    # Parse demand (columns 25-34, F10 with decimals) - FloatField(10, 24, 1) in idessem
    demand = parse_float(strip(extract_field(line, 25, 34)))
    
    # Validations - handle optional fields
    if start_hour !== nothing
        validate_range(start_hour, 0, 23, "start_hour", file=filename, line_num=line_num)
    end
    if start_half !== nothing
        validate_range(start_half, 0, 1, "start_half", file=filename, line_num=line_num)
    end
    if end_hour !== nothing
        validate_range(end_hour, 0, 23, "end_hour", file=filename, line_num=line_num)
    end
    if end_half !== nothing
        validate_range(end_half, 0, 1, "end_half", file=filename, line_num=line_num)
    end
    validate_nonnegative(demand, "demand", file=filename, line_num=line_num)
    
    return DPRecord(;
        subsystem=subsystem,
        start_day=start_day,
        start_hour=start_hour === nothing ? 0 : start_hour,
        start_half=start_half === nothing ? 0 : start_half,
        end_day=end_day,
        end_hour=end_hour === nothing ? 0 : end_hour,
        end_half=end_half === nothing ? 0 : end_half,
        demand=demand
    )
end

# ============================================================================
# Main Parser
# ============================================================================

"""
    parse_entdados(filepath::AbstractString) -> GeneralData

Parse ENTDADOS.XXX file and return GeneralData structure.

Processes TM, SIST, UH, UT, and DP records. Skips unknown record types with warning.
"""
function parse_entdados(filepath::AbstractString)
    filename = basename(filepath)
    open(filepath, "r") do io
        parse_entdados(io, filename)
    end
end

"""
    parse_entdados(io::IO, filename::AbstractString="entdados.dat") -> GeneralData

Parse ENTDADOS data from an IO stream and return GeneralData structure.

Processes TM, SIST, UH, UT, and DP records. Skips unknown record types with warning.
"""
function parse_entdados(io::IO, filename::AbstractString="entdados.dat")
    time_periods = TMRecord[]
    subsystems = SISTRecord[]
    hydro_plants = UHRecord[]
    thermal_plants = UTRecord[]
    demands = DPRecord[]
    
    line_num = 0
    for line in eachline(io)
        line_num += 1
        
        # Skip blank lines and comments
        is_blank(line) && continue
        is_comment_line(line) && continue
        
        # Extract record type
        record_type = uppercase(strip(extract_field(line, 1, 4)))
        
        try
            if record_type == "TM"
                push!(time_periods, parse_tm(line, filename, line_num))
            elseif record_type == "SIST"
                push!(subsystems, parse_sist(line, filename, line_num))
            elseif record_type == "UH"
                push!(hydro_plants, parse_uh(line, filename, line_num))
            elseif record_type == "UT"
                push!(thermal_plants, parse_ut(line, filename, line_num))
            elseif record_type == "DP"
                push!(demands, parse_dp(line, filename, line_num))
            else
                # Skip unknown record types (RD, RIVAR, REE, etc.)
                if !startswith(record_type, "&")  # Don't warn for comment lines
                    @warn "Unknown record type in $filename line $line_num: $record_type"
                end
            end
        catch e
            if isa(e, ParserError)
                rethrow(e)
            else
                throw(ParserError("Error parsing $record_type record: $(e)", filename, line_num, line))
            end
        end
    end
    
    return GeneralData(;
        time_periods=time_periods,
        subsystems=subsystems,
        hydro_plants=hydro_plants,
        thermal_plants=thermal_plants,
        demands=demands
    )
end

end # module
