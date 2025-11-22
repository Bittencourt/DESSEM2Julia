using DESSEM2Julia
using Printf
using Dates

# Define path to sample file
const SAMPLE_DIR = joinpath(dirname(@__DIR__), "docs", "Sample", "DS_ONS_102025_RV2D11")
const RENOVAVEIS_PATH = joinpath(SAMPLE_DIR, "renovaveis.dat")

function analyze_renewables()
    if !isfile(RENOVAVEIS_PATH)
        println("Error: File not found at $RENOVAVEIS_PATH")
        return
    end

    println("Reading RENOVAVEIS file from: $RENOVAVEIS_PATH")
    data = parse_renovaveis(RENOVAVEIS_PATH)

    println(
        "\n================================================================================",
    )
    println("Renewable Energy Analysis")
    println(
        "================================================================================",
    )

    # 1. Plant Statistics
    n_plants = length(data.plants)

    # Calculate total capacity (handle empty collection safely)
    valid_plants = filter(p -> p.pmax < 9000, data.plants)
    total_capacity = isempty(valid_plants) ? 0.0 : sum(p.pmax for p in valid_plants)

    println("Total Plants Registered: $n_plants")
    @printf("Total Installed Capacity: %.2f MW (excluding placeholders)\n", total_capacity)

    # 2. Subsystem Mapping
    # Create a map of Plant Code -> Subsystem
    plant_subsystem = Dict{Int,String}()
    for mapping in data.subsystem_mappings
        plant_subsystem[mapping.plant_code] = mapping.subsystem
    end

    # 3. Aggregate Generation by Subsystem
    # Structure: Dict{Subsystem, Dict{TimeKey, TotalMW}}
    # TimeKey can be a tuple (day, hour, half_hour)

    gen_by_subsystem = Dict{String,Float64}()

    # We'll just sum up the total energy in the first 24 hours for a snapshot
    # Or better, find the peak generation per subsystem

    subsystems = unique(values(plant_subsystem))
    peak_gen = Dict(s => 0.0 for s in subsystems)

    # Group forecasts by time step
    time_steps = Dict{Tuple{Int,Int,Int},Dict{String,Float64}}()

    for forecast in data.generation_forecasts
        subsystem = get(plant_subsystem, forecast.plant_code, "UNKNOWN")

        # Create a simplified time key (Start Day, Start Hour, Start Half)
        key = (forecast.start_day, forecast.start_hour, forecast.start_half_hour)

        if !haskey(time_steps, key)
            time_steps[key] = Dict(s => 0.0 for s in subsystems)
            time_steps[key]["UNKNOWN"] = 0.0
        end

        time_steps[key][subsystem] =
            get(time_steps[key], subsystem, 0.0) + forecast.generation
    end

    # Sort time steps
    sorted_keys = sort(collect(keys(time_steps)))

    println("\nRenewable Generation Profile (First 24 Records):")
    println(
        "--------------------------------------------------------------------------------",
    )
    @printf(
        "%-15s | %-10s | %-10s | %-10s | %-10s | %-10s\n",
        "Time (D-H-M)",
        "SE (MW)",
        "S (MW)",
        "NE (MW)",
        "N (MW)",
        "Total (MW)"
    )
    println(
        "--------------------------------------------------------------------------------",
    )

    for (i, key) in enumerate(sorted_keys)
        if i > 24
            break
        end # Limit output

        day, hour, half = key
        time_str = @sprintf("%02d-%02d-%d", day, hour, half)

        gens = time_steps[key]
        se = get(gens, "SE", 0.0)
        s = get(gens, "S", 0.0)
        ne = get(gens, "NE", 0.0)
        n = get(gens, "N", 0.0)
        total = sum(values(gens))

        @printf(
            "%-15s | %10.1f | %10.1f | %10.1f | %10.1f | %10.1f\n",
            time_str,
            se,
            s,
            ne,
            n,
            total
        )
    end
    println(
        "--------------------------------------------------------------------------------",
    )

    # 4. Top 10 Largest Renewable Plants
    println("\nTop 10 Largest Renewable Plants (by PMAX):")
    println(
        "--------------------------------------------------------------------------------",
    )
    @printf("%-10s | %-40s | %-10s | %-10s\n", "Code", "Name", "PMAX (MW)", "Subsystem")
    println(
        "--------------------------------------------------------------------------------",
    )

    # Filter out placeholders (9999) and sort
    valid_plants = filter(p -> p.pmax < 9000, data.plants)
    sorted_plants = sort(valid_plants, by = p -> p.pmax, rev = true)

    for (i, plant) in enumerate(sorted_plants)
        if i > 10
            break
        end
        subsystem = get(plant_subsystem, plant.plant_code, "N/A")
        @printf(
            "%-10d | %-40s | %10.1f | %-10s\n",
            plant.plant_code,
            plant.plant_name,
            plant.pmax,
            subsystem
        )
    end
end

analyze_renewables()
