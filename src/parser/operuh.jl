"""
Parser for OPERUH.DAT (Hydro Operational Constraints)

This file defines time-varying operational constraints for hydroelectric plants.
Format: Block structure with REST (restriction), LIM (limits), VAR (variation), and ELEM (element) records.

References:
- DESSEM Manual v19.0.24.3, Section III.8
- docs/dessem-complete-specs.md: Hydro Operational Constraints (OPERUH.XXX)
"""

module OperuhParser

using ..ParserCommon: extract_field, parse_int, parse_float, parse_string, is_blank, is_comment_line
using ..Types: HydroConstraintREST, HydroConstraintELEM, HydroConstraintLIM, HydroConstraintVAR, OperuhData

export parse_operuh

# ============================================================================
# Record Parsers
# ============================================================================

function parse_rest_record(line::AbstractString)::Union{HydroConstraintREST, Nothing}
    """Parse OPERUH REST record (constraint definition)"""
    try
        constraint_id = parse_int(strip(extract_field(line, 14, 18)))
        type_flag = strip(extract_field(line, 20, 21))
        variable_code = strip(extract_field(line, 23, 26))
        initial_value = parse_float(strip(extract_field(line, 40, 49)), allow_blank=true)
        
        return HydroConstraintREST(
            constraint_id = constraint_id,
            type_flag = type_flag,
            variable_code = variable_code,
            initial_value = initial_value
        )
    catch e
        @warn "Failed to parse OPERUH REST record" line exception=e
        return nothing
    end
end

function parse_elem_record(line::AbstractString)::Union{HydroConstraintELEM, Nothing}
    """Parse OPERUH ELEM record (plant participation in constraint)"""
    try
        # Split by whitespace - format: OPERUH ELEM <id> <plant_num> <plant_name> <var_code> <factor>
        parts = split(line)
        if length(parts) < 6
            @warn "ELEM record has too few fields" line
            return nothing
        end
        
        constraint_id = parse_int(parts[3])
        plant_num = parse_int(parts[4])
        plant_name = parts[5]  # May be multiple words
        # Last two fields are variable code and factor
        variable_code = parse_int(parts[end-1])
        participation_factor = parse_float(parts[end])
        
        return HydroConstraintELEM(
            constraint_id = constraint_id,
            plant_num = plant_num,
            plant_name = plant_name,
            variable_code = variable_code,
            participation_factor = participation_factor
        )
    catch e
        @warn "Failed to parse OPERUH ELEM record" line exception=e
        return nothing
    end
end

function parse_lim_record(line::AbstractString)::Union{HydroConstraintLIM, Nothing}
    """Parse OPERUH LIM record (operational limits)"""
    try
        constraint_id = parse_int(strip(extract_field(line, 14, 18)))
        start_day = strip(extract_field(line, 20, 21))
        start_hour = parse_int(strip(extract_field(line, 23, 24)), allow_blank=true)
        start_half = parse_int(strip(extract_field(line, 26, 26)), allow_blank=true)
        end_day = strip(extract_field(line, 28, 29))
        end_hour = parse_int(strip(extract_field(line, 31, 32)), allow_blank=true)
        end_half = parse_int(strip(extract_field(line, 34, 34)), allow_blank=true)
        lower_limit = parse_float(strip(extract_field(line, 38, 47)), allow_blank=true)
        upper_limit = parse_float(strip(extract_field(line, 48, 57)), allow_blank=true)
        
        return HydroConstraintLIM(
            constraint_id = constraint_id,
            start_day = start_day,
            start_hour = start_hour,
            start_half = start_half,
            end_day = end_day,
            end_hour = end_hour,
            end_half = end_half,
            lower_limit = lower_limit,
            upper_limit = upper_limit
        )
    catch e
        @warn "Failed to parse OPERUH LIM record" line exception=e
        return nothing
    end
end

function parse_var_record(line::AbstractString)::Union{HydroConstraintVAR, Nothing}
    """Parse OPERUH VAR record (variation/ramp constraints)"""
    try
        constraint_id = parse_int(strip(extract_field(line, 14, 18)))
        start_day = strip(extract_field(line, 20, 21))
        start_hour = parse_int(strip(extract_field(line, 23, 24)), allow_blank=true)
        start_half = parse_int(strip(extract_field(line, 26, 26)), allow_blank=true)
        end_day = strip(extract_field(line, 28, 29))
        end_hour = parse_int(strip(extract_field(line, 31, 32)), allow_blank=true)
        end_half = parse_int(strip(extract_field(line, 34, 34)), allow_blank=true)
        lower_ramp = parse_float(strip(extract_field(line, 59, 68)), allow_blank=true)
        upper_ramp = parse_float(strip(extract_field(line, 69, 78)), allow_blank=true)
        
        return HydroConstraintVAR(
            constraint_id = constraint_id,
            start_day = start_day,
            start_hour = start_hour,
            start_half = start_half,
            end_day = end_day,
            end_hour = end_hour,
            end_half = end_half,
            lower_ramp = lower_ramp,
            upper_ramp = upper_ramp
        )
    catch e
        @warn "Failed to parse OPERUH VAR record" line exception=e
        return nothing
    end
end

# ============================================================================
# Main Parser
# ============================================================================

"""
    parse_operuh(filepath::AbstractString) -> OperuhData

Parse OPERUH.DAT file and return OperuhData structure.

# Arguments
- `filepath`: Path to OPERUH.DAT file

# Returns
- `OperuhData` containing all hydro operational constraints

# Example
```julia
constraints = parse_operuh("path/to/operuh.dat")
println("Total REST records: ", length(constraints.rest_records))
println("Total constraints: ", length(constraints.lim_records))
```
"""
function parse_operuh(filepath::AbstractString)
    return open(filepath, "r") do io
        parse_operuh(io, filepath)
    end
end

"""
    parse_operuh(io::IO, filename::AbstractString="operuh.dat") -> OperuhData

Parse OPERUH data from an IO stream and return OperuhData structure.
"""
function parse_operuh(io::IO, filename::AbstractString="operuh.dat")
    rest_records = HydroConstraintREST[]
    elem_records = HydroConstraintELEM[]
    lim_records = HydroConstraintLIM[]
    var_records = HydroConstraintVAR[]
    
    line_num = 0
    
    for line in eachline(io)
        line_num += 1
        
        # Skip blank lines and comments
        if is_blank(line) || is_comment_line(line)
            continue
        end
        
        # Ensure line is long enough to check record type
        if length(line) < 12
            continue
        end
        
        # Check block identifier (using extract_field for UTF-8 safety)
        block_id = strip(extract_field(line, 1, 6))
        if block_id != "OPERUH"
            continue
        end
        
        # Parse record type
        record_type = strip(extract_field(line, 8, 12))
        
        if record_type == "REST"
            record = parse_rest_record(line)
            if !isnothing(record)
                push!(rest_records, record)
            end
        elseif record_type == "ELEM"
            record = parse_elem_record(line)
            if !isnothing(record)
                push!(elem_records, record)
            end
        elseif record_type == "LIM"
            record = parse_lim_record(line)
            if !isnothing(record)
                push!(lim_records, record)
            end
        elseif record_type == "VAR"
            record = parse_var_record(line)
            if !isnothing(record)
                push!(var_records, record)
            end
        else
            @debug "Unknown OPERUH record type in $filename line $line_num: $record_type" line
        end
    end
    
    return OperuhData(
        rest_records = rest_records,
        elem_records = elem_records,
        lim_records = lim_records,
        var_records = var_records
    )
end

end # module
