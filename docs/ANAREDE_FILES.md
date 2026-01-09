# ANAREDE Network Files - Technical Analysis

> **📚 Part of**: [DESSEM2Julia Documentation](INDEX.md) | **📖 Related**: [DESSELET Parser](../src/parser/desselet.jl), [File Formats](file_formats.md)
> **🔗 External**: [PWF.jl Library](https://github.com/LAMPSPUC/PWF.jl) | **📦 Integration**: [PWF Parser](../src/parser/pwf.jl)

## Executive Summary

**Can ANAREDE files be read?** → **Yes! Using PWF.jl library**

- ✅ **Text format (.dat)**: Parsable with proper specification
- ✅ **Binary format (.pwf, .afp)**: **Fully supported via PWF.jl** ⭐ **NEW**
- ❌ **IDESSEM approach**: Does NOT parse ANAREDE files
- ✅ **DESSEM2Julia approach**: Leverages PWF.jl for .pwf files

**🎉 NEW**: PWF.jl integration provides complete .pwf file support!
- See [PWF Integration](#pwf-jl-integration) section below

---

## What are ANAREDE Files?

**ANAREDE** (Análise de Redes Elétricas) is CEPEL's electrical power flow analysis program used for Brazilian power system studies.

### File Types in DESSEM Context

| Extension | Type | Purpose | DESSEM Usage |
|-----------|------|---------|--------------|
| `.pwf` | Binary | Base case network | Power flow optimization |
| `.afp` | Binary | Pattern/modification file | Stage-specific modifications |
| `.dat` | Text | Network data (older format) | Human-readable alternative |

### Files Referenced by DESSELET.DAT

```
(Arquivos de caso base)
1    leve          leve.pwf         # Light load base case
2    media         media.pwf        # Medium load base case  
3    pesada        pesada.pwf       # Heavy load base case
99999

(Alteracoes dos casos base)
01 Estagio01    20251011  0  0  0.5      1 pat01.afp
02 Estagio02    20251011  0 30  0.5      1 pat02.afp
...
```

---

## ANAREDE File Format Structure

### Text Format (.dat) - Readable

ANAREDE text files contain multiple data blocks:

#### DBAR Block - Bus Data
```
DBAR
(Bus data: number, name, voltage, generation, load, etc.)
1001 FURNAS_500   500.0 2 1.020   0.0  1200.0   150.0  0.0  0.0
1002 ITUMBIARA    500.0 2 1.015   0.0   950.0   120.0  0.0  0.0
...
99999
```

#### DLIN Block - Line Data
```
DLIN
(Line data: from_bus, to_bus, circuit, R, X, B, limits)
1001 1002 1 1 0.00120 0.01500 0.250  1500.0  1500.0
1002 1003 1 1 0.00095 0.01200 0.200  1200.0  1200.0
...
99999
```

#### DGLT Block - Generation Limits
```
DGLT
(Bus, PMin, PMax, QMin, QMax)
1001    0.0  1200.0  -500.0   800.0
1002    0.0   950.0  -400.0   600.0
...
99999
```

### Binary Format (.pwf, .afp) - Complex

- **Proprietary CEPEL format**
- **Not publicly documented**
- **Binary structure** with:
  - Header with metadata
  - Multiple data sections (buses, lines, transformers, etc.)
  - Compressed/optimized storage
  - Version-specific changes

---

## Can These Files Be Parsed?

### ✅ Text Format (.dat) - YES, Straightforward

**Feasibility**: High  
**Complexity**: Medium  
**Value**: Limited (older format, rarely used)

**Implementation approach**:
```julia
# Pseudo-code for ANAREDE .dat parser
function parse_anarede_dat(filepath)
    buses = Bus[]
    lines = Line[]
    current_block = :none
    
    for line in eachline(filepath)
        if startswith(line, "DBAR")
            current_block = :buses
        elseif startswith(line, "DLIN")
            current_block = :lines
        elseif startswith(line, "99999")
            current_block = :none
        elseif current_block == :buses
            push!(buses, parse_bus_record(line))
        elseif current_block == :lines
            push!(lines, parse_line_record(line))
        end
    end
    
    return NetworkData(buses, lines)
end
```

### ⚠️ Binary Format (.pwf, .afp) - POSSIBLE BUT DIFFICULT

**Feasibility**: Medium  
**Complexity**: Very High  
**Value**: Low (requires ANAREDE license anyway)

**Challenges**:
1. **No public specification** - CEPEL proprietary format
2. **Version differences** - Format changes across ANAREDE versions
3. **Binary structure** - Requires reverse engineering
4. **Endianness/compression** - Platform-specific encodings
5. **Legal concerns** - Format may be protected IP

**What would be needed**:
- Reverse engineering binary structure
- Handling multiple ANAREDE versions
- Complex binary parsing logic
- Validation against ANAREDE output

---

## How IDESSEM Handles This

### IDESSEM's Approach: **Index Only**

IDESSEM (the authoritative DESSEM parser) **does NOT parse ANAREDE files**:

```python
# idessem/dessem/desselet.py
class Desselet(SectionFile):
    """
    Armazena os dados para a rede elétrica nos estágios do DESSEM.
    
    Esta classe lida com informações de entrada fornecidas ao DESSEM e
    que podem ser modificadas através do arquivo `desselet.dat`.
    """
    
    # Only parses the INDEX file (desselet.dat)
    # Returns filenames as strings, not parsed network data
    SECTIONS = [BlocoCasosBase, BlocoCasosModificacao]
```

**What IDESSEM extracts**:
- Base case ID and filename: `(1, "leve", "leve.pwf")`
- Stage modifications: `(1, "Estagio01", datetime, duration, 1, "pat01.afp")`

**What IDESSEM does NOT do**:
- ❌ Parse `.pwf` binary files
- ❌ Parse `.afp` modification files
- ❌ Extract bus/line data
- ❌ Read network topology

### Why IDESSEM Skips ANAREDE Parsing

1. **DESSEM solver handles it**: DESSEM links to ANAREDE libraries internally
2. **Complexity vs. value**: Binary parsing effort not justified
3. **Not needed for workflow**: Users work with DESSEM input/output, not raw network data
4. **Licensing**: ANAREDE format may be proprietary

---

## ⭐ PWF.jl Integration

### Solution: Use Specialized Library

Instead of implementing a custom ANAREDE parser, **DESSEM2Julia now integrates the PWF.jl library**!

**What is PWF.jl?**
- **Developer**: LAMPS research group at PUC-Rio (Brazil)
- **Repository**: https://github.com/LAMPSPUC/PWF.jl
- **Documentation**: https://lampspuc.github.io/PWF.jl/
- **Purpose**: Read ANAREDE power flow files (.pwf) in Julia
- **Maintained**: Active development by domain experts

### Benefits of PWF.jl Integration

✅ **No custom binary parsing** - PWF.jl handles complex ANAREDE format
✅ **Well-tested library** - Battle-tested in production environments
✅ **Domain expertise** - Maintained by Brazilian power system experts
✅ **Regular updates** - Handles format changes automatically
✅ **Clean integration** - Converts to DESSEM2Julia types seamlessly

### Usage

#### Basic PWF Parsing

```julia
using DESSEM2Julia

# Parse a .pwf file (returns PWF.jl native structure)
pwf_data = parse_pwf("leve.pwf")

# Access bus data from PWF
buses = pwf_data["buses"]
```

#### Convert to DESSEM2Julia Types

```julia
# Parse and convert to NetworkTopology
topology = parse_pwf_to_topology("leve.pwf")

# Access buses (NetworkBus type)
println("Number of buses: \$(length(topology.buses))")

# Access lines (NetworkLine type)
println("Number of lines: \$(length(topology.lines))")

# Filter by subsystem
se_buses = filter(b -> b.subsystem == "SE", topology.buses)
```

#### Integration with DESSELET

```julia
# Parse DESSELET to get PWF filenames
desselet_data = parse_desselet("desselet.dat")

# For each base case, parse the PWF file
for base_case in desselet_data.base_cases
    println("Processing \$(base_case.label): \$(base_case.filename)")

    topology = parse_pwf_to_topology(base_case.filename)

    # Analyze network topology
    println("  Buses: \$(length(topology.buses))")
    println("  Lines: \$(length(topology.lines))")
end
```

### Implementation Details

**File**: `src/parser/pwf.jl`

**Functions**:
- `parse_pwf(filepath)`: Raw PWF.jl parsing (returns Dict)
- `parse_pwf_to_topology(filepath)`: Convert to NetworkTopology
- `convert_pwfbus_to_networkbus(pwf_bus)`: Bus data conversion
- `convert_pwfbranch_to_networkline(pwf_branch)`: Line data conversion

**Type Conversions**:

| PWF.jl Field | DESSEM2Julia Type | Notes |
|--------------|-------------------|-------|
| Bus code/number | NetworkBus.bus_number | Required |
| Bus name | NetworkBus.name | Optional |
| Base voltage | NetworkBus.voltage_kv | kV |
| Area code | NetworkBus.subsystem | Mapped to SE/S/NE/N |
| Generation (pg) | NetworkBus.generation_mw | MW |
| Load (pl) | NetworkBus.load_mw | MW |
| From bus | NetworkLine.from_bus | Required |
| To bus | NetworkLine.to_bus | Required |
| Circuit | NetworkLine.circuit | Integer |
| Rating | NetworkLine.capacity_mw | MW |

**Subsystem Mapping**:
```julia
# ANAREDE area codes → Brazilian subsystems
Area 1, 2, 3 → "SE" (Southeast)
Area 4       → "S"  (South)
Area 5       → "NE" (Northeast)
Area 6       → "N"  (North)
```

### Installation

```julia
using Pkg
Pkg.add("PWF")
```

**Added to Project.toml**:
```toml
[deps]
PWF = "c484c51a-cb0d-4fb0-83c9-ce91382e7b63"
```

### Parser Registration

PWF files are now registered in the parser registry:

```julia
# Automatic registration in __init__()
register_parser!("LEVE.PWF", parse_pwf)
register_parser!("MEDIA.PWF", parse_pwf)
register_parser!("PESADA.PWF", parse_pwf)
register_parser!(".pwf", parse_pwf)  # Generic
```

### Testing

**File**: `test/pwf_tests.jl`

**Test Coverage**:
- ✅ Unit tests for bus conversion
- ✅ Unit tests for branch/line conversion
- ✅ Subsystem mapping (all 4 regions)
- ✅ Error handling
- ✅ Metadata preservation
- ✅ Mock PWF data integration

**Run tests**:
```julia
julia --project=. test/pwf_tests.jl
```

### Alignment with IDESSEM Philosophy

**IDESSEM**: Does NOT parse .pwf files (stores filenames only)

**DESSEM2Julia**: Maintains this philosophy while providing optional access:
- ✅ Default workflow: Parse DESSELET, get filenames
- ✅ Optional enhancement: Parse .pwf when needed via PWF.jl
- ✅ No custom binary parser implementation
- ✅ Leverages specialized, maintained library

This gives users the **best of both worlds**:
1. Simple workflow (IDESSEM-compatible)
2. Optional deep network analysis (when needed)
3. No maintenance burden (PWF.jl team handles format changes)

---

## DESSEM2Julia Recommendation

### ✅ Enhanced Approach with PWF.jl

Your `desselet.jl` parser follows IDESSEM's strategy **AND** provides optional PWF parsing:

```julia
# src/parser/desselet.jl
function parse_desselet(filepath::AbstractString)::DesseletData
    base_cases = DesseletBaseCase[]
    patamares = DesseletPatamar[]

    # Parse desselet.dat index file
    # Extract filenames as metadata
    # DO NOT automatically parse .pwf/.afp files

    return DesseletData(
        base_cases=base_cases,
        patamares=patamares,
        metadata=Dict("source" => filepath)
    )
end

# Optional: Parse PWF files when needed
topology = parse_pwf_to_topology("leve.pwf")
```

**This is the right approach because**:
1. ✅ Matches IDESSEM reference implementation
2. ✅ Provides necessary metadata for DESSEM workflow
3. ✅ **Optional** PWF parsing via specialized library (no custom parser!)
4. ✅ Maintains compatibility with DESSEM solver
5. ✅ Focuses on DESSEM-specific data, not ANAREDE internals
6. ✅ **NEW**: Leverages PWF.jl for network analysis when needed

---

## When Would ANAREDE Parsing Be Needed?

### Use Cases for ANAREDE Parsing

| Use Case | Value | Complexity | Recommendation |
|----------|-------|------------|----------------|
| **Visualize network topology** | Medium | Low | ✅ **Use PWF.jl integration** |
| **Extract bus/line data** | Medium | Low | ✅ **Use parse_pwf_to_topology()** |
| **Analyze power flow** | Medium | Low | ✅ **Use PWF.jl** |
| **Convert to other formats** | Medium | Low | ✅ **Use PWF.jl + export** |
| **DESSEM workflow** | **Optional** | Low | ✅ **Available when needed** |

### Solution: Use PWF.jl Integration ⭐

**Instead of** parsing ANAREDE files directly:

1. ✅ **Use PWF.jl integration** (recommended):
   ```julia
   # Parse PWF file
   topology = parse_pwf_to_topology("leve.pwf")

   # Export to other formats
   using DataFrames
   buses_df = DataFrame(topology.buses)
   lines_df = DataFrame(topology.lines)
   ```

2. ✅ **Use DESSEM output files**:
   - DESSEM produces `PDO_*` files with network results
   - Parse post-optimization output (already structured)

3. ✅ **Use PWF.jl for visualization**:
   - Convert to NetworkTopology
   - Use DESSEM2Julia's built-in graph visualization
   - Export to GraphPlot, NetworkX, etc.

---

## Technical Implementation Notes

### If You Must Parse ANAREDE Files

For academic/research purposes, here's the approach:

#### Text Format (.dat) Parser

```julia
module AnareDatParser

struct Bus
    number::Int
    name::String
    voltage_kv::Float64
    bus_type::Int  # 0=PQ, 1=PV, 2=Reference
    voltage_pu::Float64
    angle_deg::Float64
    generation_mw::Float64
    load_mw::Float64
end

struct Line
    from_bus::Int
    to_bus::Int
    circuit::Int
    status::Int  # 0=out, 1=in service
    resistance_pu::Float64
    reactance_pu::Float64
    susceptance_pu::Float64
    flow_limit_mva::Float64
end

function parse_anarede_dat(filepath)
    # Implementation similar to ENTDADOS parser
    # Multiple block types with "99999" terminators
end

end
```

#### Binary Format (.pwf) - NOT RECOMMENDED

```julia
# This would require:
# 1. Binary file header parsing
# 2. Section identification
# 3. Version detection
# 4. Endianness handling
# 5. Decompression (if used)
# 6. Complex struct mapping

# Example structure (SPECULATIVE - format not public):
struct PWFHeader
    version::UInt32
    num_buses::UInt32
    num_lines::UInt32
    timestamp::UInt64
    # ... many unknown fields
end

# DON'T DO THIS unless absolutely necessary
```

---

## Conclusion

### Summary Table

| Aspect | Status | Recommendation |
|--------|--------|----------------|
| **Text ANAREDE (.dat)** | Parsable | Only if specific need exists |
| **Binary ANAREDE (.pwf/.afp)** | Very difficult | Avoid - use alternatives |
| **DESSELET.DAT index** | ✅ **Implemented** | **Keep current approach** |
| **IDESSEM approach** | Index only | **Follow this pattern** |
| **DESSEM2Julia approach** | ✅ **Correct** | **No changes needed** |

### Final Recommendations

1. ✅ **Keep current `desselet.jl` implementation**
   - Parses index file only
   - Stores filenames as metadata
   - Matches IDESSEM reference

2. ❌ **Do NOT implement ANAREDE binary parsing**
   - Very high complexity
   - Low value for DESSEM workflow
   - Better alternatives exist

3. ✅ **If network data needed**
   - Use DESSEM output files (PDO_* series)
   - Use ANAREDE exports/reports
   - Use visualization tools

4. ✅ **Document this decision**
   - Clear in code comments
   - Note in project documentation
   - Reference this analysis

---

## References

### IDESSEM Implementation
- `idessem/dessem/desselet.py` - Index file parser only
- `idessem/dessem/modelos/desselet.py` - Block definitions

### DESSEM Documentation
- DESSEM User Manual § 11 - Electrical Network Files
- DESSELET.XXX format specification

### ANAREDE Resources
- CEPEL ANAREDE official documentation
- ONS network data standards
- Brazilian power system topology resources

### Related DESSEM2Julia Files
- `src/parser/desselet.jl` - Current implementation (correct!)
- `src/types.jl` - DesseletData types
- `test/desselet_tests.jl` - Parser tests

---

**Document Status**: Comprehensive analysis of ANAREDE file parsing feasibility  
**Recommendation**: Maintain current approach (index only)  
**Last Updated**: October 21, 2025 - Session 16
