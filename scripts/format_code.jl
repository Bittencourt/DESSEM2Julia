using Pkg
Pkg.add(; name = "JuliaFormatter", version = "1")
using JuliaFormatter

println("Running JuliaFormatter on repository root...")
format(".", verbose = true)
println("Formatting complete.")
