module IlstriParser

using ..DESSEM2Julia: IlstriData
using ..ParserCommon: is_comment_line, is_blank

export parse_ilstri

"""
    parse_ilstri(io, filename) -> IlstriData

Parse ILSTRI.DAT file (Ilha Solteira - Três Irmãos channel).
Currently implemented as a placeholder that reads raw lines.
"""
function parse_ilstri(io::IO, filename::AbstractString)
    lines = String[]

    for line in eachline(io)
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue

        push!(lines, strip(line))
    end

    return IlstriData(lines = lines)
end

# Convenience method
parse_ilstri(filename::AbstractString) = open(io -> parse_ilstri(io, filename), filename)

end # module
