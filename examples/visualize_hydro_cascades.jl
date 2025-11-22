using Pkg
Pkg.activate(".")
using DESSEM2Julia
using Printf

# Path to the ONS sample HIDR.DAT (Binary)
const HIDR_PATH = joinpath("docs", "Sample", "DS_ONS_102025_RV2D11", "HIDR.DAT")

function calculate_capacity(plant)
    total_mw = 0.0
    # BinaryHidrRecord has 5 sets of machines
    # Check if it's a BinaryHidrRecord (has potef_conjunto as Vector)
    if hasproperty(plant, :potef_conjunto)
        for i in 1:5
            n_machines = plant.numero_maquinas_conjunto[i]
            power_per_machine = plant.potef_conjunto[i]
            if n_machines > 0
                total_mw += n_machines * power_per_machine
            end
        end
    else
        # Text format CADUSIH
        total_mw = plant.installed_capacity
    end
    return total_mw
end

function visualize_cascades()
    if !isfile(HIDR_PATH)
        println("Error: File not found: $HIDR_PATH")
        return
    end

    println("Parsing HIDR.DAT from: $HIDR_PATH")
    data = parse_hidr(HIDR_PATH)

    # Handle both binary and text formats (though we expect binary for ONS)
    records = hasproperty(data, :records) ? data.records : data.plants

    println("Loaded $(length(records)) plants.")

    # Build maps
    plant_map = Dict{Int,Any}()
    upstream_map = Dict{Int,Vector{Int}}()

    for plant in records
        # Handle field name differences (posto vs plant_num)
        id = hasproperty(plant, :posto) ? plant.posto : plant.plant_num

        # Skip invalid IDs (e.g. padding records)
        if id == 0
            continue
        end

        ds = hasproperty(plant, :jusante) ? plant.jusante : plant.downstream_plant

        # Handle nothing in text format
        if ds === nothing
            ds = 0
        end

        if haskey(plant_map, id)
            println("Warning: Duplicate plant ID $id found! Overwriting.")
        end
        plant_map[id] = plant

        # Initialize empty list for this plant in upstream_map if not exists
        if !haskey(upstream_map, id)
            upstream_map[id] = Int[]
        end

        # Add this plant to its downstream's list
        if ds != 0
            if !haskey(upstream_map, ds)
                upstream_map[ds] = Int[]
            end
            push!(upstream_map[ds], id)
        end
    end

    # Identify Sinks (Plants that flow to 0 or to a plant not in our dataset)
    sinks = Int[]
    for plant in values(plant_map)
        id = hasproperty(plant, :posto) ? plant.posto : plant.plant_num
        ds = hasproperty(plant, :jusante) ? plant.jusante : plant.downstream_plant
        if ds === nothing
            ds = 0
        end

        if ds == 0 || !haskey(plant_map, ds)
            push!(sinks, id)
        end
    end

    println("\nFound $(length(sinks)) cascade sinks (basins).")
    println("Visualizing Hydro Cascades (Sink <- Upstream):\n")

    # Sort sinks by name
    sort!(
        sinks,
        by = id ->
            hasproperty(plant_map[id], :nome) ? plant_map[id].nome :
            plant_map[id].plant_name,
    )

    for sink_id in sinks
        print_basin(sink_id, plant_map, upstream_map)
        println("\n" * "-"^60 * "\n")
    end
end

function print_basin(root_id, plant_map, upstream_map, prefix = "", is_last = true)
    plant = plant_map[root_id]
    name = hasproperty(plant, :nome) ? strip(plant.nome) : strip(plant.plant_name)
    id = hasproperty(plant, :posto) ? plant.posto : plant.plant_num
    cap = calculate_capacity(plant)

    # Format the line
    # └─ Name (ID) [Capacity MW]
    marker = is_last ? "└─" : "├─"

    @printf("%s%s %s (ID: %d) [%.1f MW]\n", prefix, marker, name, id, cap)

    # Get upstream plants
    upstream_ids = get(upstream_map, id, Int[])

    # Sort upstream by name for consistent output
    sort!(
        upstream_ids,
        by = uid ->
            hasproperty(plant_map[uid], :nome) ? plant_map[uid].nome :
            plant_map[uid].plant_name,
    )

    # Prepare prefix for children
    child_prefix = prefix * (is_last ? "   " : "│  ")

    for (i, up_id) in enumerate(upstream_ids)
        is_last_child = (i == length(upstream_ids))
        print_basin(up_id, plant_map, upstream_map, child_prefix, is_last_child)
    end
end

# Run the visualization
visualize_cascades()
