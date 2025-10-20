# Fuel Costs in DESSEM Files - Complete Guide

## Summary

Fuel costs in DESSEM are stored in **two different ways** depending on what you need:

1. **TERMDAT.DAT** → Plant-level fuel characteristics (heat rate + fuel cost)
2. **OPERUT.DAT** → Unit-level operating costs (CVU - Custo Variável Unitário)

## 1. TERMDAT.DAT - Fuel Characteristics (Plant Level)

### File Structure: CADUSIT Records

**Location**: `termdat.dat`  
**Record Type**: `CADUSIT` (Thermal Plant Registry)

### Fields Related to Fuel Costs

```julia
CADUSIT struct:
    plant_num::Int              # Plant ID
    plant_name::String          # Plant name
    subsystem::Int              # Electrical subsystem
    ...
    fuel_type::Int              # Fuel type code
    heat_rate::Float64          # Heat rate (kJ/kWh)
    fuel_cost::Float64          # Fuel cost (R$/unit)
```

### Example from ONS Sample

```
CADUSIT   1 ANGRA 1       1 1985 01 01 00 0    1
         ^^^ ^^^^^^^^^^^^ ^ ^^^^^^^^^ ^^ ^ ^^^^
         ID  Name         S Year     FT HC NumU
```

**Note**: In the ONS sample, these fields often contain default/zero values because:
- Heat rate is defined per unit in CURVACOMB records
- Operating costs are specified in OPERUT.DAT

### Heat Rate Curves (CURVACOMB)

More detailed fuel consumption data is in **CURVACOMB** records:

```
CURVACOMB  1  1  10500   100.0
          ^^^ ^^ ^^^^^^ ^^^^^^^
          Plt Un HeatR  GenMW
```

This defines the heat rate (fuel consumption efficiency) at different generation levels.

**Formula**:
```
Fuel Cost (R$/MWh) = Heat Rate (kJ/kWh) × Fuel Cost (R$/kJ)
                   = (kJ/kWh) × (R$/unit) / (kJ/unit)
```

## 2. OPERUT.DAT - Operating Costs (Unit Level) ⭐ **PRIMARY SOURCE**

### File Structure: OPER Block

**Location**: `operut.dat`  
**Record Type**: `OPER` (Operating Cost Records)

### Fields in OPER Records

```julia
OPERRecord struct:
    plant_num::Int              # Plant number
    plant_name::String          # Plant name
    unit_num::Int               # Unit number
    start_day::Int              # Start day
    start_hour::Int             # Start hour
    start_half::Int             # Start half-hour
    end_day::Union{Int,String}  # End day or "F"
    operating_cost::Float64     # R$/MWh ⭐ THIS IS THE KEY FIELD
```

### Example from ONS Sample

```
OPER
  1 ANGRA 1       1 11  0 0 F                                31.17
 13 ANGRA 2       1 11  0 0 F                                20.12
 97 CUBATAO       1 11  0 0 F                               384.92
 12 CUIABA CC     1 11  0 0 F                               933.00
 63 IBIRITE       1 11  0 0 F                               942.64
```

**Format Breakdown**:
```
  1 ANGRA 1       1 11  0 0 F                                31.17
 ^^ ^^^^^^^^^^^^ ^^ ^^ ^^ ^ ^                              ^^^^^^
 ID Name         Un Di Hr H EF                             Cost R$/MWh
```

Where:
- **ID**: Plant number (columns 1-3)
- **Name**: Plant name (columns 5-16)
- **Un**: Unit number (columns 18-19)
- **Di**: Start day (columns 21-22)
- **Hr**: Start hour (columns 24-25)
- **H**: Start half-hour (column 27)
- **EF**: End day or "F" for final (columns 29-30)
- **Cost**: Operating cost in R$/MWh (columns 59-70) ⭐

## 3. Which File Should You Use?

### Use OPERUT.DAT When:
✅ You need **actual operating costs** (CVU - Variable Unit Cost)  
✅ You want costs **per unit** (not per plant)  
✅ You need **time-varying costs** (different periods)  
✅ You're doing **dispatch optimization**  
✅ You want **production-ready values** used by DESSEM

### Use TERMDAT.DAT When:
✅ You need **fuel type information**  
✅ You want **heat rate curves** (efficiency at different loads)  
✅ You're analyzing **fuel consumption** patterns  
✅ You need **plant characteristics** (not operational costs)

## 4. Example: Extracting Operating Costs

### Julia Code

```julia
using DESSEM2Julia

# Parse OPERUT file
operut = parse_operut("operut.dat")

# Get all operating costs
for record in operut.oper_records
    println("Plant $(record.plant_num) - $(record.plant_name), " *
            "Unit $(record.unit_num): $(record.operating_cost) R\$/MWh")
end

# Find cheapest units
costs = [(r.plant_name, r.unit_num, r.operating_cost) for r in operut.oper_records]
sort!(costs, by=x->x[3])  # Sort by cost

println("\n5 Cheapest Units:")
for (name, unit, cost) in costs[1:5]
    println("  $name Unit $unit: $(round(cost, digits=2)) R\$/MWh")
end
```

### Sample Output from ONS Data (October 2025)

```
5 Cheapest Units:
  ANGRA 2 Unit 1: 20.12 R$/MWh      (Nuclear - very low operating cost)
  ANGRA 1 Unit 1: 31.17 R$/MWh      (Nuclear)
  CUBATAO Unit 1: 384.92 R$/MWh     (Natural gas)
  CUIABA CC Unit 1: 933.00 R$/MWh   (Combined cycle)
  IBIRITE Unit 1: 942.64 R$/MWh     (Coal)
```

## 5. Cost Components Explained

### Operating Cost (CVU) Includes:

1. **Fuel Cost**: Primary component
   - Natural gas, coal, diesel, nuclear fuel, etc.
   - Varies with international fuel prices
   - Updated regularly (monthly/weekly)

2. **Operation & Maintenance (O&M)**: Variable O&M costs
   - Wear and tear
   - Consumables
   - Routine maintenance

3. **Other Variable Costs**:
   - Water consumption (cooling)
   - Chemical additives
   - Environmental compliance costs

### Cost Formula (Simplified)

```
CVU (R$/MWh) = Fuel Cost (R$/kJ) × Heat Rate (kJ/kWh) / 1000 + O&M (R$/MWh)

Example for natural gas plant:
- Fuel cost: 0.20 R$/m³
- Heat rate: 9,500 kJ/kWh (efficiency ~38%)
- Energy density: 35,000 kJ/m³
- O&M: 5 R$/MWh

CVU = (0.20 × 9,500 / 35,000) × 1000 + 5
    = 54.3 + 5
    = 59.3 R$/MWh
```

## 6. Real Data from Your ONS Sample

From `DS_ONS_102025_RV2D11/operut.dat`:

| Plant | Unit | Cost (R$/MWh) | Technology | Note |
|-------|------|---------------|------------|------|
| ANGRA 2 | 1 | 20.12 | Nuclear | Lowest cost |
| ANGRA 1 | 1 | 31.17 | Nuclear | Very low |
| CUBATAO | 1-3 | 384.92 | Natural Gas | Medium |
| CUIABA CC | 1-3 | 933.00 | Combined Cycle | High |
| IBIRITE | 1 | 942.64 | Coal | High |
| J.FORA | 1-2 | 1,171.19 | Diesel/Oil | Very high |
| MARANHAO V | 1 | 3,014.12 | Diesel | Highest (peaker) |

### Cost Range Analysis:
- **Nuclear**: 20-31 R$/MWh (base load)
- **Natural Gas**: 385-450 R$/MWh (intermediate)
- **Coal**: 900-1,000 R$/MWh (intermediate/base)
- **Diesel/Oil**: 1,100-3,000+ R$/MWh (peaker units)

## 7. Complete Example Script

See: `examples/list_thermal_costs.jl`

This example:
- Parses OPERUT.DAT
- Extracts all operating costs
- Sorts units by cost
- Shows cost distribution
- Identifies cheapest/most expensive units

**Run it**:
```bash
julia --project=. examples/list_thermal_costs.jl
```

## 8. Related Documentation

- **OPERUT Parser**: `src/parser/operut.jl`
- **TERMDAT Parser**: `src/parser/termdat.jl`
- **Type Definitions**: `src/types.jl` (OPERRecord, CADUSIT, CURVACOMB)
- **Example**: `examples/list_thermal_costs.jl`

## 9. Key Takeaways

✅ **Primary source for operating costs**: `OPERUT.DAT` → `OPER` records → `operating_cost` field  
✅ **Units**: R$/MWh (Brazilian Reais per Megawatt-hour)  
✅ **Granularity**: Per unit, per time period  
✅ **Time-varying**: Can change by study period  
✅ **Already parsed**: Use `parse_operut()` and access `oper_records`  

🔥 **Most common mistake**: Looking for costs in TERMDAT instead of OPERUT!

## 10. Next Steps

If you need to:
- **List all costs**: Use `examples/list_thermal_costs.jl`
- **Find cheapest units**: Sort by `operating_cost`
- **Calculate total cost**: Multiply by generation (MWh)
- **Analyze by fuel type**: Cross-reference with TERMDAT `fuel_type`
- **Compare periods**: Parse multiple OPERUT files from different revisions

---

**TL;DR**: Unit fuel costs (operating costs) are in **OPERUT.DAT** in the **OPER block**, stored as **`operating_cost`** in R$/MWh. Use `parse_operut()` to access them.
