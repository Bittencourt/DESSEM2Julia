module ModifParser

using ..DESSEM2Julia: ModifRecord, ModifData
using ..ParserCommon: is_comment_line, is_blank

"""
    parse_modif(io::IO) -> ModifData

Parse MODIF.DAT file.
Currently implements a skeleton parser that stores raw lines, as no sample data is available.
"""
function parse_modif(io::IO)
    records = ModifRecord[]

    for line in eachline(io)
        if is_comment_line(line) || is_blank(line)
            continue
        end

        # Placeholder: Store raw line
        push!(records, ModifRecord(line = String(line)))
    end

    return ModifData(records = records)
end

"""
    parse_modif(filename::String) -> ModifData

Parse MODIF.DAT file from a file path.
"""
parse_modif(filename::AbstractString) = open(io -> parse_modif(io), filename)

export parse_modif

end # module
