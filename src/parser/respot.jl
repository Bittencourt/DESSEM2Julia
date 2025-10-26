"""
RESPOT.DAT Parser

Parses power reserve requirement files containing:
- RP records: Reserve pool definitions (control area + time window)
- LM records: Minimum reserve limits (half-hourly time series)

# IDESSEM Reference
idessem/dessem/modelos/respot.py
- class RP: Reserve pool definition
- class LM: Reserve limit values

# File Format
Fixed-width columns with StageDateField pattern (month, day, hour, half, marker).
Typically 48 LM records per reserve pool (half-hourly requirements).

# Example
```
&
RP    1  11  0 0  F           5% CARGA DO SECO+SUL NO CAG SECO
&
LM    1  11  0 0  F            2732
LM    1  11  0 1  F            2632
...
```
"""
module RespotParser

using ..DESSEM2Julia: RespotRP, RespotLM, RespotData
using ..ParserCommon

# Import functions explicitly
import ..ParserCommon: extract_field, is_comment_line, is_blank, parse_int, parse_float

"""
    parse_rp_record(line::AbstractString, filename::AbstractString, line_num::Int) -> RespotRP

Parse a reserve pool definition record (RP).

# Format (Fixed-width columns per IDESEM)
- Columns 1-4: Identifier "RP  "
- Columns 5-7 (I3): codigo_area
- Columns 10-16 (StageDateField): dia_inicial, hora_inicial, meia_hora_inicial
  - Columns 10-11: month (if numeric) or special marker ("I")
  - Columns 14-15: hour
  - Column 17: half-hour (0 or 1)
- Columns 18-24 (StageDateField): dia_final, hora_final, meia_hora_final
  - Columns 18-19: day or "F"
  - Columns 22-23: hour (optional)
  - Column 25: half-hour (optional)
- Columns 31-70 (A40): descricao

# IDESEM Reference
```python
LINE = Line([
    IntegerField(3, 4),  # codigo_area (0-indexed pos 4-6)
    StageDateField(starting_position=9, special_day_character="I"),
    StageDateField(starting_position=17, special_day_character="F"),
    LiteralField(40, 30)  # description (0-indexed pos 30-69)
])
```
"""
function parse_rp_record(line::AbstractString, filename::AbstractString, line_num::Int)
    # Extract codigo_area (columns 5-7, 1-indexed Julia)
    codigo_area = parse(Int, strip(extract_field(line, 5, 7)))
    
    # Extract initial stage date (columns 10-16, 1-indexed)
    # Column 10-11: day or "I"
    dia_inicial_str = strip(extract_field(line, 10, 11))
    dia_inicial = isempty(dia_inicial_str) ? 0 : (dia_inicial_str == "I" ? "I" : parse(Int, dia_inicial_str))
    
    # Columns 14-15: hour (optional)
    hora_inicial_str = strip(extract_field(line, 14, 15))
    hora_inicial = isempty(hora_inicial_str) ? nothing : parse_int(hora_inicial_str)
    
    # Column 17: half-hour (optional)
    meia_hora_inicial_str = strip(extract_field(line, 17, 17))
    meia_hora_inicial = isempty(meia_hora_inicial_str) ? nothing : parse_int(meia_hora_inicial_str)
    
    # Extract final stage date (columns 18-24, 1-indexed)
    # Columns 18-19: day or "F"
    dia_final_str = strip(extract_field(line, 18, 19))
    dia_final = isempty(dia_final_str) ? "F" : (dia_final_str == "F" ? "F" : parse(Int, dia_final_str))
    
    # Columns 22-23: hour (optional)
    hora_final_str = strip(extract_field(line, 22, 23))
    hora_final = isempty(hora_final_str) ? nothing : parse_int(hora_final_str)
    
    # Column 25: half-hour (optional)
    meia_hora_final_str = strip(extract_field(line, 25, 25))
    meia_hora_final = isempty(meia_hora_final_str) ? nothing : parse_int(meia_hora_final_str)
    
    # Extract description (columns 31-70, 1-indexed)
    descricao = strip(extract_field(line, 31, 70))
    
    return RespotRP(
        codigo_area=codigo_area,
        dia_inicial=dia_inicial,
        hora_inicial=hora_inicial,
        meia_hora_inicial=meia_hora_inicial,
        dia_final=dia_final,
        hora_final=hora_final,
        meia_hora_final=meia_hora_final,
        descricao=descricao
    )
end

"""
    parse_lm_record(line::AbstractString, filename::AbstractString, line_num::Int) -> RespotLM

Parse a reserve limit record (LM).

# Format (Fixed-width columns per IDESEM)
- Columns 1-4: Identifier "LM  "
- Columns 5-7 (I3): codigo_area
- Columns 10-16 (StageDateField): dia_inicial, hora_inicial, meia_hora_inicial
- Columns 18-24 (StageDateField): dia_final, hora_final, meia_hora_final
- Columns 26-35 (F10.2): limite_inferior (minimum reserve in MW)

# IDESEM Reference
```python
LINE = Line([
    IntegerField(3, 4),  # codigo_area (0-indexed pos 4-6)
    StageDateField(starting_position=9, special_day_character="I"),
    StageDateField(starting_position=17, special_day_character="F"),
    FloatField(10, 25, 2)  # limite_inferior (0-indexed pos 25-34)
])
```
"""
function parse_lm_record(line::AbstractString, filename::AbstractString, line_num::Int)
    # Extract codigo_area (columns 5-7, 1-indexed Julia)
    codigo_area = parse(Int, strip(extract_field(line, 5, 7)))
    
    # Extract initial stage date (columns 10-16, 1-indexed)
    dia_inicial_str = strip(extract_field(line, 10, 11))
    dia_inicial = isempty(dia_inicial_str) ? 0 : (dia_inicial_str == "I" ? "I" : parse(Int, dia_inicial_str))
    
    hora_inicial_str = strip(extract_field(line, 14, 15))
    hora_inicial = isempty(hora_inicial_str) ? nothing : parse_int(hora_inicial_str)
    
    meia_hora_inicial_str = strip(extract_field(line, 17, 17))
    meia_hora_inicial = isempty(meia_hora_inicial_str) ? nothing : parse_int(meia_hora_inicial_str)
    
    # Extract final stage date (columns 18-24, 1-indexed)
    dia_final_str = strip(extract_field(line, 18, 19))
    dia_final = isempty(dia_final_str) ? "F" : (dia_final_str == "F" ? "F" : parse(Int, dia_final_str))
    
    hora_final_str = strip(extract_field(line, 22, 23))
    hora_final = isempty(hora_final_str) ? nothing : parse_int(hora_final_str)
    
    meia_hora_final_str = strip(extract_field(line, 25, 25))
    meia_hora_final = isempty(meia_hora_final_str) ? nothing : parse_int(meia_hora_final_str)
    
    # Extract limite_inferior (columns 26-35, 1-indexed, F10.2)
    limite_str = strip(extract_field(line, 26, 35))
    limite_inferior = parse(Float64, limite_str)
    
    return RespotLM(
        codigo_area=codigo_area,
        dia_inicial=dia_inicial,
        hora_inicial=hora_inicial,
        meia_hora_inicial=meia_hora_inicial,
        dia_final=dia_final,
        hora_final=hora_final,
        meia_hora_final=meia_hora_final,
        limite_inferior=limite_inferior
    )
end

"""
    parse_respot(io::IO, filename::AbstractString) -> RespotData

Parse complete RESPOT.DAT file.

Processes all RP (reserve pool) and LM (limit) records, skipping comments and blank lines.

# Returns
`RespotData` containing vectors of RP and LM records.

# Example
```julia
data = open("respot.dat") do io
    parse_respot(io, "respot.dat")
end
println("Reserve pools: \$(length(data.rp_records))")
println("Limit records: \$(length(data.lm_records))")
```
"""
function parse_respot(io::IO, filename::AbstractString)
    rp_records = RespotRP[]
    lm_records = RespotLM[]
    
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
    
    return RespotData(
        rp_records=rp_records,
        lm_records=lm_records
    )
end

# Convenience method for filename input
parse_respot(filename::AbstractString) = open(io -> parse_respot(io, filename), filename)

export parse_respot, parse_rp_record, parse_lm_record

end  # module
