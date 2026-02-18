"""
Demonstration script: Parse sample DESSEM case and explore data structures

This script:
1. Parses dessem.arq to discover all input files
2. Parses available files (TERMDAT.DAT, ENTDADOS.DAT)
3. Shows sample data from the parsed structures
4. Demonstrates access patterns
"""

using DESSEM2Julia
using Dates

println("="^80)
println("DESSEM2Julia - Sample Data Parsing Demonstration")
println("="^80)
println()

# Sample data directory - use ONS sample which has more complete data
sample_dir = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")
println("📁 Sample directory: $sample_dir")
println()

# Step 1: Parse dessem.arq (master file index)
println("="^80)
println("Step 1: Parsing dessem.arq (Master File Index)")
println("="^80)

arq_path = joinpath(sample_dir, "dessem.arq")
arq = parse_dessemarq(arq_path)

println("✓ Successfully parsed dessem.arq")
println()
println("📋 File Registry:")
println("  CASO (case name):        $(arq.caso)")
println("  TITULO (title):          $(arq.titulo)")
println("  VAZOES (inflows):        $(arq.vazoes)")
println("  DADGER (general data):   $(arq.dadger)")
println("  CADTERM (thermal):       $(arq.cadterm)")
println("  CADUSIH (hydro):         $(arq.cadusih)")
println("  OPERUH (hydro ops):      $(arq.operuh)")
println("  OPERUT (thermal ops):    $(arq.operut)")
println("  MAPFCF (cut map):        $(arq.mapfcf)")
println("  CORTFCF (cuts):          $(arq.cortfcf)")
println("  EOLICA (renewables):     $(arq.eolica)")
println()

# Step 2: Parse TERMDAT.DAT (thermal plants)
println("="^80)
println("Step 2: Parsing TERMDAT.DAT (Thermal Plant Registry)")
println("="^80)

termdat_path = joinpath(sample_dir, arq.cadterm)
thermal_registry = parse_termdat(termdat_path)

println("✓ Successfully parsed $(arq.cadterm)")
println()
println("📊 Thermal System Summary:")
println("  Total plants: $(length(thermal_registry.plants))")
println("  Total units:  $(length(thermal_registry.units))")
println("  Heat curves:  $(length(thermal_registry.heat_curves))")
println()

# Show first 5 plants
println("🏭 First 5 Thermal Plants:")
println("  " * "─"^76)
println(
    "  $(rpad("Num", 5)) $(rpad("Name", 14)) $(rpad("Subsys", 8)) $(rpad("Fuel", 6)) $(rpad("Units", 7)) Heat Rate",
)
println("  " * "─"^76)
for (i, plant) in enumerate(thermal_registry.plants[1:min(5, end)])
    fuel_name =
        plant.fuel_type == 1 ? "Gas" :
        plant.fuel_type == 2 ? "Coal" :
        plant.fuel_type == 3 ? "Oil" :
        plant.fuel_type == 4 ? "Bio" : plant.fuel_type == 5 ? "Nuc" : "Other"
    println(
        "  $(rpad(plant.plant_num, 5)) $(rpad(plant.plant_name, 14)) " *
        "$(rpad(plant.subsystem, 8)) $(rpad(fuel_name, 6)) $(rpad(plant.num_units, 7)) " *
        "$(round(plant.heat_rate, digits=1)) kJ/kWh",
    )
end
println("  " * "─"^76)
println()

# Show sample units for first plant
first_plant_num = thermal_registry.plants[1].plant_num
plant_units = filter(u -> u.plant_num == first_plant_num, thermal_registry.units)
println("⚡ Units for plant $(first_plant_num) ($(thermal_registry.plants[1].plant_name)):")
println("  " * "─"^76)
println(
    "  $(rpad("Unit", 6)) $(rpad("Capacity", 12)) $(rpad("Min Gen", 10)) $(rpad("Ramp Up", 12)) Ramp Down",
)
println("  " * "─"^76)
for unit in plant_units
    println(
        "  $(rpad(unit.unit_num, 6)) $(rpad("$(round(unit.unit_capacity, digits=1)) MW", 12)) " *
        "$(rpad("$(round(unit.min_generation, digits=1)) MW", 10)) " *
        "$(rpad("$(isinf(unit.ramp_up_rate) ? "∞" : string(round(unit.ramp_up_rate, digits=1))) MW/h", 12)) " *
        "$(isinf(unit.ramp_down_rate) ? "∞" : string(round(unit.ramp_down_rate, digits=1))) MW/h",
    )
end
println("  " * "─"^76)
println()

# Show fuel type distribution
println("🔥 Fuel Type Distribution:")
fuel_counts = Dict{Int,Int}()
for plant in thermal_registry.plants
    fuel_counts[plant.fuel_type] = get(fuel_counts, plant.fuel_type, 0) + 1
end
fuel_names = Dict(
    1 => "Natural Gas",
    2 => "Coal",
    3 => "Oil/Diesel",
    4 => "Biomass",
    5 => "Nuclear",
    6 => "Other",
)
for (fuel_type, count) in sort(collect(fuel_counts))
    fuel_name = get(fuel_names, fuel_type, "Unknown")
    println("  $(rpad(fuel_name, 15)): $(count) plants")
end
println()

# Step 3: Parse ENTDADOS.DAT (general operational data)
println("="^80)
println("Step 3: Parsing ENTDADOS.DAT (General Operational Data)")
println("="^80)

entdados_path = joinpath(sample_dir, arq.dadger)
general_data = parse_entdados(entdados_path)

println("✓ Successfully parsed $(arq.dadger)")
println()
println("📊 General Data Summary:")
println("  Time periods:    $(length(general_data.time_periods))")
println("  Subsystems:      $(length(general_data.subsystems))")
println("  Hydro plants:    $(length(general_data.hydro_plants))")
println("  Thermal plants:  $(length(general_data.thermal_plants))")
println("  Demand records:  $(length(general_data.demands))")
println()

# Show time periods
println("⏰ Time Discretization (first 10 periods):")
println("  " * "─"^76)
println(
    "  $(rpad("Period", 8)) $(rpad("Day", 5)) $(rpad("Hour", 6)) $(rpad("Half", 6)) " *
    "$(rpad("Duration", 10)) $(rpad("Network", 9)) Load Level",
)
println("  " * "─"^76)
for (i, tm) in enumerate(general_data.time_periods[1:min(10, end)])
    network =
        tm.network_flag == 0 ? "No" :
        tm.network_flag == 1 ? "Yes" : tm.network_flag == 2 ? "Yes+Loss" : "?"
    println(
        "  $(rpad(i, 8)) $(rpad(tm.day, 5)) $(rpad(tm.hour, 6)) $(rpad(tm.half_hour, 6)) " *
        "$(rpad("$(tm.duration) h", 10)) $(rpad(network, 9)) $(tm.load_level)",
    )
end
println("  " * "─"^76)
println()

# Show subsystems
println("🗺️  Subsystems:")
println("  " * "─"^76)
println("  $(rpad("Num", 5)) $(rpad("Code", 6)) $(rpad("Status", 8)) Name")
println("  " * "─"^76)
for sist in general_data.subsystems
    println(
        "  $(rpad(sist.subsystem_num, 5)) $(rpad(sist.subsystem_code, 6)) " *
        "$(rpad(sist.status, 8)) $(sist.subsystem_name)",
    )
end
println("  " * "─"^76)
println()

# Show hydro plants by subsystem
println("💧 Hydro Plants by Subsystem (first 5 per subsystem):")
for sist in general_data.subsystems
    subsys_plants =
        filter(p -> p.subsystem == sist.subsystem_num, general_data.hydro_plants)
    if !isempty(subsys_plants)
        println()
        println(
            "  $(sist.subsystem_name) ($(sist.subsystem_code)): $(length(subsys_plants)) plants",
        )
        println("  " * "─"^74)
        println(
            "    $(rpad("Num", 5)) $(rpad("Name", 14)) $(rpad("Init Vol%", 11)) $(rpad("Min Vol", 10)) Max Vol",
        )
        println("  " * "─"^74)
        for plant in subsys_plants[1:min(5, end)]
            min_vol_str =
                isnothing(plant.min_volume) ? "N/A" : "$(round(plant.min_volume, digits=0))"
            max_vol_str =
                isnothing(plant.max_volume) ? "N/A" : "$(round(plant.max_volume, digits=0))"
            println(
                "    $(rpad(plant.plant_num, 5)) $(rpad(plant.plant_name, 14)) " *
                "$(rpad("$(round(plant.initial_volume_pct, digits=1))%", 11)) " *
                "$(rpad(min_vol_str, 10)) $(max_vol_str)",
            )
        end
        if length(subsys_plants) > 5
            println("    ... and $(length(subsys_plants) - 5) more plants")
        end
        println("  " * "─"^74)
    end
end
println()

# Show demand summary
println("📈 Demand Summary:")
total_demand = sum(d.demand for d in general_data.demands)
avg_demand = total_demand / length(general_data.demands)
println("  Total demand records: $(length(general_data.demands))")
println("  Average demand:       $(round(avg_demand, digits=1)) MW")
println()

# Demand by subsystem
println("  Demand by Subsystem (average):")
println("  " * "─"^76)
println("  $(rpad("Subsystem", 20)) $(rpad("Records", 10)) Average Demand")
println("  " * "─"^76)
for sist in general_data.subsystems
    subsys_demands = filter(d -> d.subsystem == sist.subsystem_num, general_data.demands)
    if !isempty(subsys_demands)
        avg = sum(d.demand for d in subsys_demands) / length(subsys_demands)
        println(
            "  $(rpad(sist.subsystem_name, 20)) $(rpad(length(subsys_demands), 10)) " *
            "$(round(avg, digits=1)) MW",
        )
    end
end
println("  " * "─"^76)
println()

# Step 4: Demonstrate data access patterns
println("="^80)
println("Step 4: Data Access Patterns")
println("="^80)
println()

# Find specific plant
println("🔍 Finding FURNAS hydro plant:")
furnas = findfirst(p -> occursin("FURNAS", p.plant_name), general_data.hydro_plants)
if !isnothing(furnas)
    plant = general_data.hydro_plants[furnas]
    println("  ✓ Found: $(plant.plant_name) (plant #$(plant.plant_num))")
    println("    Subsystem: $(plant.subsystem)")
    println("    Initial volume: $(plant.initial_volume_pct)% of useful capacity")
    if !isnothing(plant.min_volume)
        println("    Min volume: $(plant.min_volume) hm³")
    end
    if !isnothing(plant.max_volume)
        println("    Max volume: $(plant.max_volume) hm³")
    end
else
    println("  ⚠ FURNAS not found in this dataset")
end
println()

# Find largest thermal plant
println("🏆 Largest Thermal Plant:")
if !isempty(thermal_registry.units)
    local largest_unit = thermal_registry.units[1]
    for unit in thermal_registry.units[2:end]
        if unit.unit_capacity > largest_unit.unit_capacity
            largest_unit = unit
        end
    end
    local plant_idx =
        findfirst(p -> p.plant_num == largest_unit.plant_num, thermal_registry.plants)
    if !isnothing(plant_idx)
        plant_info = thermal_registry.plants[plant_idx]
        println("  Plant: $(plant_info.plant_name) (plant #$(plant_info.plant_num))")
        println(
            "  Unit #$(largest_unit.unit_num): $(round(largest_unit.unit_capacity, digits=1)) MW",
        )
        println("  Min generation: $(round(largest_unit.min_generation, digits=1)) MW")
    end
end
println()

# Calculate total installed capacity
println("💡 System Capacity Summary:")
thermal_capacity = sum(u.unit_capacity for u in thermal_registry.units)
println("  Total thermal capacity: $(round(thermal_capacity, digits=1)) MW")
println("  Number of thermal units: $(length(thermal_registry.units))")
println(
    "  Average unit size: $(round(thermal_capacity / length(thermal_registry.units), digits=1)) MW",
)
println()

# Step 5: Show new core type system integration
println("="^80)
println("Step 5: Core Type System Integration")
println("="^80)
println()

println("🏗️  Creating DessemCase with new type system:")
println()

# Create a partial DessemCase with the data we have
case = DessemCase(
    case_name = something(arq.caso, "UNKNOWN"),
    case_title = something(arq.titulo, ""),
    base_directory = sample_dir,
    file_registry = FileRegistry(
        caso = arq.caso,
        titulo = arq.titulo,
        vazoes = arq.vazoes,
        dadger = arq.dadger,
        cadterm = arq.cadterm,
        cadusih = arq.cadusih,
        operuh = arq.operuh,
        operut = arq.operut,
        mapfcf = arq.mapfcf,
        cortfcf = arq.cortfcf,
    ),
    metadata = Dict(
        "parse_time" => now(),
        "sample_dataset" => "DS_CCEE_102025_SEMREDE_RV0D28",
        "parser_version" => "0.1.0",
    ),
)

println("✓ DessemCase created successfully!")
println()
println("📦 Case Information:")
println("  Name:      $(case.case_name)")
println("  Title:     $(case.case_title)")
println("  Directory: $(case.base_directory)")
println()
println("📋 File Registry:")
println("  DADGER:  $(case.file_registry.dadger)")
println("  CADTERM: $(case.file_registry.cadterm)")
println("  CADUSIH: $(case.file_registry.cadusih)")
println("  VAZOES:  $(case.file_registry.vazoes)")
println()
println("ℹ️  Metadata:")
for (key, value) in case.metadata
    println("  $key: $value")
end
println()

println("="^80)
println("✅ Demonstration Complete!")
println("="^80)
println()
println("📚 Summary:")
println("  - Parsed dessem.arq master file index")
println(
    "  - Loaded thermal plant data ($(length(thermal_registry.plants)) plants, $(length(thermal_registry.units)) units)",
)
println("  - Loaded general operational data:")
println("    * $(length(general_data.time_periods)) time periods")
println("    * $(length(general_data.subsystems)) subsystems")
println("    * $(length(general_data.hydro_plants)) hydro plants")
println("    * $(length(general_data.thermal_plants)) thermal operations")
println("    * $(length(general_data.demands)) demand records")
println("  - Created DessemCase with new type system")
println()
println("🎯 Next steps: Implement parsers for remaining files (hidr.dat, operuh.dat, etc.)")
println()
