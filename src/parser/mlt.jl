"""
MLT.DAT Parser

Parses long-term average flow files containing:
- Plant number
- Plant name
- 12 monthly flow values (Jan-Dec)

# File Format
Fixed-width columns.
- Columns 1-3: Plant number
- Columns 5-16: Plant name
- Columns 20-29: Jan flow
- ...
- Columns 141-150: Dec flow

# Example
```
  1 ESTREITO        123.45    130.00    ...
```
"""
module MltParser

using ..DESSEM2Julia: MltRecord, MltData
using ..ParserCommon

# Import functions explicitly
import ..ParserCommon: extract_field, is_comment_line, is_blank

"""
    parse_mlt_record(line::AbstractString, line_num::Int) -> MltRecord

Parse a single MLT record.
"""
function parse_mlt_record(line::AbstractString, line_num::Int)
    # Extract plant number (1-3)
    plant_num = parse(Int, strip(extract_field(line, 1, 3)))

    # Extract plant name (5-16)
    plant_name = strip(extract_field(line, 5, 16))

    # Extract monthly flows
    monthly_flows = Float64[]

    # Column positions for 12 months:
    # Jan: 20-29
    # Feb: 31-40
    # ...
    # Dec: 141-150

    starts = [20, 31, 42, 53, 64, 75, 86, 97, 108, 119, 130, 141]

    for start_col in starts
        end_col = start_col + 9
        val_str = strip(extract_field(line, start_col, end_col))
        val = isempty(val_str) ? 0.0 : parse(Float64, val_str)
        push!(monthly_flows, val)
    end

    return MltRecord(
        plant_num = plant_num,
        plant_name = plant_name,
        monthly_flows = monthly_flows,
    )
end

"""
    parse_mlt(io::IO) -> MltData

Parse complete MLT.DAT file.
"""
function parse_mlt(io::IO)
    records = MltRecord[]

    for (line_num, line) in enumerate(eachline(io))
        is_comment_line(line) && continue
        is_blank(line) && continue

        try
            record = parse_mlt_record(line, line_num)
            push!(records, record)
        catch e
            @warn "Error parsing MLT record at line $line_num: $e"
        end
    end

    return MltData(records = records)
end

parse_mlt(filename::AbstractString) = open(parse_mlt, filename)

export parse_mlt

end # module
