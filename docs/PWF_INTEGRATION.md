# PWF.jl Integration Guide

> **📚 Part of**: [DESSEM2Julia Documentation](INDEX.md) | **🔗 External**: [PWF.jl GitHub](https://github.com/LAMPSPUC/PWF.jl)
> **📦 Implementation**: [src/parser/pwf.jl](../src/parser/pwf.jl) | **🧪 Tests**: [test/pwf_tests.jl](../test/pwf_tests.jl)

## Overview

DESSEM2Julia now integrates **PWF.jl** to read ANAREDE `.pwf` (power flow) files, providing complete access to Brazilian power system network topology data.

## What is PWF.jl?

**PWF.jl** is a Julia package developed by the **LAMPS research group at PUC-Rio** (Brazil) specifically for reading ANAREDE power system data files.

### Key Information

- **Developer**: LAMPS research group, PUC-Rio
- **Repository**: https://github.com/LAMPSPUC/PWF.jl
- **Documentation**: https://lampspuc.github.io/PWF.jl/
- **Purpose**: Read ANAREDE `.pwf` files in Julia
- **License**: Open source (check repository for details)
- **Maintenance**: Active development

### Why Use PWF.jl?

✅ **Specialized**: Designed specifically for Brazilian power systems
✅ **Well-tested**: Battle-tested in production environments
✅ **Maintained**: Regular updates from domain experts
✅ **No reinventing**: Avoids complex binary format reverse engineering
✅ **Clean integration**: Seamless conversion to DESSEM2Julia types

## Installation

### Add PWF.jl Dependency

PWF.jl is already added to `Project.toml`:

```toml
[deps]
PWF = "c484c51a-cb0d-4fb0-83c9-ce91382e7b63"
```

### Install Package

```julia
using Pkg
Pkg.add("PWF")
```

Or install from the project directory:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Quick Start

### 1. Parse a PWF File

```julia
using DESSEM2Julia

# Parse PWF file (returns native PWF.jl structure)
pwf_data = parse_pwf("leve.pwf")

# Access bus data
buses = pwf_data["buses"]

# Access branch/line data
branches = pwf_data["branches"]
```

### 2. Convert to DESSEM2Julia Types

```julia
# Parse and convert to NetworkTopology
topology = parse_pwf_to_topology("leve.pwf")

# Access buses (NetworkBus type)
println("Number of buses: $(length(topology.buses))")
println("Number of lines: $(length(topology.lines))")

# Access first bus
first_bus = topology.buses[1]
println("Bus $(first_bus.bus_number): $(first_bus.name)")
println("  Voltage: $(first_bus.voltage_kv) kV")
println("  Subsystem: $(first_bus.subsystem)")
println("  Generation: $(first_bus.generation_mw) MW")
println("  Load: $(first_bus.load_mw) MW")
```

### 3. Filter and Analyze

```julia
# Filter buses by subsystem
se_buses = filter(b -> b.subsystem == "SE", topology.buses)
println("Southeast buses: $(length(se_buses))")

# Find high-voltage buses (500 kV)
hv_buses = filter(b -> b.voltage_kv == 500.0, topology.buses)

# Find lines from specific bus
from_bus_1001 = filter(l -> l.from_bus == 1001, topology.lines)
```

### 4. Integration with DESSELET

```julia
# Parse DESSELET to get PWF filenames
desselet_data = parse_desselet("desselet.dat")

# Process each base case
for base_case in desselet_data.base_cases
    println("\nProcessing $(base_case.label): $(base_case.filename)")

    # Parse PWF file
    topology = parse_pwf_to_topology(base_case.filename)

    # Analyze network
    println("  Buses: $(length(topology.buses))")
    println("  Lines: $(length(topology.lines))")

    # Count by subsystem
    for subsys in ["SE", "S", "NE", "N"]
        count = count(b -> b.subsystem == subsys, topology.buses)
        println("  $subsys: $count buses")
    end
end
```

## API Reference

### Functions

#### `parse_pwf(filepath::AbstractString) -> Dict{String, Any}`

Parse an ANAREDE `.pwf` file using PWF.jl library.

**Arguments**:
- `filepath`: Path to .pwf file

**Returns**:
- Dictionary with PWF.jl native data structure

**Example**:
```julia
pwf_data = parse_pwf("leve.pwf")
```

---

#### `parse_pwf_to_topology(filepath::AbstractString) -> NetworkTopology`

Parse a `.pwf` file and convert to DESSEM2Julia `NetworkTopology`.

**Arguments**:
- `filepath`: Path to .pwf file

**Returns**:
- `NetworkTopology` with:
  - `buses::Vector{NetworkBus}`
  - `lines::Vector{NetworkLine}`
  - `metadata::Dict{String, Any}`

**Example**:
```julia
topology = parse_pwf_to_topology("media.pwf")
```

---

### Data Types

#### NetworkBus

```julia
struct NetworkBus
    bus_number::Int                      # Bus ID
    name::String                         # Bus name
    subsystem::String                    # SE, S, NE, N
    generation_mw::Union{Float64,Nothing}   # Generation (MW)
    load_mw::Union{Float64,Nothing}         # Load (MW)
    voltage_kv::Union{Float64,Nothing}      # Nominal voltage (kV)
end
```

#### NetworkLine

```julia
struct NetworkLine
    from_bus::Int                        # From bus number
    to_bus::Int                          # To bus number
    circuit::Int                         # Circuit identifier
    flow_mw::Union{Float64,Nothing}      # Power flow (MW)
    capacity_mw::Union{Float64,Nothing}  # Line capacity (MW)
    constraint_name::String              # Constraint name
end
```

#### NetworkTopology

```julia
struct NetworkTopology
    buses::Vector{NetworkBus}            # All buses
    lines::Vector{NetworkLine}           # All lines
    stage::Union{Int, Nothing}           # Time stage
    load_level::String                   # LEVE, MEDIA, PESADA
    metadata::Dict{String, Any}          # Additional info
end
```

## Type Conversion Mapping

### Bus Data (PWF.jl → NetworkBus)

| PWF.jl Field | NetworkBus Field | Type | Notes |
|--------------|------------------|------|-------|
| codigo / number / bus_id | bus_number | Int | Required |
| nome / name | name | String | Optional |
| vbase / basekv / voltage | voltage_kv | Float64 | kV |
| area / area_code | subsystem | String | Mapped to SE/S/NE/N |
| pg / geracao | generation_mw | Float64 | MW |
| pl / carga | load_mw | Float64 | MW |

### Branch Data (PWF.jl → NetworkLine)

| PWF.jl Field | NetworkLine Field | Type | Notes |
|--------------|-------------------|------|-------|
| de / from / bus_from | from_bus | Int | Required |
| para / to / bus_to | to_bus | Int | Required |
| circuit / ck | circuit | Int | Default: 1 |
| rating / capacidade | capacity_mw | Float64 | MW |

## Subsystem Mapping

ANAREDE area codes are mapped to Brazilian subsystems:

```julia
Area Code → Subsystem
    1      →    "SE"   (Southeast)
    2      →    "SE"   (Southeast)
    3      →    "SE"   (Southeast)
    4      →    "S"    (South)
    5      →    "NE"   (Northeast)
    6      →    "N"    (North)
   other   →    ""    (Unknown)
```

## Parser Registration

PWF files are automatically registered in the parser registry:

```julia
register_parser!("LEVE.PWF", parse_pwf)
register_parser!("MEDIA.PWF", parse_pwf)
register_parser!("PESADA.PWF", parse_pwf)
register_parser!(".pwf", parse_pwf)  # Generic
```

This allows automatic file type detection when using `parse_file()`.

## Testing

### Run Tests

```bash
# Run all PWF tests
julia --project=. test/pwf_tests.jl

# Run specific test
julia --project=. -e 'using DESSEM2Julia; include("test/pwf_tests.jl")'
```

### Test Coverage

The test suite includes:

✅ **Unit tests**:
- Bus data conversion
- Branch/line data conversion
- Subsystem mapping (all regions)
- Alternative field names
- Error handling

✅ **Integration tests**:
- Mock PWF data structures
- Type conversions
- Metadata preservation

✅ **Edge cases**:
- Missing fields
- Invalid data
- Empty data structures

## Examples

### Example 1: Basic Network Analysis

```julia
using DESSEM2Julia

# Parse PWF file
topology = parse_pwf_to_topology("leve.pwf")

# Basic statistics
println("Network Statistics:")
println("  Total buses: $(length(topology.buses))")
println("  Total lines: $(length(topology.lines))")

# Subsystem breakdown
for subsys in ["SE", "S", "NE", "N"]
    buses = filter(b -> b.subsystem == subsys, topology.buses)
    gen = sum(b.generation_mw for b in buses if b.generation_mw !== nothing)
    load = sum(b.load_mw for b in buses if b.load_mw !== nothing)
    println("  $subsys: $(length(buses)) buses, $(gen) MW gen, $(load) MW load")
end
```

### Example 2: Find Connected Buses

```julia
# Find all buses connected to bus 1001
target_bus = 1001

connected_lines = filter(l -> l.from_bus == target_bus || l.to_bus == target_bus, topology.lines)
connected_bus_numbers = Set{Int}()

for line in connected_lines
    push!(connected_bus_numbers, line.from_bus)
    push!(connected_bus_numbers, line.to_bus)
end

println("Buses connected to $target_bus:")
for bus_num in sort(collect(connected_bus_numbers))
    bus = findfirst(b -> b.bus_number == bus_num, topology.buses)
    if bus !== nothing
        println("  $bus_num: $(bus.name)")
    end
end
```

### Example 3: Export to DataFrame

```julia
using DataFrames

# Convert buses to DataFrame
buses_df = DataFrame(topology.buses)

# Save to CSV
CSV.write("buses.csv", buses_df)

# Convert lines to DataFrame
lines_df = DataFrame(topology.lines)
CSV.write("lines.csv", lines_df)
```

### Example 4: Network Visualization

```julia
using Graphs
using GraphPlot

# Create graph from topology
g = Graph()
bus_map = Dict{Int, Int}()

# Add vertices (buses)
for bus in topology.buses
    bus_map[bus.bus_number] = add_vertex!(g)
end

# Add edges (lines)
for line in topology.lines
    v1 = bus_map[line.from_bus]
    v2 = bus_map[line.to_bus]
    add_edge!(g, v1, v2)
end

# Plot graph (simplified)
# For full visualization, see examples/network_visualization.jl
```

## Limitations and Considerations

### Subsystem Mapping

- **Area codes required**: PWF files must have area codes for subsystem mapping
- **Default empty**: If no area code, subsystem is empty string ("")
- **ONS-specific**: Mapping is based on Brazilian subsystem structure

### Generation and Load

- **Base case values**: These are initial conditions, not optimized results
- **For optimization results**: Use DESSEM output files (PDO_*.dat)
- **Optional fields**: May be `nothing` for some buses

### Line Capacity

- **From base case**: Represents capacity limits in input data
- **Not binding**: May differ from DESSEM optimization constraints
- **Check actual limits**: Use DESSEM constraint files for operational limits

### Stage-Specific Data

- **Single load level**: Each PWF file represents one load level (LEVE, MEDIA, PESADA)
- **Not time-series**: No temporal variation within file
- **Stage modifications**: Use .afp files (not yet supported)

## Troubleshooting

### Error: "PWF not found"

**Problem**: PWF.jl package not installed

**Solution**:
```julia
using Pkg
Pkg.add("PWF")
```

### Warning: "Bus number not found"

**Problem**: PWF.jl structure doesn't match expected format

**Solution**: Check PWF.jl version and data structure. Report issue if format changed.

### Empty subsystem field

**Problem**: Area code not available in PWF file

**Solution**: This is expected for some PWF files. Subsystem mapping requires area codes.

### Missing buses or lines

**Problem**: Not all data converted from PWF

**Solution**:
- Check PWF.jl data structure: `keys(pwf_data)`
- Verify field names match conversion expectations
- Check for errors in conversion (logged with `@warn`)

## Integration with IDESSEM

### Philosophy Alignment

**IDESSEM approach**:
- Does NOT parse .pwf files
- Only stores filenames from DESSELET.DAT

**DESSEM2Julia approach**:
- ✅ Maintains IDESSEM compatibility (parse DESSELET for filenames)
- ✅ Optional PWF parsing via PWF.jl (when needed)
- ✅ No custom binary parser implementation
- ✅ Leverages specialized library

This gives users the best of both worlds:
1. **Simple workflow**: Parse DESSELET, get filenames (IDESSEM-compatible)
2. **Optional enhancement**: Parse .pwf when needed for network analysis

### When to Use PWF Parsing

✅ **Use PWF parsing when**:
- Visualizing network topology
- Analyzing bus/line connectivity
- Exporting network data to other formats
- Understanding base case network structure
- Teaching/learning Brazilian power system

❌ **Don't use PWF parsing when**:
- You need optimized generation (use PDO files instead)
- You need DESSEM-specific constraints (use constraint files)
- You only need filenames (use DESSELET parser)

## Additional Resources

### Documentation

- **PWF.jl**: https://lampspuc.github.io/PWF.jl/
- **ANAREDE**: See [ANAREDE Files](ANAREDE_FILES.md)
- **Network Topology**: See [Network Topology Parser](../src/parser/network_topology.jl)

### Related Files

- `src/parser/pwf.jl` - PWF parser implementation
- `src/parser/desselet.jl` - DESSELET parser (gets PWF filenames)
- `src/types.jl` - NetworkBus, NetworkLine, NetworkTopology types
- `test/pwf_tests.jl` - Comprehensive test suite

### Examples

- `examples/network_plants_by_subsystem.jl` - Network analysis example
- `examples/visualize_network.jl` - Network visualization (if available)

## Changelog

### Version 0.1.0 (Current)

**Added**:
- PWF.jl integration
- `parse_pwf()` function
- `parse_pwf_to_topology()` function
- Bus and branch conversion functions
- Subsystem mapping for Brazilian regions
- Comprehensive test suite
- Documentation and examples

**Dependencies**:
- PWF.jl >= 0.1.0

---

**Last Updated**: 2025-01-04
**Status**: ✅ Production Ready
**Maintainer**: DESSEM2Julia Project
