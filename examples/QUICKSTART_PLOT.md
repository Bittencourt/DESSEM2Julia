# Quick Start: Network Diagram Visualization

## 🚀 One-Command Setup

```bash
# 1. Install plotting packages (one-time setup)
julia --project=. -e 'using Pkg; Pkg.add(["Graphs", "GraphPlot", "Colors", "Compose"])'

# 2. Generate network diagram
julia --project=. examples/plot_network_simple.jl
```

**Output**: `electrical_network.png` - Beautiful network diagram! 🎨

## 📊 What You Get

A typical electrical network diagram showing:

- **Buses** (nodes) colored by region:
  - 🔴 Red = Southeast (SE) - Main load center
  - 🔵 Blue = South (S)
  - 🟡 Orange = Northeast (NE)  
  - 🟢 Green = North (N)

- **Transmission Lines** (edges):
  - Thickness = Power flow (MW)
  - Darkness = Flow intensity

- **Labels** for important buses (hubs and power plants)

## 🎯 Common Use Cases

### Generate Diagram for Your Case

```bash
julia --project=. examples/plot_network_simple.jl "/path/to/your/case" 1
```

### Analyze Specific Stage

```bash
# Stage 24 (midday)
julia --project=. examples/plot_network_simple.jl "docs/Sample/DS_ONS_102025_RV2D11" 24
```

### Create All Stages

```julia
using DESSEM2Julia
include("examples/plot_network_simple.jl")

for stage in 1:48
    plot_electrical_network("docs/Sample/DS_ONS_102025_RV2D11",
                           stage=stage,
                           output_file="network_stage_$stage.png")
end
```

## 🔧 Customization

### Larger Networks

```bash
# Show up to 1000 buses (default 500)
julia -e 'include("examples/plot_network_simple.jl"); 
          plot_electrical_network("path/to/case", max_buses=1000)'
```

### Different Layout

Edit `plot_network_simple.jl`:
```julia
loc_x, loc_y = spring_layout(g, C=2.0)  # Default
# OR
loc_x, loc_y = stress_layout(g)         # Alternative
loc_x, loc_y = circular_layout(g)       # Circular
```

## 📦 Troubleshooting

### "Plotting libraries not available"

```julia
# In Julia REPL
using Pkg
Pkg.add(["Graphs", "GraphPlot", "Colors", "Compose"])
```

### "Case directory not found"

Use absolute path:
```bash
julia --project=. examples/plot_network_simple.jl "C:/Users/you/cases/mycase"
```

### Diagram too crowded

Reduce buses or plot subsystems:
```julia
plot_electrical_network(case_dir, max_buses=200)  # Fewer buses
plot_subsystem_diagram(topology, "SE")            # One region only
```

## 📸 Example Output

```
Electrical Network Diagram
======================================================================
Case: docs/Sample/DS_ONS_102025_RV2D11
Stage: 1

📊 Extracting network topology...
   ✓ 342 buses
   ✓ 629 transmission lines

🔧 Building graph...
   ✓ Graph: 342 nodes, 629 edges

✓ Diagram created successfully!

📊 Network Statistics:
   • Buses: 342
   • Lines: 629
   • Average connections: 3.68
   • Max connections: 20

🗺️  Subsystem Distribution:
   • SE: 14 buses (Red)
   • S: 7 buses (Blue)
   • NE: 5 buses (Orange)
   • N: 2 buses (Green)
```

## 🎨 Color Scheme

Based on typical Brazilian power system maps:

| Subsystem | Color | Region |
|-----------|-------|--------|
| SE | 🔴 Red | Southeast (São Paulo, Rio) |
| S | 🔵 Blue | South (Paraná, Santa Catarina, Rio Grande do Sul) |
| NE | 🟡 Orange | Northeast (Bahia, Pernambuco, etc.) |
| N | 🟢 Green | North (Amazonas, Pará, etc.) |

## 📚 More Examples

See `examples/NETWORK_VISUALIZATION.md` for:
- Complete analysis with statistics
- Subsystem filtering
- CSV export
- Time-series animation
- Integration with external tools

## 💡 Pro Tips

1. **Start small**: Test with `max_buses=100` first
2. **Use subsystems**: For detailed analysis of regions
3. **Export CSV**: For custom analysis in Python/R
4. **Adjust layout**: Try different algorithms for clarity
5. **High-res output**: Edit figure size in code for publications

---

**Need help?** See `examples/NETWORK_VISUALIZATION.md` for full documentation.
