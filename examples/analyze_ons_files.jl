# Script to analyze the actual ONS file formats
# This will help understand why the reference dessem_reader.jl didn't work

println("=" ^ 80)
println("ONS File Format Analysis")
println("=" ^ 80)
println()

ons_dir = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")

# Function to get unique record types from a file
function analyze_file_records(filepath, max_lines=100)
    if !isfile(filepath)
        println("  ⚠ File not found")
        return
    end
    
    lines = readlines(filepath)
    record_types = Dict{String, Int}()
    
    for (i, line) in enumerate(lines)
        if i > max_lines
            break
        end
        
        line = strip(line)
        
        # Skip empty lines and comments
        if isempty(line) || startswith(line, "&") || startswith(line, "*")
            continue
        end
        
        # Get first word/token as record type
        tokens = split(line)
        if !isempty(tokens)
            rec_type = tokens[1]
            record_types[rec_type] = get(record_types, rec_type, 0) + 1
        end
    end
    
    println("  Total lines: $(length(lines))")
    println("  Unique record types found (first $max_lines lines):")
    for (rec_type, count) in sort(collect(record_types), by=x->x[2], rev=true)
        println("    $rec_type: $count occurrences")
    end
end

# Analyze key files
println("1. entdados.dat")
println("-" ^ 80)
analyze_file_records(joinpath(ons_dir, "entdados.dat"), 200)
println()

println("2. dadvaz.dat")
println("-" ^ 80)
analyze_file_records(joinpath(ons_dir, "dadvaz.dat"), 100)
println()

println("3. operut.dat")
println("-" ^ 80)
analyze_file_records(joinpath(ons_dir, "operut.dat"), 100)
println()

println("4. operuh.dat")
println("-" ^ 80)
analyze_file_records(joinpath(ons_dir, "operuh.dat"), 100)
println()

println("5. termdat.dat")
println("-" ^ 80)
analyze_file_records(joinpath(ons_dir, "termdat.dat"), 100)
println()

println("6. hidr.dat (checking if binary)")
println("-" ^ 80)
hidr_path = joinpath(ons_dir, "hidr.dat")
if isfile(hidr_path)
    # Check if file is binary
    bytes = read(hidr_path, 100)
    is_binary = any(b -> b < 0x20 && b != 0x0a && b != 0x0d && b != 0x09, bytes)
    println("  File exists: yes")
    println("  File size: $(filesize(hidr_path)) bytes")
    println("  Is binary: $is_binary")
    if !is_binary
        println("  First line: ", readline(hidr_path))
    end
else
    println("  ⚠ File not found")
end
println()

println("=" ^ 80)
println("Summary")
println("=" ^ 80)
println("The reference dessem_reader.jl was designed for a simplified/different")
println("DESSEM format. The actual ONS files use different record types and formats.")
println("Your DESSEM2Julia project parsers are needed to handle the real formats!")
println("=" ^ 80)
