"""
MODIF.DAT Parser

Parser for DESSEM modification records (MODIF.DAT).

# Implementation Status

This parser implements **placeholder logic** that preserves raw line content.
The MODIF.DAT format allows runtime modifications to case data, but:
- No sample file exists in test data (CCEE or ONS)
- The reference IDESEM Python implementation has no parser for this file
- The format specification is not publicly documented

# Current Approach

Each non-comment, non-blank line is stored as a ModifRecord with the raw line
content, allowing:
- Data preservation for future analysis
- Manual inspection of modification records
- Passthrough to tools that understand the format

# Future Enhancement

When a sample file becomes available or the specification is documented,
this parser can be upgraded to extract structured modification data.
"""
module ModifParser

using ..DESSEM2Julia: ModifRecord, ModifData
using ..ParserCommon: is_comment_line, is_blank

"""
    parse_modif(io::IO) -> ModifData

Parse MODIF.DAT file (runtime case modifications).

Stores raw line content as no sample data or specification is available.
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
