"""
Example: Analyzing Entity Relationships in DESSEM Data

This example demonstrates how to traverse and analyze the relational structure
of DESSEM data, treating the files as a distributed database with foreign key
relationships.

Demonstrates:
1. Subsystem → Plants hierarchy
2. Thermal Plant → Units relationship
3. Plant → Operating Cost joins
4. Cross-file data integration

For complete relationship documentation, see docs/ENTITY_RELATIONSHIPS.md

Usage:
    julia --project=. examples/analyze_relationships.jl
"""

using DESSEM2Julia

# Path to sample case
sample_dir = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")

println("="^80)
println("DESSEM Entity Relationship Analysis")
println("="^80)
println()

# ============================================================================
# 1. Load Data from Multiple Files
# ============================================================================
println("📁 Loading data from multiple files...")

# Parse ENTDADOS (master configuration with subsystems and plants)
entdados_file = joinpath(sample_dir, "entdados.dat")
entdados = parse_entdados(entdados_file)

# Parse TERMDAT.DAT (thermal plant registry with units)
termdat_file = joinpath(sample_dir, "termdat.dat")
termdat = parse_termdat(termdat_file)

# Parse OPERUT.DAT (thermal operational data with costs)
operut_file = joinpath(sample_dir, "operut.dat")
operut = parse_operut(operut_file)

println(
    "✓ ENTDADOS: $(length(entdados.subsystems)) subsystems, $(length(entdados.thermal_plants)) thermal plants",
)
println("✓ TERMDAT:  $(length(termdat.plants)) plants, $(length(termdat.units)) units")
println(
    "✓ OPERUT:   $(length(operut.init_records)) init, $(length(operut.oper_records)) oper records",
)
println()

# ============================================================================
# 2. SUBSYSTEM → THERMAL PLANTS Relationship (One-to-Many)
# ============================================================================
println("="^80)
println("1. SUBSYSTEM → THERMAL PLANTS (One-to-Many)")
println("="^80)
println()

# For each subsystem, find all thermal plants
subsystem_plants = Dict{Int,Vector{String}}()

for subsys in entdados.subsystems
    # Find all thermal plants in this subsystem (Foreign Key: UT.subsystem → SIST.subsystem_num)
    plants_in_subsys =
        filter(p -> p.subsystem == subsys.subsystem_num, entdados.thermal_plants)

    plant_names = [p.plant_name for p in plants_in_subsys]
    subsystem_plants[subsys.subsystem_num] = plant_names

    println(
        "Subsystem $(subsys.subsystem_num) ($(subsys.subsystem_code)): $(length(plant_names)) thermal plants",
    )
    if length(plant_names) <= 5
        for name in plant_names
            println("    ├─ $name")
        end
    else
        for name in plant_names[1:3]
            println("    ├─ $name")
        end
        println("    ├─ ... ($(length(plant_names) - 5) more)")
        for name in plant_names[(end-1):end]
            println("    ├─ $name")
        end
    end
    println()
end

# ============================================================================
# 3. THERMAL PLANT → UNITS Relationship (One-to-Many)
# ============================================================================
println("="^80)
println("2. THERMAL PLANT → UNITS (One-to-Many)")
println("="^80)
println()

# Example: Pick first 3 plants and show their units
example_plants = entdados.thermal_plants[1:min(3, length(entdados.thermal_plants))]

for entdados_plant in example_plants
    # Find corresponding TERMDAT plant record (same plant_num)
    termdat_plant = findfirst(p -> p.plant_num == entdados_plant.plant_num, termdat.plants)

    if !isnothing(termdat_plant)
        plant = termdat.plants[termdat_plant]

        # Find all units for this plant (Foreign Key: CADUNIDT.plant_num → CADUSIT.plant_num)
        units = filter(u -> u.plant_num == plant.plant_num, termdat.units)

        println("Plant $(plant.plant_num): $(plant.plant_name)")
        println("  Subsystem: $(plant.subsystem)")
        println("  Total Units: $(length(units))")

        for unit in units[1:min(3, length(units))]
            println("    Unit $(unit.unit_num):")
            println("      - Capacity: $(unit.unit_capacity) MW")
            println("      - Min Gen: $(unit.min_generation) MW")
            println("      - Cold Startup: $(unit.cold_startup_cost) R\$")
        end

        if length(units) > 3
            println("    ... ($(length(units) - 3) more units)")
        end
        println()
    end
end

# ============================================================================
# 4. THERMAL UNIT → OPERATING COST Join (Across Files)
# ============================================================================
println("="^80)
println("3. THERMAL UNIT → OPERATING COST (Cross-File Join)")
println("="^80)
println()

# Join TERMDAT units with OPERUT operating costs
# This demonstrates a foreign key relationship across different files:
# OPER.(plant_num, unit_num) → CADUNIDT.(plant_num, unit_num)

println("Joining thermal units with their operating costs...")
println()

# Group OPER records by (plant_num, unit_num)
unit_costs = Dict{Tuple{Int,Int},Vector{Float64}}()

for oper in operut.oper_records
    key = (oper.plant_num, oper.unit_num)
    if !haskey(unit_costs, key)
        unit_costs[key] = Float64[]
    end
    push!(unit_costs[key], oper.operating_cost)
end

println("Found operating costs for $(length(unit_costs)) unique units")
println()

# Show 5 examples with unit details from TERMDAT
unit_examples = collect(keys(unit_costs))[1:min(5, length(unit_costs))]

for (plant_num, unit_num) in unit_examples
    # Find unit in TERMDAT (referential integrity check)
    unit_idx =
        findfirst(u -> u.plant_num == plant_num && u.unit_num == unit_num, termdat.units)

    if !isnothing(unit_idx)
        unit = termdat.units[unit_idx]
        costs = unit_costs[(plant_num, unit_num)]

        # Find plant name from TERMDAT
        plant_idx = findfirst(p -> p.plant_num == plant_num, termdat.plants)
        plant_name =
            !isnothing(plant_idx) ? termdat.plants[plant_idx].plant_name : "Unknown"

        println("$(plant_name) - Unit $(unit_num):")
        println("  Capacity: $(unit.unit_capacity) MW")
        println("  Cost records: $(length(costs))")
        println(
            "  Cost range: $(round(minimum(costs), digits=2)) - $(round(maximum(costs), digits=2)) R\$/MWh",
        )

        if length(costs) <= 3
            for (i, cost) in enumerate(costs)
                println("    Period $(i): $(round(cost, digits=2)) R\$/MWh")
            end
        else
            println("    Min: $(round(minimum(costs), digits=2)) R\$/MWh")
            println("    Max: $(round(maximum(costs), digits=2)) R\$/MWh")
            println("    Avg: $(round(sum(costs)/length(costs), digits=2)) R\$/MWh")
        end
        println()
    end
end

# ============================================================================
# 5. Referential Integrity Check
# ============================================================================
println("="^80)
println("4. Referential Integrity Validation")
println("="^80)
println()

# Check that all thermal plants in ENTDADOS exist in TERMDAT
entdados_plant_nums = Set(p.plant_num for p in entdados.thermal_plants)
termdat_plant_nums = Set(p.plant_num for p in termdat.plants)

missing_in_termdat = setdiff(entdados_plant_nums, termdat_plant_nums)
extra_in_termdat = setdiff(termdat_plant_nums, entdados_plant_nums)

println("Foreign Key Validation: ENTDADOS.UT.plant_num → TERMDAT.CADUSIT.plant_num")
println("  ENTDADOS plants: $(length(entdados_plant_nums))")
println("  TERMDAT plants: $(length(termdat_plant_nums))")
println("  Missing in TERMDAT: $(length(missing_in_termdat))")
println("  Extra in TERMDAT: $(length(extra_in_termdat))")

if length(missing_in_termdat) == 0 && length(extra_in_termdat) == 0
    println("  ✓ Perfect referential integrity!")
else
    println("  ⚠ Referential integrity violations detected")
    if length(missing_in_termdat) > 0
        println("    Missing plants: $(collect(missing_in_termdat))")
    end
    if length(extra_in_termdat) > 0
        println(
            "    Extra plants: $(collect(extra_in_termdat)[1:min(5, length(extra_in_termdat))])...",
        )
    end
end
println()

# Check that all OPERUT records reference valid units in TERMDAT
termdat_unit_keys = Set((u.plant_num, u.unit_num) for u in termdat.units)
operut_unit_keys = Set((o.plant_num, o.unit_num) for o in operut.oper_records)

orphan_oper_records = setdiff(operut_unit_keys, termdat_unit_keys)

println(
    "Foreign Key Validation: OPERUT.OPER.(plant_num, unit_num) → TERMDAT.CADUNIDT.(plant_num, unit_num)",
)
println("  OPERUT units: $(length(operut_unit_keys))")
println("  TERMDAT units: $(length(termdat_unit_keys))")
println("  Orphan OPER records: $(length(orphan_oper_records))")

if length(orphan_oper_records) == 0
    println("  ✓ All operating cost records reference valid units!")
else
    println("  ⚠ Found orphan operating cost records")
    println(
        "    Examples: $(collect(orphan_oper_records)[1:min(3, length(orphan_oper_records))])...",
    )
end
println()

# ============================================================================
# 6. Summary Statistics
# ============================================================================
println("="^80)
println("Summary: Entity Counts and Relationships")
println("="^80)
println()

println("Entity Hierarchy:")
println("  System")
println("    └─► $(length(entdados.subsystems)) Subsystems")
println("          ├─► $(length(entdados.hydro_plants)) Hydro Plants")
println("          └─► $(length(entdados.thermal_plants)) Thermal Plants")
println("                └─► $(length(termdat.units)) Thermal Units")
println("                      └─► $(length(operut.oper_records)) Operating Cost Records")
println()

println("Cross-File Relationships:")
println(
    "  SUBSYSTEM (1) ──► (*) THERMAL_PLANT: $(length(entdados.subsystems)) → $(length(entdados.thermal_plants))",
)
println(
    "  THERMAL_PLANT (1) ──► (*) THERMAL_UNIT: $(length(termdat.plants)) → $(length(termdat.units))",
)
println(
    "  THERMAL_UNIT (1) ──► (*) OPER_RECORD: $(length(termdat.units)) → $(length(operut.oper_records))",
)
println()

println("Average relationships:")
avg_plants_per_subsys =
    length(entdados.thermal_plants) / max(1, length(entdados.subsystems))
avg_units_per_plant = length(termdat.units) / max(1, length(termdat.plants))
avg_cost_records_per_unit = length(operut.oper_records) / max(1, length(unit_costs))

println("  Plants per Subsystem: $(round(avg_plants_per_subsys, digits=1))")
println("  Units per Plant: $(round(avg_units_per_plant, digits=1))")
println("  Cost records per Unit: $(round(avg_cost_records_per_unit, digits=1))")
println()

println("✅ Relationship analysis complete!")
println()
println("For complete documentation of all entity relationships, see:")
println("  docs/ENTITY_RELATIONSHIPS.md")
