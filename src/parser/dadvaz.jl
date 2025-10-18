"""
DADVAZ.DAT Parser

Parses natural inflow data along with header metadata.
"""
module DadvazParser

using Dates
using ..Types: DadvazHeader, DadvazInflowRecord, DadvazData
using ..ParserCommon: extract_field, parse_int, parse_float, is_comment_line, is_blank

export parse_dadvaz

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

"""Parse day markers that can be numeric or special tokens (I/F)."""
function _parse_day_token(token::AbstractString)
    value = strip(token)
    isempty(value) && return nothing
    if value == "F" || value == "I"
        return String(value)  # Convert SubString to String
    end
    return parse(Int, value)
end

"""Parse optional integer field returning nothing when blank."""
_parse_optional_int(token::AbstractString) = parse_int(token; allow_blank=true)

"""Parse a single inflow record line."""
function _parse_inflow_line(line::AbstractString)
    # Check for end-of-file markers
    line_clean = strip(line)
    if line_clean == "FIM" || line_clean == "9999" || isempty(line_clean)
        return nothing
    end
    
    # Skip if line is too short
    length(line) < 53 && return nothing
    
    plant_num = parse(Int, extract_field(line, 1, 3))
    plant_name = extract_field(line, 5, 16)
    inflow_type = parse(Int, extract_field(line, 20, 20))

    start_day = _parse_day_token(extract_field(line, 25, 26))
    start_hour = _parse_optional_int(extract_field(line, 28, 29))
    start_half = _parse_optional_int(extract_field(line, 31, 31))

    end_day = _parse_day_token(extract_field(line, 33, 34))
    end_hour = _parse_optional_int(extract_field(line, 36, 37))
    end_half = _parse_optional_int(extract_field(line, 39, 39))

    flow_value = parse_float(extract_field(line, 45, 53))

    # Ensure required day markers are present
    start_day === nothing && error("Missing start day in DADVAZ record")
    end_day === nothing && error("Missing end day in DADVAZ record")

    return DadvazInflowRecord(
        plant_num=plant_num,
        plant_name=plant_name,
        inflow_type=inflow_type,
        start_day=start_day,
        start_hour=start_hour,
        start_half_hour=start_half,
        end_day=end_day,
        end_hour=end_hour,
        end_half_hour=end_half,
        flow_m3s=flow_value
    )
end

"""Collect integer identifiers from a line, ignoring non-numeric tokens."""
function _collect_ints_from_line!(acc::Vector{Int}, line::AbstractString)
    for token in split(strip(line))
        all(isdigit, token) || continue
        push!(acc, parse(Int, token))
    end
    return acc
end

# -----------------------------------------------------------------------------
# Main parser
# -----------------------------------------------------------------------------

function parse_dadvaz(filepath::AbstractString)::DadvazData
    lines = readlines(filepath)
    total = length(lines)
    idx = 1

    plant_count::Union{Int, Nothing} = nothing
    plant_numbers = Int[]
    study_start::Union{DateTime, Nothing} = nothing
    initial_day_code::Union{Int, Nothing} = nothing
    fcf_week_index::Union{Int, Nothing} = nothing
    study_weeks::Union{Int, Nothing} = nothing
    simulation_flag::Union{Int, Nothing} = nothing

    inflow_records = DadvazInflowRecord[]
    in_record_section = false

    while idx <= total
        raw_line = lines[idx]
        stripped = strip(raw_line)

        if isempty(stripped)
            idx += 1
            continue
        end

        if is_comment_line(raw_line)
            idx += 1
            continue
        end

        if startswith(stripped, "NUMERO DE USINAS")
            idx += 2
            idx > total && error("Unexpected end of file while reading plant count")
            plant_count = parse(Int, strip(lines[idx]))
            idx += 1
            continue
        elseif startswith(stripped, "NUMERO DAS USINAS")
            idx += 1
            while idx <= total
                candidate = strip(lines[idx])
                isempty(candidate) && (idx += 1; continue)
                if startswith(candidate, "Hr")
                    break
                end
                startswith(candidate, "XXX") && (idx += 1; continue)
                _collect_ints_from_line!(plant_numbers, candidate)
                idx += 1
            end
            continue
        elseif startswith(stripped, "Hr")
            idx += 2
            idx > total && error("Unexpected end of file while reading study start")
            parts = split(strip(lines[idx]))
            length(parts) < 4 && error("Invalid study start line in DADVAZ header")
            hour = parse(Int, parts[1])
            day = parse(Int, parts[2])
            month = parse(Int, parts[3])
            year = parse(Int, parts[4])
            study_start = DateTime(year, month, day, hour)
            idx += 1
            continue
        elseif startswith(stripped, "Dia inic")
            idx += 2
            idx > total && error("Unexpected end of file while reading study parameters")
            parts = split(strip(lines[idx]))
            length(parts) < 4 && error("Invalid study parameter line in DADVAZ header")
            initial_day_code = parse(Int, parts[1])
            fcf_week_index = parse(Int, parts[2])
            study_weeks = parse(Int, parts[3])
            simulation_flag = parse(Int, parts[4])
            idx += 1
            continue
        elseif startswith(stripped, "VAZOES DIARIAS")
            in_record_section = true
            idx += 1
            continue
        elseif in_record_section && (startswith(stripped, "NUM") || startswith(stripped, "XXX") || startswith(stripped, "itp"))
            idx += 1
            continue
        elseif in_record_section
            record = _parse_inflow_line(raw_line)
            if !isnothing(record)
                push!(inflow_records, record)
            end
            idx += 1
            continue
        else
            idx += 1
        end
    end

    plant_count === nothing && error("Missing plant count in DADVAZ header")
    study_start === nothing && error("Missing study start in DADVAZ header")
    initial_day_code === nothing && error("Missing study parameters in DADVAZ header")
    fcf_week_index === nothing && error("Missing FCF week index in DADVAZ header")
    study_weeks === nothing && error("Missing study weeks in DADVAZ header")
    simulation_flag === nothing && error("Missing simulation flag in DADVAZ header")

    if length(plant_numbers) >= 2 * plant_count
        expected = collect(1:plant_count)
        if plant_numbers[1:plant_count] == expected
            plant_numbers = plant_numbers[plant_count+1:end]
        end
    end

    if length(plant_numbers) > plant_count
        plant_numbers = plant_numbers[1:plant_count]
    elseif length(plant_numbers) < plant_count
        error("Incomplete plant number list in DADVAZ header: expected $plant_count entries, found $(length(plant_numbers))")
    end

    header = DadvazHeader(
        plant_count=plant_count,
        plant_numbers=plant_numbers,
        study_start=study_start,
        initial_day_code=initial_day_code,
        fcf_week_index=fcf_week_index,
        study_weeks=study_weeks,
        simulation_flag=simulation_flag
    )

    return DadvazData(header=header, records=inflow_records)
end

end # module
