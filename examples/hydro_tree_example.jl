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

# Helper to get field values regardless of format (Binary/Text)
function get_id(plant)
    hasproperty(plant, :posto) ? plant.posto : plant.plant_num
end

function get_name(plant)
    hasproperty(plant, :nome) ? strip(plant.nome) : strip(plant.plant_name)
end

function get_downstream(plant)
    val = hasproperty(plant, :jusante) ? plant.jusante : plant.downstream_plant
    return val === nothing ? 0 : val
end

function get_subsystem(plant)
    hasproperty(plant, :subsistema) ? plant.subsistema : plant.subsystem
end

function get_capacity(plant)
    if hasproperty(plant, :potef_conjunto)
        # Binary: sum of sets
        total = 0.0
        for i in 1:5
            if plant.numero_maquinas_conjunto[i] > 0
                total += plant.numero_maquinas_conjunto[i] * plant.potef_conjunto[i]
            end
        end
        return total
    else
        # Text
        return plant.installed_capacity
    end
end

function get_vol_min(plant)
    hasproperty(plant, :volume_minimo) ? plant.volume_minimo :
    (plant.min_volume === nothing ? 0.0 : plant.min_volume)
end

function get_vol_max(plant)
    hasproperty(plant, :volume_maximo) ? plant.volume_maximo :
    (plant.max_volume === nothing ? 0.0 : plant.max_volume)
end

function build_plant_map(plants)
    """Build a dictionary mapping plant_num -> plant for quick lookup"""
    plant_map = Dict{Int,Any}()
    for plant in plants
        id = get_id(plant)
        if id > 0  # Skip empty/padding records
            plant_map[id] = plant
        end
    end
    return plant_map
end

function find_upstream_plants(plant_num, plant_map)
    """Find all plants that flow into this plant"""
    upstream = []
    for (num, plant) in plant_map
        if get_downstream(plant) == plant_num
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
        ds = get_downstream(plant)
        if ds > 0
            push!(downstream_plants, ds)
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
    name = get_name(plant)
    if isempty(name)
        name = "[Unnamed]"
    end

    capacity = get_capacity(plant)
    volume_min = get_vol_min(plant)
    volume_max = get_vol_max(plant)
    subsystem = get_subsystem(plant)

    # Print plant info
    prefix = indent == 0 ? "🏔️ " : "└─ "
    println("  "^indent * "$prefix $name (#$plant_num)")
    println("  "^indent * "   ├─ Capacity: $(round(capacity, digits=1)) MW")
    println(
        "  "^indent *
        "   ├─ Volume: $(round(volume_min, digits=1)) - $(round(volume_max, digits=1)) hm³",
    )
    println("  "^indent * "   └─ Subsystem: $subsystem")

    # Find and print downstream plant
    ds = get_downstream(plant)
    if ds > 0
        println("  "^indent * "   ⬇️  Flows to:")
        print_tree(ds, plant_map, indent + 1, visited)
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
        sub = get_subsystem(plant)
        subsystems[sub] = get(subsystems, sub, 0) + 1
        total_capacity += get_capacity(plant)
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

        # Handle both binary and text formats
        plants = hasproperty(data, :records) ? data.records : data.plants

        println("   Plants found: $(length(plants))")

        # Build plant lookup map
        plant_map = build_plant_map(plants)
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
            ds = get_downstream(plant)
            if ds > 0
                example_plant = plant
                break
            end
        end

        if example_plant !== nothing
            downstream_num = get_downstream(example_plant)
            upstream_plants = find_upstream_plants(downstream_num, plant_map)

            downstream = plant_map[downstream_num]
            println("\n🎯 Example: Plant #$(downstream_num) - $(get_name(downstream))")
            println("   Receives water from $(length(upstream_plants)) upstream plant(s):")

            for up_num in upstream_plants
                up_plant = plant_map[up_num]
                println("      • #$up_num - $(get_name(up_plant))")
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
