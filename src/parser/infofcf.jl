# INFOFCF.DAT Parser - FCF Information File
# Contains mappings for travel time plants, GNL subsystems, load patterns, and fixed values
#
# Based on file structure from ONS sample data

module InfofcfDatParser

using ..DESSEM2Julia:
    InfofcfDatTviag, InfofcfDatSisgnl, InfofcfDatDurpat, InfofcfDatFix, InfofcfDatData

export parse_infofcf_dat

"""
    is_comment(line::AbstractString) -> Bool

Check if a line is a comment (starts with &).
"""
function is_comment(line::AbstractString)
    stripped = strip(line)
    return isempty(stripped) || startswith(stripped, "&")
end

"""
    extract_field(line::AbstractString, start_pos::Int, end_pos::Int) -> String

Extract a fixed-width field from a line (1-indexed positions).
"""
function extract_field(line::AbstractString, start_pos::Int, end_pos::Int)
    if end_pos > length(line)
        if start_pos > length(line)
            return ""
        end
        return line[start_pos:end]
    end
    return line[start_pos:end_pos]
end

"""
    parse_tviag_record(line::AbstractString) -> InfofcfDatTviag

Parse a MAPFCF TVIAG record.

Format: MAPFCF  TVIAG     1 156
- Columns 1-6: "MAPFCF"
- Columns 9-13: "TVIAG"
- Column 19: Index (single digit)
- Columns 21-23: Plant code
"""
function parse_tviag_record(line::AbstractString)
    index = parse(Int, strip(extract_field(line, 19, 19)))
    plant_code = parse(Int, strip(extract_field(line, 21, min(length(line), 23))))
    return InfofcfDatTviag(index = index, plant_code = plant_code)
end

"""
    parse_sisgnl_record(line::AbstractString) -> InfofcfDatSisgnl

Parse a MAPFCF SISGNL record.

Format: MAPFCF  SISGNL   1   1   2   3
- Columns 1-6: "MAPFCF"
- Columns 9-14: "SISGNL"
- Column 18: Index
- Column 22: Subsystem
- Column 26: Number of lags
- Column 30: Number of patterns
"""
function parse_sisgnl_record(line::AbstractString)
    index = parse(Int, strip(extract_field(line, 17, 18)))
    subsystem = parse(Int, strip(extract_field(line, 21, 22)))
    num_lags = parse(Int, strip(extract_field(line, 25, 26)))
    num_patterns = parse(Int, strip(extract_field(line, 29, 30)))
    return InfofcfDatSisgnl(
        index = index,
        subsystem = subsystem,
        num_lags = num_lags,
        num_patterns = num_patterns,
    )
end

"""
    parse_durpat_record(line::AbstractString) -> InfofcfDatDurpat

Parse a MAPFCF DURPAT record.

Format: MAPFCF  DURPAT   2   1      172.84
- Columns 1-6: "MAPFCF"
- Columns 9-14: "DURPAT"
- Column 18: Lag
- Column 22: Pattern
- Columns 29-34: Duration (hours)
"""
function parse_durpat_record(line::AbstractString)
    lag = parse(Int, strip(extract_field(line, 17, 18)))
    pattern = parse(Int, strip(extract_field(line, 21, 22)))
    duration = parse(Float64, strip(extract_field(line, 23, min(length(line), 40))))
    return InfofcfDatDurpat(lag = lag, pattern = pattern, duration = duration)
end

"""
    parse_fcffix_record(line::AbstractString) -> InfofcfDatFix

Parse a FCFFIX record.

Format: FCFFIX USIT    86 GTERF    2   1     500.00 Usina termica GNL.
- Columns 1-6: "FCFFIX"
- Columns 8-13: Entity type (e.g., "USIT")
- Columns 15-17: Entity ID
- Columns 19-24: Variable type (e.g., "GTERF")
- Columns 26-28: Lag
- Columns 30-32: Pattern
- Columns 34-43: Value
- Columns 45+: Justification
"""
function parse_fcffix_record(line::AbstractString)
    entity_type = strip(extract_field(line, 8, 13))
    entity_id = parse(Int, strip(extract_field(line, 15, 17)))
    variable_type = strip(extract_field(line, 19, 24))
    lag = parse(Int, strip(extract_field(line, 26, 28)))
    pattern = parse(Int, strip(extract_field(line, 30, 32)))
    value = parse(Float64, strip(extract_field(line, 34, 43)))
    justification = strip(extract_field(line, 45, length(line)))

    return InfofcfDatFix(
        entity_type = entity_type,
        entity_id = entity_id,
        variable_type = variable_type,
        lag = lag,
        pattern = pattern,
        value = value,
        justification = justification,
    )
end

"""
    parse_infofcf_dat(io::IO, filename::AbstractString="") -> InfofcfDatData

Parse an INFOFCF.DAT file.

The file contains FCF mapping information:
- MAPFCF TVIAG: Plants with water travel time
- MAPFCF SISGNL: Subsystems with GNL thermal plants
- MAPFCF DURPAT: Load pattern durations for future periods
- FCFFIX: Fixed future values for GNL plants

# Arguments
- `io::IO`: Input stream
- `filename::AbstractString`: Filename for error messages

# Returns
- `InfofcfDatData`: Parsed FCF information
"""
function parse_infofcf_dat(io::IO, filename::AbstractString = "")
    tviag = InfofcfDatTviag[]
    sisgnl = InfofcfDatSisgnl[]
    durpat = InfofcfDatDurpat[]
    fcffix = InfofcfDatFix[]

    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and empty lines
        is_comment(line) && continue
        isempty(strip(line)) && continue

        # Skip format specification lines (XXXXXX patterns)
        if startswith(strip(line), "XXXXXX")
            continue
        end

        try
            if startswith(line, "MAPFCF")
                # Determine record type
                if occursin("TVIAG", line)
                    push!(tviag, parse_tviag_record(line))
                elseif occursin("SISGNL", line)
                    push!(sisgnl, parse_sisgnl_record(line))
                elseif occursin("DURPAT", line)
                    push!(durpat, parse_durpat_record(line))
                end
            elseif startswith(line, "FCFFIX")
                push!(fcffix, parse_fcffix_record(line))
            end
        catch e
            @warn "Failed to parse line $line_num in $filename: $line" exception = e
        end
    end

    return InfofcfDatData(tviag = tviag, sisgnl = sisgnl, durpat = durpat, fcffix = fcffix)
end

"""
    parse_infofcf_dat(filename::AbstractString) -> InfofcfDatData

Parse an INFOFCF.DAT file from a path.
"""
function parse_infofcf_dat(filename::AbstractString)
    open(filename, "r") do io
        return parse_infofcf_dat(io, filename)
    end
end

end # module InfofcfDatParser
