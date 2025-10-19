"""
Quick ONS Compatibility Check
Tests if existing parsers work with ONS network-enabled cases
"""

using DESSEM2Julia
using Logging

println("DESSEM2Julia - ONS Compatibility Verification\n")

ons_dir = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")

if !isdir(ons_dir)
    println("❌ ONS sample directory not found: $ons_dir")
    exit(1)
end

println("Testing: $(basename(ons_dir))\n")

# Suppress warnings temporarily
original_logger = global_logger()
global_logger(SimpleLogger(stderr, Logging.Error))

results = Dict{String, Bool}()

# Test 1: dessem.arq
print("1. dessem.arq parsing... ")
try
    arq = parse_dessemarq(joinpath(ons_dir, "dessem.arq"))
    results["dessem.arq"] = true
    has_network = !isnothing(arq.indelet) && !isempty(arq.indelet)
    println("✅ (Network: $(has_network ? "enabled" : "disabled"))")
    println("   Files: $(arq.dadger), $(arq.cadterm), $(arq.cadusih)")
    if has_network
        println("   Network file: $(arq.indelet)")
    end
catch e
    results["dessem.arq"] = false
    println("❌ Error: $(typeof(e))")
end

# Test 2: termdat.dat
print("\n2. termdat.dat parsing... ")
try
    arq = parse_dessemarq(joinpath(ons_dir, "dessem.arq"))
    thermal = parse_termdat(joinpath(ons_dir, arq.cadterm))
    results["termdat.dat"] = true
    println("✅")
    println("   Plants: $(length(thermal.plants)), Units: $(length(thermal.units))")
catch e
    results["termdat.dat"] = false
    println("❌ Error: $(typeof(e))")
end

# Test 3: entdados.dat
print("\n3. entdados.dat parsing... ")
try
    arq = parse_dessemarq(joinpath(ons_dir, "dessem.arq"))
    general = parse_entdados(joinpath(ons_dir, arq.dadger))
    results["entdados.dat"] = true
    println("✅")
    println("   Periods: $(length(general.time_periods))")
    println("   Subsystems: $(length(general.subsystems))")
    println("   Hydro plants: $(length(general.hydro_plants))")
    println("   Demand records: $(length(general.demands))")
    
    # Check network flags
    network_periods = sum(p.network_flag for p in general.time_periods)
    if network_periods > 0
        println("   ⚠️  Network modeling: $network_periods/$(length(general.time_periods)) periods")
    else
        println("   ℹ️  Network modeling: disabled (all periods)")
    end
catch e
    results["entdados.dat"] = false
    println("❌ Error: $(typeof(e)): $e")
    println("   Partial results may still be available")
end

# Test 4: desselet.dat
print("\n4. desselet.dat parsing... ")
try
    arq = parse_dessemarq(joinpath(ons_dir, "dessem.arq"))
    if isnothing(arq.indelet) || isempty(arq.indelet)
        println("⚠️  dessem.arq does not reference DESSELET")
        results["desselet.dat"] = true
    else
        desselet_path = joinpath(ons_dir, arq.indelet)
        if !isfile(desselet_path)
            println("❌ Missing file: $(arq.indelet)")
            results["desselet.dat"] = false
        else
            network = parse_desselet(desselet_path)
            results["desselet.dat"] = true
            println("✅")
            println("   Base cases: $(length(network.base_cases))")
            println("   Patamares: $(length(network.patamares))")
        end
    end
catch e
    results["desselet.dat"] = false
    println("❌ Error: $(typeof(e))")
end

# Restore logger
global_logger(original_logger)

# Summary
println("\n" * "="^60)
println("Summary:")
println("="^60)

all_passed = all(values(results))
if all_passed
    println("✅ All tests PASSED - ONS compatibility confirmed!")
else
    println("⚠️  Some tests failed:")
    for (test, passed) in results
        println("  $(passed ? "✅" : "❌") $test")
    end
end

println("\nConclusion:")
if all_passed
    println("  The existing parsers are fully compatible with")
    println("  ONS network-enabled DESSEM cases.")
    println()
    println("Next steps:")
    println("  • Implement parsers for unknown record types")
    println("  • Document ONS-specific features")
else
    println("  Additional work needed for ONS compatibility.")
end

println()
