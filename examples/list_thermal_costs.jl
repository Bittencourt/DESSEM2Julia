"""
Example: List Thermal Power Plants Ordered by Operating Cost

This example demonstrates how to:
1. Read thermal power plant operational data from OPERUT file
2. Extract operating costs (CVU - Custo Variável Unitário) in R\$/MWh
3. List plants ordered from lowest to highest cost

The operating cost data comes from the OPER block in OPERUT.DAT, which specifies
the variable unit cost (CVU) for each thermal plant unit during the study period.

Usage:
    julia --project=. examples/list_thermal_costs.jl
"""

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using DESSEM2Julia

# Path to the ONS sample case
sample_dir = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")
operut_file = joinpath(sample_dir, "operut.dat")

println("="^70)
println("Thermal Power Plant Operating Costs (CVU)")
println("="^70)
println()

# Parse OPERUT file to get operating costs
println("Reading OPERUT file...")
operut_data = parse_operut(operut_file)

# Extract OPER records (operating costs and limits)
oper_records = operut_data.oper_records

println("Found $(length(oper_records)) thermal unit operating cost records\n")

# Group by plant+unit and collect cost data
# Note: OPER records may have time-varying costs, so we take the first record for each unit
unit_costs = Dict{Tuple{Int,Int},Tuple{String,Float64}}()  # (plant_num, unit_num) => (plant_name, cost)

for record in oper_records
    key = (record.plant_num, record.unit_num)
    if !haskey(unit_costs, key)
        unit_costs[key] = (record.plant_name, record.operating_cost)
    end
end

# Convert to vector for sorting
cost_data = [
    (plant_num, unit_num, plant_name, cost) for
    ((plant_num, unit_num), (plant_name, cost)) in unit_costs
]

# Sort by cost (ascending)
sort!(cost_data, by = x -> x[4])

# Print header
println("="^70)
println("Thermal Units Ordered by Operating Cost (R\$/MWh)")
println("="^70)
println()
println("Rank | Plant # | Unit | Plant Name        | Cost (R\$/MWh)")
println("-"^70)

# Print all units ordered by cost
for (rank, (plant_num, unit_num, plant_name, cost)) in enumerate(cost_data)
    # Format plant name to 17 characters (pad or truncate)
    name_formatted = rpad(plant_name[1:min(length(plant_name), 17)], 17)
    println(
        "$(lpad(rank, 4)) | $(lpad(plant_num, 7)) | $(lpad(unit_num, 4)) | $(name_formatted) | $(lpad(round(cost, digits=2), 13))",
    )
end

println()
println("="^70)
println("Summary Statistics")
println("="^70)

# Calculate statistics
costs = [x[4] for x in cost_data]
println("  Total units:     $(length(costs))")
println("  Minimum cost:    $(round(minimum(costs), digits=2)) R\$/MWh")
println("  Maximum cost:    $(round(maximum(costs), digits=2)) R\$/MWh")
println("  Average cost:    $(round(sum(costs)/length(costs), digits=2)) R\$/MWh")
println("  Median cost:     $(round(costs[div(length(costs), 2)], digits=2)) R\$/MWh")
println()

# Highlight top 10 cheapest
println("="^70)
println("Top 10 Cheapest Units (Lowest Operating Cost)")
println("="^70)
println()
for i in 1:min(10, length(cost_data))
    plant_num, unit_num, plant_name, cost = cost_data[i]
    println(
        "  $i. Plant $(plant_num) Unit $(unit_num) - $(plant_name): $(round(cost, digits=2)) R\$/MWh",
    )
end
println()

# Highlight top 10 most expensive
println("="^70)
println("Top 10 Most Expensive Units (Highest Operating Cost)")
println("="^70)
println()
start_idx = max(1, length(cost_data) - 9)
for i in start_idx:length(cost_data)
    rank = i - start_idx + 1
    plant_num, unit_num, plant_name, cost = cost_data[i]
    println(
        "  $rank. Plant $(plant_num) Unit $(unit_num) - $(plant_name): $(round(cost, digits=2)) R\$/MWh",
    )
end
println()

# Cost distribution analysis
println("="^70)
println("Cost Distribution Analysis")
println("="^70)
println()

# Define cost ranges
ranges = [
    (0.0, 50.0, "Very Low (< 50)"),
    (50.0, 100.0, "Low (50-100)"),
    (100.0, 200.0, "Medium (100-200)"),
    (200.0, 300.0, "High (200-300)"),
    (300.0, 500.0, "Very High (300-500)"),
    (500.0, Inf, "Extreme (> 500)"),
]

for (low, high, label) in ranges
    count = sum(low ≤ c < high for c in costs)
    percentage = round(100 * count / length(costs), digits = 1)
    println("  $(rpad(label, 25)): $(lpad(count, 3)) units ($(lpad(percentage, 5))%)")
end

println()
println("="^70)
println("✅ Done!")
println("="^70)
