#!/usr/bin/env julia
"""
Simple Hydro Plant Tree Visualization

Shows complete hydro cascades in a tree structure.
"""

using DESSEM2Julia

function print_plant_tree(plant_num, plant_map, prefix="", is_last=true, visited=Set{Int}())
    """Print a single plant in tree format"""
    
    # Prevent infinite loops
    if plant_num in visited
        println(prefix * "↻ [CYCLE]")
        return
    end
    push!(visited, plant_num)
    
    plant = get(plant_map, plant_num, nothing)
    if plant === nothing
        return  # Skip missing plants silently
    end
    
    # Format plant info
    name = strip(plant.plant_name)
    if isempty(name)
        name = "[Unnamed]"
    end
    
    capacity = plant.installed_capacity !== nothing ? plant.installed_capacity : 0.0
    volume_min = plant.min_volume !== nothing ? plant.min_volume : 0.0
    volume_max = plant.max_volume !== nothing ? plant.max_volume : 0.0
    
    # Tree structure symbols
    connector = is_last ? "└─" : "├─"
    extension = is_last ? "  " : "│ "
    
    # Print plant
    println(prefix * connector * " 🏭 $name (#$plant_num)")
    println(prefix * extension * "   Capacity: $(round(capacity, digits=1)) MW")
    println(prefix * extension * "   Storage: $(round(volume_min, digits=0))-$(round(volume_max, digits=0)) hm³")
    
    # Continue to downstream plant if it exists
    if plant.downstream_plant !== nothing && plant.downstream_plant > 0
        downstream = get(plant_map, plant.downstream_plant, nothing)
        if downstream !== nothing
            println(prefix * extension * "   ⬇️")
            print_plant_tree(plant.downstream_plant, plant_map, prefix * extension, true, visited)
        end
    end
end

function main()
    ons_sample = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11", "hidr.dat")
    
    println("="^70)
    println("🌊 HYDRO POWER PLANT CASCADE VISUALIZATION")
    println("="^70)
    
    # Parse HIDR file
    data = parse_hidr(ons_sample)
    
    # Build plant map (excluding empty records)
    plant_map = Dict{Int, Any}()
    for plant in data.plants
        if plant.plant_num > 0
            plant_map[plant.plant_num] = plant
        end
    end
    
    println("\n📊 Summary:")
    println("   Total plants: $(length(plant_map))")
    
    # Calculate total capacity by subsystem
    subsystems = Dict{Int, Vector{Int}}()
    for (num, plant) in plant_map
        subsys = plant.subsystem
        if !haskey(subsystems, subsys)
            subsystems[subsys] = []
        end
        push!(subsystems[subsys], num)
    end
    
    total_capacity = sum(p.installed_capacity !== nothing ? p.installed_capacity : 0.0 for p in values(plant_map))
    println("   Total capacity: $(round(total_capacity, digits=1)) MW")
    println("   Subsystems: $(length(subsystems))")
    
    # Find some interesting complete cascades
    println("\n" * "="^70)
    println("🏔️  EXAMPLE CASCADES (Showing longest/most interesting)")
    println("="^70)
    
    # Pre-selected interesting cascades from the data
    interesting_cascades = [
        (14, "Caconde Cascade (Southeast - Paraná River)"),
        (20, "Bocaina Cascade (Southeast - Paranaíba River)"),
        (47, "Laydner Cascade (Southeast - Paranapanema River)"),
        (74, "Furnas Cascade (Southeast - Grande River)"),
        (117, "G.B. Munhoz Cascade (South - Iguaçu River)"),
        (145, "Passo Real Cascade (South - Jacuí River)"),
    ]
    
    for (idx, (root_num, description)) in enumerate(interesting_cascades)
        if haskey(plant_map, root_num)
            println("\n" * "─"^70)
            println("CASCADE #$idx: $description")
            println("─"^70)
            print_plant_tree(root_num, plant_map)
        end
    end
    
    # Show subsystem breakdown
    println("\n" * "="^70)
    println("🗺️  PLANTS BY SUBSYSTEM")
    println("="^70)
    
    subsystem_names = Dict(
        1 => "Southeast/Center-West",
        2 => "South",
        3 => "Northeast",
        4 => "North"
    )
    
    for subsys in sort(collect(keys(subsystems)))
        plants_in_subsys = subsystems[subsys]
        name = get(subsystem_names, subsys, "Unknown")
        capacity_subsys = sum(
            plant_map[num].installed_capacity !== nothing ? plant_map[num].installed_capacity : 0.0 
            for num in plants_in_subsys
        )
        
        println("\n📍 Subsystem $subsys - $name")
        println("   Plants: $(length(plants_in_subsys))")
        println("   Total capacity: $(round(capacity_subsys, digits=1)) MW")
        
        # Show first 3 plants as examples
        println("   Examples:")
        for (i, num) in enumerate(sort(plants_in_subsys)[1:min(3, length(plants_in_subsys))])
            plant = plant_map[num]
            name_str = strip(plant.plant_name)
            cap = plant.installed_capacity !== nothing ? plant.installed_capacity : 0.0
            println("      • $name_str (#$num) - $(round(cap, digits=1)) MW")
        end
    end
    
    println("\n" * "="^70)
    println("✅ Hydro data extraction complete!")
    println("="^70)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
