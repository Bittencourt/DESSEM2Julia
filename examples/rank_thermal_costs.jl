using Pkg
Pkg.activate(".")

using DESSEM2Julia

# Path to the ONS sample case
operut_file = joinpath("docs", "Sample", "DS_ONS_102025_RV2D11", "operut.dat")

if !isfile(operut_file)
    println("Error: File not found at $operut_file")
    exit(1)
end

println("Reading OPERUT file from: $operut_file")
operut_data = parse_operut(operut_file)

# Extract OPER records (operating costs and limits)
oper_records = operut_data.oper_records

# Group by plant+unit and collect cost data
# Note: OPER records may have time-varying costs, so we take the first record for each unit
unit_costs = Dict{Tuple{Int,Int},Tuple{String,Float64}}()  # (plant_num, unit_num) => (plant_name, cost)

for record in oper_records
    key = (record.plant_num, record.unit_num)
    if !haskey(unit_costs, key)
        unit_costs[key] = (record.plant_name, record.operating_cost)
    end
end

# Convert to vector for sorting
cost_data = [
    (plant_num, unit_num, plant_name, cost) for
    ((plant_num, unit_num), (plant_name, cost)) in unit_costs
]

# Sort by cost (ascending)
sort!(cost_data, by = x -> x[4])

# Print header
println("="^80)
println("Thermal Units Ordered by Operating Cost (R\$/MWh)")
println("="^80)
println("Rank | Plant # | Unit | Plant Name        | Cost (R\$/MWh)")
println("-"^80)

# Print all units ordered by cost
for (rank, (plant_num, unit_num, plant_name, cost)) in enumerate(cost_data)
    # Format plant name to 17 characters (pad or truncate)
    name_formatted = rpad(plant_name[1:min(length(plant_name), 17)], 17)
    println(
        "$(lpad(rank, 4)) | $(lpad(plant_num, 7)) | $(lpad(unit_num, 4)) | $(name_formatted) | $(lpad(round(cost, digits=2), 13))",
    )
end
