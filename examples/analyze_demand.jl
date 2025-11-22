using DESSEM2Julia
using Printf

# Define path to sample file
const SAMPLE_DIR = joinpath(dirname(@__DIR__), "docs", "Sample", "DS_ONS_102025_RV2D11")
const ENTDADOS_PATH = joinpath(SAMPLE_DIR, "entdados.dat")

function analyze_demand()
    if !isfile(ENTDADOS_PATH)
        println("Error: File not found at $ENTDADOS_PATH")
        return
    end

    println("Reading ENTDADOS file from: $ENTDADOS_PATH")
    data = parse_entdados(ENTDADOS_PATH)

    println(
        "\n================================================================================",
    )
    println("System Demand Analysis")
    println(
        "================================================================================",
    )

    # 1. Subsystem Mapping
    subsystem_names = Dict{Int,String}()
    for sist in data.subsystems
        subsystem_names[sist.subsystem_num] = sist.subsystem_name
    end

    # 2. Group Demand Blocks by Subsystem
    # Dict{SubsystemID, Vector{DPRecord}}
    demand_by_subsystem = Dict{Int,Vector{Any}}()

    for dp in data.demands
        if !haskey(demand_by_subsystem, dp.subsystem)
            demand_by_subsystem[dp.subsystem] = []
        end
        push!(demand_by_subsystem[dp.subsystem], dp)
    end

    # 3. Print Demand Blocks
    sorted_subsystems = sort(collect(keys(demand_by_subsystem)))

    for sub_id in sorted_subsystems
        sub_name = get(subsystem_names, sub_id, "Unknown")
        blocks = demand_by_subsystem[sub_id]

        println("\nSubsystem: $sub_name (ID: $sub_id)")
        println("------------------------------------------------------------")
        @printf("%-15s | %-15s | %-15s\n", "Start Time", "End Time", "Demand (MW)")
        println("------------------------------------------------------------")

        # Sort blocks by start time
        sort!(blocks, by = b -> (b.start_day, b.start_hour, b.start_half))

        for block in blocks
            start_str = @sprintf(
                "D%02d %02d:%d0",
                block.start_day,
                block.start_hour,
                block.start_half == 1 ? 3 : 0
            )

            end_day_str = block.end_day == "F" ? "FINAL" : @sprintf("D%02d", block.end_day)
            end_str = @sprintf(
                "%s %02d:%d0",
                end_day_str,
                block.end_hour,
                block.end_half == 1 ? 3 : 0
            )

            @printf("%-15s | %-15s | %10.1f\n", start_str, end_str, block.demand)
        end
    end

    # 4. Total System Demand (Snapshot at first block)
    # Assuming all subsystems start at the same time for the first block
    println("\n------------------------------------------------------------")
    println("Initial System Load Snapshot:")
    total_load = 0.0
    for sub_id in sorted_subsystems
        blocks = demand_by_subsystem[sub_id]
        if !isempty(blocks)
            # Take the first block
            first_block = blocks[1]
            sub_name = get(subsystem_names, sub_id, "Unknown")
            @printf("  %-15s: %10.1f MW\n", sub_name, first_block.demand)
            total_load += first_block.demand
        end
    end
    println("------------------------------------------------------------")
    @printf("  %-15s: %10.1f MW\n", "TOTAL SYSTEM", total_load)
end

analyze_demand()
