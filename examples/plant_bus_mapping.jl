using JLD2
using DESSEM2Julia
using Printf

# Load the JLD2 file
jld2_path = joinpath("examples", "ons_sample.jld2")
if !isfile(jld2_path)
    error(
        "JLD2 file not found: $jld2_path. Please run examples/convert_ons_to_jld2.jl first.",
    )
end

println("📂 Loading JLD2 file: $jld2_path")
data = load(jld2_path)["data"]

# Helper to find file by suffix/name in the map
function find_file_data(data, filename_pattern)
    # First try exact match (case insensitive)
    for (fname, content) in data.files
        if uppercase(fname) == uppercase(filename_pattern)
            return fname, content
        end
    end

    # Then try suffix
    for (fname, content) in data.files
        if endswith(uppercase(fname), uppercase(filename_pattern))
            return fname, content
        end
    end

    # Finally try contains
    for (fname, content) in data.files
        if occursin(uppercase(filename_pattern), uppercase(fname))
            return fname, content
        end
    end
    return nothing, nothing
end

# 1. Extract Buses from PWF files (stored as raw strings)
buses = Dict{Int,String}() # Number -> Name
pwf_files = []

for (fname, content) in data.files
    if endswith(uppercase(fname), ".PWF")
        push!(pwf_files, fname)
        println("  Found PWF file: $fname")

        # Parse DBAR records
        # DBAR format: 
        # (     NUM  OP E  TENS  ANG  G  C  MIN  MAX  BSH  NAME        )
        # DBAR  1027 O      230  0.0  0  0    0    0    0  ANGRA 1     

        in_dbar = false
        for line in split(content, '\n')
            stripped_line = strip(line)
            if startswith(stripped_line, "DBAR")
                in_dbar = true
                continue
            end

            if in_dbar
                if startswith(stripped_line, "99999") ||
                   startswith(stripped_line, "GLIN") ||
                   startswith(stripped_line, "DGER")
                    in_dbar = false
                    continue
                end

                if startswith(stripped_line, "(") || isempty(stripped_line)
                    continue
                end

                # Fixed width parsing for DBAR
                # Num: 1-5
                # Name: 11-22 (12 chars)
                if length(line) >= 22
                    try
                        num_str = strip(line[1:5])
                        name_str = strip(line[11:22])

                        if !isempty(num_str)
                            num = parse(Int, num_str)
                            buses[num] = name_str
                        end
                    catch
                        # Ignore parse errors
                    end
                end
            end
        end
    end
end

println("  Parsed $(length(buses)) buses from PWF files.")
if haskey(buses, 90)
    println("  ✅ Bus 90 (ITAIPU) found: '$(buses[90])'")
else
    println("  ❌ Bus 90 (ITAIPU) NOT found!")
end
if haskey(buses, 32)
    println("  ✅ Bus 32 (CAPIM BRAN) found: '$(buses[32])'")
else
    println("  ❌ Bus 32 (CAPIM BRAN) NOT found!")
end

# 2. Extract Plants
hydro_plants = []
thermal_plants = []
renewable_plants = []
renewable_bus_map = Dict{Int,Int}() # PlantCode -> BusCode

# Hydro from HIDR.DAT
_, hidr_data = find_file_data(data, "HIDR.DAT")
if hidr_data !== nothing
    if hidr_data isa HidrData
        append!(hydro_plants, hidr_data.cadusih)
    elseif hidr_data isa BinaryHidrData
        append!(hydro_plants, hidr_data.records)
    end
end

# Thermal from TERMDAT.DAT
_, term_data = find_file_data(data, "TERMDAT.DAT")
if term_data !== nothing && term_data isa ThermalRegistry
    append!(thermal_plants, term_data.plants)
end

# Renewables from RENOVAVEIS.DAT
_, renov_data = find_file_data(data, "RENOVAVEIS.DAT")
if renov_data !== nothing && renov_data isa RenovaveisData
    append!(renewable_plants, renov_data.plants)
    for mapping in renov_data.bus_mappings
        renewable_bus_map[mapping.plant_code] = mapping.bus_code
    end
end

println("  Found $(length(hydro_plants)) hydro plants.")
println("  Found $(length(thermal_plants)) thermal plants.")
println("  Found $(length(renewable_plants)) renewable plants.")

# 3. Match Plants to Buses
println("\n🔗 Matching Plants to Buses...")

matches = []

# Helper for name normalization
function normalize_plant_name(name)
    n = uppercase(strip(name))
    n = replace(n, "SAO " => "S.")
    n = replace(n, "SANTO " => "STO.")
    n = replace(n, "SANTA " => "STA.")
    n = replace(n, "DOUTOR " => "DR.")
    n = replace(n, "PROFESSOR " => "PROF.")
    n = replace(n, "GOVERNADOR " => "GOV.")
    n = replace(n, "PRESIDENTE " => "PRES.")
    n = replace(n, " " => "")
    n = replace(n, "." => "")
    return n
end

# Helper to clean bus name for reverse matching
function clean_bus_name_for_match(name)
    n = uppercase(strip(name))
    # Remove common suffixes
    n = replace(n, r"-[A-Z]{2}.*" => "") # -MG..., -SP...
    n = replace(n, r"UHE.*" => "")
    n = replace(n, r"UTE.*" => "")
    n = replace(n, r"UNE.*" => "")
    n = replace(n, r"\d+$" => "") # Trailing numbers
    n = replace(n, r"^\d+\s+" => "") # Leading numbers (e.g. "0 ITAIPU")
    n = replace(n, r"^\d+" => "") # Leading numbers without space
    return strip(n)
end

# Known aliases for hard-to-match plants
const PLANT_ALIASES = Dict(
    "MDEMORAES" => "MASCAR",      # Mascarenhas de Moraes
    "EDACUNHA" => "ECUNHA",       # Euclides da Cunha
    "ASOLIVEIRA" => "ARMAND",     # Armando de Salles Oliveira
    "GBMUNHOZ" => "MUNHOZ",       # Governador Bento Munhoz
    "TRESIRMAOS" => "TRESIRMAO",  # Tres Irmaos
    "VOLTAGRANDE" => "VGRAND",    # Volta Grande
    "NOVAPONTE" => "NPONTE",      # Nova Ponte
    "CAPIMBRANC1" => "CAPIMBRAN", # Capim Branco 1
    "CAPIMBRANC2" => "CAPIMBRAN", # Capim Branco 2
    "SAOJOAO" => "SJOAO",         # Sao Joao
    "STABRANCAT" => "SBRANC",     # Santa Branca
    "SLTSANTIAGO" => "SANTIA",    # Salto Santiago
    "SGDECHOPIM" => "CHOPIM",     # Salto Grande Chopim
    "BAIXOIGUACU" => "BIGUAC",    # Baixo Iguacu
    "SJERONIMO" => "SJERO",       # Sao Jeronimo
    "PASSOFUNDO" => "PASSOFUND",  # Passo Fundo
    "MASCARENHAS" => "MASCARENHA",# Mascarenhas
)

bus_name_map = Dict(normalize_plant_name(name) => num for (num, name) in buses)

# Match Hydro
for plant in hydro_plants
    # Handle different struct types (Text vs Binary)
    p_name = hasproperty(plant, :plant_name) ? plant.plant_name : plant.nome
    p_num = hasproperty(plant, :plant_num) ? plant.plant_num : plant.posto

    # Skip empty records
    if p_num == 0 || isempty(strip(p_name))
        continue
    end

    norm_name = normalize_plant_name(p_name)

    # Check aliases
    if haskey(PLANT_ALIASES, norm_name)
        alias_search = PLANT_ALIASES[norm_name]
        # Try to find bus containing alias
        for (b_num, b_name) in buses
            norm_bus = normalize_plant_name(b_name)
            if occursin(alias_search, norm_bus)
                push!(
                    matches,
                    (
                        type = "Hydro",
                        id = p_num,
                        name = p_name,
                        bus = b_num,
                        bus_name = b_name,
                    ),
                )
                @goto next_hydro
            end
        end
    end

    bus_num = get(bus_name_map, norm_name, nothing)

    # If no exact match, try fuzzy match against ALL buses
    if bus_num === nothing
        best_match_len = 0

        for (b_num, b_name) in buses
            norm_bus = normalize_plant_name(b_name)
            clean_bus = clean_bus_name_for_match(b_name)
            norm_clean_bus = normalize_plant_name(clean_bus)

            # Strategy 1: Plant name inside Bus name (e.g. ANGRA1 in ANGRA1UNE001)
            if length(norm_name) >= 4 && occursin(norm_name, norm_bus)
                bus_num = b_num
                break
            end

            # Strategy 2: Cleaned Bus name inside Plant name (e.g. ITUTIN in ITUTINGA)
            if length(norm_clean_bus) >= 4 && occursin(norm_clean_bus, norm_name)
                if length(norm_clean_bus) > best_match_len
                    best_match_len = length(norm_clean_bus)
                    bus_num = b_num
                end
            end

            # Strategy 3: Plant name starts with Cleaned Bus name (e.g. ITUTINGA starts with ITUTIN)
            if length(norm_clean_bus) >= 4 && startswith(norm_name, norm_clean_bus)
                if length(norm_clean_bus) > best_match_len
                    best_match_len = length(norm_clean_bus)
                    bus_num = b_num
                end
            end
        end
    end

    if bus_num !== nothing
        push!(
            matches,
            (
                type = "Hydro",
                id = p_num,
                name = p_name,
                bus = bus_num,
                bus_name = buses[bus_num],
            ),
        )
    end

    @label next_hydro
end

# Match Thermal
for plant in thermal_plants
    norm_name = normalize_plant_name(plant.plant_name)
    bus_num = get(bus_name_map, norm_name, nothing)

    if bus_num === nothing
        best_match_len = 0

        for (b_num, b_name) in buses
            norm_bus = normalize_plant_name(b_name)
            clean_bus = clean_bus_name_for_match(b_name)
            norm_clean_bus = normalize_plant_name(clean_bus)

            if length(norm_name) >= 4 && occursin(norm_name, norm_bus)
                bus_num = b_num
                break
            end

            if length(norm_clean_bus) >= 4 && occursin(norm_clean_bus, norm_name)
                if length(norm_clean_bus) > best_match_len
                    best_match_len = length(norm_clean_bus)
                    bus_num = b_num
                end
            end
        end
    end

    if bus_num !== nothing
        push!(
            matches,
            (
                type = "Thermal",
                id = plant.plant_num,
                name = plant.plant_name,
                bus = bus_num,
                bus_name = buses[bus_num],
            ),
        )
    end
end

# Match Renewables
for plant in renewable_plants
    bus_num = get(renewable_bus_map, plant.plant_code, nothing)

    if bus_num !== nothing && haskey(buses, bus_num)
        push!(
            matches,
            (
                type = "Renewable",
                id = plant.plant_code,
                name = plant.plant_name,
                bus = bus_num,
                bus_name = buses[bus_num],
            ),
        )
    elseif bus_num !== nothing
        push!(
            matches,
            (
                type = "Renewable",
                id = plant.plant_code,
                name = plant.plant_name,
                bus = bus_num,
                bus_name = "Unknown Bus",
            ),
        )
    end
end

# 4. Output Results
println("\n📊 Match Results:")
println("--------------------------------------------------------------------------------")
@printf(
    "%-10s | %-5s | %-20s | %-5s | %-20s\n",
    "Type",
    "ID",
    "Plant Name",
    "Bus",
    "Bus Name"
)
println("--------------------------------------------------------------------------------")

# Sort by Type then ID
sort!(matches, by = x -> (x.type, x.id))

renewable_count = 0
for m in matches
    if m.type == "Renewable"
        global renewable_count += 1
        if renewable_count <= 10
            @printf(
                "%-10s | %-5d | %-20s | %-5d | %-20s\n",
                m.type,
                m.id,
                first(m.name, 20),
                m.bus,
                first(m.bus_name, 20)
            )
        end
    else
        @printf(
            "%-10s | %-5d | %-20s | %-5d | %-20s\n",
            m.type,
            m.id,
            first(m.name, 20),
            m.bus,
            first(m.bus_name, 20)
        )
    end
end

if renewable_count > 10
    println("... (and $(renewable_count - 10) more Renewable matches)")
end

println("--------------------------------------------------------------------------------")
println("Total Matches: $(length(matches))")
println("Hydro: $(count(x->x.type=="Hydro", matches)) / $(length(hydro_plants))")
println("Thermal: $(count(x->x.type=="Thermal", matches)) / $(length(thermal_plants))")
println(
    "Renewable: $(count(x->x.type=="Renewable", matches)) / $(length(renewable_plants))",
)

# Debug unmatched Hydro
println("\n--- Unmatched Hydro Debug (First 20) ---")
unmatched_count = 0
matched_ids = Set(m.id for m in matches if m.type == "Hydro")

for plant in hydro_plants
    # Handle different struct types
    p_id = hasproperty(plant, :plant_num) ? plant.plant_num : plant.posto
    p_name = hasproperty(plant, :plant_name) ? plant.plant_name : plant.nome

    # Skip empty records
    if p_id == 0 || isempty(strip(p_name))
        continue
    end

    if !(p_id in matched_ids)
        global unmatched_count += 1
        if unmatched_count <= 20
            norm_p_name = normalize_plant_name(p_name)
            println("Unmatched Hydro: ID=$p_id Name='$p_name' (Norm: '$norm_p_name')")

            # Find potential candidates (simple substring match)
            candidates = []
            search_term = length(norm_p_name) >= 4 ? norm_p_name[1:4] : norm_p_name

            for (b_num, b_name) in buses
                norm_b_name = normalize_plant_name(b_name)
                if occursin(search_term, norm_b_name)
                    push!(candidates, "$b_name ($b_num)")
                end
            end

            if !isempty(candidates)
                println("  Potential Candidates (contains '$search_term'):")
                for c in first(candidates, 5)
                    println("    - $c")
                end
                if length(candidates) > 5
                    println("    - ... and $(length(candidates)-5) more")
                end
            else
                println("  No candidates found containing '$search_term'")
            end
        end
    end
end
