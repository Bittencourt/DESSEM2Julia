module RestsegParser

using ..DESSEM2Julia:
    RestsegIndice, RestsegTabela, RestsegLimite, RestsegCelula, RestsegData
using ..ParserCommon
import ..ParserCommon: is_comment_line, is_blank

"""
    parse_restseg(io, filename) -> RestsegData

Parse RESTSEG.DAT (table constraints). The format in production files uses
keyworded lines beginning with "TABSEG" followed by a section keyword and
fields separated by variable whitespace. We avoid fixed-width assumptions and
tokenize safely while tolerating multiple spaces.
"""
function parse_restseg(io::IO, filename::AbstractString)
    indices = RestsegIndice[]
    tabelas = RestsegTabela[]
    limites = RestsegLimite[]
    celulas = RestsegCelula[]

    for (ln, raw) in enumerate(eachline(io))
        line = strip(raw)
        (isempty(line) || is_comment_line(line)) && continue
        startswith(line, "TABSEG") || continue

        # Normalize internal whitespace but keep description tail intact where needed
        # We split at most to detect the subkeyword, then branch per type.
        # Examples observed:
        # TABSEG INDICE     7 <descricao...>
        # TABSEG TABELA     7 CONTR  DREF    9004
        # TABSEG LIMITE     7        800
        # TABSEG CELULA     7        300             700         800

        m = match(r"^TABSEG\s+(\S+)(.*)$", line)
        m === nothing && continue
        kind = uppercase(String(m.captures[1]))
        rest = strip(String(m.captures[2]))

        if kind == "INDICE"
            # number + description tail
            m2 = match(r"^(\d+)\s+(.+)$", rest)
            if m2 === nothing
                # tolerate missing description
                try
                    idx = parse(Int, rest)
                    push!(indices, RestsegIndice(indice = idx, descricao = ""))
                catch
                    @warn "RESTSEG INDICE parse error" filename line = ln text = line
                end
            else
                idx = parse(Int, m2.captures[1])
                desc = strip(m2.captures[2])
                push!(indices, RestsegIndice(indice = idx, descricao = desc))
            end
        elseif kind == "TABELA"
            # idx tipo1 tipo2 num [pcarg]
            parts = split(rest)
            if length(parts) >= 4
                idx = parse(Int, parts[1])
                tipo1 = parts[2]
                tipo2 = parts[3]
                num::Union{Int,Nothing} = nothing
                pcarg = nothing
                # parts[4] may be numeric (e.g., DREF/RE codes) or string (e.g., CARGA S/SIN)
                if isnothing(tryparse(Int, parts[4]))
                    # Not a numeric code; treat as pcarg string
                    pcarg = String(parts[4])
                else
                    num = parse(Int, parts[4])
                    if length(parts) >= 5
                        pcarg = try
                            parse(Int, parts[5])
                        catch
                            String(parts[5])
                        end
                    end
                end
                push!(
                    tabelas,
                    RestsegTabela(
                        indice = idx,
                        tipo1 = tipo1,
                        tipo2 = tipo2,
                        num = num,
                        pcarg = pcarg,
                    ),
                )
            else
                @warn "RESTSEG TABELA parse error" filename line = ln text = line
            end
        elseif kind == "LIMITE"
            # idx value
            parts = split(rest)
            if length(parts) >= 2
                idx = parse(Int, parts[1])
                val = parse(Int, parts[end])
                push!(limites, RestsegLimite(indice = idx, limite = val))
            else
                @warn "RESTSEG LIMITE parse error" filename line = ln text = line
            end
        elseif kind == "CELULA"
            # idx limite [F] [par1_inf] [par1_sup]
            parts = split(rest)
            if length(parts) >= 2
                idx = parse(Int, parts[1])
                lim = parse(Int, parts[2])
                flag = nothing
                p1i = nothing
                p1s = nothing
                # Remaining tokens may include a single-letter flag then two ints
                if length(parts) >= 3
                    # If third token is non-numeric, treat as flag
                    if isnothing(tryparse(Int, parts[3]))
                        flag = parts[3]
                        if length(parts) >= 5
                            p1i = try
                                parse(Int, parts[4])
                            catch
                                nothing
                            end
                            p1s = try
                                parse(Int, parts[5])
                            catch
                                nothing
                            end
                        end
                    else
                        # No flag, only ranges
                        if length(parts) >= 4
                            p1i = try
                                parse(Int, parts[3])
                            catch
                                nothing
                            end
                            p1s = try
                                parse(Int, parts[4])
                            catch
                                nothing
                            end
                        end
                    end
                end
                push!(
                    celulas,
                    RestsegCelula(
                        indice = idx,
                        limite = lim,
                        flag = flag,
                        par1_inf = p1i,
                        par1_sup = p1s,
                    ),
                )
            else
                @warn "RESTSEG CELULA parse error" filename line = ln text = line
            end
        end
    end

    return RestsegData(
        indices = indices,
        tabelas = tabelas,
        limites = limites,
        celulas = celulas,
    )
end

parse_restseg(filename::AbstractString) = open(io -> parse_restseg(io, filename), filename)

export parse_restseg

end # module
