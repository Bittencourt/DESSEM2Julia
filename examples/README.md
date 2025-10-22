# DESSEM2Julia Examples

This directory contains example scripts demonstrating various features of DESSEM2Julia.

## 🌟 Featured: Network Visualization (NEW!)

### Quick Start - Create Network Diagram

```bash
# 1. Install plotting packages (one-time)
julia --project=. -e 'using Pkg; Pkg.add(["Graphs", "GraphPlot", "Colors", "Compose"])'

# 2. Generate electrical network diagram
julia --project=. examples/plot_network_simple.jl
```

**Output**: Beautiful electrical network diagram showing buses and transmission lines! 🎨

📖 **See**: `QUICKSTART_PLOT.md` for complete guide

---

## 📂 Example Scripts

### Network Analysis

- **`plot_network_simple.jl`** ⭐ NEW!
  - Create typical electrical network diagram
  - Buses colored by subsystem, edges by power flow
  - One command: instant visualization
  - 📖 See: `QUICKSTART_PLOT.md`

- **`visualize_network_topology.jl`**
  - Complete network topology analysis
  - Statistics, connectivity, power flows
  - Multiple diagram outputs (full + subsystems)
  - CSV export
  - 📖 See: `NETWORK_VISUALIZATION.md`

### Parsing Examples

- **`parse_sample_case.jl`**
  - Parse complete DESSEM case
  - Extract all data types
  - Basic analysis

- **`test_ons_parsers.jl`**
  - Test parsers with ONS sample data
  - Validate data quality

### Hydro System

- **`hydro_tree_example.jl`**
  - Build hydro cascade tree
  - Visualize upstream/downstream relationships

- **`simple_hydro_tree.jl`**
  - Simple cascade visualization
  - Export to DOT format

### Thermal System

- **`list_thermal_costs.jl`**
  - Extract thermal generation costs
  - Sort by cost/MW

- **`plot_thermal_costs.jl`**
  - Visualize cost curves
  - Compare plants

### Subsystem Analysis

- **`network_plants_by_subsystem.jl`**
  - Group plants by subsystem (SE, S, NE, N)
  - Calculate regional capacity

### Data Exploration

- **`analyze_ons_files.jl`**
  - Explore ONS sample structure
  - File statistics

- **`analyze_relationships.jl`**
  - Study entity relationships
  - Cross-file references

### Validation

- **`verify_ons_compatibility.jl`**
  - Validate parser compatibility
  - Check ONS data quality

## 🚀 Quick Examples

### Parse a DESSEM Case

```julia
using DESSEM2Julia

# Parse complete case
case_dir = "docs/Sample/DS_ONS_102025_RV2D11"
data = parse_dessem_case(case_dir)

println("Hydro plants: ", length(data.hydro_plants))
println("Thermal plants: ", length(data.thermal_plants))
```

### Extract Topology

```julia
using DESSEM2Julia

# Extract network topology
topology = parse_network_topology("docs/Sample/DS_ONS_102025_RV2D11")

println("Buses: ", length(topology.buses))
println("Lines: ", length(topology.lines))
```

### Create Network Diagram

```julia
using DESSEM2Julia

# One-line visualization
include("examples/plot_network_simple.jl")
plot_electrical_network("docs/Sample/DS_ONS_102025_RV2D11")
```

## 📚 Documentation

- **`QUICKSTART_PLOT.md`** - Quick reference for network visualization
- **`NETWORK_VISUALIZATION.md`** - Complete visualization guide
- Main project: `../README.md`
- Type system: `../docs/type_system.md`
- Parser docs: `../docs/parsers/`

## 💡 Tips

1. **Start simple**: Try `plot_network_simple.jl` first
2. **Use ONS sample**: Provided in `docs/Sample/`
3. **Check docs**: Each feature has detailed guides
4. **Experiment**: Modify examples to learn

## 🐛 Troubleshooting

### "Package not found"

```julia
using Pkg
Pkg.add("DESSEM2Julia")
```

### "Plotting libraries not available"

```julia
using Pkg
Pkg.add(["Graphs", "GraphPlot", "Colors", "Compose"])
```

### "Sample file not found"

Ensure you're running from project root:
```bash
cd DESSEM2Julia
julia --project=. examples/script.jl
```

## 📖 More Examples

See main project README for:
- API documentation
- Advanced usage
- Custom parsers
- Integration examples

---

**New to DESSEM2Julia?** Start with:
1. `parse_sample_case.jl` - Understand data structure
2. `plot_network_simple.jl` - Visualize the system
3. `hydro_tree_example.jl` - Explore relationships
