module PtoperParser

using ..DESSEM2Julia: PtoperRecord, PtoperData
using ..ParserCommon: extract_field, is_comment_line, is_blank, parse_int, parse_float

export parse_ptoper, parse_ptoper_record

"""
    parse_ptoper_record(line, filename, line_num) -> PtoperRecord

Parse a single PTOPER record from a line.

# Format
- Mnemonic: 1-6
- Element Type: 8-12 (5 chars)
- Element ID: 13-17 (5 chars)
- Variable: 19-24 (6 chars)
- Start Day: 26-27
- Start Hour: 29-30
- Start Half: 32
- End Day: 34-35
- End Hour: 37-38
- End Half: 40
- Value: 42-60 (approx)
"""
function parse_ptoper_record(line::AbstractString, filename::AbstractString, line_num::Int)
    # Mnemonic 1-6 checked by caller or ignored

    element_type = strip(extract_field(line, 8, 12))
    element_id = parse(Int, strip(extract_field(line, 13, 17)))
    variable = strip(extract_field(line, 19, 24))

    start_day_str = strip(extract_field(line, 26, 27))
    start_day = start_day_str == "I" ? "I" : parse(Int, start_day_str)

    start_hour = parse(Int, strip(extract_field(line, 29, 30)))
    start_half = parse(Int, strip(extract_field(line, 32, 32)))

    end_day_str = strip(extract_field(line, 34, 35))
    end_day = end_day_str == "F" ? "F" : parse(Int, end_day_str)

    end_hour_str = strip(extract_field(line, 37, 38))
    end_hour = isempty(end_hour_str) ? 0 : parse(Int, end_hour_str)

    end_half_str = strip(extract_field(line, 40, 40))
    end_half = isempty(end_half_str) ? 0 : parse(Int, end_half_str)

    value_str = strip(extract_field(line, 42, 60)) # Use generous width
    value = parse(Float64, value_str)

    return PtoperRecord(
        element_type = element_type,
        element_id = element_id,
        variable = variable,
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
        value = value,
    )
end

"""
    parse_ptoper(io, filename) -> PtoperData

Parse complete PTOPER file.
"""
function parse_ptoper(io::IO, filename::AbstractString)
    records = PtoperRecord[]

    for (line_num, line) in enumerate(eachline(io))
        is_comment_line(line) && continue
        is_blank(line) && continue

        if startswith(line, "PTOPER")
            push!(records, parse_ptoper_record(line, filename, line_num))
        end
    end

    return PtoperData(records = records)
end

parse_ptoper(filename::AbstractString) = open(io -> parse_ptoper(io, filename), filename)

end
