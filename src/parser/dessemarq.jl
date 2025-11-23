"""
Parser for DESSEM.ARQ file - the master index file that lists all DESSEM input files.

This file acts as a central registry, mapping mnemonic codes to actual filenames for all
input files in a DESSEM case study. Lines starting with '&' indicate optional/commented files.

Format:
    Mnemonic  Description                    Filename
    CASO      NOME DO CASO                   DAT
    VAZOES    VAZOES NATURAIS                dadvaz.dat
    DADGER    DADOS GERAIS DO PROBLEMA       entdados.dat
    ...

Reference: idessem/dessem/dessemarq.py (https://github.com/rjmalves/idessem)
"""
module DessemArqParser

export parse_dessemarq, DessemArq, DessemFileRecord

using ..DESSEM2Julia: ParserError

"""
    DessemFileRecord

Ordered entry from `dessem.arq` capturing mnemonic, description, and resolved
filename for a DESSEM input file. Maintains the original order of declarations
to support sequential processing requirements.
"""
Base.@kwdef struct DessemFileRecord
    mnemonic::String
    description::String = ""
    filename::String
end

"""
    DessemArq

Master file registry parsed from `dessem.arq`. Individual fields expose direct
access to each mnemonic, while the `files` vector preserves the declaration
order as `DessemFileRecord` entries for iteration.
"""
Base.@kwdef struct DessemArq
    caso::Union{String,Nothing} = nothing
    titulo::Union{String,Nothing} = nothing
    vazoes::Union{String,Nothing} = nothing
    dadger::Union{String,Nothing} = nothing
    mapfcf::Union{String,Nothing} = nothing
    cortfcf::Union{String,Nothing} = nothing
    cadusih::Union{String,Nothing} = nothing
    operuh::Union{String,Nothing} = nothing
    deflant::Union{String,Nothing} = nothing
    cadterm::Union{String,Nothing} = nothing
    operut::Union{String,Nothing} = nothing
    indelet::Union{String,Nothing} = nothing
    ilstri::Union{String,Nothing} = nothing
    cotasr11::Union{String,Nothing} = nothing
    simul::Union{String,Nothing} = nothing
    areacont::Union{String,Nothing} = nothing
    respot::Union{String,Nothing} = nothing
    mlt::Union{String,Nothing} = nothing
    tolperd::Union{String,Nothing} = nothing
    curvtviag::Union{String,Nothing} = nothing
    ptoper::Union{String,Nothing} = nothing
    infofcf::Union{String,Nothing} = nothing
    meta::Union{String,Nothing} = nothing
    ree::Union{String,Nothing} = nothing
    eolica::Union{String,Nothing} = nothing
    rampas::Union{String,Nothing} = nothing
    rstlpp::Union{String,Nothing} = nothing
    restseg::Union{String,Nothing} = nothing
    respotele::Union{String,Nothing} = nothing
    ilibs::Union{String,Nothing} = nothing
    dessopc::Union{String,Nothing} = nothing
    rmpflx::Union{String,Nothing} = nothing
    bateria::Union{String,Nothing} = nothing
    files::Vector{DessemFileRecord} = DessemFileRecord[]
end

"""
    parse_dessemarq(filepath::String) -> DessemArq

Parse a DESSEM.ARQ master index file to extract all input file references.

# Arguments
- `filepath::String`: Path to the dessem.arq file

# Returns
- `DessemArq`: Structure containing filenames for all DESSEM input files

# Format
The file is a fixed-format text file with three columns:
1. Mnemonic (8 chars): File identifier (e.g., "CASO", "VAZOES")
2. Description (40 chars): File description
3. Filename (variable): Actual filename or text content

Lines starting with '&' are comments (optional/disabled files) and are skipped.
Lines starting with '&M' are header lines and are skipped.

# Example
```julia
arq = parse_dessemarq("docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/dessem.arq")
println(arq.dadger)   # "entdados.dat"
println(arq.cadterm)  # "termdat.dat"
println(arq.simul)    # nothing (commented out)
```

# Throws
- `ParserError`: If the file cannot be read or parsed
"""
function parse_dessemarq(filepath::String)::DessemArq
    # Dictionary to collect file mappings and ordered registry
    files = Dict{Symbol,String}()
    records = DessemFileRecord[]

    try
        open(filepath, "r") do io
            for (line_num, line) in enumerate(eachline(io))
                # Skip empty lines
                isempty(strip(line)) && continue

                # Skip comment lines (starting with &)
                startswith(line, '&') && continue

                # Parse the line using fixed-width format
                # Format: MNEMONIC (col 1-10) DESCRIPTION (col 11-50) FILENAME (col 51+)
                if length(line) < 51
                    # Line too short, try to parse as space-separated
                    parts = split(strip(line))
                    length(parts) >= 2 || continue

                    mnemonic_token = parts[1]
                    filename = parts[end]

                    # Skip flags
                    if filename == "(F)" || filename == "(NF)"
                        filename = length(parts) >= 3 ? parts[end-1] : ""
                    end

                    isempty(filename) && continue

                    description = length(parts) > 2 ? join(parts[2:end-1], " ") : ""
                    mnemonic = lowercase(mnemonic_token)
                    files[Symbol(mnemonic)] = filename

                    record = DessemFileRecord(
                        mnemonic = uppercase(mnemonic_token),
                        description = description,
                        filename = filename,
                    )
                else
                    # Use fixed-width parsing
                    mnemonic_token = strip(line[1:10])
                    mnemonic = lowercase(mnemonic_token)
                    description = strip(line[11:50])
                    # Filename starts at column 51
                    filename_part = strip(line[51:end])

                    isempty(filename_part) && continue

                    files[Symbol(mnemonic)] = filename_part

                    record = DessemFileRecord(
                        mnemonic = uppercase(mnemonic_token),
                        description = description,
                        filename = filename_part,
                    )
                end

                # Ensure latest record wins while preserving order
                existing_index = findfirst(r -> r.mnemonic == record.mnemonic, records)
                if existing_index !== nothing
                    records[existing_index] = record
                else
                    push!(records, record)
                end
            end
        end
    catch e
        if isa(e, SystemError)
            # Provide full context to ParserError (message, file, line, content)
            throw(ParserError("Failed to read dessem.arq file", filepath, 0, string(e)))
        else
            rethrow(e)
        end
    end

    # Construct the DessemArq struct from the parsed files
    return DessemArq(
        caso = get(files, :caso, nothing),
        titulo = get(files, :titulo, nothing),
        vazoes = get(files, :vazoes, nothing),
        dadger = get(files, :dadger, nothing),
        mapfcf = get(files, :mapfcf, nothing),
        cortfcf = get(files, :cortfcf, nothing),
        cadusih = get(files, :cadusih, nothing),
        operuh = get(files, :operuh, nothing),
        deflant = get(files, :deflant, nothing),
        cadterm = get(files, :cadterm, nothing),
        operut = get(files, :operut, nothing),
        indelet = get(files, :indelet, nothing),
        ilstri = get(files, :ilstri, nothing),
        cotasr11 = get(files, :cotasr11, nothing),
        simul = get(files, :simul, nothing),
        areacont = get(files, :areacont, nothing),
        respot = get(files, :respot, nothing),
        mlt = get(files, :mlt, nothing),
        tolperd = get(files, :tolperd, nothing),
        curvtviag = get(files, :curvtviag, nothing),
        ptoper = get(files, :ptoper, nothing),
        infofcf = get(files, :infofcf, nothing),
        meta = get(files, :meta, nothing),
        ree = get(files, :ree, nothing),
        eolica = get(files, :eolica, nothing),
        rampas = get(files, :rampas, nothing),
        rstlpp = get(files, :rstlpp, nothing),
        restseg = get(files, :restseg, nothing),
        respotele = get(files, :respotele, nothing),
        ilibs = get(files, :ilibs, nothing),
        dessopc = get(files, :dessopc, nothing),
        rmpflx = get(files, :rmpflx, nothing),
        bateria = get(files, :bateria, nothing),
        files = records,
    )
end

end # module
