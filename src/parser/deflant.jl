"""
DEFLANT.DAT Parser

Parses previous flow data for water travel time modeling.

# IDESEM Reference
- idessem/dessem/deflant.py - Main parser
- idessem/dessem/modelos/deflant.py - DEFANT register model

# File Format
Fixed-width columns with DEFANT identifier:
- Columns 10-12: Upstream plant code (int)
- Columns 15-17: Downstream element code (int)
- Column 20: Element type ("H"=hydro, "S"=river section)
- Columns 25-31: Initial date/time (day, hour, half-hour)
- Columns 33-39: Final date/time (day, hour, half-hour)
- Columns 45-54: Flow rate in m³/s (float)

# Example
```
&        Mont Jus TpJ   di hi m df hf m     defluencia
DEFANT     2    4  H    10 00 0  F                 113
```
"""
module DeflantParser

using ..DESSEM2Julia: DeflantRecord, DeflantData
using ..ParserCommon: extract_field, is_comment_line, is_blank, parse_int, parse_float

"""
    parse_stage_date(line, start_pos) -> (day, hour, half_hour)

Parse stage date/time field from DEFLANT record.

Reused from OPERUH parser. Returns:
- day: "I" (inicio), "F" (fim), or integer day (1-31)
- hour: 0-23 or nothing
- half_hour: 0 or 1, or nothing

# Arguments
- `line`: Line containing date/time field
- `start_pos`: 1-indexed start position of date field
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

"""
    parse_deflant_record(line, filename, line_num) -> DeflantRecord

Parse a single DEFANT record from a line.

# IDESEM Reference
idessem/dessem/modelos/deflant.py - DEFANT class
```python
LINE = Line([
    IntegerField(3, 9),      # codigo_usina_montante
    IntegerField(3, 14),     # codigo_elemento_jusante
    LiteralField(1, 19),     # tipo_elemento_jusante
    StageDateField(starting_position=24, special_day_character="I"),
    StageDateField(starting_position=32, special_day_character="F"),
    FloatField(10, 44, 1)    # defluencia
])
```

# Column Mapping (Python 0-indexed → Julia 1-indexed)
- Columns 10-12: Upstream plant code
- Columns 15-17: Downstream element code
- Column 20: Element type
- Columns 25-31: Initial date/time
- Columns 33-39: Final date/time
- Columns 45-54: Flow rate
"""
function parse_deflant_record(
    line::AbstractString,
    filename::AbstractString,
    line_num::Int,
)::DeflantRecord
    # Extract upstream plant code (columns 10-12)
    upstream_str = strip(extract_field(line, 10, 12))
    upstream_plant = parse(Int, upstream_str)

    # Extract downstream element code (columns 15-17)
    downstream_str = strip(extract_field(line, 15, 17))
    downstream_element = parse(Int, downstream_str)

    # Extract element type (column 20)
    element_type = strip(extract_field(line, 20, 20))

    # Parse initial date/time (columns 25-31)
    initial_day, initial_hour, initial_half = parse_stage_date(line, 25)

    # Parse final date/time (columns 33-39)
    final_day, final_hour, final_half = parse_stage_date(line, 33)

    # Extract flow rate (columns 45-54)
    flow_str = strip(extract_field(line, 45, 54))
    flow = parse(Float64, flow_str)

    return DeflantRecord(
        upstream_plant = upstream_plant,
        downstream_element = downstream_element,
        element_type = element_type,
        initial_day = initial_day,
        initial_hour = initial_hour,
        initial_half = initial_half,
        final_day = final_day,
        final_hour = final_hour,
        final_half = final_half,
        flow = flow,
    )
end

"""
    parse_deflant(io, filename) -> DeflantData

Parse complete DEFLANT.DAT file from IO stream.

# Arguments
- `io`: IO stream containing DEFLANT.DAT data
- `filename`: Name of file being parsed (for error reporting)

# Returns
DeflantData containing all parsed DEFANT records

# Example
```julia
deflant_data = parse_deflant("deflant.dat")
println("Parsed \$(length(deflant_data.records)) flow records")
```
"""
function parse_deflant(io::IO, filename::AbstractString)::DeflantData
    records = DeflantRecord[]

    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue

        # Skip lines that don't start with DEFANT identifier
        !occursin(r"^DEFANT", line) && continue

        # Parse DEFANT record
        try
            record = parse_deflant_record(line, filename, line_num)
            push!(records, record)
        catch e
            @warn "Failed to parse DEFANT record at line $line_num" exception =
                (e, catch_backtrace())
            continue
        end
    end

    return DeflantData(records = records)
end

"""
    parse_deflant(filename) -> DeflantData

Parse DEFLANT.DAT file from path.

# Arguments
- `filename`: Path to DEFLANT.DAT file

# Returns
DeflantData containing all parsed DEFANT records
"""
function parse_deflant(filename::AbstractString)::DeflantData
    open(io -> parse_deflant(io, filename), filename)
end

export parse_deflant, parse_deflant_record

end  # module
