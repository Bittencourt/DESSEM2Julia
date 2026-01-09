"""
Quick exploration of DS_ONS JLD2 data
"""

using JLD2

println("="^80)
println("DS_ONS Sample JLD2 Explorer")
println("="^80)
println()

# Load the JLD2 file
jld2_path = joinpath(@__DIR__, "ons_sample.jld2")
println("Loading: $jld2_path")
println()

data = JLD2.load(jld2_path)

# The data should have a "data" key containing DessemData
if haskey(data, "data")
    dessem_data = data["data"]
    println("✅ DessemData loaded")
    println()

    # Access the files dict
    files = dessem_data.files
    println("📁 Parsed files: $(length(files))")
    println()

    println("Files successfully parsed:")
    for fname in sort(collect(keys(files)))
        item = files[fname]
        if !(item isa AbstractString)
            println("  ✓ $fname")
        end
    end
    println()

    # Show some examples
    if haskey(files, "dessem.arq")
        arq = files["dessem.arq"]
        println("🗂️  DESSEM.ARQ:")
        println("   CASO: $(arq.caso)")
        println("   TITULO: $(arq.titulo)")
        println()
    end

    if haskey(files, "entdados.dat")
        ent = files["entdados.dat"]
        println("📊 ENTDADOS.DAT:")
        println("   Time periods: $(length(ent.time_periods))")
        println("   Subsystems: $(length(ent.subsystems))")
        println("   Hydro plants: $(length(ent.hydro_plants))")
        println("   Thermal plants: $(length(ent.thermal_plants))")
        println()
    end

    if haskey(files, "hidr.dat")
        hidr = files["hidr.dat"]
        println("💧 HIDR.DAT:")
        println("   Plants: $(length(hidr.records))")
        if !isempty(hidr.records)
            println("   First plant: $(hidr.records[1].nome)")
        end
        println()
    end

    if haskey(files, "termdat.dat")
        term = files["termdat.dat"]
        println("🏭 TERMDAT.DAT:")
        println("   Plants: $(length(term.plants))")
        println("   Units: $(length(term.units))")
        println()
    end

    # Show metadata
    println("ℹ️  Metadata:")
    for (key, value) in dessem_data.metadata
        println("   $key: $value")
    end
else
    println("❌ Could not find 'data' key in JLD2 file")
    println("Available keys: $(collect(keys(data)))")
end

println()
println("="^80)
