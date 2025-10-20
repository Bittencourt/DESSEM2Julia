# HIDR.DAT Quick Reference

> **📚 Part of**: [DESSEM2Julia Documentation](INDEX.md) | **📖 Also see**: [HIDR Binary Complete](HIDR_BINARY_COMPLETE.md), [HIDR Entity Diagram](HIDR_ENTITY_DIAGRAM.md), [Entity Relationships](ENTITY_RELATIONSHIPS.md)

## Parser Usage

```julia
using DESSEM2Julia

# Auto-detect and parse (binary or text)
hidr_data = parse_hidr("hidr.dat")

# Access data
plants = hidr_data.plants              # Vector{CADUSIH}
travel_times = hidr_data.travel_times  # Vector{USITVIAG} (empty for binary)
unit_sets = hidr_data.unit_sets        # Vector{CADCONJ} (empty for binary)
```

## Format Support

| Feature | Text Format | Binary Format |
|---------|-------------|---------------|
| **Plant Registry** (CADUSIH) | ✅ | ✅ |
| **Travel Times** (USITVIAG) | ✅ | ❌ |
| **Volume-Elevation** (POLCOT) | ✅ | ❌ |
| **Volume-Area** (POLARE) | ✅ | ❌ |
| **Tailrace** (POLJUS) | ✅ | ❌ |
| **Evaporation** (COEFEVA) | ✅ | ❌ |
| **Unit Sets** (CADCONJ) | ✅ | ❌ |
| **Fields per plant** | 14 (CADUSIH) | 111 → 14 mapped |
| **File size pattern** | Variable | Multiple of 792 bytes |

## CADUSIH Fields (Plant Registry)

```julia
struct CADUSIH
    plant_num::Int              # Primary key
    plant_name::String          # 12 chars max
    subsystem::Int              # FK → SIST.subsystem_num
    downstream_plant::Union{Int, Nothing}  # FK → CADUSIH.plant_num (cascade)
    diversion_downstream::Union{Int, Nothing}  # Alternative flow path
    min_volume::Union{Float64, Nothing}    # hm³
    max_volume::Union{Float64, Nothing}    # hm³
    installed_capacity::Union{Float64, Nothing}  # MW
    productivity::Union{Float64, Nothing}   # MW/(m³/s)
    commission_year::Union{Int, Nothing}
    commission_month::Union{Int, Nothing}
    commission_day::Union{Int, Nothing}
    plant_type::Union{Int, Nothing}   # Turbine type
    max_turbine_flow::Float64         # m³/s
end
```

## Relationships

### Foreign Keys
```
CADUSIH.subsystem → SIST.subsystem_num (ENTDADOS)
CADUSIH.downstream_plant → CADUSIH.plant_num (self-reference)
CADUSIH.plant_num ← USITVIAG.from_plant/to_plant
CADUSIH.plant_num ← POLCOT.plant_num
CADUSIH.plant_num ← CADCONJ.plant_num
CADUSIH.plant_num ← DADVAZ.plant_num
CADUSIH.plant_num ← OPERUH.plant_num
CADUSIH.plant_num ← ENTDADOS.UH.plant_num
```

### Cascade Topology
```
Plant (upstream) 
  └─► downstream_plant → Plant (intermediate)
                           └─► downstream_plant → Plant (final)
```

## Common Queries

### Get cascade roots (upstream plants)
```julia
function find_cascade_roots(hidr_data)
    downstream_set = Set(p.downstream_plant for p in hidr_data.plants 
                         if p.downstream_plant !== nothing && p.downstream_plant > 0)
    return filter(p -> p.plant_num > 0 && p.plant_num ∉ downstream_set, 
                  hidr_data.plants)
end
```

### Get all downstream plants
```julia
function get_downstream_cascade(plant_num, hidr_data)
    cascade = [plant_num]
    
    function traverse(pnum)
        plant = findfirst(p -> p.plant_num == pnum, hidr_data.plants)
        if plant !== nothing && plant.downstream_plant !== nothing && plant.downstream_plant > 0
            push!(cascade, plant.downstream_plant)
            traverse(plant.downstream_plant)
        end
    end
    
    traverse(plant_num)
    return cascade
end
```

### Get all upstream plants
```julia
function get_upstream_plants(plant_num, hidr_data)
    return filter(p -> p.downstream_plant == plant_num, hidr_data.plants)
end
```

### Filter by subsystem
```julia
# Southeast plants (subsystem 1)
se_plants = filter(p -> p.subsystem == 1, hidr_data.plants)

# Calculate total capacity
total_mw = sum(p.installed_capacity for p in se_plants 
               if p.installed_capacity !== nothing)
```

### Calculate cascade capacity
```julia
function cascade_total_capacity(root_plant_num, hidr_data)
    cascade = get_downstream_cascade(root_plant_num, hidr_data)
    
    total = 0.0
    for pnum in cascade
        plant = findfirst(p -> p.plant_num == pnum, hidr_data.plants)
        if plant !== nothing && plant.installed_capacity !== nothing
            total += plant.installed_capacity
        end
    end
    
    return total
end
```

## Real-World Example (ONS Sample)

From `DS_ONS_102025_RV2D11/hidr.dat` (binary format):

```
Total: 185 plants, 24,218 MW

Subsystems:
  1 (Southeast): 117 plants, 11,727 MW
  2 (South):      36 plants,  4,662 MW
  3 (Northeast):  14 plants,  4,474 MW
  4 (North):      18 plants,  3,355 MW

Longest Cascade: Paranapanema River (11 plants, 923 MW)
  A.A. LAYDNER → PIRAJU → PARANAPANEMA → CHAVANTES → OURINHOS →
  L.N. GARCEZ → CANOAS II → CANOAS I → CAPIVARA → TAQUARUCU → ROSANA
```

## See Also

- **Implementation**: `src/parser/hidr.jl`, `src/parser/hidr_binary.jl`
- **Types**: `src/types.jl` (CADUSIH, HidrData, etc.)
- **Tests**: `test/hidr_tests.jl`
- **Examples**: `examples/hydro_tree_example.jl`, `examples/simple_hydro_tree.jl`
- **Complete docs**: `docs/HIDR_BINARY_COMPLETE.md`
- **Relationships**: `docs/ENTITY_RELATIONSHIPS.md`
- **Format specs**: `docs/file_formats.md`
