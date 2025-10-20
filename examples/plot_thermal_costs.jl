"""
Example: Plot Thermal Power Plant Maximum Generation Capacity

This example demonstrates how to:
1. Read thermal power plant data from ENTDADOS file
2. Extract maximum generation capacity for each plant
3. Plot them ordered from lowest to highest capacity

Note: Cost data is not available in the ONS sample files, so we plot 
capacity instead as a meaningful metric for thermal plants.

Usage:
    julia --project=. examples/plot_thermal_costs.jl
"""

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using DESSEM2Julia
using Plots

# Path to the ONS sample case
sample_dir = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")
entdados_file = joinpath(sample_dir, "entdados.dat")

println("Reading ENTDADOS file...")
data = parse_entdados(entdados_file)

# Extract thermal plant data (UT records)
thermal_plants = data.thermal_plants

println("\nFound $(length(thermal_plants)) thermal power plants")

# Extract plant numbers and maximum generation capacities
plant_numbers = [plant.plant_num for plant in thermal_plants]
max_generation = [plant.max_generation for plant in thermal_plants]

# Sort by maximum generation (ascending)
sorted_indices = sortperm(max_generation)
sorted_numbers = plant_numbers[sorted_indices]
sorted_capacities = max_generation[sorted_indices]

# Print summary statistics
println("\nMaximum Generation Capacity Statistics:")
println("  Minimum: $(minimum(max_generation)) MW")
println("  Maximum: $(maximum(max_generation)) MW")
println("  Average: $(round(sum(max_generation)/length(max_generation), digits=2)) MW")
println("  Median:  $(sorted_capacities[div(length(sorted_capacities), 2)]) MW")
println("  Total:   $(sum(max_generation)) MW")

# Print top 5 smallest and largest plants
println("\n5 Smallest Plants:")
for i in 1:min(5, length(sorted_numbers))
    plant = thermal_plants[sorted_indices[i]]
    println("  Plant $(sorted_numbers[i]) ($(plant.plant_name)): $(sorted_capacities[i]) MW")
end

println("\n5 Largest Plants:")
for i in max(1, length(sorted_numbers)-4):length(sorted_numbers)
    plant = thermal_plants[sorted_indices[i]]
    println("  Plant $(sorted_numbers[i]) ($(plant.plant_name)): $(sorted_capacities[i]) MW")
end

# Create the plot
println("\nGenerating plot...")
p = plot(
    1:length(sorted_capacities),
    sorted_capacities,
    seriestype=:bar,
    title="Thermal Power Plant Maximum Generation Capacity (Ordered)",
    xlabel="Plant Index (sorted by capacity)",
    ylabel="Maximum Generation (MW)",
    legend=false,
    color=:steelblue,
    size=(1000, 600),
    margin=5Plots.mm
)

# Add horizontal line for average capacity
hline!(p, [sum(max_generation)/length(max_generation)], 
       color=:red, 
       linestyle=:dash, 
       linewidth=2,
       label="Average Capacity")

# Save the plot
output_file = joinpath(@__DIR__, "thermal_costs.png")
savefig(p, output_file)
println("Plot saved to: $output_file")

# Display the plot (if running in interactive environment)
display(p)

println("\n✅ Done!")
