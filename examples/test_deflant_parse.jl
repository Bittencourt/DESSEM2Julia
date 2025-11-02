"""
Example: Parse and analyze DEFLANT.DAT (previous flows)

This example demonstrates parsing previous flow data for water travel time modeling.
"""

using DESSEM2Julia

# Parse DEFLANT.DAT from ONS sample
deflant_path = "docs/Sample/DS_ONS_102025_RV2D11/deflant.dat"
if !isfile(deflant_path)
    error("ONS sample file not found: $deflant_path")
end

# Parse the file
println("Parsing DEFLANT.DAT...")
deflant_data = parse_deflant(deflant_path)

# Display summary
println("\n" * "="^70)
println("DEFLANT.DAT Summary")
println("="^70)
println("Total flow records: $(length(deflant_data.records))")

# Group by initial day
day_counts = Dict{Union{Int,String},Int}()
for record in deflant_data.records
    day = record.initial_day
    day_counts[day] = get(day_counts, day, 0) + 1
end

println("\nFlow records by initial day:")
for (day, count) in sort(collect(day_counts), by = x -> x[1])
    day_str = day isa String ? "\"$day\"" : string(day)
    println("  Day $day_str: $count records")
end

# Find records with special day markers
inicio_records = filter(r -> r.initial_day == "I", deflant_data.records)
fim_records = filter(r -> r.final_day == "F", deflant_data.records)

println("\nSpecial markers:")
println("  Records with initial day = 'I' (inicio): $(length(inicio_records))")
println("  Records with final day = 'F' (fim): $(length(fim_records))")

# Element type distribution
hydro_count = count(r -> r.element_type == "H", deflant_data.records)
section_count = count(r -> r.element_type == "S", deflant_data.records)

println("\nDownstream element types:")
println("  H (Hydro plants): $hydro_count")
println("  S (River sections): $section_count")

# Flow statistics
flows = [r.flow for r in deflant_data.records]
println("\nFlow statistics (m³/s):")
println("  Minimum: $(minimum(flows))")
println("  Maximum: $(maximum(flows))")
println("  Average: $(round(sum(flows) / length(flows), digits=2))")

# Find largest flows
println("\nTop 5 largest flows:")
sorted_records = sort(deflant_data.records, by = r -> r.flow, rev = true)
for (i, record) in enumerate(sorted_records[1:min(5, length(sorted_records))])
    println(
        "  $i. Plant $(record.upstream_plant) → Element $(record.downstream_element): $(record.flow) m³/s",
    )
end

# Find records for a specific plant (e.g., plant 2)
plant_2_records = filter(r -> r.upstream_plant == 2, deflant_data.records)
if !isempty(plant_2_records)
    println("\nPlant 2 flow records:")
    for record in plant_2_records
        day_str =
            record.initial_day isa String ? "\"$(record.initial_day)\"" :
            string(record.initial_day)
        println(
            "  Day $day_str, $(record.initial_hour):$(record.initial_half*30) → Element $(record.downstream_element) ($(record.element_type)): $(record.flow) m³/s",
        )
    end
end

# Time period analysis
hour_counts = Dict{Int,Int}()
for record in deflant_data.records
    if !isnothing(record.initial_hour)
        hour_counts[record.initial_hour] = get(hour_counts, record.initial_hour, 0) + 1
    end
end

println("\nFlow records by initial hour:")
for (hour, count) in sort(collect(hour_counts), by = x -> x[1])
    println("  Hour $hour:00: $count records")
end

println("\n" * "="^70)
println("✅ DEFLANT parsing complete!")
println("="^70)
