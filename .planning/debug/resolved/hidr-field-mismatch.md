---
status: resolved
trigger: "list_buses_with_generators.jl uses wrong field names reading binary HIDR data"
created: 2026-02-18T10:00:00
updated: 2026-02-18T10:05:00
---

## Current Focus
hypothesis: Example script uses English field names but BinaryHidrRecord uses Portuguese field names from IDESSEM spec
test: Read BinaryHidrRecord struct definition and compare with example script usage
expecting: Confirm field name mismatch between expected (plant_num, plant_name) and actual (posto, nome)
next_action: Read full BinaryHidrRecord definition to identify all field name mappings

## Symptoms
expected: Example script should access hydro plant data using field names like `plant_num` and `plant_name`
actual: Script fails with FieldError - BinaryHidrRecord has no field `plant_num`
errors: "FieldError: type BinaryHidrRecord has no field `plant_num`, available fields: `nome`, `posto`, `posto_bdh`, ..."
reproduction: Run `julia --project examples/list_buses_with_generators.jl`
timeline: Occurred when testing PWF.jl integration after fixing it

## Eliminated

## Evidence
- timestamp: 2026-02-18T10:00:00
  checked: Example script line 212
  found: Script accesses `plant.plant_num`, `plant.plant_name`, `plant.installed_capacity`
  implication: These are likely incorrect English names; BinaryHidrRecord uses Portuguese names

## Resolution
root_cause: Example script uses English field names (plant_num, plant_name, installed_capacity) but BinaryHidrRecord uses Portuguese field names from IDESSEM spec (posto, nome, potef_conjunto)
fix: Updated list_buses_with_generators.jl to use correct Portuguese field names and calculate installed capacity from machine sets (numero_maquinas_conjunto * potef_conjunto)
verification: Tested field access with `julia --project -e` - all fields accessible and capacity calculation works (CAMARGOS: 2 machines × 23 MW = 46 MW)
files_changed: [examples/list_buses_with_generators.jl]
