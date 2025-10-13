using DESSEM2Julia

println("Testing core types module...")

# Test that DessemCase can be constructed
case = DessemCase(
    case_name = "TEST_CASE",
    case_title = "Test Case"
)

println("✓ DessemCase created successfully")
println("  Case name: $(case.case_name)")
println("  Title: $(case.case_title)")

# Test HydroPlant
hydro = HydroPlant(
    plant_num = 6,
    plant_name = "FURNAS",
    subsystem = 1,
    installed_capacity_mw = 1216.0,
    num_units = 8
)

println("✓ HydroPlant created successfully")
println("  Plant: $(hydro.plant_name)")
println("  Capacity: $(hydro.installed_capacity_mw) MW")

# Test ThermalPlant
thermal = ThermalPlant(
    plant_num = 101,
    plant_name = "ANGRA1",
    subsystem = 1,
    num_units = 1
)

println("✓ ThermalPlant created successfully")
println("  Plant: $(thermal.plant_name)")

# Test TimePeriod
period = TimePeriod(
    period_id = 1,
    day = 1,
    hour = 0,
    network_flag = 0
)

println("✓ TimePeriod created successfully")
println("  Period: $(period.period_id), Day: $(period.day), Hour: $(period.hour)")

println("\n✅ All core types working correctly!")
println("\nAvailable container types:")
println("  - DessemCase")
println("  - HydroSystem")
println("  - ThermalSystem")
println("  - PowerSystem")
println("  - RenewableSystem")
println("  - NetworkSystem")
println("  - OperationalConstraints")
println("  - TimeDiscretization")
println("  - DecompCut")
println("  - ExecutionOptions")
println("  - FileRegistry")
