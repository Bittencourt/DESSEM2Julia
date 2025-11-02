"""
CURVTVIAG.DAT Parser

Parses travel time propagation curves for hydro cascades.

# IDESSEM Reference
idessem/dessem/modelos/dessemarq.py - RegistroCurvtviag
idessem/dessem/modelos/operut.py - TabelaPdoOperTviagCalha

# Format
Fixed-width records with "CURVTV" prefix:
```
CURVTV    66    1  S             1        10
```
- Columns 1-6: "CURVTV" mnemonic
- Columns 11-13: upstream plant code (Int)
- Columns 18-20: downstream element code (Int)
- Columns 23: downstream element type (String: S=section, H=plant)
- Columns 29-30: hour (Int, 0-24)
- Columns 37-39: accumulated percentage (Int, 0-100)

# Purpose
Defines water travel time distribution curves between upstream plants
and downstream sections/plants. Accumulated percentage represents
cumulative flow arrival after N hours.

# Section Separators
Lines containing only "&" separate different propagation curves.
"""
module CurvTviagParser

using ..DESSEM2Julia: CurvTviagRecord, CurvTviagData
using ..ParserCommon: extract_field, is_comment_line, is_blank

"""
    parse_curvtviag_record(line) -> CurvTviagRecord

Parse a single travel time curve record.

# Format
```
CURVTV    66    1  S             1        10
```
"""
function parse_curvtviag_record(line::AbstractString)
    # Extract fixed fields - right-aligned integers
    codigo_usina_montante = parse(Int, strip(extract_field(line, 10, 13)))  # Right-aligned 1-3 digits
    codigo_elemento_jusante = parse(Int, strip(extract_field(line, 16, 19)))  # Right-aligned 1-3 digits
    tipo_elemento_jusante = strip(extract_field(line, 20, 20))  # S/H at position 20

    # hora and % are right-aligned in wider fields - extract the whole field and strip
    hora_str = strip(extract_field(line, 21, 36))  # hora field spans positions 21-36
    hora = parse(Int, hora_str)

    perc_str = strip(extract_field(line, 37, min(length(line), 48)))  # % field from 37 to end
    percentual_acumulado = parse(Int, perc_str)

    return CurvTviagRecord(
        codigo_usina_montante = codigo_usina_montante,
        codigo_elemento_jusante = codigo_elemento_jusante,
        tipo_elemento_jusante = tipo_elemento_jusante,
        hora = hora,
        percentual_acumulado = percentual_acumulado,
    )
end

"""
    parse_curvtviag(io, filename) -> CurvTviagData

Parse complete CURVTVIAG.DAT file.

Returns all travel time propagation curves defined in the system.
Section separators ("&" lines) are skipped.
"""
function parse_curvtviag(io::IO, filename::AbstractString)
    records = CurvTviagRecord[]

    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue

        # Skip section separators (just "&")
        if strip(line) == "&"
            continue
        end

        # Only parse lines starting with CURVTV
        if !startswith(strip(line), "CURVTV")
            continue
        end

        try
            record = parse_curvtviag_record(line)
            push!(records, record)
        catch e
            @warn "Failed to parse curvtviag record at line $line_num" exception =
                (e, catch_backtrace())
        end
    end

    return CurvTviagData(records = records)
end

# Convenience method
parse_curvtviag(filename::AbstractString) =
    open(io -> parse_curvtviag(io, filename), filename)

export parse_curvtviag

end # module
