#!/usr/bin/env julia
# Test DESSEM2Julia parsers on ONS sample data
# This script uses the actual DESSEM2Julia parsers (not the reference script)

using DESSEM2Julia
using Dates

println("="^80)
println("DESSEM2Julia Parser Test - ONS Sample Data")
println("="^80)
println()

# ONS sample directory
ons_dir = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")

println("Testing directory: $ons_dir")
println()

# Check if directory exists
if !isdir(ons_dir)
    error("ONS sample directory not found: $ons_dir")
end

# Track results
results = Dict{String,Any}()
errors = Dict{String,String}()

# Helper function to test a parser
function test_parser(name::String, filepath::String, parser_func)
    println("-"^80)
    println("Testing: $name")
    println("File: $(basename(filepath))")

    if !isfile(filepath)
        println("  ⚠️  File not found")
        errors[name] = "File not found"
        return nothing
    end

    try
        println("  📖 Parsing...")
        start_time = time()
        data = parser_func(filepath)
        elapsed = time() - start_time

        println("  ✅ Success! ($(round(elapsed, digits=3))s)")

        # Print summary based on data type
        if name == "entdados.dat"
            println("  📊 Summary:")
            println("     - TM records: $(length(data.tm_records))")
            println("     - SIST records: $(length(data.sist_records))")
            println("     - UH records: $(length(data.uh_records))")
            println("     - UT records: $(length(data.ut_records))")
            println("     - DP records: $(length(data.dp_records))")
        elseif name == "dadvaz.dat"
            println("  📊 Summary:")
            println("     - Number of plants: $(data.header.num_plants)")
            println("     - Inflow records: $(length(data.inflow_records))")
            println("     - Study start: $(data.header.study_start)")
        elseif name == "operuh.dat"
            println("  📊 Summary:")
            println("     - REST constraints: $(length(data.rest_constraints))")
            println("     - ELEM constraints: $(length(data.elem_constraints))")
            println("     - LIM constraints: $(length(data.lim_constraints))")
            println("     - VAR constraints: $(length(data.var_constraints))")
        elseif name == "operut.dat"
            println("  📊 Summary:")
            println("     - INIT records: $(length(data.init_records))")
            println("     - OPER records: $(length(data.oper_records))")
        elseif name == "termdat.dat"
            println("  📊 Summary:")
            if isa(data, ThermalRegistry)
                println("     - CADUSIT records: $(length(data.cadusit))")
                println("     - CADUNIDT records: $(length(data.cadunidt))")
                println("     - CURVACOMB records: $(length(data.curvacomb))")
            end
        elseif name == "dessem.arq"
            println("  📊 Summary:")
            println("     - File entries: $(length(data.files))")
        end

        results[name] = data
        return data

    catch e
        println("  ❌ Error: $e")
        errors[name] = string(e)

        # Print stack trace for debugging
        println("\n  Stack trace:")
        for (exc, bt) in Base.catch_stack()
            showerror(stdout, exc, bt)
            println()
        end

        return nothing
    end
end

println("="^80)
println("PARSING FILES")
println("="^80)
println()

# Test each parser
test_parser("dessem.arq", joinpath(ons_dir, "dessem.arq"), parse_dessemarq)
test_parser("entdados.dat", joinpath(ons_dir, "entdados.dat"), parse_entdados)
test_parser("dadvaz.dat", joinpath(ons_dir, "dadvaz.dat"), parse_dadvaz)
test_parser("operuh.dat", joinpath(ons_dir, "operuh.dat"), parse_operuh)
test_parser("operut.dat", joinpath(ons_dir, "operut.dat"), parse_operut)
test_parser("termdat.dat", joinpath(ons_dir, "termdat.dat"), parse_termdat)

println()
println("="^80)
println("FINAL SUMMARY")
println("="^80)
println()

total_files = 6
success_count = length(results)
error_count = length(errors)

println("Files tested: $total_files")
println("✅ Successful: $success_count")
println("❌ Failed: $error_count")
println()

if success_count > 0
    println("Successfully parsed files:")
    for (name, data) in results
        println("  ✓ $name")
    end
    println()
end

if error_count > 0
    println("Failed files:")
    for (name, error) in errors
        println("  ✗ $name")
        println("    Error: $(first(error, 100))...")
    end
    println()
end

# Calculate success rate
success_rate = round(success_count / total_files * 100, digits = 1)
println("Success rate: $success_rate%")
println()

if success_count == total_files
    println("🎉 All parsers working correctly!")
elseif success_count > 0
    println("⚠️  Some parsers working, others need fixes")
else
    println("❌ All parsers failed - need investigation")
end

println()
println("="^80)
println("Test completed at: $(now())")
println("="^80)
