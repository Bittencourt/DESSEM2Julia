"""
Binary DECOMP Parsers

Parsers for binary integration files:
- INFOFCF.DEC
- MAPCUT.DEC
- CORTES.DEC

# Note
These parsers currently implement a placeholder logic as the binary specification
is not fully available. They read the file content into a raw buffer.
"""
module BinaryDecParser

using ..DESSEM2Julia:
    InfofcfRecord, InfofcfData, MapcutRecord, MapcutData, CortesRecord, CortesData

"""
    parse_infofcf(io::IO) -> InfofcfData

Parse INFOFCF.DEC file.
"""
function parse_infofcf(io::IO)
    # Read all bytes
    raw = read(io)
    record = InfofcfRecord(raw)
    return InfofcfData(records = [record])
end

parse_infofcf(filename::AbstractString) = open(parse_infofcf, filename)

"""
    parse_mapcut(io::IO) -> MapcutData

Parse MAPCUT.DEC file.
"""
function parse_mapcut(io::IO)
    raw = read(io)
    record = MapcutRecord(raw)
    return MapcutData(records = [record])
end

parse_mapcut(filename::AbstractString) = open(parse_mapcut, filename)

"""
    parse_cortes(io::IO) -> CortesData

Parse CORTES.DEC file.
"""
function parse_cortes(io::IO)
    raw = read(io)
    record = CortesRecord(raw)
    return CortesData(records = [record])
end

parse_cortes(filename::AbstractString) = open(parse_cortes, filename)

export parse_infofcf, parse_mapcut, parse_cortes

end # module
