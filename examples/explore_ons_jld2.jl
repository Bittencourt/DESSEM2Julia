"""
Explore the converted DS_ONS JLD2 file

This script demonstrates how to load and analyze the
DS_ONS sample data that was converted to JLD2 format.
"""

using JLD2
using DESSEM2Julia

println("="^80)
println("Exploring DS_ONS JLD2 Data")
println("="^80)
println()

# Load the JLD2 file
jld2_path = joinpath(@__DIR__, "ons_sample.jld2")

if !isfile(jld2_path)
    error("JLD2 file not found: $jld2_path")
end

println("📦 Loading JLD2 file: $jld2_path")
println()

# Load the data
data = JLD2.load(jld2_path)

println("✅ Data loaded successfully!")
println()

# Explore what's in the file
println("="^80)
println("📋 File Contents")
println("="^80)
println()

println("Top-level keys:")
for key in sort(collect(keys(data)))
    value = data[key]
    value_type = typeof(value)

    # Show more details for known types
    if value_type <: Dict
        println("  • $key : Dict with $(length(value)) entries")
    elseif value_type <: AbstractString
        println("  • $key : String ($(length(value)) chars)")
    else
        println("  • $key : $value_type")
    end
end
println()

# Show the files_map contents
if haskey(data, "files_map") || haskey(data, "dessem_data")
    files_map = get(data, "files_map", get(data, "dessem_data", Dict()))

    println("="^80)
    println("📁 Parsed DESSEM Files ($(length(files_map)) files)")
    println("="^80)
    println()

    # Group by type
    text_files = String[]
    parsed_files = String[]

    for (filename, content) in files_map
        if content isa AbstractString
            push!(text_files, filename)
        else
            push!(parsed_files, filename)
        end
    end

    println("✅ Structured Parsed Files ($(length(parsed_files))):")
    for fname in sort(parsed_files)
        content = files_map[fname]
        content_type = typeof(content)
        println("  • $fname : $content_type")
    end
    println()

    if !isempty(text_files)
        println("📄 Raw Text Files ($(length(text_files)) - stored as-is):")
        for fname in sort(text_files)[1:min(20, end)]
            println("  • $fname")
        end
        if length(text_files) > 20
            println("  ... and $(length(text_files) - 20) more")
        end
        println()
    end

    # Show some examples of parsed data
    println("="^80)
    println("📊 Sample Data Preview")
    println("="^80)
    println()

    # Example: dessem.arq
    if haskey(files_map, "dessem.arq")
        arq = files_map["dessem.arq"]
        println("🗂️  DESSEM.ARQ (Master File Index):")
        println("   CASO: $(arq.caso)")
        println("   TITULO: $(arq.titulo)")
        println("   Number of files: $(length(arq.files))")
        println()
    end

    # Example: entdados.dat
    if haskey(files_map, "entdados.dat")
        ent = files_map["entdados.dat"]
        println("📊 ENTDADOS.DAT (General Operational Data):")
        println("   Time periods: $(length(ent.time_periods))")
        println("   Subsystems: $(length(ent.subsystems))")
        println("   Hydro plants: $(length(ent.hydro_plants))")
        println("   Thermal plants: $(length(ent.thermal_plants))")
        println("   Demand records: $(length(ent.demands))")
        println()
    end

    # Example: termdat.dat
    if haskey(files_map, "termdat.dat")
        term = files_map["termdat.dat"]
        println("🏭 TERMDAT.DAT (Thermal Plant Registry):")
        println("   Plants: $(length(term.plants))")
        println("   Units: $(length(term.units))")
        println("   Heat curves: $(length(term.heat_curves))")
        println()
    end

    # Example: hidr.dat
    if haskey(files_map, "hidr.dat")
        hidr = files_map["hidr.dat"]
        println("💧 HIDR.DAT (Hydro Plant Registry):")
        println("   Hydro plants: $(length(hidr.plants))")
        if !isempty(hidr.plants)
            plant = hidr.plants[1]
            println("   Sample plant: $(plant.name)")
            println("   Fields per plant: $(length(fieldnames(typeof(plant))))")
        end
        println()
    end
end

# Show metadata
if haskey(data, "metadata")
    println("="^80)
    println("ℹ️  Metadata")
    println("="^80)
    println()
    for (key, value) in data["metadata"]
        println("  $key: $value")
    end
    println()
end

println("="^80)
println("✅ Exploration Complete!")
println("="^80)
println()
println("💡 Tip: Access specific data using:")
println("   data = JLD2.load(\"ons_sample.jld2\")")
println("   entdados = data[\"files_map\"][\"entdados.dat\"]")
println("   hydro_plants = entdados.hydro_plants")
println()
