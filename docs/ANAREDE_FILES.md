# ANAREDE Network Files - Technical Analysis

> **📚 Part of**: [DESSEM2Julia Documentation](INDEX.md) | **📖 Related**: [DESSELET Parser](../src/parser/desselet.jl), [File Formats](file_formats.md)

## Executive Summary

**Can ANAREDE files be read?** → **Yes, but with significant limitations**

- ✅ **Text format (.dat)**: Parsable with proper specification
- ⚠️ **Binary format (.pwf, .afp)**: Possible but complex
- ❌ **IDESSEM approach**: Does NOT parse ANAREDE files
- ✅ **DESSEM2Julia approach**: Follows IDESSEM - only parse index file

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

## DESSEM2Julia Recommendation

### ✅ Current Approach is Correct

Your `desselet.jl` parser follows IDESSEM's strategy:

```julia
# src/parser/desselet.jl
function parse_desselet(filepath::AbstractString)::DesseletData
    base_cases = DesseletBaseCase[]
    patamares = DesseletPatamar[]
    
    # Parse desselet.dat index file
    # Extract filenames as metadata
    # DO NOT parse .pwf/.afp files
    
    return DesseletData(
        base_cases=base_cases,
        patamares=patamares,
        metadata=Dict("source" => filepath)
    )
end
```

**This is the right approach because**:
1. ✅ Matches IDESSEM reference implementation
2. ✅ Provides necessary metadata for DESSEM workflow
3. ✅ Avoids complex binary parsing
4. ✅ Maintains compatibility with DESSEM solver
5. ✅ Focuses on DESSEM-specific data, not ANAREDE internals

---

## When Would ANAREDE Parsing Be Needed?

### Use Cases for ANAREDE Parsing

| Use Case | Value | Complexity | Recommendation |
|----------|-------|------------|----------------|
| **Visualize network topology** | Medium | High | Use ANAREDE GUI or export |
| **Extract bus/line data** | Low | High | Use ANAREDE reports |
| **Analyze power flow** | Low | Very High | Use ANAREDE directly |
| **Convert to other formats** | Medium | High | Use ANAREDE export |
| **DESSEM workflow** | **None** | High | **Not needed** |

### Alternative Solutions

Instead of parsing ANAREDE files directly:

1. **Use ANAREDE exports**:
   - Export network to CSV/text from ANAREDE GUI
   - Parse exported files (simple text format)

2. **Use DESSEM output files**:
   - DESSEM produces `PDO_*` files with network results
   - Parse post-optimization output (already structured)

3. **Query DESSEM directly**:
   - DESSEM has APIs for network data access
   - Use solver output rather than input

4. **Use visualization tools**:
   - ANAREDE has built-in visualization
   - Third-party tools exist for Brazilian power system

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
