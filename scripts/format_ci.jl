import Pkg
# Activate a temporary environment to avoid modifying the project
Pkg.activate(temp = true)
Pkg.add(; name = "JuliaFormatter", version = "1")
using JuliaFormatter

println("[format_ci] Running JuliaFormatter in temporary env...")
format(".", verbose = true)
println("[format_ci] Done.")
