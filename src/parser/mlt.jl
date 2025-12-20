module MltParser

using ..DESSEM2Julia: MltData

"""
    parse_mlt(io::IO) -> MltData

Parse MLT.DAT binary file (FPHA - Hydraulic Production Function Approximation).

MLT.DAT is a binary file containing pre-computed data for the hydraulic production
function. The format is not publicly documented. This parser stores the raw binary
content, preserving it for future use or analysis.

# Note
This is a placeholder implementation. The binary format specification is not
available in the reference IDESEM implementation.
"""
function parse_mlt(io::IO)
    raw_bytes = read(io)
    return MltData(raw_bytes = raw_bytes, size = length(raw_bytes))
end

parse_mlt(filename::AbstractString) = open(parse_mlt, filename)

export parse_mlt

end # module
