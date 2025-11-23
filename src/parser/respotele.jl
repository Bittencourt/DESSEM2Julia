"""
RESPOTELE.DAT Parser

Parses electrical reserve requirement files containing:
- RP records: Electrical reserve pool definitions (control area + time window)
- LM records: Minimum electrical reserve limits (half-hourly time series)

# File Format
Fixed-width columns with StageDateField pattern (month, day, hour, half, marker).
Similar to RESPOT.DAT but for electrical network reserves.
Typically 48 LM records per reserve pool (half-hourly requirements).

# Example
```
&
RP    1  11  0 0  F           ELECTRICAL RESERVE AREA 1
&
LM    1  11  0 0  F            2732
LM    1  11  0 1  F            2632
...
```

# Notes
RESPOTELE.DAT does not have an IDESEM reference implementation (respotele.py).
This parser is based on the RESPOT.DAT format as they are structurally similar.
"""
module RespoteleParser

using ..DESSEM2Julia: RespoteleRP, RespoteLM, RespoteleData
using ..ParserCommon

# Import functions explicitly
import ..ParserCommon: extract_field, is_comment_line, is_blank, parse_int, parse_float

"""
    parse_rp_record(line::AbstractString, filename::AbstractString, line_num::Int) -> RespoteleRP

Parse an electrical reserve pool definition record (RP).

# Format (Fixed-width columns, similar to RESPOT.DAT)
- Columns 1-4: Identifier "RP  "
- Columns 5-7 (I3): codigo_area
- Columns 10-16 (StageDateField): dia_inicial, hora_inicial, meia_hora_inicial
  - Columns 10-11: month (if numeric) or special marker ("I")
  - Columns 13-14: hour
  - Column 16: half-hour (0 or 1)
- Columns 18-24 (StageDateField): dia_final, hora_final, meia_hora_final
  - Columns 18-19: day or "F"
  - Columns 21-22: hour (optional)
  - Column 24: half-hour (optional)
- Columns 31-70 (A40): descricao
"""
function parse_rp_record(line::AbstractString, filename::AbstractString, line_num::Int)
    # Extract codigo_area (columns 5-7, 1-indexed Julia)
    codigo_area = parse(Int, strip(extract_field(line, 5, 7)))

    # Extract initial stage date (based on RESPOT format)
    # Columns 10-11: day or "I " (2 chars)
    dia_inicial_str = strip(extract_field(line, 10, 11))
    dia_inicial =
        isempty(dia_inicial_str) ? 0 :
        (dia_inicial_str == "I" ? "I" : parse(Int, dia_inicial_str))

    # Columns 13-14: hour (2 chars, space-padded for single digits)
    hora_inicial_str = strip(extract_field(line, 13, 14))
    hora_inicial = isempty(hora_inicial_str) ? nothing : parse_int(hora_inicial_str)

    # Column 16: half-hour (1 char: 0 or 1)
    meia_hora_inicial_str = strip(extract_field(line, 16, 16))
    meia_hora_inicial =
        isempty(meia_hora_inicial_str) ? nothing : parse_int(meia_hora_inicial_str)

    # Extract final stage date
    # Columns 18-19: day or " F" (2 chars)
    dia_final_str = strip(extract_field(line, 18, 19))
    dia_final =
        isempty(dia_final_str) ? "F" :
        (dia_final_str == "F" ? "F" : parse(Int, dia_final_str))

    # Columns 21-22: hour (2 chars, optional for numeric final day)
    hora_final_str = strip(extract_field(line, 21, 22))
    hora_final = isempty(hora_final_str) ? nothing : parse_int(hora_final_str)

    # Column 24: half-hour (1 char, optional for numeric final day)
    meia_hora_final_str = strip(extract_field(line, 24, 24))
    meia_hora_final =
        isempty(meia_hora_final_str) ? nothing : parse_int(meia_hora_final_str)

    # Extract description (columns 31-70, 1-indexed)
    descricao = strip(extract_field(line, 31, 70))

    return RespoteleRP(
        codigo_area = codigo_area,
        dia_inicial = dia_inicial,
        hora_inicial = hora_inicial,
        meia_hora_inicial = meia_hora_inicial,
        dia_final = dia_final,
        hora_final = hora_final,
        meia_hora_final = meia_hora_final,
        descricao = descricao,
    )
end

"""
    parse_lm_record(line::AbstractString, filename::AbstractString, line_num::Int) -> RespoteLM

Parse an electrical reserve limit record (LM).

# Format (Fixed-width columns, similar to RESPOT.DAT)
- Columns 1-4: Identifier "LM  "
- Columns 5-7 (I3): codigo_area
- Columns 10-16 (StageDateField): dia_inicial, hora_inicial, meia_hora_inicial
- Columns 18-24 (StageDateField): dia_final, hora_final, meia_hora_final
- Columns 26-35 (F10.2): limite_inferior (minimum electrical reserve in MW)
"""
function parse_lm_record(line::AbstractString, filename::AbstractString, line_num::Int)
    # Extract codigo_area (columns 5-7, 1-indexed Julia)
    codigo_area = parse(Int, strip(extract_field(line, 5, 7)))

    # Extract initial stage date (based on RESPOT format)
    # Columns 10-11: day or "I " (2 chars)
    dia_inicial_str = strip(extract_field(line, 10, 11))
    dia_inicial =
        isempty(dia_inicial_str) ? 0 :
        (dia_inicial_str == "I" ? "I" : parse(Int, dia_inicial_str))

    # Columns 13-14: hour (2 chars, space-padded for single digits)
    hora_inicial_str = strip(extract_field(line, 13, 14))
    hora_inicial = isempty(hora_inicial_str) ? nothing : parse_int(hora_inicial_str)

    # Column 16: half-hour (1 char: 0 or 1)
    meia_hora_inicial_str = strip(extract_field(line, 16, 16))
    meia_hora_inicial =
        isempty(meia_hora_inicial_str) ? nothing : parse_int(meia_hora_inicial_str)

    # Extract final stage date
    # Columns 18-19: day or " F" (2 chars)
    dia_final_str = strip(extract_field(line, 18, 19))
    dia_final =
        isempty(dia_final_str) ? "F" :
        (dia_final_str == "F" ? "F" : parse(Int, dia_final_str))

    # Columns 21-22: hour (2 chars, optional for numeric final day)
    hora_final_str = strip(extract_field(line, 21, 22))
    hora_final = isempty(hora_final_str) ? nothing : parse_int(hora_final_str)

    # Column 24: half-hour (1 char, optional for numeric final day)
    meia_hora_final_str = strip(extract_field(line, 24, 24))
    meia_hora_final =
        isempty(meia_hora_final_str) ? nothing : parse_int(meia_hora_final_str)

    # Extract limite_inferior (columns 26-35, 1-indexed, F10.2)
    limite_str = strip(extract_field(line, 26, 35))
    limite_inferior = parse(Float64, limite_str)

    return RespoteLM(
        codigo_area = codigo_area,
        dia_inicial = dia_inicial,
        hora_inicial = hora_inicial,
        meia_hora_inicial = meia_hora_inicial,
        dia_final = dia_final,
        hora_final = hora_final,
        meia_hora_final = meia_hora_final,
        limite_inferior = limite_inferior,
    )
end

"""
    parse_respotele(io::IO, filename::AbstractString) -> RespoteleData

Parse complete RESPOTELE.DAT file.

Processes all RP (electrical reserve pool) and LM (limit) records, skipping comments and blank lines.

# Returns
`RespoteleData` containing vectors of RP and LM records.

# Example
```julia
data = open("respotele.dat") do io
    parse_respotele(io, "respotele.dat")
end
println("Electrical reserve pools: \$(length(data.rp_records))")
println("Limit records: \$(length(data.lm_records))")
```
"""
function parse_respotele(io::IO, filename::AbstractString)
    rp_records = RespoteleRP[]
    lm_records = RespoteLM[]

    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue

        # Identify record type by first 4 characters
        if length(line) < 4
            continue
        end

        identifier = strip(line[1:4])

        if identifier == "RP"
            record = parse_rp_record(line, filename, line_num)
            push!(rp_records, record)
        elseif identifier == "LM"
            record = parse_lm_record(line, filename, line_num)
            push!(lm_records, record)
        else
            # Unknown record type - skip silently (may be other markers)
            continue
        end
    end

    return RespoteleData(rp_records = rp_records, lm_records = lm_records)
end

# Convenience method for filename input
parse_respotele(filename::AbstractString) =
    open(io -> parse_respotele(io, filename), filename)

export parse_respotele, parse_rp_record, parse_lm_record

end  # module
