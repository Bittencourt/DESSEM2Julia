"""
Parser for OPERUH.DAT (Hydro Operational Constraints)

This file defines time-varying operational constraints for hydroelectric plants.
Format: Register file with REST (restriction), LIM (limits), VAR (variation), and ELEM (element) records.

IDESEM Reference: idessem/dessem/operuh.py and idessem/dessem/modelos/operuh.py

Column Positions (Python 0-indexed → Julia 1-indexed):
- REST: codigo_restricao(14-18), tipo_restricao(21), intervalo_aplicacao(23),
        valor_inicial(40-49), tipo_restricao_variacao(51), duracao_janela(55-59)
- ELEM: codigo_restricao(14-18), codigo_usina(20-22), nome_usina(24-35),
        tipo(37), coeficiente(39-43)
- LIM: codigo_restricao(14-18), StageDateField(20-26) start, StageDateField(28-34) end,
       limite_inferior(38-47), limite_superior(48-57)
- VAR: codigo_restricao(14-18), StageDateField(19-25) start, StageDateField(27-33) end,
       ramps at (37-46), (47-56), (57-66), (67-76)

References:
- DESSEM Manual v19.0.24.3, Section III.8
- docs/dessem-complete-specs.md: Hydro Operational Constraints (OPERUH.XXX)
- IDESEM: idessem/dessem/modelos/operuh.py
"""

module OperuhParser

using ..ParserCommon:
    extract_field, parse_int, parse_float, parse_string, is_blank, is_comment_line
using ..Types:
    HydroConstraintREST,
    HydroConstraintELEM,
    HydroConstraintLIM,
    HydroConstraintVAR,
    OperuhData

export parse_operuh

# ============================================================================
# Helper Functions
# ============================================================================

# NOTE: LF line endings enforced via .gitattributes for consistent CI formatting

"""
Parse StageDateField - composite field with day, hour, half-hour.
Format: DD HH M where DD can be 'I', 'F', or day number (1-31)
"""
function parse_stage_date(
    line::AbstractString,
    start_pos::Int,
)::Tuple{Union{String,Int},Union{Int,Nothing},Union{Int,Nothing}}
    # Day field (2 chars)
    day_str = strip(extract_field(line, start_pos, start_pos + 1))
    day = if day_str in ["I", "F", ""]
        String(day_str)  # Convert SubString to String for Union type
    else
        parsed = parse_int(day_str, allow_blank = true)
        isnothing(parsed) ? "" : parsed
    end

    # Hour field (2 chars, offset by 3 from day)
    hour = parse_int(
        strip(extract_field(line, start_pos + 3, start_pos + 4)),
        allow_blank = true,
    )

    # Half-hour field (1 char, offset by 6 from day)
    half = parse_int(
        strip(extract_field(line, start_pos + 6, start_pos + 6)),
        allow_blank = true,
    )

    return (day, hour, half)
end

# ============================================================================
# Record Parsers
# ============================================================================

function parse_rest_record(line::AbstractString)::Union{HydroConstraintREST,Nothing}
    """
    Parse OPERUH REST record (constraint definition).

    IDESEM Reference: idessem/dessem/modelos/operuh.py - REST class
    Fields: IntegerField(5,14), LiteralField(1,21), LiteralField(1,23), LiteralField(12,27),
            FloatField(10,40,2), IntegerField(1,51), FloatField(5,55,2)
    """

    try
        # Add 1 to IDESEM positions for Julia 1-indexing
        constraint_id = parse(Int, strip(extract_field(line, 15, 19)))  # 14+1 to 18+1
        type_flag = strip(extract_field(line, 22, 22))  # 21+1
        interval_type = strip(extract_field(line, 24, 24))  # 23+1
        variable_code = strip(extract_field(line, 28, 39))  # 27+1 to 38+1

        # Optional fields
        initial_value = parse_float(strip(extract_field(line, 41, 50)), allow_blank = true)  # 40+1 to 49+1
        variation_type_str = strip(extract_field(line, 52, 52))  # 51+1
        variation_type =
            isempty(variation_type_str) ? nothing : parse(Int, variation_type_str)
        window_duration =
            parse_float(strip(extract_field(line, 56, 60)), allow_blank = true)  # 55+1 to 59+1

        return HydroConstraintREST(
            constraint_id = constraint_id,
            type_flag = type_flag,
            interval_type = interval_type,
            variable_code = variable_code,
            initial_value = initial_value,
            variation_type = variation_type,
            window_duration = window_duration,
        )
    catch e
        @warn "Failed to parse OPERUH REST record" line exception = e
        return nothing
    end
end

function parse_elem_record(line::AbstractString)::Union{HydroConstraintELEM,Nothing}
    """
    Parse OPERUH ELEM record (plant participation in constraint).

    IDESEM Reference: idessem/dessem/modelos/operuh.py - ELEM class
    Fields: IntegerField(5,14), IntegerField(3,20), LiteralField(12,25),
            IntegerField(2,40), FloatField(5,43,2)

    Column positions (Julia 1-indexed):
    - constraint_id: 15-19 (size 5)
    - plant_code: 21-23 (size 3)
    - plant_name: 26-37 (size 12)
    - variable_type: 41-42 (size 2)
    - coefficient: 44-48 (size 5)
    """

    try
        # Add 1 to IDESEM positions for Julia 1-indexing
        constraint_id = parse(Int, strip(extract_field(line, 15, 19)))  # 14+1 to 14+5
        plant_code = parse(Int, strip(extract_field(line, 21, 23)))  # 20+1 to 20+3
        plant_name = strip(extract_field(line, 26, 37))  # 25+1 to 25+12
        variable_type = parse(Int, strip(extract_field(line, 41, 42)))  # 40+1 to 40+2
        coefficient = parse(Float64, strip(extract_field(line, 44, 48)))  # 43+1 to 43+5

        return HydroConstraintELEM(
            constraint_id = constraint_id,
            plant_code = plant_code,
            plant_name = plant_name,
            variable_type = variable_type,
            coefficient = coefficient,
        )
    catch e
        @warn "Failed to parse OPERUH ELEM record" line exception = e
        return nothing
    end
end

function parse_lim_record(line::AbstractString)::Union{HydroConstraintLIM,Nothing}
    """
    Parse OPERUH LIM record (operational limits).

    IDESEM Reference: idessem/dessem/modelos/operuh.py - LIM class
    Fields: IntegerField(5,14), StageDateField(20,'I'), StageDateField(28,'F'),
            FloatField(10,38,2), FloatField(10,48,2)
    """

    try
        # Add 1 to IDESEM positions for Julia 1-indexing
        constraint_id = parse(Int, strip(extract_field(line, 15, 19)))  # 14+1 to 18+1

        # Parse start date (20+1 = 21)
        start_day, start_hour, start_half = parse_stage_date(line, 21)

        # Parse end date (28+1 = 29)
        end_day, end_hour, end_half = parse_stage_date(line, 29)

        # Parse limits
        lower_limit = parse_float(strip(extract_field(line, 39, 48)), allow_blank = true)  # 38+1 to 47+1
        upper_limit = parse_float(strip(extract_field(line, 49, 58)), allow_blank = true)  # 48+1 to 57+1

        return HydroConstraintLIM(
            constraint_id = constraint_id,
            start_day = start_day,
            start_hour = start_hour,
            start_half = start_half,
            end_day = end_day,
            end_hour = end_hour,
            end_half = end_half,
            lower_limit = lower_limit,
            upper_limit = upper_limit,
        )
    catch e
        @warn "Failed to parse OPERUH LIM record" line exception = e
        return nothing
    end
end

function parse_var_record(line::AbstractString)::Union{HydroConstraintVAR,Nothing}
    """
    Parse OPERUH VAR record (variation/ramp constraints).

    IDESEM Reference: idessem/dessem/modelos/operuh.py - VAR class
    Fields: IntegerField(5,14), StageDateField(19,'I'), StageDateField(27,'F'),
            FloatField(10,37,2), FloatField(10,47,2), FloatField(10,57,2), FloatField(10,67,2)
    """

    try
        # Add 1 to IDESEM positions for Julia 1-indexing
        constraint_id = parse(Int, strip(extract_field(line, 15, 19)))  # 14+1 to 18+1

        # Parse start date (19+1 = 20)
        start_day, start_hour, start_half = parse_stage_date(line, 20)

        # Parse end date (27+1 = 28)
        end_day, end_hour, end_half = parse_stage_date(line, 28)

        # Parse ramp limits (4 fields, all 10.2 format)
        ramp_down = parse_float(strip(extract_field(line, 38, 47)), allow_blank = true)  # 37+1 to 46+1
        ramp_up = parse_float(strip(extract_field(line, 48, 57)), allow_blank = true)  # 47+1 to 56+1
        ramp_down_2 = parse_float(strip(extract_field(line, 58, 67)), allow_blank = true)  # 57+1 to 66+1
        ramp_up_2 = parse_float(strip(extract_field(line, 68, 77)), allow_blank = true)  # 67+1 to 76+1

        return HydroConstraintVAR(
            constraint_id = constraint_id,
            start_day = start_day,
            start_hour = start_hour,
            start_half = start_half,
            end_day = end_day,
            end_hour = end_hour,
            end_half = end_half,
            ramp_down = ramp_down,
            ramp_up = ramp_up,
            ramp_down_2 = ramp_down_2,
            ramp_up_2 = ramp_up_2,
        )
    catch e
        @warn "Failed to parse OPERUH VAR record" line exception = e
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
function parse_operuh(io::IO, filename::AbstractString = "operuh.dat")
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
        var_records = var_records,
    )
end

end # module
