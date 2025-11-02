"""
DESSELET.DAT parser (electrical network case mapping).

This parser uses split() instead of fixed-width parsing because:
1. The actual data files use variable spacing between fields
2. All filenames in practice are single words without spaces (e.g., "leve.pwf", "pat01.afp")
3. IDESSEM's field positions don't match the actual data format

IDESSEM Reference: idessem/dessem/modelos/desselet.py
"""
module DesseletParser

using Dates
using ..Types: DesseletBaseCase, DesseletPatamar, DesseletData
using ..ParserCommon: is_comment_line, is_blank

export parse_desselet

"""
    parse_base_case_record(line, filename, line_num) -> DesseletBaseCase

Parse a single base case record from DESSELET.DAT.

# Format
```
1    leve          leve        .pwf
```

Fields: base_id, label, filename_parts...
"""
function parse_base_case_record(
    line::AbstractString,
    filename::AbstractString,
    line_num::Int,
)
    parts = split(strip(String(line)))
    length(parts) >= 3 ||
        error("Invalid base case line at $line_num: requires at least 3 fields")

    base_id = parse(Int, parts[1])
    label = parts[2]

    # Combine filename parts (e.g., ["leve", ".pwf"] → "leve.pwf")
    arquivo = join(parts[3:end], "")

    return DesseletBaseCase(base_id = base_id, label = label, filename = arquivo)
end

"""
    parse_modification_record(line, filename, line_num) -> DesseletPatamar

Parse a single modification record from DESSELET.DAT.

# Format
```
  01 Estagio01    20251011  0  0  0.5      1 pat01.afp
```

Fields: patamar_id, name, date, hour, minute, duration, base_case_id, filename
"""
function parse_modification_record(
    line::AbstractString,
    filename::AbstractString,
    line_num::Int,
)
    parts = split(strip(String(line)))
    length(parts) >= 8 ||
        error("Invalid patamar line at $line_num: requires at least 8 fields")

    patamar_id = parse(Int, parts[1])
    name = parts[2]

    # Date parsing
    date_str = parts[3]
    date_val = try
        Date(date_str, dateformat"yyyymmdd")
    catch e
        error("Invalid date format at line $line_num: '$date_str' - $e")
    end

    hour = parse(Int, parts[4])
    minute = parse(Int, parts[5])
    duration_hours = parse(Float64, parts[6])
    base_case_id = parse(Int, parts[7])

    # Combine filename parts if split (e.g., ["pat01", ".afp"] → "pat01.afp")
    file_mod = join(parts[8:end], "")

    return DesseletPatamar(
        patamar_id = patamar_id,
        name = name,
        date = date_val,
        hour = hour,
        minute = minute,
        duration_hours = duration_hours,
        base_case_id = base_case_id,
        filename = file_mod,
    )
end

"""
    parse_desselet(filepath) -> DesseletData

Parse DESSELET.DAT network mapping file.

This file maps DESSEM stages to Anarede network cases:
- Section 1: Base cases (PWF files)
- Section 2: Stage modifications (AFP pattern files)

# IDESSEM Reference
idessem/dessem/desselet.py
idessem/dessem/modelos/desselet.py
"""
function parse_desselet(filepath::AbstractString)::DesseletData
    base_cases = DesseletBaseCase[]
    patamares = DesseletPatamar[]
    section = :none

    open(filepath, "r") do io
        for (line_num, raw_line) in enumerate(eachline(io))
            # Skip comments and blank lines first
            is_comment_line(raw_line) && continue
            is_blank(raw_line) && continue

            # Skip header lines starting with ### or (###
            stripped = strip(raw_line)
            if startswith(stripped, "###") || startswith(stripped, "(###")
                continue
            end

            # Detect section markers
            if occursin(r"Arquivos de caso base"i, raw_line) ||
               occursin(r"Arquivos com caso base"i, raw_line)
                section = :base
                continue
            elseif occursin(r"Alteracoes dos casos base"i, raw_line) ||
                   occursin(r"Alterações dos casos base"i, raw_line)
                section = :patamar
                continue
            end

            # Section terminator
            if startswith(stripped, "99999")
                section = :none
                continue
            end

            # End of file marker
            if occursin(r"^\s*FIM\s*$"i, raw_line)
                break
            end

            # Parse data lines
            try
                if section == :base
                    record = parse_base_case_record(raw_line, filepath, line_num)
                    push!(base_cases, record)
                elseif section == :patamar
                    record = parse_modification_record(raw_line, filepath, line_num)
                    push!(patamares, record)
                end
            catch e
                @warn "Failed to parse DESSELET line" filepath line_num line = raw_line exception =
                    (e, catch_backtrace())
                rethrow()
            end
        end
    end

    return DesseletData(
        base_cases = base_cases,
        patamares = patamares,
        metadata = Dict("source" => String(filepath)),
    )
end

# Convenience method for IO
parse_desselet(io::IO, filename::AbstractString) = parse_desselet(filename)

end # module
