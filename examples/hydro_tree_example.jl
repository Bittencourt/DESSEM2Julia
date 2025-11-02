#!/usr/bin/env julia
"""
Hydro Power Plant Tree Structure Example

This script demonstrates:
1. Parsing HIDR.DAT file (binary format)
2. Extracting hydro plant data
3. Building a tree structure showing downstream relationships
4. Visualizing the cascade of reservoirs
"""

using DESSEM2Julia

function build_plant_map(plants)
    """Build a dictionary mapping plant_num -> plant for quick lookup"""
    plant_map = Dict{Int,Any}()
    for plant in plants
        if plant.plant_num > 0  # Skip empty/padding records
            plant_map[plant.plant_num] = plant
        end
    end
    return plant_map
end

function find_upstream_plants(plant_num, plant_map)
    """Find all plants that flow into this plant"""
    upstream = []
    for (num, plant) in plant_map
        if plant.downstream_plant == plant_num
            push!(upstream, num)
        end
    end
    return sort(upstream)
end

function find_root_plants(plant_map)
    """Find plants with no upstream (cascade starting points)"""
    # Get all plant numbers that are downstream of something
    downstream_plants = Set{Int}()
    for (num, plant) in plant_map
        if plant.downstream_plant !== nothing && plant.downstream_plant > 0
            push!(downstream_plants, plant.downstream_plant)
        end
    end

    # Root plants are those NOT in downstream set
    roots = []
    for (num, plant) in plant_map
        if num ∉ downstream_plants
            push!(roots, num)
        end
    end
    return sort(roots)
end

function print_tree(plant_num, plant_map, indent = 0, visited = Set{Int}())
    """Recursively print the plant tree structure"""

    # Prevent infinite loops
    if plant_num in visited
        println("  "^indent * "↻ [CYCLE DETECTED]")
        return
    end
    push!(visited, plant_num)

    plant = get(plant_map, plant_num, nothing)
    if plant === nothing
        println("  "^indent * "⚠️  Plant #$plant_num [NOT FOUND]")
        return
    end

    # Format plant info
    name = strip(plant.plant_name)
    if isempty(name)
        name = "[Unnamed]"
    end

    capacity = plant.installed_capacity !== nothing ? plant.installed_capacity : 0.0
    volume_min = plant.min_volume !== nothing ? plant.min_volume : 0.0
    volume_max = plant.max_volume !== nothing ? plant.max_volume : 0.0

    # Print plant info
    prefix = indent == 0 ? "🏔️ " : "└─ "
    println("  "^indent * "$prefix $name (#$plant_num)")
    println("  "^indent * "   ├─ Capacity: $(round(capacity, digits=1)) MW")
    println(
        "  "^indent *
        "   ├─ Volume: $(round(volume_min, digits=1)) - $(round(volume_max, digits=1)) hm³",
    )
    println("  "^indent * "   └─ Subsystem: $(plant.subsystem)")

    # Find and print downstream plant
    if plant.downstream_plant !== nothing && plant.downstream_plant > 0
        println("  "^indent * "   ⬇️  Flows to:")
        print_tree(plant.downstream_plant, plant_map, indent + 1, visited)
    else
        println("  "^indent * "   🌊 [Final discharge - no downstream plant]")
    end
end

function print_cascade_summary(plant_map)
    """Print summary statistics of cascades"""
    println("\n" * "="^70)
    println("HYDRO CASCADE SUMMARY")
    println("="^70)

    roots = find_root_plants(plant_map)

    println("\n📊 Statistics:")
    println("   Total plants: $(length(plant_map))")
    println("   Cascade starting points: $(length(roots))")

    # Count plants by subsystem
    subsystems = Dict{Int,Int}()
    total_capacity = 0.0
    for (num, plant) in plant_map
        subsystems[plant.subsystem] = get(subsystems, plant.subsystem, 0) + 1
        if plant.installed_capacity !== nothing
            total_capacity += plant.installed_capacity
        end
    end

    println("\n🔌 Total installed capacity: $(round(total_capacity, digits=1)) MW")

    println("\n🗺️  Plants by subsystem:")
    for (subsys, count) in sort(collect(subsystems))
        println("   Subsystem $subsys: $count plants")
    end
end

function main()
    # Check for ONS sample file
    ons_sample =
        joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11", "hidr.dat")

    if !isfile(ons_sample)
        println("❌ Error: Sample file not found at: $ons_sample")
        println("\nPlease provide a valid HIDR.DAT file path.")
        return
    end

    println("="^70)
    println("HYDRO POWER PLANT CASCADE VISUALIZATION")
    println("="^70)
    println("\n📂 Reading: $ons_sample")

    # Parse the HIDR file
    try
        data = parse_hidr(ons_sample)
        println("✅ Successfully parsed HIDR.DAT")
        println("   Format: Binary (792 bytes/plant)")
        println("   Plants found: $(length(data.plants))")

        # Build plant lookup map
        plant_map = build_plant_map(data.plants)
        println("   Valid plants (excluding padding): $(length(plant_map))")

        # Print summary
        print_cascade_summary(plant_map)

        # Find cascade starting points
        roots = find_root_plants(plant_map)

        println("\n" * "="^70)
        println("HYDRO CASCADES (Root → Downstream)")
        println("="^70)

        if isempty(roots)
            println(
                "\n⚠️  Warning: No root plants found (all plants seem to have upstream)",
            )
            println("This might indicate circular references or data issues.")

            # Show first 5 plants anyway
            println("\nShowing first 5 plants:")
            count = 0
            for (num, plant) in sort(collect(plant_map), by = x -> x[1])
                if count >= 5
                    break
                end
                println("\n" * "-"^70)
                print_tree(num, plant_map)
                count += 1
            end
        else
            println("\nFound $(length(roots)) cascade(s):\n")

            # Limit to first 10 cascades to avoid overwhelming output
            display_count = min(length(roots), 10)

            for (idx, root) in enumerate(roots[1:display_count])
                println("\n" * "-"^70)
                println("CASCADE #$idx of $(length(roots))")
                println("-"^70)
                print_tree(root, plant_map)
            end

            if length(roots) > display_count
                println("\n" * "-"^70)
                println(
                    "⚠️  Showing only first $display_count of $(length(roots)) cascades",
                )
                println("(Many plants may be independent/single-reservoir systems)")
            end
        end

        # Show example of finding upstream relationships
        println("\n" * "="^70)
        println("UPSTREAM ANALYSIS EXAMPLE")
        println("="^70)

        # Find a plant with downstream connection
        example_plant = nothing
        for (num, plant) in plant_map
            if plant.downstream_plant !== nothing && plant.downstream_plant > 0
                example_plant = plant
                break
            end
        end

        if example_plant !== nothing
            downstream_num = example_plant.downstream_plant
            upstream_plants = find_upstream_plants(downstream_num, plant_map)

            downstream = plant_map[downstream_num]
            println(
                "\n🎯 Example: Plant #$(downstream_num) - $(strip(downstream.plant_name))",
            )
            println("   Receives water from $(length(upstream_plants)) upstream plant(s):")

            for up_num in upstream_plants
                up_plant = plant_map[up_num]
                println("      • #$up_num - $(strip(up_plant.plant_name))")
            end
        end

    catch e
        println("\n❌ Error parsing HIDR.DAT:")
        println("   $(typeof(e)): $e")
        rethrow(e)
    end
end

# Run the example
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
