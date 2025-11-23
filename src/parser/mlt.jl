module MltParser

using ..DESSEM2Julia: MltRecord, MltData

"""
    parse_mlt(io::IO) -> MltData

Parse MLT.DAT file.
"""
function parse_mlt(io::IO)
    records = MltRecord[]
    for line in eachline(io)
        push!(records, MltRecord(raw_line = line))
    end
    return MltData(records = records)
end

parse_mlt(filename::AbstractString) = open(parse_mlt, filename)

export parse_mlt

end # module
