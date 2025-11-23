module TolperdParser

using ..DESSEM2Julia: TolperdData
using ..ParserCommon: is_comment_line, is_blank

export parse_tolperd

"""
    parse_tolperd(io, filename) -> TolperdData

Parse TOLPERD.DAT file (Loss tolerance parameters).
Currently implemented as a placeholder that reads raw lines.
"""
function parse_tolperd(io::IO, filename::AbstractString)
    lines = String[]

    for line in eachline(io)
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue

        push!(lines, strip(line))
    end

    return TolperdData(lines = lines)
end

# Convenience method
parse_tolperd(filename::AbstractString) = open(io -> parse_tolperd(io, filename), filename)

end # module
