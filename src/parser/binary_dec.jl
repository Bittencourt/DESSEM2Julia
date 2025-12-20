"""
Binary DECOMP Parsers

Parsers for binary integration files from DECOMP:
- INFOFCF.DEC - Information about Future Cost Function cuts
- MAPCUT.DEC - Cut mapping header from DECOMP
- CORTES.DEC - Future Cost Function cuts from DECOMP

# Implementation Status

These parsers implement **placeholder logic** that preserves raw binary content.
The binary format specifications are proprietary to CEPEL and not publicly documented.
The reference IDESEM Python implementation only stores filename references for these
files without parsing the binary content.

# Current Approach

Each parser reads the complete file into a raw byte buffer, allowing:
- Data preservation for future analysis
- Passthrough to other tools that understand the format
- Size validation and basic integrity checks

# Future Enhancement

When/if the binary specification becomes available, these parsers can be upgraded
to extract structured data (cut coefficients, RHS values, entity mappings, etc.).
"""
module BinaryDecParser

using ..DESSEM2Julia:
    InfofcfRecord, InfofcfData, MapcutRecord, MapcutData, CortesRecord, CortesData

"""
    parse_infofcf(io::IO) -> InfofcfData

Parse INFOFCF.DEC binary file (Future Cost Function cut information).

Stores raw binary content as the format specification is not publicly available.
"""
function parse_infofcf(io::IO)
    raw = read(io)
    record = InfofcfRecord(raw)
    return InfofcfData(records = [record])
end

parse_infofcf(filename::AbstractString) = open(parse_infofcf, filename)

"""
    parse_mapcut(io::IO) -> MapcutData

Parse MAPCUT.DEC binary file (DECOMP cut mapping header).

Stores raw binary content as the format specification is not publicly available.
"""
function parse_mapcut(io::IO)
    raw = read(io)
    record = MapcutRecord(raw)
    return MapcutData(records = [record])
end

parse_mapcut(filename::AbstractString) = open(parse_mapcut, filename)

"""
    parse_cortes(io::IO) -> CortesData

Parse CORTES.DEC binary file (Future Cost Function cuts from DECOMP).

Stores raw binary content as the format specification is not publicly available.
"""
function parse_cortes(io::IO)
    raw = read(io)
    record = CortesRecord(raw)
    return CortesData(records = [record])
end

parse_cortes(filename::AbstractString) = open(parse_cortes, filename)

export parse_infofcf, parse_mapcut, parse_cortes

end # module
