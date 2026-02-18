#!/usr/bin/env julia
"""
Network Analysis: Power Plants Grouped by Subsystem

This example demonstrates how to analyze the electrical network structure
by grouping power plants according to their subsystem (electrical region).

In DESSEM data:
- Subsystems represent major electrical regions (Southeast, South, Northeast, North)
- Each plant is assigned to a subsystem
- This is analogous to bus grouping in detailed network analysis

The example shows:
1. All thermal plants grouped by subsystem
2. All hydro plants grouped by subsystem
3. Total generation capacity per subsystem
4. Statistical analysis of plant distribution

Note: The ONS sample data includes network files (*.pwf) with detailed
bus-level topology, but those require specialized parsers. This example
uses the subsystem grouping available from ENTDADOS and TERMDAT.

Usage:
    julia --project=. examples/network_plants_by_subsystem.jl
"""

using DESSEM2Julia

# Path to ONS sample case (network-enabled)
sample_dir = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")

println("="^80)
println("DESSEM Network Analysis: Power Plants by Subsystem")
println("="^80)
println()

# ============================================================================
# 1. Load Data
# ============================================================================
println("📂 Loading network configuration data...")

entdados_file = joinpath(sample_dir, "entdados.dat")
termdat_file = joinpath(sample_dir, "termdat.dat")
hidr_file = joinpath(sample_dir, "hidr.dat")

entdados = parse_entdados(entdados_file)
termdat = parse_termdat(termdat_file)
hidr = parse_hidr(hidr_file)

# Handle both binary (BinaryHidrData with `records`) and text format (with `plants`)
hidr_records = hasproperty(hidr, :records) ? hidr.records : hidr.plants

println("✓ ENTDADOS: $(length(entdados.subsystems)) subsystems")
println("✓ TERMDAT:  $(length(termdat.plants)) thermal plants")
println("✓ HIDR:     $(length(hidr_records)) hydro plants")
println()

# Check network configuration from time periods
if !isempty(entdados.time_periods)
    first_period = entdados.time_periods[1]
    network_mode =
        first_period.network_flag == 0 ? "No network modeling" :
        first_period.network_flag == 1 ? "Network without losses" :
        first_period.network_flag == 2 ? "Network with losses" : "Unknown"
    println("🔌 Network Configuration: $network_mode")
    println()
end

# ============================================================================
# 2. Define Subsystem Names
# ============================================================================
subsystem_names = Dict(
    1 => "Southeast/Center-West (SE/CO)",
    2 => "South (S)",
    3 => "Northeast (NE)",
    4 => "North (N)",
)

# ============================================================================
# 3. Group Thermal Plants by Subsystem
# ============================================================================
println("="^80)
println("⚡ THERMAL POWER PLANTS BY SUBSYSTEM")
println("="^80)
println()

# Group thermal plants from TERMDAT
thermal_by_subsystem = Dict{Int,Vector{Any}}()
for plant in termdat.plants
    subsys = plant.subsystem
    if !haskey(thermal_by_subsystem, subsys)
        thermal_by_subsystem[subsys] = []
    end

    # Get capacity from ENTDADOS (has max_generation)
    entdados_plant = findfirst(p -> p.plant_num == plant.plant_num, entdados.thermal_plants)
    max_gen =
        !isnothing(entdados_plant) ?
        entdados.thermal_plants[entdados_plant].max_generation : 0.0

    # Get number of units
    units = filter(u -> u.plant_num == plant.plant_num, termdat.units)

    push!(
        thermal_by_subsystem[subsys],
        (
            plant_num = plant.plant_num,
            name = plant.plant_name,
            num_units = length(units),
            capacity = max_gen,
        ),
    )
end

# Display thermal plants by subsystem
for subsys in sort(collect(keys(thermal_by_subsystem)))
    plants = thermal_by_subsystem[subsys]
    name = get(subsystem_names, subsys, "Unknown")
    total_capacity = sum(p.capacity for p in plants)

    println("━"^80)
    println("📍 Subsystem $subsys - $name")
    println("━"^80)
    println("   Total Plants: $(length(plants))")
    println("   Total Capacity: $(round(total_capacity, digits=1)) MW")
    println()

    # Sort by capacity (descending)
    sort!(plants, by = p -> p.capacity, rev = true)

    # Show all plants
    println("   Plant# │ Plant Name           │ Units │ Capacity (MW)")
    println("   ───────┼──────────────────────┼───────┼──────────────")

    for plant in plants
        name_str = rpad(plant.name[1:min(length(plant.name), 20)], 20)
        println(
            "   $(lpad(plant.plant_num, 6)) │ $(name_str) │ $(lpad(plant.num_units, 5)) │ $(lpad(round(plant.capacity, digits=1), 12))",
        )
    end
    println()
end

# ============================================================================
# 4. Group Hydro Plants by Subsystem
# ============================================================================
println("="^80)
println("💧 HYDRO POWER PLANTS BY SUBSYSTEM")
println("="^80)
println()

# Group hydro plants
hydro_by_subsystem = Dict{Int,Vector{Any}}()
for plant in hidr_records
    # Handle both BinaryHidrRecord (Portuguese fields) and text format (English fields)
    plant_num = hasproperty(plant, :posto) ? plant.posto : plant.plant_num
    if plant_num <= 0  # Skip invalid/padding records
        continue
    end

    subsys = hasproperty(plant, :subsistema) ? plant.subsistema : plant.subsystem
    if !haskey(hydro_by_subsystem, subsys)
        hydro_by_subsystem[subsys] = []
    end

    # Get capacity from either potef_conjunto (binary) or installed_capacity (text)
    if hasproperty(plant, :potef_conjunto)
        capacity = sum(plant.numero_maquinas_conjunto[i] * plant.potef_conjunto[i] for i in 1:5)
    else
        capacity = plant.installed_capacity !== nothing ? plant.installed_capacity : 0.0
    end

    # Get plant name
    plant_name = hasproperty(plant, :nome) ? plant.nome : plant.plant_name

    # Get volume range
    if hasproperty(plant, :volume_minimo)
        min_vol = plant.volume_minimo
        max_vol = plant.volume_maximo
    else
        min_vol = plant.min_volume !== nothing ? plant.min_volume : 0.0
        max_vol = plant.max_volume !== nothing ? plant.max_volume : 0.0
    end

    push!(
        hydro_by_subsystem[subsys],
        (
            plant_num = plant_num,
            name = strip(plant_name),
            capacity = capacity,
            volume = (min_vol, max_vol),
        ),
    )
end

# Display hydro plants by subsystem (top 10 per subsystem for brevity)
for subsys in sort(collect(keys(hydro_by_subsystem)))
    plants = hydro_by_subsystem[subsys]
    name = get(subsystem_names, subsys, "Unknown")
    total_capacity = sum(p.capacity for p in plants)

    println("━"^80)
    println("📍 Subsystem $subsys - $name")
    println("━"^80)
    println("   Total Plants: $(length(plants))")
    println("   Total Capacity: $(round(total_capacity, digits=1)) MW")
    println()

    # Sort by capacity (descending)
    sort!(plants, by = p -> p.capacity, rev = true)

    # Show top 10 plants
    display_count = min(10, length(plants))
    println("   Top $display_count Plants by Capacity:")
    println("   Plant# │ Plant Name           │ Capacity (MW) │ Storage (hm³)")
    println("   ───────┼──────────────────────┼───────────────┼──────────────")

    for plant in plants[1:display_count]
        name_str = rpad(plant.name[1:min(length(plant.name), 20)], 20)
        storage_str = "$(round(plant.volume[1], digits=0))-$(round(plant.volume[2], digits=0))"
        println(
            "   $(lpad(plant.plant_num, 6)) │ $(name_str) │ $(lpad(round(plant.capacity, digits=1), 13)) │ $(rpad(storage_str, 14))",
        )
    end

    if length(plants) > display_count
        println("   ... and $(length(plants) - display_count) more plants")
    end
    println()
end

# ============================================================================
# 5. Summary Statistics
# ============================================================================
println("="^80)
println("📊 NETWORK SUMMARY STATISTICS")
println("="^80)
println()

total_thermal_capacity =
    sum(sum(p.capacity for p in plants) for plants in values(thermal_by_subsystem))
total_hydro_capacity =
    sum(sum(p.capacity for p in plants) for plants in values(hydro_by_subsystem))

println("System-Wide Totals:")
println("  Thermal Generation: $(round(total_thermal_capacity, digits=1)) MW")
println("  Hydro Generation:   $(round(total_hydro_capacity, digits=1)) MW")
println(
    "  Total Generation:   $(round(total_thermal_capacity + total_hydro_capacity, digits=1)) MW",
)
println()

println("Capacity by Subsystem:")
for subsys in sort(collect(keys(subsystem_names)))
    name = subsystem_names[subsys]
    thermal_cap =
        haskey(thermal_by_subsystem, subsys) ?
        sum(p.capacity for p in thermal_by_subsystem[subsys]) : 0.0
    hydro_cap =
        haskey(hydro_by_subsystem, subsys) ?
        sum(p.capacity for p in hydro_by_subsystem[subsys]) : 0.0
    total_cap = thermal_cap + hydro_cap

    thermal_pct =
        total_thermal_capacity > 0 ? 100 * thermal_cap / total_thermal_capacity : 0.0
    hydro_pct = total_hydro_capacity > 0 ? 100 * hydro_cap / total_hydro_capacity : 0.0

    println()
    println("  Subsystem $subsys - $name:")
    println(
        "    Thermal: $(rpad(round(thermal_cap, digits=1), 10)) MW ($(round(thermal_pct, digits=1))% of system)",
    )
    println(
        "    Hydro:   $(rpad(round(hydro_cap, digits=1), 10)) MW ($(round(hydro_pct, digits=1))% of system)",
    )
    println("    Total:   $(rpad(round(total_cap, digits=1), 10)) MW")

    num_thermal =
        haskey(thermal_by_subsystem, subsys) ? length(thermal_by_subsystem[subsys]) : 0
    num_hydro = haskey(hydro_by_subsystem, subsys) ? length(hydro_by_subsystem[subsys]) : 0
    println("    Plants:  $num_thermal thermal, $num_hydro hydro")
end

println()
println("="^80)
println("✅ Network Analysis Complete!")
println("="^80)
println()

println("💡 Notes:")
println("   - Subsystems represent major electrical regions")
println("   - Each subsystem can exchange power through interconnections")
println("   - Detailed bus-level topology available in *.pwf network files")
println("   - Use ENTDADOS network_config to check network modeling mode")
println()
