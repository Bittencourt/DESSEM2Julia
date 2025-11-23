using DESSEM2Julia
using Dates

# Define paths
# Using relative paths assuming script is run from project root
ons_sample_dir = joinpath("docs", "Sample", "DS_ONS_102025_RV2D11")
output_file = joinpath("examples", "ons_sample.jld2")

println("🚀 Starting conversion of ONS sample data...")
println("📂 Input directory: $ons_sample_dir")
println("💾 Output file:     $output_file")

if !isdir(ons_sample_dir)
    error("❌ Input directory not found: $ons_sample_dir")
end

# Perform conversion
try
    start_time = now()
    output_path = convert_inputs(ons_sample_dir, output_file)
    duration = now() - start_time

    println("\n✅ Conversion successful!")
    println("⏱️  Time taken: $(duration)")
    println("📄 Saved to: $output_path")

    # Verify file exists and print size
    if isfile(output_path)
        size_mb = filesize(output_path) / 1024 / 1024
        println("📦 File size: $(round(size_mb, digits=2)) MB")
    end

catch e
    println("\n❌ Conversion failed!")
    showerror(stdout, e)
    println()
    rethrow(e)
end
