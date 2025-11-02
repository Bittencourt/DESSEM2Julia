"""
AREACONT.DAT Parser

Parses control area definitions for power reserve.

# IDESSEM Reference
idessem/dessem/modelos/areacont.py - BlocoArea, BlocoUsina

# Format
Block structure:
- AREA block: lists control areas
- USINA block: lists plants/components in each area
- Ends with "9999"

Area format (fixed width):
- Columns 1-3: codigo_area (Int)
- Columns 9+: nome_area (String)

Usina format (fixed width):
- Columns 1-3: codigo_area (Int)
- Column 8: tipo_componente (H/T/etc.)
- Columns 10-12: codigo_componente (Int)
- Columns 15+: nome_componente (String)
"""
module AreaContParser

using ..DESSEM2Julia: AreaRecord, UsinaRecord, AreaContData
using ..ParserCommon: is_comment_line, is_blank, extract_field

"""
    parse_area_record(line) -> AreaRecord

Parse an area definition line.
"""
function parse_area_record(line::AbstractString)
    codigo_area = parse(Int, strip(extract_field(line, 1, 3)))
    nome_area = strip(extract_field(line, 9, length(line)))

    return AreaRecord(codigo_area = codigo_area, nome_area = nome_area)
end

"""
    parse_usina_record(line) -> UsinaRecord

Parse a usina (plant/component) line.
"""
function parse_usina_record(line::AbstractString)
    codigo_area = parse(Int, strip(extract_field(line, 1, 3)))
    tipo_componente = strip(extract_field(line, 8, 8))  # Col 8 (Python index 7)
    codigo_componente = parse(Int, strip(extract_field(line, 10, 12)))  # Cols 10-12 (Python 9-11)
    nome_componente = strip(extract_field(line, 15, length(line)))  # Col 15+ (Python 14+)

    return UsinaRecord(
        codigo_area = codigo_area,
        tipo_componente = tipo_componente,
        codigo_componente = codigo_componente,
        nome_componente = nome_componente,
    )
end

"""
    parse_areacont(io, filename) -> AreaContData

Parse complete AREACONT.DAT file.

# Format
```
AREA
  1      AREA NAME
FIM
&
USINA
  1    H 261  PLANT NAME
  1    H  34  ANOTHER PLANT
FIM
9999
```
"""
function parse_areacont(io::IO, filename::AbstractString)
    areas = AreaRecord[]
    usinas = UsinaRecord[]

    in_area_block = false
    in_usina_block = false

    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue

        # Check for end of file marker
        if startswith(strip(line), "9999")
            break
        end

        # Check for block markers
        if occursin(r"^\s*AREA\s*$", line)
            in_area_block = true
            continue
        end

        if occursin(r"^\s*USINA\s*$", line)
            in_usina_block = true
            continue
        end

        if occursin(r"^\s*FIM\s*$", line)
            in_area_block = false
            in_usina_block = false
            continue
        end

        # Parse records based on current block
        if in_area_block
            try
                record = parse_area_record(line)
                push!(areas, record)
            catch e
                @warn "Failed to parse area record at line $line_num" exception =
                    (e, catch_backtrace())
            end
        elseif in_usina_block
            try
                record = parse_usina_record(line)
                push!(usinas, record)
            catch e
                @warn "Failed to parse usina record at line $line_num" exception =
                    (e, catch_backtrace())
            end
        end
    end

    return AreaContData(areas = areas, usinas = usinas)
end

# Convenience method
parse_areacont(filename::AbstractString) =
    open(io -> parse_areacont(io, filename), filename)

export parse_areacont

end # module
