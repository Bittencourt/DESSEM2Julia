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

export parse_dessemarq, DessemArq

using ..DESSEM2Julia: ParserError

"""
    DessemArq

Structure representing the master index file (dessem.arq) that maps all DESSEM input files.

Each field contains the filename for a specific DESSEM input file. A value of `nothing` 
indicates the file is not specified (line was commented with '&' prefix).

# Fields
- `caso::Union{String, Nothing}`: Case name file
- `titulo::Union{String, Nothing}`: Study title text
- `vazoes::Union{String, Nothing}`: Natural flows file (DADVAZ)
- `dadger::Union{String, Nothing}`: General data file (ENTDADOS)
- `mapfcf::Union{String, Nothing}`: DECOMP cuts map file
- `cortfcf::Union{String, Nothing}`: DECOMP cuts file
- `cadusih::Union{String, Nothing}`: Hydroelectric plant registry (HIDR)
- `operuh::Union{String, Nothing}`: Hydro operational restrictions
- `deflant::Union{String, Nothing}`: Antecedent outflows
- `cadterm::Union{String, Nothing}`: Thermal plant registry (TERMDAT)
- `operut::Union{String, Nothing}`: Thermal unit operations
- `indelet::Union{String, Nothing}`: Electric network index (DESSELET)
- `ilstri::Union{String, Nothing}`: Pereira Barreto canal
- `cotasr11::Union{String, Nothing}`: Previous R11 quotas
- `simul::Union{String, Nothing}`: Simulation data
- `areacont::Union{String, Nothing}`: Power reserve registry
- `respot::Union{String, Nothing}`: Power reserve study
- `mlt::Union{String, Nothing}`: FPHA data (MLT)
- `tolperd::Union{String, Nothing}`: Loss tolerances
- `curvtviag::Union{String, Nothing}`: TVIAG propagation curve
- `ptoper::Union{String, Nothing}`: GNL plant operating point
- `infofcf::Union{String, Nothing}`: FCF cuts information
- `meta::Union{String, Nothing}`: Goal restrictions
- `ree::Union{String, Nothing}`: Equivalent energy reservoirs
- `eolica::Union{String, Nothing}`: Wind plants (renewables)
- `rampas::Union{String, Nothing}`: Trajectory file
- `rstlpp::Union{String, Nothing}`: LPP restrictions
- `restseg::Union{String, Nothing}`: Table restrictions
- `respotele::Union{String, Nothing}`: Electric network power reserve
- `ilibs::Union{String, Nothing}`: LIBS functionalities
- `dessopc::Union{String, Nothing}`: Execution options
- `rmpflx::Union{String, Nothing}`: Flow ramp

# Example
```julia
arq = parse_dessemarq("dessem.arq")
println("General data file: ", arq.dadger)  # "entdados.dat"
println("Thermal registry: ", arq.cadterm)  # "termdat.dat"
```
"""
Base.@kwdef struct DessemArq
    caso::Union{String, Nothing} = nothing
    titulo::Union{String, Nothing} = nothing
    vazoes::Union{String, Nothing} = nothing
    dadger::Union{String, Nothing} = nothing
    mapfcf::Union{String, Nothing} = nothing
    cortfcf::Union{String, Nothing} = nothing
    cadusih::Union{String, Nothing} = nothing
    operuh::Union{String, Nothing} = nothing
    deflant::Union{String, Nothing} = nothing
    cadterm::Union{String, Nothing} = nothing
    operut::Union{String, Nothing} = nothing
    indelet::Union{String, Nothing} = nothing
    ilstri::Union{String, Nothing} = nothing
    cotasr11::Union{String, Nothing} = nothing
    simul::Union{String, Nothing} = nothing
    areacont::Union{String, Nothing} = nothing
    respot::Union{String, Nothing} = nothing
    mlt::Union{String, Nothing} = nothing
    tolperd::Union{String, Nothing} = nothing
    curvtviag::Union{String, Nothing} = nothing
    ptoper::Union{String, Nothing} = nothing
    infofcf::Union{String, Nothing} = nothing
    meta::Union{String, Nothing} = nothing
    ree::Union{String, Nothing} = nothing
    eolica::Union{String, Nothing} = nothing
    rampas::Union{String, Nothing} = nothing
    rstlpp::Union{String, Nothing} = nothing
    restseg::Union{String, Nothing} = nothing
    respotele::Union{String, Nothing} = nothing
    ilibs::Union{String, Nothing} = nothing
    dessopc::Union{String, Nothing} = nothing
    rmpflx::Union{String, Nothing} = nothing
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
    # Dictionary to collect file mappings
    files = Dict{Symbol, String}()
    
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
                    parts = split(line)
                    length(parts) >= 2 || continue
                    
                    mnemonic = lowercase(parts[1])
                    filename = parts[end]
                    
                    # Skip flags
                    if filename == "(F)" || filename == "(NF)"
                        filename = length(parts) >= 3 ? parts[end-1] : ""
                    end
                    
                    if !isempty(filename) && filename != "(F)" && filename != "(NF)"
                        files[Symbol(mnemonic)] = filename
                    end
                else
                    # Use fixed-width parsing
                    mnemonic = lowercase(strip(line[1:10]))
                    # Description is in columns 11-50, filename starts at 51
                    filename_part = strip(line[51:end])
                    
                    # Skip if no filename specified
                    isempty(filename_part) && continue
                    
                    # Store the mapping
                    files[Symbol(mnemonic)] = filename_part
                end
            end
        end
    catch e
        if isa(e, SystemError)
            throw(ParserError("Failed to read dessem.arq file: $filepath", 0, e))
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
    )
end

end # module
