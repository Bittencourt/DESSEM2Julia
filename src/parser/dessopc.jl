"""
Parser for DESSOPC.DAT - DESSEM execution options

This file contains solver and execution configuration options.

# IDESSEM Reference
idessem/dessem/modelos/dessopc.py
idessem/dessem/dessopc.py

# Format
- Keyword-value pairs
- Comments with '&' prefix
- Three types:
  1. Flag keywords (PINT, CPLEXLOG) - presence = enabled
  2. Single-value keywords (UCTPAR 2, UCTERM 2) - keyword + integer
  3. Multi-value keywords (CONSTDADOS 0 1) - keyword + multiple integers
"""
module DessOpcParser

using ..DESSEM2Julia: DessOpcData
using ..ParserCommon: is_comment_line, is_blank

"""
    parse_dessopc_line(line) -> Union{Tuple{Symbol, Any}, Nothing}

Parse a single line from DESSOPC.DAT.

Returns:
- `(keyword::Symbol, value)` where value can be:
  - `true` for flag keywords (PINT, CPLEXLOG, UCTBUSLOC)
  - `Int` for single-value keywords (UCTPAR, UCTERM)
  - `Vector{Int}` for multi-value keywords (CONSTDADOS, CROSSOVER)
- `nothing` for comments or blank lines

# IDESSEM Mapping
Based on idessem/dessem/modelos/dessopc.py:
- BlocoUctPar: "UCTPAR" + IntegerField(2, 7)
- BlocoUcTerm: "UCTERM" + IntegerField(2, 7)
- BlocoPint: "PINT" (flag only)
- BlocoRegraNPTV: "REGRANPTV" + IntegerField(5, 10)
- BlocoAvlCmo: "AVLCMO" + IntegerField(2, 7)
- BlocoCplexLog: "CPLEXLOG" (flag only)
- BlocoUctBusLoc: "UCTBUSLOC" (flag only)
- BlocoUctHeurFp: "UCTHEURFP" + 3 integers
- BlocoConstDados: "CONSTDADOS" + 2 integers
- BlocoAjusteFcf: "AJUSTEFCF" + 3 integers
- BlocoTolerIlh: "TOLERILH" + IntegerField(2, 10)
- BlocoCrossover: "CROSSOVER" + 4 integers
- BlocoEngolimento: "ENGOLIMENTO" + IntegerField(1, 12)
- BlocoTrataInviabIlha: "TRATA_INVIAB_ILHA" + IntegerField(1, 18)
"""
function parse_dessopc_line(line::AbstractString)
    # Skip comments and blank lines
    is_comment_line(line) && return nothing
    is_blank(line) && return nothing

    # Extract keyword (first word)
    parts = split(strip(line))
    isempty(parts) && return nothing

    keyword_str = uppercase(String(parts[1]))  # Normalize to uppercase
    keyword = Symbol(lowercase(keyword_str))

    # Flag-only keywords (presence = enabled)
    if keyword_str in ["PINT", "CPLEXLOG", "UCTBUSLOC"]
        return (keyword, true)
    end

    # Single-value keywords (but check for extended syntax first)
    if keyword_str in ["UCTPAR", "AVLCMO", "TOLERILH", "ENGOLIMENTO"]
        if length(parts) >= 2
            value = parse(Int, parts[2])
            return (keyword, value)
        else
            @warn "Keyword $keyword_str expects a value but none found"
            return nothing
        end
    end

    # UCTERM can have 1 or 3 values - treat as multi-value
    if keyword_str == "UCTERM"
        if length(parts) >= 2
            values = Int[]
            for i in 2:length(parts)
                try
                    push!(values, parse(Int, parts[i]))
                catch
                    break
                end
            end
            # If single value, return as Int; otherwise as Vector
            return (keyword, length(values) == 1 ? values[1] : values)
        else
            @warn "Keyword $keyword_str expects a value but none found"
            return nothing
        end
    end

    # Multi-value keywords
    if keyword_str in [
        "REGRANPTV",
        "CONSTDADOS",
        "UCTHEURFP",
        "AJUSTEFCF",
        "CROSSOVER",
        "TRATA_INVIAB_ILHA",
        "UCTESPERTO",
        "TRATA_TERM_TON",
    ]
        # Parse all remaining integers
        values = Int[]
        for i in 2:length(parts)
            try
                push!(values, parse(Int, parts[i]))
            catch
                # Skip non-integer tokens (shouldn't happen in well-formed files)
                continue
            end
        end

        # Some keywords can be flags OR have values
        if isempty(values) && keyword_str in ["TRATA_TERM_TON"]
            return (keyword, true)
        end

        return (keyword, values)
    end

    # Unknown keyword - store as true flag for single keywords
    if length(parts) == 1
        # Flag keyword
        return (keyword, true)
    else
        # Unknown keyword with values - skip to avoid type errors
        @warn "Unknown keyword with values: $keyword_str - skipping"
        return nothing
    end
end

"""
    parse_dessopc(io, filename) -> DessOpcData

Parse complete DESSOPC.DAT file.

# Arguments
- `io::IO`: Input stream
- `filename::AbstractString`: Filename for error messages

# Returns
- `DessOpcData`: Parsed execution options
"""
function parse_dessopc(io::IO, filename::AbstractString)
    data = DessOpcData()

    for (line_num, line) in enumerate(eachline(io))
        result = parse_dessopc_line(line)

        if result !== nothing
            keyword, value = result

            # Store in appropriate field
            if keyword == :uctpar
                data.uctpar = value
            elseif keyword == :ucterm
                # UCTERM can have 1 or 3 values - store first value as Int
                if isa(value, Int)
                    data.ucterm = value
                elseif isa(value, Vector{Int}) && !isempty(value)
                    data.ucterm = value[1]  # Store only first value for now
                end
            elseif keyword == :pint
                data.pint = value
            elseif keyword == :regranptv
                data.regranptv = value
            elseif keyword == :avlcmo
                data.avlcmo = value
            elseif keyword == :cplexlog
                data.cplexlog = value
            elseif keyword == :uctbusloc
                data.uctbusloc = value
            elseif keyword == :uctheurfp
                data.uctheurfp = value
            elseif keyword == :constdados
                data.constdados = value
            elseif keyword == :ajustefcf
                data.ajustefcf = value
            elseif keyword == :tolerilh
                data.tolerilh = value
            elseif keyword == :crossover
                data.crossover = value
            elseif keyword == :engolimento
                data.engolimento = value
            elseif keyword == :trata_inviab_ilha
                # Can be integer or flag
                if isa(value, Int)
                    data.trata_inviab_ilha = value
                elseif isa(value, Vector{Int}) && !isempty(value)
                    data.trata_inviab_ilha = value[1]
                else
                    data.trata_inviab_ilha = 1  # Default if flag only
                end
            elseif keyword == :uctesperto
                if isa(value, Vector{Int}) && !isempty(value)
                    data.uctesperto = value[1]
                else
                    data.uctesperto = 1
                end
            elseif keyword == :trata_term_ton
                data.trata_term_ton = true
            else
                # Store unknown keywords in other_options
                data.other_options[String(keyword)] = value
            end
        end
    end

    return data
end

"""
    parse_dessopc(filename) -> DessOpcData

Convenience method to parse DESSOPC.DAT from a filename.
"""
function parse_dessopc(filename::AbstractString)
    open(filename) do io
        parse_dessopc(io, filename)
    end
end

export parse_dessopc, parse_dessopc_line

end  # module
