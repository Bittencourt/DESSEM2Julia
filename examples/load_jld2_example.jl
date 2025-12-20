# Simple script to load a JLD2 file as Julia objects
# Run from project root: julia --project=. examples/load_jld2_example.jl

using DESSEM2Julia

# Path to the JLD2 file
jld2_path = joinpath("examples", "ons_sample.jld2")

# Check if file exists
if !isfile(jld2_path)
    error("JLD2 file not found: $jld2_path\nRun convert_ons_to_jld2.jl first to create it.")
end

# Load the data
println("Loading JLD2 file: $jld2_path")
data = load_jld2(jld2_path);

# Print summary
println("\n📦 Loaded DessemData with $(length(data.files)) files:")
for (filename, content) in data.files
    println("  • $filename: $(typeof(content))")
end

# Example: Access specific parsed data
println("\n🔍 Example data access:")

# Access TERMDAT (thermal plant data) if available
for (fname, content) in data.files
    if occursin("termdat", lowercase(fname))
        println("\nThermal plants (first 5):")
        for plant in content.plants[1:min(5, end)]
            println("  ID: $(plant.plant_num), Name: $(plant.plant_name)")
        end
        break
    end
end

# Access OPERUT (thermal unit constraints) if available
for (fname, content) in data.files
    if occursin("operut.dat", lowercase(fname))
        println("OPERUT records: $(length(content.oper_records))")
        break
    end
end
