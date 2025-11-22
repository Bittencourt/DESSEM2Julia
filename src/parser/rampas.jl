module RampasParser

using ..DESSEM2Julia: RampasRecord, RampasData
using ..ParserCommon: extract_field, is_comment_line, is_blank

"""
    parse_rampas_record(line, filename, line_num) -> RampasRecord

Parse a single RAMPAS record from a line.
"""
function parse_rampas_record(line::AbstractString, filename::AbstractString, line_num::Int)
    # Fixed width parsing based on sample file analysis
    # Cols 1-3: Plant ID
    # Cols 4-7: Unit ID
    # Cols 14: Config (S/C)
    # Cols 18: Type (A/D)
    # Cols 21-30: Power
    # Cols 32-36: Time
    # Cols 38: Flag

    usina = parse(Int, strip(extract_field(line, 1, 3)))
    unidade = parse(Int, strip(extract_field(line, 4, 7)))
    configuracao = strip(extract_field(line, 14, 14))
    tipo = strip(extract_field(line, 18, 18))
    potencia = parse(Float64, strip(extract_field(line, 21, 30)))
    tempo = parse(Int, strip(extract_field(line, 32, 36)))
    flag_meia_hora = parse(Int, strip(extract_field(line, 38, 38)))

    return RampasRecord(
        usina = usina,
        unidade = unidade,
        configuracao = configuracao,
        tipo = tipo,
        potencia = potencia,
        tempo = tempo,
        flag_meia_hora = flag_meia_hora,
    )
end

"""
    parse_rampas(io, filename) -> RampasData

Parse complete RAMPAS.DAT file.
"""
function parse_rampas(io::IO, filename::AbstractString)
    records = RampasRecord[]

    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue

        # Skip header "RAMP"
        strip(line) == "RAMP" && continue

        # Check for end of file marker
        startswith(strip(line), "FIM") && break

        # Parse record
        try
            record = parse_rampas_record(line, filename, line_num)
            push!(records, record)
        catch e
            # Optional: log warning or rethrow with context
            rethrow(
                ErrorException(
                    "Error parsing line $line_num in $filename: $line. Error: $e",
                ),
            )
        end
    end

    return RampasData(records = records)
end

parse_rampas(filename::AbstractString) = open(io -> parse_rampas(io, filename), filename)

export parse_rampas

end
