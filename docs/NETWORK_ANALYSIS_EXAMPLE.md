# Network Analysis Example - Power Plants by Subsystem

## Overview

This example demonstrates how to analyze the DESSEM electrical network structure by grouping power plants according to their subsystem (major electrical region).

## Example File

**Location**: `examples/network_plants_by_subsystem.jl`

## What It Shows

### 1. **Thermal Power Plants by Subsystem**
- Complete listing of all thermal plants in each electrical region
- Plant capacity, number of units, and plant identifiers
- Sorted by capacity (largest first)

### 2. **Hydro Power Plants by Subsystem**
- Top 10 largest hydro plants per subsystem
- Installed capacity and reservoir storage capacity
- Complete count of all plants per region

### 3. **Network Statistics**
- Total generation capacity per subsystem
- Breakdown of thermal vs. hydro capacity
- Percentage distribution across the Brazilian system

## Sample Output

```
================================================================================
DESSEM Network Analysis: Power Plants by Subsystem
================================================================================

🔌 Network Configuration: Network without losses

⚡ THERMAL POWER PLANTS BY SUBSYSTEM
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Subsystem 1 - Southeast/Center-West (SE/CO)
   Total Plants: 37
   Total Capacity: 12,846.9 MW
   
   Largest: GNA II (1,672.6 MW), ANGRA 2 (1,350 MW), GNA I (1,338.3 MW)
```

## Key Findings from ONS Sample

### System-Wide Totals (October 2025 Case)
- **Thermal**: 23,739.9 MW (47% of system)
- **Hydro**: 26,883.1 MW (53% of system)
- **Total**: 50,623 MW

### By Subsystem

**Southeast/Center-West (SE/CO)** - Largest subsystem
- 37 thermal plants (12,846.9 MW)
- 137 hydro plants (13,656.5 MW)
- Total: 26,503.4 MW (52% of Brazilian system)
- Notable: ITAIPU (1,400 MW), ANGRA 2 (1,350 MW), GNA II (1,672.6 MW)

**South (S)**
- 12 thermal plants (2,180.6 MW)
- 40 hydro plants (4,987.5 MW)
- Total: 7,168 MW (14% of system)
- Notable: G.B. MUNHOZ (419 MW), MACHADINHO (380 MW)

**Northeast (NE)**
- 25 thermal plants (5,034.5 MW)
- 15 hydro plants (4,884.5 MW)
- Total: 9,919 MW (20% of system)
- Notable: P. SERGIPE I (1,593.2 MW), COMP PAF-MOX (1,927.6 MW)

**North (N)**
- 24 thermal plants (3,678 MW)
- 18 hydro plants (3,354.7 MW)
- Total: 7,032.7 MW (14% of system)
- Notable: TUCURUI (762.5 MW), BELO MONTE (611.1 MW)

## Understanding the Network Structure

### Subsystems vs. Buses

**Subsystem** (what this example shows):
- High-level electrical regions
- Represents major interconnected areas of Brazil's power grid
- 4-5 subsystems typically (SE/CO, S, NE, N, and sometimes isolated systems)
- Plants within same subsystem are electrically close
- Inter-subsystem power exchange through major transmission lines

**Bus** (detailed network level - in PWF files):
- Individual connection points in the electrical network
- Hundreds of buses per subsystem
- Each plant connects to one or more specific buses
- Requires parsing PWF (PowerWorld) format files
- Detailed for voltage, angle, and power flow analysis

### Network Configuration

The example detects network modeling mode from ENTDADOS time periods:
- **Mode 0**: No network modeling (aggregated by subsystem)
- **Mode 1**: Network without losses (simplified power flow)
- **Mode 2**: Network with losses (full AC power flow)

ONS sample uses **Mode 1** (network without losses).

## Usage

```bash
# Run the example
julia --project=. examples/network_plants_by_subsystem.jl
```

## Data Sources

The example integrates data from three files:

1. **ENTDADOS.DAT**:
   - Subsystem definitions (SIST records)
   - Thermal plant operational data (UT records)
   - Network configuration flags (TM records)

2. **TERMDAT.DAT**:
   - Thermal plant registry (CADUSIT records)
   - Thermal unit details (CADUNIDT records)
   - Number of units per plant

3. **HIDR.DAT** (binary format):
   - Hydro plant registry (792 bytes/plant)
   - Installed capacity, storage capacity
   - Subsystem assignments

## Extending the Example

### For Bus-Level Analysis

To show plants connected to individual buses, you would need to:

1. **Parse PWF files** (`*.pwf` - PowerWorld format):
   - Bus definitions with voltage levels
   - Plant-to-bus connections
   - Transmission line topology

2. **Parse DESSELET** for network case mapping:
   - Maps study periods to PWF files
   - Different network configurations per load level

3. **Create bus-level groupings**:
   ```julia
   # Pseudocode
   buses = parse_pwf("leve.pwf")
   for bus in buses
       plants_at_bus = find_plants_connected_to(bus.number)
       println("Bus $(bus.number): $(length(plants_at_bus)) plants")
   end
   ```

## Technical Notes

### Type Safety
- Uses proper Julia types (CADUSIT, CADUNIDT, CADUSIH)
- Safe handling of optional fields (Union{T, Nothing})
- Validated against ONS production data

### Performance
- Efficient grouping with Dict structures
- Linear scan through plant lists
- Minimal memory allocation

### Data Quality
- Handles plants with zero capacity (offline units)
- Filters invalid hydro records (plant_num ≤ 0)
- Robust to missing optional fields

## Related Examples

- `examples/analyze_relationships.jl` - Cross-file entity relationships
- `examples/hydro_tree_example.jl` - Hydro cascade topology
- `examples/simple_hydro_tree.jl` - Simplified cascade visualization

## Future Enhancements

Potential additions to this example:

1. **Interconnection Analysis**:
   - Show power exchange capacity between subsystems
   - Visualize transmission corridors

2. **Load Distribution**:
   - Parse demand data (DP records)
   - Compare generation vs. demand per subsystem

3. **Time-Varying Analysis**:
   - Show how network configuration changes by load level
   - Different plant availability by period

4. **Bus-Level Details**:
   - Parse PWF files for detailed bus topology
   - Show voltage levels and connection types

## Conclusion

This example provides a high-level view of the Brazilian power system structure, showing how 50+ GW of generation capacity is distributed across 4 major electrical regions. While it groups by subsystem rather than individual buses, it demonstrates the key relationships between plants and the electrical network.

For detailed bus-level analysis, the PWF network files would need to be parsed (future work).
