# FCF Cuts Binary Parser Implementation Guide

> **📚 Part of**: [DESSEM2Julia Documentation](../INDEX.md) | **📖 Related**: [Binary Files](BINARY_FILES.md), [IDESEM Comparison](idessem_comparison.md)

## Overview

This guide documents the implementation of the binary FCF (Future Cost Function) cuts parser for cortdeco.rv2/rv0 files. These files contain Benders cuts from NEWAVE/DECOMP that represent marginal water values for the hydrothermal optimization problem.

## Background

### What are FCF Cuts?

The Future Cost Function (FCF) represents the expected cost of future water usage in the hydrothermal optimization. Benders decomposition produces linear cuts (hyperplanes) that approximate this nonlinear function:

```
α >= RHS + Σ(πᵢ × variableᵢ)
```

Where:
- `α` = future cost
- `RHS` = independent term
- `πᵢ` = coefficient for variable i (water values, inflow coefficients, thermal coefficients)
- `variableᵢ` = decision variables (storage, inflows, thermal generation)

### File Names

- **cortdeco.rv0** / **cortdeco.rv2** - FCF Benders cuts (CORTFCF mnemonic in dessem.arq)
- **mapcut.rv0** / **mapcut.rv2** - Cut mapping header (MAPFCF mnemonic)
- **infofcf.dat** - Text metadata file with travel time plants, GNL subsystems, etc.

The `.rv0`, `.rv2` suffixes indicate revision numbers (Revision 0, Revision 2, etc.).

## Binary Format Specification

### Record Structure

Based on inewave implementation ([source](https://github.com/rjmalves/inewave/blob/main/inewave/newave/modelos/cortes.py)):

```
┌─────────────────────────────────────────────┐
│ Header (16 bytes)                           │
├─────────────────────────────────────────────┤
│ indice_corte (Int32, 4 bytes)              │  ← Linked list pointer
│ iteracao_construcao (Int32, 4 bytes)       │  ← Construction iteration
│ indice_forward (Int32, 4 bytes)            │  ← Forward pass index
│ iteracao_desativacao (Int32, 4 bytes)      │  ← Deactivation iteration (0 = active)
├─────────────────────────────────────────────┤
│ RHS (Float64, 8 bytes)                     │  ← Independent term
├─────────────────────────────────────────────┤
│ Coefficient 1 (Float64, 8 bytes)           │  ← pi_1
│ Coefficient 2 (Float64, 8 bytes)           │  ← pi_2
│ ...                                         │
│ Coefficient N (Float64, 8 bytes)           │  ← pi_N
└─────────────────────────────────────────────┘

Total record size: 16 + 8(N+1) bytes
Standard: 1664 bytes → N = 205 coefficients
```

### Linked List Structure

Cuts are stored in a **backward linked list**:

```
File:  [Cut 1] [Cut 2] [Cut 3] [Cut 4] ... [Cut N]
               ↗       ↗       ↗           ↗
Links:    0    1       2       3    ...   N-1

Reading algorithm:
1. Start at last cut (index N)
2. Read cut.indice_corte → points to previous cut (N-1)
3. Follow chain until indice_corte == 0
4. Reverse list for chronological order
```

### Coefficient Interpretation

The coefficient vector structure depends on the FCF mode:

#### Individualized Mode (UHE codes provided)

```julia
coeficientes[1:N_uhes]                              # pi_varm_uhe (volume marginal values)
coeficientes[N_uhes+1:N_uhes*(P+1)]                # pi_qafl_uhe (inflow coefficients, P lags)
coeficientes[...]                                   # pi_gnl_sbm (GNL thermal by submarket/load/lag)
```

#### Aggregated Mode (REE codes provided)

```julia
coeficientes[1:N_rees]                              # pi_earm_ree (energy stored marginal values)
coeficientes[N_rees+1:N_rees*(P+1)]                # pi_ena_ree (energy inflow, P lags)
coeficientes[...]                                   # pi_gnl_sbm (GNL thermal by submarket/load/lag)
```

## Implementation

### Type System

**File**: `src/models/core_types.jl`

```julia
"""Single FCF cut with header and coefficients"""
Base.@kwdef struct FCFCut
    indice_corte::Int32               # Cut index (1-based, sequential)
    iteracao_construcao::Int32        # Construction iteration
    indice_forward::Int32             # Forward pass index
    iteracao_desativacao::Int32       # Deactivation iteration (0 = active)
    rhs::Float64                      # Independent term
    coeficientes::Vector{Float64}     # Cut coefficients
end

"""Container for all FCF cuts with metadata"""
Base.@kwdef struct FCFCutsData
    cortes::Vector{FCFCut} = FCFCut[]
    tamanho_registro::Int = 1664      # Record size in bytes
    numero_total_cortes::Int = 0      # Total cuts read
    codigos_rees::Vector{Int} = Int[] # REE codes (aggregated mode)
    codigos_uhes::Vector{Int} = Int[] # UHE codes (individualized mode)
    codigos_submercados::Vector{Int} = Int[]
    ordem_maxima_parp::Int = 12       # Max PAR(p) order
    numero_patamares_carga::Int = 3   # Number of load levels
    lag_maximo_gnl::Int = 2           # Max GNL lag
end

"""High-level container in DessemCase"""
Base.@kwdef struct DecompCut
    fcf_cuts::Union{FCFCutsData, Nothing} = nothing
    cut_map_file::Union{String, Nothing} = nothing
    cut_info_file::Union{String, Nothing} = nothing
end
```

### Parser Module

**File**: `src/parser/cortdeco.jl`

```julia
module CortdecoParser

using ..DESSEM2Julia: FCFCut, FCFCutsData

function parse_cortdeco(
    filepath::String;
    tamanho_registro::Int=1664,
    indice_ultimo_corte::Int=1,
    numero_total_cortes::Int=10000,
    codigos_rees::Vector{Int}=Int[],
    codigos_uhes::Vector{Int}=Int[],
    codigos_submercados::Vector{Int}=[1, 2, 3, 4],
    ordem_maxima_parp::Int=12,
    numero_patamares_carga::Int=3,
    lag_maximo_gnl::Int=2,
)
    # Calculate coefficient count from record size
    bytes_header = 16
    numero_coeficientes = (tamanho_registro - bytes_header) ÷ 8
    
    cortes = FCFCut[]
    
    open(filepath, "r") do io
        # Read from last cut, following linked list backward
        indice_proximo = indice_ultimo_corte
        cortes_lidos = 0
        
        while indice_proximo != 0 && cortes_lidos < numero_total_cortes
            # Seek to cut position (0-based indexing in file)
            offset = (indice_proximo - 1) * tamanho_registro
            seek(io, offset)
            
            # Read header (4 × Int32)
            int_values = reinterpret(Int32, read(io, 16))
            indice_corte_anterior = int_values[1]  # Previous cut index
            
            # Read coefficients (N × Float64)
            float_values = reinterpret(Float64, read(io, numero_coeficientes * 8))
            rhs = float_values[1]
            coeficientes = collect(float_values[2:end])
            
            # Create cut
            push!(cortes, FCFCut(...))
            
            # Move to previous cut
            indice_proximo = indice_corte_anterior
            cortes_lidos += 1
        end
    end
    
    # Reverse list (read backward, want chronological order)
    reverse!(cortes)
    
    return FCFCutsData(...)
end

export parse_cortdeco, get_water_value, get_active_cuts, get_cut_statistics

end # module
```

### Helper Functions

#### Water Value Lookup

```julia
"""
Get average water value for a hydro plant across all cuts.

# Arguments
- `cuts::FCFCutsData`: Parsed FCF cuts
- `uhe_code::Int`: Hydro plant code
- `storage::Float64=0.0`: Current storage (unused, for future interpolation)

# Returns
- `Float64`: Average water value in R$/hm³

# Example
```julia
cuts = parse_cortdeco("cortdeco.rv2", codigos_uhes=[1, 2, 4, 6])
wv = get_water_value(cuts, 6)  # Water value for plant 6
```
"""
function get_water_value(cuts::FCFCutsData, uhe_code::Int, storage::Float64=0.0)
    uhe_idx = findfirst(==(uhe_code), cuts.codigos_uhes)
    
    # Water value is at coefficient index uhe_idx
    total_wv = sum(cut.coeficientes[uhe_idx] for cut in cuts.cortes 
                   if uhe_idx <= length(cut.coeficientes))
    
    return total_wv / length(cuts.cortes)
end
```

#### Active Cuts Filter

```julia
"""Filter cuts to only active ones (iteracao_desativacao == 0)"""
function get_active_cuts(cuts::FCFCutsData)
    return filter(c -> c.iteracao_desativacao == 0, cuts.cortes)
end
```

## Usage Examples

### Basic Parsing

```julia
using DESSEM2Julia

# Parse FCF cuts file
cuts = parse_cortdeco("cortdeco.rv2")

println("Loaded $(length(cuts.cortes)) cuts")
println("Record size: $(cuts.tamanho_registro) bytes")

# Show first cut
first_cut = cuts.cortes[1]
println("First cut: RHS=$(first_cut.rhs), iteration=$(first_cut.iteracao_construcao)")
```

### Individualized Mode (Hydro Plants)

```julia
# Parse with specific UHE codes
cuts = parse_cortdeco(
    "cortdeco.rv2",
    codigos_uhes=[1, 2, 4, 6, 7, 8, 9, 10, 11, 12]
)

# Get water value for plant 6
wv = get_water_value(cuts, 6)
println("Water value for plant 6: $wv R\$/hm³")

# Get all water values
for uhe in cuts.codigos_uhes
    wv = get_water_value(cuts, uhe)
    println("Plant $uhe: $wv R\$/hm³")
end
```

### Statistics

```julia
# Get cut statistics
stats = get_cut_statistics(cuts)
println("Total cuts: $(stats["total_cuts"])")
println("Active cuts: $(stats["active_cuts"])")
println("Average RHS: $(stats["avg_rhs"])")

# Filter to active cuts only
active_cuts = get_active_cuts(cuts)
println("Using $(length(active_cuts)) active cuts")
```

### Custom Record Size

```julia
# Non-standard record size (if file format varies)
cuts = parse_cortdeco(
    "custom_cortdeco.dat",
    tamanho_registro=2048,  # Custom size
    indice_ultimo_corte=500,
    codigos_uhes=[1, 2, 3, 4, 5]
)
```

## Integration with DessemCase

Future integration will load FCF cuts automatically:

```julia
# Parse DESSEM case
case = parse_dessem_case("dessem.arq")

# Access FCF cuts
if case.decomp_cuts.fcf_cuts !== nothing
    cuts = case.decomp_cuts.fcf_cuts
    println("$(length(cuts.cortes)) FCF cuts loaded")
    
    # Use cuts for water value calculations
    for plant in case.hydro_system.plants
        wv = get_water_value(cuts, plant.plant_num)
        println("$(plant.plant_name): $wv R\$/hm³")
    end
end
```

## Testing

**File**: `test/cortdeco_tests.jl`

Comprehensive test suite covering:
- ✅ Synthetic binary file parsing with linked list
- ✅ Water value calculation for multiple plants
- ✅ Active/inactive cut filtering
- ✅ Empty file handling
- ✅ Custom record sizes
- ✅ Configuration parameters

**Test Coverage**: 51/51 tests passing ✅

```julia
using Test
using DESSEM2Julia

@testset "Cortdeco Parser" begin
    # Create synthetic test file
    mktempdir() do tmpdir
        test_file = joinpath(tmpdir, "cortdeco.rv2")
        
        # Write binary cuts...
        cuts = parse_cortdeco(test_file, codigos_uhes=[1, 2, 3])
        
        @test length(cuts.cortes) > 0
        @test cuts.tamanho_registro == 1664
        
        # Test water values
        wv = get_water_value(cuts, 1)
        @test isfinite(wv)
    end
end
```

## Reference Implementation

This implementation is based on the **inewave** Python library:

- **Repository**: https://github.com/rjmalves/inewave
- **File**: `inewave/newave/modelos/cortes.py` (SecaoDadosCortes class)
- **Method**: Uses NumPy's `frombuffer()` for binary reading

### Key Differences from inewave

| Aspect | inewave (Python) | DESSEM2Julia (Julia) |
|--------|------------------|---------------------|
| **Indexing** | 0-based (file positions) | 1-based (Julia convention) |
| **Binary reading** | `np.frombuffer()` | `reinterpret(T, read(io, n))` |
| **Data structure** | Pandas DataFrame | Immutable Julia structs |
| **Storage** | NumPy arrays | Julia Vector{Float64} |
| **Coefficient interpretation** | Built into read logic | Separate helper functions |

## Format Notes

### Record Size Variations

Standard NEWAVE/DECOMP format uses **1664 bytes**, but this is configurable:

```
Record size = 16 (header) + 8 × N (coefficients)

Standard: 1664 = 16 + 8 × 206
Custom:   2048 = 16 + 8 × 254
Minimum:    24 = 16 + 8 × 1
```

### Linked List Indexing

**Critical**: File uses 0-based indexing for linked list pointers, but we convert to 1-based for Julia:

```julia
# In file (0-based):
# Cut at position 100 has indice_corte = 99 (points to position 99)

# After parsing (1-based):
# Cut 101 has indice_corte = 101 (sequential index)
```

### Active vs Inactive Cuts

Cuts can be deactivated during NEWAVE iterations:
- `iteracao_desativacao == 0` → Active cut (used in optimization)
- `iteracao_desativacao > 0` → Inactive cut (removed at that iteration)

Use `get_active_cuts()` to filter to active cuts only.

## Troubleshooting

### File Size Mismatch

**Symptom**: Parser reads fewer cuts than expected

**Cause**: Incorrect record size or file truncation

**Solution**: 
```julia
# Calculate expected cuts
file_size = filesize("cortdeco.rv2")
expected_cuts = file_size ÷ 1664
println("Expected $expected_cuts cuts")

# Try different record size
cuts = parse_cortdeco("cortdeco.rv2", tamanho_registro=2048)
```

### Invalid Water Values

**Symptom**: `get_water_value()` returns `0.0` or strange values

**Cause**: Incorrect `codigos_uhes` or coefficient indexing

**Solution**: Verify configuration matches file:
```julia
# Check first cut coefficients
first_cut = cuts.cortes[1]
println("Num coefficients: $(length(first_cut.coeficientes))")
println("First 10 coefficients: $(first_cut.coeficientes[1:10])")
```

### Empty File or No Cuts

**Symptom**: `cuts.cortes` is empty

**Cause**: Invalid file, wrong start index, or file format issue

**Solution**:
```julia
# Check file size
filesize("cortdeco.rv2")  # Should be multiple of record size

# Try starting from cut 1
cuts = parse_cortdeco("cortdeco.rv2", indice_ultimo_corte=1)

# Check for warnings
# Parser emits @warn for invalid files
```

## Future Enhancements

1. **mapcut.rv2 Parser**: Parse cut mapping file (if needed)
2. **Storage Interpolation**: Use storage level in water value calculation
3. **Cut Selection**: Select best cuts based on hyperplane distance
4. **Visualization**: Plot water value functions
5. **Text Output**: Parse `PDO_ECO_FCFCORTES` text output as alternative source

## Related Documentation

- **Binary Format Reference**: [BINARY_FILES.md](BINARY_FILES.md)
- **IDESEM Comparison**: [idessem_comparison.md](idessem_comparison.md)
- **Type System**: [../type_system.md](../type_system.md)
- **DESSEM Specs**: [../dessem-complete-specs.md](../dessem-complete-specs.md)

## References

1. **inewave**: https://github.com/rjmalves/inewave
2. **idessem**: https://github.com/rjmalves/idessem
3. **CEPEL DESSEM Manual**: (proprietary documentation)
4. **Benders Decomposition**: Classic algorithm for multistage stochastic programming
