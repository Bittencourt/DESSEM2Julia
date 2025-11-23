module MetasParser

using ..DESSEM2Julia: MetasData
using ..ParserCommon: is_comment_line, is_blank

export parse_metas

"""
    parse_metas(io, filename) -> MetasData

Parse METAS.DAT file (Weekly targets).
Currently implemented as a placeholder that reads raw lines.
"""
function parse_metas(io::IO, filename::AbstractString)
    lines = String[]

    for line in eachline(io)
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue

        push!(lines, strip(line))
    end

    return MetasData(lines = lines)
end

# Convenience method
parse_metas(filename::AbstractString) = open(io -> parse_metas(io, filename), filename)

end # module
