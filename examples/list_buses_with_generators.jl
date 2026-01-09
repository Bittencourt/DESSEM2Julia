#!/usr/bin/env julia
"""
List All Buses with Connected Generators

This example demonstrates the enhanced PWF.jl integration to show:
1. All electrical buses in the network
2. Generators (hydro, thermal, renewable) connected to each bus
3. Bus attributes (voltage, subsystem, generation, load)
4. Statistics and summary information

Now uses PWF.jl for reliable ANAREDE .pwf file parsing instead of manual parsing.

Usage:
    julia --project=. examples/list_buses_with_generators.jl

Requirements:
    - PWF.jl package installed
    - ONS sample case with network files (DS_ONS_*)

Author: DESSEM2Julia Project
Date: 2025-01-04
"""

using DESSEM2Julia
using Printf
using DataFrames

# ============================================================================
# CONFIGURATION
# ============================================================================

# Path to ONS network-enabled sample case
SAMPLE_DIR = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")

# Output options
SHOW_ALL_BUSES = false  # Set to true to show all buses (may be long)
SHOW_UNMATCHED_GENERATORS = true  # Show generators that couldn't be matched to buses
MAX_BUSES_TO_SHOW = 50  # Limit output for readability

println("═"^100)
println(" DESSEM2Julia: Bus-to-Generator Mapping Analysis")
println(" Using PWF.jl for ANAREDE .pwf file parsing")
println("═"^100)
println()

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

"""
    normalize_name(name::String) -> String

Normalize plant/bus names for matching by removing common variations.
"""
function normalize_name(name::String)
    n = uppercase(strip(name))
    # Remove common abbreviations and spacing variations
    n = replace(n, r"\s+" => "")           # Remove all spaces
    n = replace(n, "-" => "")             # Remove hyphens
    n = replace(n, "." => "")             # Remove periods
    n = replace(n, "SAO" => "S.")
    n = replace(n, "SANTO" => "STO.")
    n = replace(n, "SANTA" => "STA.")
    n = replace(n, "DOUTOR" => "DR.")
    n = replace(n, "PROFESSOR" => "PROF.")
    n = replace(n, "GOVERNADOR" => "GOV.")
    n = replace(n, "PRESIDENTE" => "PRES.")
    return strip(n)
end

"""
    find_bus_for_plant(plant_name::String, buses::Vector{NetworkBus}) -> Union{NetworkBus, Nothing}

Find the most likely bus for a given plant name using fuzzy matching.
"""
function find_bus_for_plant(plant_name::String, buses::Vector{NetworkBus})
    norm_plant = normalize_name(plant_name)

    # Strategy 1: Exact match (after normalization)
    for bus in buses
        norm_bus = normalize_name(bus.name)
        if norm_plant == norm_bus
            return bus
        end
    end

    # Strategy 2: Plant name is contained in bus name
    for bus in buses
        norm_bus = normalize_name(bus.name)
        if length(norm_plant) >= 4 && occursin(norm_plant, norm_bus)
            return bus
        end
    end

    # Strategy 3: Bus name is contained in plant name
    for bus in buses
        norm_bus = normalize_name(bus.name)
        if length(norm_bus) >= 4 && occursin(norm_bus, norm_plant)
            return bus
        end
    end

    # Strategy 4: Partial match (first 6+ characters)
    if length(norm_plant) >= 6
        search_term = norm_plant[1:6]
        for bus in buses
            norm_bus = normalize_name(bus.name)
            if length(norm_bus) >= 6 && startswith(norm_bus, search_term)
                return bus
            end
        end
    end

    return nothing
end

# ============================================================================
# LOAD DATA
# ============================================================================

println("📂 Loading data from: $SAMPLE_DIR")
println()

# Check if sample directory exists
if !isdir(SAMPLE_DIR)
    error(
        "Sample directory not found: $SAMPLE_DIR\nPlease ensure ONS sample case is available.",
    )
end

# 1. Parse PWF files for network topology
println("🔌 Parsing ANAREDE .pwf files (using PWF.jl)...")

pwf_files = filter(f -> endswith(lowercase(f), ".pwf"), readdir(SAMPLE_DIR))

if isempty(pwf_files)
    error(
        "No .pwf files found in $SAMPLE_DIR\nThis example requires network-enabled ONS sample case.",
    )
end

# Parse the first PWF file (usually LEVE.PWF - light load)
pwf_file = joinpath(SAMPLE_DIR, pwf_files[1])
println("  Reading: $(basename(pwf_file))")

topology = parse_pwf_to_topology(pwf_file)
buses = topology.buses

println("  ✓ Loaded $(length(buses)) buses")
println("  ✓ Loaded $(length(topology.lines)) transmission lines")
println()

# 2. Parse generator data files
println("⚡ Parsing generator data...")

# Hydro plants
hidr_file = joinpath(SAMPLE_DIR, "hidr.dat")
if isfile(hidr_file)
    hidr_data = parse_hidr(hidr_file)
    hydro_plants = hidr_data.plants
    println("  ✓ HIDR.DAT: $(length(hydro_plants)) hydro plants")
else
    println("  ⚠ HIDR.DAT not found - skipping hydro plants")
    hydro_plants = []
end

# Thermal plants
termdat_file = joinpath(SAMPLE_DIR, "termdat.dat")
if isfile(termdat_file)
    termdat_data = parse_termdat(termdat_file)
    thermal_plants = termdat_data.plants
    println("  ✓ TERMDAT.DAT: $(length(thermal_plants)) thermal plants")
else
    println("  ⚠ TERMDAT.DAT not found - skipping thermal plants")
    thermal_plants = []
end

# Renewable plants
renov_file = joinpath(SAMPLE_DIR, "renovaveis.dat")
if isfile(renov_file)
    renov_data = parse_renovaveis(renov_file)
    renewable_plants = renov_data.plants
    println("  ✓ RENOVAVEIS.DAT: $(length(renewable_plants)) renewable plants")
else
    println("  ⚠ RENOVAVEIS.DAT not found - skipping renewable plants")
    renewable_plants = []
end

println()

# ============================================================================
# MATCH GENERATORS TO BUSES
# ============================================================================

println("🔗 Matching generators to buses...")

# Structure to hold bus-to-generator mappings
bus_generators = Dict{Int,Vector{NamedTuple}}()

# Initialize with all buses
for bus in buses
    bus_generators[bus.bus_number] = []
end

# Track matched and unmatched generators
matched_stats = Dict("hydro" => 0, "thermal" => 0, "renewable" => 0)
unmatched_generators = []

# Match hydro plants
for plant in hydro_plants
    if plant.plant_num <= 0 || isempty(strip(plant.plant_name))
        continue  # Skip invalid records
    end

    bus = find_bus_for_plant(plant.plant_name, buses)

    if bus !== nothing
        push!(
            bus_generators[bus.bus_number],
            (
                type = "Hydro",
                id = plant.plant_num,
                name = plant.plant_name,
                capacity = plant.installed_capacity,
            ),
        )
        matched_stats["hydro"] += 1
    else
        if SHOW_UNMATCHED_GENERATORS
            push!(
                unmatched_generators,
                (type = "Hydro", id = plant.plant_num, name = plant.plant_name),
            )
        end
    end
end

# Match thermal plants
for plant in thermal_plants
    if plant.plant_num <= 0 || isempty(strip(plant.plant_name))
        continue
    end

    bus = find_bus_for_plant(plant.plant_name, buses)

    if bus !== nothing
        # Get capacity from units if available
        total_capacity =
            sum(u.max_capacity for u in plant.units if u.max_capacity !== nothing)
        push!(
            bus_generators[bus.bus_number],
            (
                type = "Thermal",
                id = plant.plant_num,
                name = plant.plant_name,
                capacity = total_capacity,
            ),
        )
        matched_stats["thermal"] += 1
    else
        if SHOW_UNMATCHED_GENERATORS
            push!(
                unmatched_generators,
                (type = "Thermal", id = plant.plant_num, name = plant.plant_name),
            )
        end
    end
end

# Match renewable plants (using explicit bus mapping from RENOVAVEIS)
if !isempty(renewable_plants)
    # Create bus lookup
    bus_lookup = Dict(b.bus_number => b for b in buses)

    for plant in renewable_plants
        # Find bus mapping for this plant
        bus_mapping =
            findfirst(m -> m.plant_code == plant.plant_code, renov_data.bus_mappings)

        if bus_mapping !== nothing
            bus_num = bus_mapping.bus_code
            if haskey(bus_generators, bus_num)
                capacity =
                    plant.installed_capacity !== nothing ? plant.installed_capacity : 0.0
                push!(
                    bus_generators[bus_num],
                    (
                        type = "Renewable",
                        id = plant.plant_code,
                        name = plant.plant_name,
                        capacity = capacity,
                    ),
                )
                matched_stats["renewable"] += 1
            else
                if SHOW_UNMATCHED_GENERATORS
                    push!(
                        unmatched_generators,
                        (
                            type = "Renewable",
                            id = plant.plant_code,
                            name = plant.plant_name,
                        ),
                    )
                end
            end
        end
    end
end

println("  ✓ Matched $(matched_stats["hydro"]) hydro plants to buses")
println("  ✓ Matched $(matched_stats["thermal"]) thermal plants to buses")
println("  ✓ Matched $(matched_stats["renewable"]) renewable plants to buses")
println("  ⚠ Unmatched generators: $(length(unmatched_generators))")
println()

# ============================================================================
# DISPLAY RESULTS
# ============================================================================

println("═"^100)
println(" BUS-TO-GENERATOR MAPPING RESULTS")
println("═"^100)
println()

# Sort buses by number of connected generators (descending)
sorted_buses =
    sort(collect(buses), by = b -> length(bus_generators[b.bus_number]), rev = true)

# Statistics
buses_with_generators = count(b -> !isempty(bus_generators[b.bus_number]), buses)
total_capacity = sum(
    sum(g.capacity for g in bus_generators[b.bus_number] if g.capacity !== nothing) for
    b in buses
)

println("📊 STATISTICS:")
println("  Total buses: $(length(buses))")
println("  Buses with generators: $buses_with_generators")
println("  Total matched capacity: $(round(total_capacity, digits=1)) MW")
println("  Hydro plants matched: $(matched_stats["hydro"])")
println("  Thermal plants matched: $(matched_stats["thermal"])")
println("  Renewable plants matched: $(matched_stats["renewable"])")
println()

# ============================================================================
# DISPLAY BUSES WITH GENERATORS
# ============================================================================

println("═"^100)
println(" BUSES WITH CONNECTED GENERATORS")
println("═"^100)
println()

display_count = 0
for bus in sorted_buses
    generators = bus_generators[bus.bus_number]

    if !isempty(generators)
        display_count += 1

        if display_count > MAX_BUSES_TO_SHOW && !SHOW_ALL_BUSES
            remaining = count(
                b -> !isempty(bus_generators[b.bus_number]),
                sorted_buses[display_count:end],
            )
            println("... and $remaining more buses with generators")
            println()
            println("(Set SHOW_ALL_BUSES=true to see all buses)")
            break
        end

        # Bus header
        println("┌" * "─"^98 * "┐")
        println(
            "│ Bus $(lpad(bus.bus_number, 4)) │ $(rpad(bus.name, 50)) │ $(lpad(bus.subsystem, 5)) │ $(lpad(bus.voltage_kv !== nothing ? "$(bus.voltage_kv) kV" : "N/A", 10)) │",
        )
        println("└" * "─"^98 * "┘")

        # Bus attributes
        gen_mw = bus.generation_mw !== nothing ? bus.generation_mw : 0.0
        load_mw = bus.load_mw !== nothing ? bus.load_mw : 0.0

        println("  Attributes:")
        println(
            "    Voltage:    $(bus.voltage_kv !== nothing ? "$(bus.voltage_kv) kV" : "N/A")",
        )
        println("    Subsystem:  $(bus.subsystem)")
        println("    Generation: $(round(gen_mw, digits=1)) MW")
        println("    Load:       $(round(load_mw, digits=1)) MW")
        println()

        # Connected generators
        println("  Connected Generators ($(length(generators))):")

        # Group by type
        hydro_gens = filter(g -> g.type == "Hydro", generators)
        thermal_gens = filter(g -> g.type == "Thermal", generators)
        renewable_gens = filter(g -> g.type == "Renewable", generators)

        if !isempty(hydro_gens)
            println("    💧 Hydro:")
            for gen in sort(hydro_gens, by = g -> g.capacity, rev = true)
                cap_str =
                    gen.capacity !== nothing ? "$(round(gen.capacity, digits=1)) MW" : "N/A"
                println("      #$(lpad(gen.id, 3)) │ $(rpad(gen.name, 30)) │ $cap_str")
            end
        end

        if !isempty(thermal_gens)
            println("    ⚡ Thermal:")
            for gen in sort(thermal_gens, by = g -> g.capacity, rev = true)
                cap_str =
                    gen.capacity !== nothing && gen.capacity > 0 ?
                    "$(round(gen.capacity, digits=1)) MW" : "N/A"
                println("      #$(lpad(gen.id, 3)) │ $(rpad(gen.name, 30)) │ $cap_str")
            end
        end

        if !isempty(renewable_gens)
            println("    🌱 Renewable:")
            for gen in renewable_gens
                cap_str =
                    gen.capacity !== nothing && gen.capacity > 0 ?
                    "$(round(gen.capacity, digits=1)) MW" : "N/A"
                println("      #$(lpad(gen.id, 3)) │ $(rpad(gen.name, 30)) │ $cap_str")
            end
        end

        # Total capacity at this bus
        bus_capacity = sum(g.capacity for g in generators if g.capacity !== nothing)
        println("    ──────────────────────────────────────────────────────────────────")
        println("    Total Bus Capacity: $(round(bus_capacity, digits=1)) MW")
        println()
    end
end

# ============================================================================
# DISPLAY UNMATCHED GENERATORS (if requested)
# ============================================================================

if SHOW_UNMATCHED_GENERATORS && !isempty(unmatched_generators)
    println("═"^100)
    println(" UNMATCHED GENERATORS (First 50)")
    println("═"^100)
    println()
    println("Note: These generators could not be automatically matched to buses.")
    println("This may be due to:")
    println("  - Different naming conventions between plant and bus records")
    println("  - Plants connected to buses not in the network model")
    println("  - Data quality issues")
    println()

    display_unmatched = min(50, length(unmatched_generators))

    for gen in first(unmatched_generators, display_unmatched)
        println("  $(lpad(gen.type, 10)) │ #$(lpad(gen.id, 4)) │ $(gen.name)")
    end

    if length(unmatched_generators) > display_unmatched
        println(
            "  ... and $(length(unmatched_generators) - display_unmatched) more unmatched generators",
        )
    end

    println()
end

# ============================================================================
# SUBSYSTEM SUMMARY
# ============================================================================

println("═"^100)
println(" SUBSYSTEM SUMMARY")
println("═"^100)
println()

# Group by subsystem
subsystem_data = Dict{String,NamedTuple}()

for bus in buses
    subsys = bus.subsystem
    if isempty(subsys)
        subsys = "Unknown"
    end

    if !haskey(subsystem_data, subsys)
        subsystem_data[subsys] = (
            buses = 0,
            buses_with_gen = 0,
            total_capacity = 0.0,
            total_load = 0.0,
            total_gen = 0.0,
        )
    end

    data = subsystem_data[subsys]
    data = (
        buses = data.buses + 1,
        buses_with_gen = data.buses_with_gen +
                         (isempty(bus_generators[bus.bus_number]) ? 0 : 1),
        total_capacity = data.total_capacity + sum(
            g.capacity for g in bus_generators[bus.bus_number] if g.capacity !== nothing
        ),
        total_load = data.total_load + (bus.load_mw !== nothing ? bus.load_mw : 0.0),
        total_gen = data.total_gen +
                    (bus.generation_mw !== nothing ? bus.generation_mw : 0.0),
    )
    subsystem_data[subsys] = data
end

# Display subsystem summary
subsystem_names = Dict(
    "SE" => "Southeast",
    "S" => "South",
    "NE" => "Northeast",
    "N" => "North",
    "Unknown" => "Unknown",
)

for subsys in sort(collect(keys(subsystem_data)))
    data = subsystem_data[subsys]
    full_name = get(subsystem_names, subsys, subsys)

    println("📍 $full_name ($subsys):")
    println("  Buses: $(data.buses)")
    println("  Buses with generators: $(data.buses_with_gen)")
    println("  Total Installed Capacity: $(round(data.total_capacity, digits=1)) MW")
    println("  Base Case Generation: $(round(data.total_gen, digits=1)) MW")
    println("  Total Load: $(round(data.total_load, digits=1)) MW")
    println()
end

# ============================================================================
# CONCLUSION
# ============================================================================

println("═"^100)
println(" ✅ ANALYSIS COMPLETE")
println("═"^100)
println()

println("💡 Key Insights:")
println("   - Total buses in network: $(length(buses))")
println("   - Buses with matched generators: $buses_with_generators")
println(
    "   - Matching rate: $(round(100 * buses_with_generators / length(buses), digits=1))%",
)
println()

println("📖 Notes:")
println("   - This analysis uses PWF.jl for reliable ANAREDE .pwf file parsing")
println("   - Generator-to-bus matching uses fuzzy name matching")
println("   - Some generators may not match due to naming convention differences")
println("   - Base case generation/load values are from PWF, not optimized DESSEM results")
println()

println("🔧 To improve matching:")
println("   - Review unmatched generators and add aliases")
println("   - Use manual mapping for critical plants")
println("   - Check for naming convention patterns in your data")
println()
