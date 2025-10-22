# Network Topology Visualization Examples

This directory contains examples for visualizing electrical network topology extracted from DESSEM cases.

## 📊 Available Examples

### 1. `plot_network_simple.jl` - Quick Network Diagram

**Purpose**: Create a typical electrical network diagram showing buses and transmission lines.

**Features**:
- Buses colored by subsystem (SE=Red, S=Blue, NE=Orange, N=Green)
- Node size proportional to connectivity
- Edge thickness proportional to power flow
- Labels for important buses (hubs and named plants)

**Requirements**:
```julia
using Pkg
Pkg.add(["Graphs", "GraphPlot", "Colors", "Compose"])
```

**Usage**:
```bash
# Default (uses ONS sample)
julia --project=. examples/plot_network_simple.jl

# Custom case and stage
julia --project=. examples/plot_network_simple.jl /path/to/case 1
```

**Output**: `electrical_network.png`

### 2. `visualize_network_topology.jl` - Complete Analysis

**Purpose**: Comprehensive network analysis with statistics, diagrams, and CSV export.

**Features**:
- Detailed network statistics
- Connectivity analysis (degree distribution, hubs)
- Power flow analysis
- Multiple diagram outputs (full network + subsystems)
- CSV export of topology

**Usage**:
```bash
julia --project=. examples/visualize_network_topology.jl
```

**Outputs**:
- `network_topology_summary.csv` - Complete topology data
- `network_full.png` - Full network diagram
- `network_se.png`, `network_s.png`, etc. - Subsystem diagrams

## 🎨 Diagram Features

### Node (Bus) Representation

**Color Coding** (Brazilian subsystems):
- 🔴 **Red** - Southeast (SE) - Main load center
- 🔵 **Blue/Cyan** - South (S)
- 🟡 **Yellow/Orange** - Northeast (NE)
- 🟢 **Green** - North (N)
- ⚪ **Gray** - Unknown/unassigned

**Size**: Larger nodes = more connections (higher degree)

**Labels**: Shown for:
- Named buses (hydro plants, major substations)
- High-connectivity buses (>8 or >10 connections)

### Edge (Line) Representation

**Thickness**: Proportional to power flow magnitude (MW)
- Thin lines: Low power flow
- Thick lines: High power flow (>1000 MW)

**Opacity/Darkness**: Flow intensity
- Lighter: Lower flows
- Darker: Higher flows (near capacity)

### Layout Algorithms

The examples use **spring layout** by default (force-directed):
- Pushes connected nodes together
- Pushes all nodes apart
- Results in natural clustering of subsystems

Other layouts available:
- `:stress` - Stress minimization
- `:circular` - Circular arrangement
- `:shell` - Concentric shells

## 📈 Example Output

From ONS sample (DS_ONS_102025_RV2D11):

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

🎨 Styling network elements...
   ✓ Styled 342 nodes and 629 edges

📐 Computing spring layout...
🖼️  Rendering diagram...
💾 Saving to: electrical_network.png

======================================================================
✓ Diagram created successfully!
======================================================================

📊 Network Statistics:
   • Buses: 342
   • Lines: 629
   • Average connections: 3.68
   • Max connections: 20

🗺️  Subsystem Distribution:
   • N: 2 buses (Green)
   • NE: 5 buses (Orange)
   • S: 7 buses (Blue)
   • SE: 14 buses (Red)
```

## 🔧 Customization

### Adjust Number of Buses

For large networks, limit buses for performance:

```julia
plot_electrical_network(case_dir, max_buses=300)
```

### Change Layout Algorithm

```julia
plot_network_diagram(topology, layout=:stress)  # Alternative layouts
```

### Highlight Specific Subsystem

```julia
plot_subsystem_diagram(topology, "SE")  # Southeast only
```

### Custom Colors

Edit the `subsystem_colors` dictionary:

```julia
subsystem_colors = Dict(
    "SE" => colorant"#FF0000",  # Your custom red
    "S"  => colorant"#0000FF",  # Your custom blue
    # etc.
)
```

## 📦 Package Installation

If you get "library not available" errors:

```julia
# In Julia REPL
using Pkg

# Install all required packages
Pkg.add("Graphs")        # Graph data structures
Pkg.add("GraphPlot")     # Graph visualization
Pkg.add("Colors")        # Color handling
Pkg.add("Compose")       # Drawing backend
Pkg.add("Statistics")    # For mean() function
```

## 🐛 Troubleshooting

### "Plotting libraries not available"

Install missing packages (see above).

### "Case directory not found"

Ensure the path is correct:
```bash
julia --project=. examples/plot_network_simple.jl "C:/full/path/to/case"
```

### Diagram too crowded

Reduce max_buses:
```julia
plot_electrical_network(case_dir, max_buses=200)
```

### Out of memory

- Reduce `max_buses` parameter
- Plot individual subsystems instead of full network
- Use `:circular` layout (faster than `:spring`)

## 📚 Additional Examples

### Generate Diagrams for All Stages

```julia
using DESSEM2Julia
include("examples/plot_network_simple.jl")

case_dir = "docs/Sample/DS_ONS_102025_RV2D11"

for stage in 1:48
    println("Plotting stage $stage...")
    plot_electrical_network(case_dir, 
                           stage=stage,
                           output_file="network_stage_$(stage).png")
end
```

### Filter by Flow Threshold

```julia
# Only show lines with >500 MW
topology = parse_network_topology(case_dir)

high_flow_lines = [line for line in topology.lines 
                   if !isnothing(line.flow_mw) && abs(line.flow_mw) > 500]

filtered_topology = NetworkTopology(
    buses=topology.buses,
    lines=high_flow_lines,
    stage=topology.stage,
    load_level=topology.load_level
)

plot_network_diagram(filtered_topology)
```

### Export for External Tools

```julia
# Export to GraphML (for Gephi, Cytoscape, etc.)
using LightGraphs, GraphIO

g = build_graph_from_topology(topology)
savegraph("network.graphml", g, GraphMLFormat())
```

## 🎯 Use Cases

1. **System Overview**: Quick visualization of network structure
2. **Bottleneck Identification**: Find heavily loaded lines
3. **Subsystem Analysis**: Isolate regional networks
4. **Connectivity Study**: Identify critical buses (hubs)
5. **Time Series**: Track network evolution across stages
6. **Presentations**: Create publication-quality diagrams

## 📖 References

- **GraphPlot.jl**: https://github.com/JuliaGraphs/GraphPlot.jl
- **Graphs.jl**: https://juliagraphs.org/Graphs.jl/
- **DESSEM2Julia**: See main project README

## 💡 Tips

- Start with small subsystems before plotting full network
- Use `max_buses=100` for quick iteration
- Spring layout takes longer but produces better results
- For large networks (>1000 buses), consider interactive tools like Gephi
- Export CSV and use Python/NetworkX for additional analysis
