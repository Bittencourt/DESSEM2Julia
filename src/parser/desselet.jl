"""
DESSELET.DAT parser (electrical network case mapping).
"""
module DesseletParser

using Dates
using ..Types: DesseletBaseCase, DesseletPatamar, DesseletData
using ..ParserCommon: ParserError

export parse_desselet

const DATEFMT = dateformat"yyyymmdd"

# Assemble filename pieces like ["leve", ".pwf"] -> "leve.pwf"
function _combine_filename(parts, start_idx::Int)
    combined = join(parts[start_idx:end], "")
    return combined
end

function _parse_base_case(line::AbstractString, filepath::String, line_num::Int)
    parts = split(strip(String(line)))
    length(parts) >= 3 || throw(ParserError("Invalid base case line", filepath, line_num, line))

    base_id = parse(Int, parts[1])
    label = parts[2]
    filename = length(parts) == 3 ? parts[3] : _combine_filename(parts, 3)

    return DesseletBaseCase(base_id=base_id, label=label, filename=filename)
end

function _parse_patamar(line::AbstractString, filepath::String, line_num::Int)
    parts = split(strip(String(line)))
    length(parts) >= 8 || throw(ParserError("Invalid patamar line", filepath, line_num, line))

    patamar_id = parse(Int, parts[1])
    name = parts[2]
    date_val = try
        Date(parts[3], DATEFMT)
    catch
        throw(ParserError("Invalid date field", filepath, line_num, line))
    end
    hour = parse(Int, parts[4])
    minute = parse(Int, parts[5])
    duration_hours = parse(Float64, replace(parts[6], "," => "."))
    base_case_id = parse(Int, parts[7])
    filename = _combine_filename(parts, 8)

    return DesseletPatamar(
        patamar_id=patamar_id,
        name=name,
        date=date_val,
        hour=hour,
        minute=minute,
        duration_hours=duration_hours,
        base_case_id=base_case_id,
        filename=filename,
    )
end

"""
    parse_desselet(filepath::AbstractString) -> DesseletData

Parse DESSELET.DAT network mapping file.
"""
function parse_desselet(filepath::AbstractString)::DesseletData
    base_cases = DesseletBaseCase[]
    patamares = DesseletPatamar[]
    section = :none

    open(filepath, "r") do io
        for (line_num, raw) in enumerate(eachline(io))
            stripped = strip(raw)
            isempty(stripped) && continue

            if occursin("Arquivos de caso base", stripped)
                section = :base
                continue
            elseif occursin("Alteracoes dos casos base", stripped)
                section = :patamar
                continue
            end

            if stripped == "99999"
                section = :none
                continue
            elseif uppercase(stripped) == "FIM"
                break
            end

            if startswith(stripped, "(") || startswith(stripped, "###")
                continue
            end

            try
                if section == :base
                    push!(base_cases, _parse_base_case(stripped, filepath, line_num))
                elseif section == :patamar
                    push!(patamares, _parse_patamar(stripped, filepath, line_num))
                end
            catch e
                if e isa ParserError
                    rethrow()
                else
                    throw(ParserError("Failed to parse DESSELET line", filepath, line_num, raw))
                end
            end
        end
    end

    return DesseletData(
        base_cases=base_cases,
        patamares=patamares,
        metadata=Dict("source" => String(filepath)),
    )
end

end # module
