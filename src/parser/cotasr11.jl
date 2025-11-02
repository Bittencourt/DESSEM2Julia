"""
COTASR11.DAT Parser

Parses historical Itaipu R11 gauge levels before study period.

# IDESSEM Reference
idessem/dessem/modelos/dessemarq.py - RegistroCotasR11

# Format
Simple fixed-width format:
- Columns 1-2: day (Int)
- Columns 4-5: hour (0-23)
- Columns 7: half-hour (0 or 1)
- Columns 13-22: water level at R11 gauge (Float64, meters)

Each line represents one half-hour measurement.

# Related
- R11 register in ENTDADOS.DAT
- Itaipu canal de fuga (tailrace) restrictions
"""
module CotasR11Parser

using ..DESSEM2Julia: CotaR11Record, CotasR11Data
using ..ParserCommon: extract_field, is_comment_line, is_blank

"""
    parse_cotasr11_record(line) -> CotaR11Record

Parse a single R11 gauge level record.

# Format
```
27  0 0              96.35
```
"""
function parse_cotasr11_record(line::AbstractString)
    dia = parse(Int, strip(extract_field(line, 1, 2)))
    hora = parse(Int, strip(extract_field(line, 4, 5)))
    meia_hora = parse(Int, strip(extract_field(line, 7, 7)))
    cota = parse(Float64, strip(extract_field(line, 17, 26)))  # Right-aligned float

    return CotaR11Record(dia = dia, hora = hora, meia_hora = meia_hora, cota = cota)
end

"""
    parse_cotasr11(io, filename) -> CotasR11Data

Parse complete COTASR11.DAT file.

Returns all R11 gauge level measurements before study start.
"""
function parse_cotasr11(io::IO, filename::AbstractString)
    records = CotaR11Record[]

    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue

        try
            record = parse_cotasr11_record(line)
            push!(records, record)
        catch e
            @warn "Failed to parse cotasr11 record at line $line_num" exception =
                (e, catch_backtrace())
        end
    end

    return CotasR11Data(records = records)
end

# Convenience method
parse_cotasr11(filename::AbstractString) =
    open(io -> parse_cotasr11(io, filename), filename)

export parse_cotasr11

end # module
