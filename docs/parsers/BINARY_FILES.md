# Binary File Formats in DESSEM

**Date:** 2025-10-12  
**Based on:** IDESEM Python library analysis

## Overview

Modern DESSEM versions (used by ONS/CCEE) use **binary format** for registry files to improve performance. The IDESEM project (https://github.com/rjmalves/idessem) successfully parses these files using Python's NumPy library.

## Files Using Binary Format

| File | Format | Record Size | Status |
|------|--------|-------------|--------|
| `HIDR.DAT` | Binary | 792 bytes/plant | ⏳ Not implemented |
| `TERM.DAT` | Text | Variable | ✅ Implemented |
| `ENTDADOS.XXX` | Text | Variable | ✅ Implemented |
| `OPERUH.XXX` | Text | Variable | ✅ Implemented |

**Note:** Only `HIDR.DAT` uses binary format in current DESSEM versions. Other files remain text-based.

## HIDR.DAT Binary Structure

### Record Layout

**Total Size:** 792 bytes per hydroelectric plant

**Data Types Used:**
- `Int32` (4 bytes) - Most integers
- `Int64` (8 bytes) - Large integers (BDH station code)
- `Float32` (4 bytes) - Most floating-point values
- `String` (fixed-length) - Plant names, dates, observations

### Complete Field Map

```
Offset | Size | Type    | Field Name                    | Description
-------|------|---------|-------------------------------|---------------------------
     0 |   12 | String  | nome                          | Plant name (space-padded)
    12 |    4 | Int32   | posto                         | Station code
    16 |    8 | Int64   | posto_bdh                     | BDH station code
    24 |    4 | Int32   | subsistema                    | Subsystem number
    28 |    4 | Int32   | empresa                       | Company code
    32 |    4 | Int32   | jusante                       | Downstream plant
    36 |    4 | Int32   | desvio                        | Diversion plant
    40 |    4 | Float32 | volume_minimo                 | Minimum volume (hm³)
    44 |    4 | Float32 | volume_maximo                 | Maximum volume (hm³)
    48 |    4 | Float32 | volume_vertedouro             | Spillway volume (hm³)
    52 |    4 | Float32 | volume_desvio                 | Diversion volume (hm³)
    56 |    4 | Float32 | cota_minima                   | Minimum elevation (m)
    60 |    4 | Float32 | cota_maxima                   | Maximum elevation (m)
    64 |   20 | Float32[5] | polinomio_volume_cota      | Vol-Elev polynomial (5 coeffs)
    84 |   20 | Float32[5] | polinomio_cota_area        | Elev-Area polynomial (5 coeffs)
   104 |   48 | Int32[12] | evaporacao                  | Evap coefficients (Jan-Dec)
   152 |    4 | Int32   | numero_conjuntos_maquinas     | Number of machine sets
   156 |   20 | Int32[5]   | numero_maquinas_conjunto   | Machines per set
   176 |   20 | Float32[5] | potef_conjunto             | Effective power per set (MW)
   196 |  300 | bytes   | (ignored)                     | Reserved/unused fields
   496 |   20 | Float32[5] | hef_conjunto               | Nominal head per set (m)
   516 |   20 | Int32[5]   | qef_conjunto               | Nominal flow per set (m³/s)
   536 |    4 | Float32 | produtibilidade_especifica    | Specific productivity
   540 |    4 | Float32 | perdas                        | Losses
   544 |    4 | Int32   | numero_polinomios_jusante     | Num tailrace polynomials
   548 |  120 | Float32[30] | polinomios_jusante        | 6 sets × 5 coeffs
   668 |   24 | Float32[6] | polinomios_jusante_ref     | Reference polynomial
   692 |    4 | Float32 | canal_fuga_medio              | Average tailrace canal (m)
   696 |    4 | Int32   | influencia_vertimento         | Spillage influence
   700 |    4 | Float32 | fator_carga_maximo            | Maximum load factor
   704 |    4 | Float32 | fator_carga_minimo            | Minimum load factor
   708 |    4 | Int32   | vazao_minima_historica        | Historical minimum flow
   712 |    4 | Int32   | numero_unidades_base          | Number of base units
   716 |    4 | Int32   | tipo_turbina                  | Turbine type
   720 |    4 | Int32   | representacao_conjunto        | Set representation
   724 |    4 | Float32 | teif                          | Forced outage rate
   728 |    4 | Float32 | ip                            | Programmed outage rate
   732 |    4 | Int32   | tipo_perda                    | Loss type
   736 |   12 | String  | data_referencia               | Reference date
   748 |   39 | String  | observacao                    | Observation
   787 |    4 | Float32 | volume_referencia             | Reference volume
   791 |    1 | String  | tipo_regulacao                | Regulation type
-------|------|---------|-------------------------------|---------------------------
TOTAL: 792 bytes
```

## How IDESEM Reads Binary Files

### Python Implementation (cfinterface)

IDESEM uses the `cfinterface` library which provides:

1. **Field Definitions** - Specify field type, size, and position
2. **Binary Repository** - Reads fields using NumPy's `frombuffer()`
3. **Automatic Type Conversion** - Maps field sizes to NumPy dtypes

**Example from IDESEM source:**

```python
from cfinterface.components.line import Line
from cfinterface.components.integerfield import IntegerField
from cfinterface.components.floatfield import FloatField

class RegistroUHEHidr(Register):
    LINE = Line(
        [
            LiteralField(size=12, starting_position=0),    # Plant name
            IntegerField(size=4, starting_position=12),    # Station code (Int32)
            IntegerField(size=8, starting_position=16),    # BDH code (Int64)
            IntegerField(size=4, starting_position=24),    # Subsystem (Int32)
            FloatField(size=4, starting_position=40),      # Min volume (Float32)
            FloatField(size=4, starting_position=44),      # Max volume (Float32)
            # ... 100+ more fields
        ],
        storage="BINARY",  # ← Tells framework to use binary reading
    )
```

**Binary Reading Logic:**

```python
# FloatField binary read (cfinterface/components/floatfield.py)
def _binary_read(self, line: bytes) -> float:
    return float(
        np.frombuffer(
            line[self._starting_position : self._ending_position],
            dtype=np.float32,  # Determined by field size
            count=1,
        )[0]
    )

# IntegerField binary read (cfinterface/components/integerfield.py)
def _binary_read(self, line: bytes) -> int:
    return int(
        np.frombuffer(
            line[self._starting_position : self._ending_position],
            dtype=np.int32,  # Determined by field size
            count=1,
        )[0]
    )
```

**Type Mapping (Size → NumPy dtype):**

| Field Size | Integer Type | Float Type |
|------------|--------------|------------|
| 2 bytes | `np.int16` | `np.float16` |
| 4 bytes | `np.int32` | `np.float32` |
| 8 bytes | `np.int64` | `np.float64` |

## Julia Implementation Strategies

### Strategy 1: Struct Mapping (Recommended)

**Define Julia struct matching binary layout:**

```julia
# Must use primitive types with known sizes
struct HIDRRecord
    # Strings as byte arrays
    nome::NTuple{12, UInt8}              # 12 bytes
    
    # Integers (4 bytes = Int32)
    posto::Int32                          # 4 bytes
    posto_bdh::Int64                      # 8 bytes (special case!)
    subsistema::Int32                     # 4 bytes
    empresa::Int32                        # 4 bytes
    jusante::Int32                        # 4 bytes
    desvio::Int32                         # 4 bytes
    
    # Floats (4 bytes = Float32)
    volume_minimo::Float32                # 4 bytes
    volume_maximo::Float32                # 4 bytes
    volume_vertedouro::Float32            # 4 bytes
    volume_desvio::Float32                # 4 bytes
    cota_minima::Float32                  # 4 bytes
    cota_maxima::Float32                  # 4 bytes
    
    # Arrays (tuples for fixed size)
    polinomio_vc::NTuple{5, Float32}      # 20 bytes
    polinomio_ca::NTuple{5, Float32}      # 20 bytes
    evaporacao::NTuple{12, Int32}         # 48 bytes
    
    num_conjuntos::Int32                  # 4 bytes
    num_maquinas::NTuple{5, Int32}        # 20 bytes
    potef::NTuple{5, Float32}             # 20 bytes
    
    # Ignored block (300 bytes)
    _ignored::NTuple{300, UInt8}          # 300 bytes
    
    # Continue for all fields...
    # Total must be exactly 792 bytes
end

# Verify struct size
@assert sizeof(HIDRRecord) == 792 "Struct size mismatch!"

# Read binary file
function parse_hidr_binary(filepath::String)
    plants = HIDRRecord[]
    
    open(filepath, "r") do io
        while !eof(io)
            # Read exactly 792 bytes as struct
            record = read(io, HIDRRecord)
            push!(plants, record)
        end
    end
    
    return plants
end

# Convert to friendly struct
function to_plant_data(record::HIDRRecord)
    # Convert name from bytes to string
    name = String(collect(record.nome))
    name = strip(replace(name, '\0' => ' '))
    
    return (
        nome = name,
        posto = record.posto,
        subsistema = record.subsistema,
        volume_minimo = record.volume_minimo,
        volume_maximo = record.volume_maximo,
        # ... all other fields
    )
end
```

### Strategy 2: Manual Field Reading

**Read fields individually with type specifications:**

```julia
function read_hidr_record(io::IO)
    # Read fields one by one
    nome_bytes = read(io, 12)
    nome = String(nome_bytes) |> strip
    
    posto = read(io, Int32)           # Next 4 bytes as Int32
    posto_bdh = read(io, Int64)       # Next 8 bytes as Int64
    subsistema = read(io, Int32)      # Next 4 bytes as Int32
    empresa = read(io, Int32)
    jusante = read(io, Int32)
    desvio = read(io, Int32)
    
    volume_minimo = read(io, Float32)    # Next 4 bytes as Float32
    volume_maximo = read(io, Float32)
    volume_vertedouro = read(io, Float32)
    volume_desvio = read(io, Float32)
    cota_minima = read(io, Float32)
    cota_maxima = read(io, Float32)
    
    # Read arrays
    polinomio_vc = [read(io, Float32) for _ in 1:5]
    polinomio_ca = [read(io, Float32) for _ in 1:5]
    evaporacao = [read(io, Int32) for _ in 1:12]
    
    # ... continue for all fields
    
    return (
        nome = nome,
        posto = posto,
        subsistema = subsistema,
        volume_minimo = volume_minimo,
        # ...
    )
end

function parse_hidr_binary(filepath::String)
    plants = []
    open(filepath, "r") do io
        while !eof(io)
            plant = read_hidr_record(io)
            push!(plants, plant)
        end
    end
    return plants
end
```

### Strategy 3: Reinterpret Array (Advanced)

**Read entire file as byte array, then reinterpret:**

```julia
function parse_hidr_binary_fast(filepath::String)
    # Read entire file
    data = read(filepath)
    
    # Number of records
    num_plants = length(data) ÷ 792
    @assert length(data) == num_plants * 792 "Invalid file size"
    
    plants = []
    for i in 0:(num_plants-1)
        offset = i * 792
        
        # Extract record bytes
        record_bytes = data[(offset+1):(offset+792)]
        
        # Reinterpret as struct
        record = reinterpret(HIDRRecord, record_bytes)[1]
        
        push!(plants, record)
    end
    
    return plants
end
```

## Important Implementation Notes

### 1. Byte Order (Endianness)

- DESSEM binary files use **little-endian** format (standard for x86/x64)
- Julia's `read()` automatically handles native byte order
- If cross-platform compatibility needed, use:
  - `ltoh(x)` - little-endian to host byte order
  - `htol(x)` - host to little-endian byte order

### 2. String Handling

```julia
# Strings are fixed-length, space-padded
nome_bytes = read(io, 12)  # Read 12 bytes
nome = String(nome_bytes)  # Convert to String

# Clean up padding
nome = strip(nome)                    # Remove leading/trailing spaces
nome = replace(nome, '\0' => ' ')     # Replace null bytes with spaces
nome = strip(nome)                    # Strip again
```

### 3. Struct Alignment

**Critical:** Julia structs must match C memory layout EXACTLY!

```julia
# Check struct size
@assert sizeof(HIDRRecord) == 792 "Size mismatch - check field types!"

# If size doesn't match, check for:
# - Wrong field types (Int64 instead of Int32, etc.)
# - Missing fields
# - Padding bytes (Julia may add alignment padding)
```

**Forcing C layout (if needed):**

```julia
# Use Base.@cstruct (experimental) or manual padding
struct HIDRRecord
    # ... fields ...
    _padding1::UInt8  # Explicit padding if needed
end
```

### 4. Validation After Reading

```julia
function validate_hidr_record(record)
    # Check file size
    expected_size = 792 * num_plants
    @assert filesize(path) == expected_size "File size mismatch"
    
    # Check plant name is readable ASCII
    @assert all(c -> c in ' ':'~', record.nome) "Invalid plant name"
    
    # Check reasonable values
    @assert record.volume_maximo > record.volume_minimo "Invalid volumes"
    @assert record.subsistema > 0 "Invalid subsystem"
    
    # Check numeric ranges
    @assert isfinite(record.volume_minimo) "Non-finite value"
end
```

## Testing Strategy

### 1. Start with Known Data

```julia
# Test with sample file
hidr_path = "docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/hidr.dat"

# Read first record
open(hidr_path, "r") do io
    record = read(io, HIDRRecord)
    
    # Expected from hex dump: "CAMARGOS    "
    name = String(collect(record.nome)) |> strip
    @test name == "CAMARGOS"
    
    # Print all fields for manual verification
    println("Plant: $name")
    println("  Subsystem: ", record.subsistema)
    println("  Min Volume: ", record.volume_minimo)
    println("  Max Volume: ", record.volume_maximo)
end
```

### 2. Compare with IDESEM Output

```julia
# Read with our parser
our_data = parse_hidr_binary("hidr.dat")

# Read with IDESEM (Python)
# Save IDESEM output to CSV for comparison
# Compare values field by field

@testset "HIDR Binary Parser" begin
    # Check number of plants
    @test length(our_data) == 98  # Known from sample
    
    # Check first plant (CAMARGOS from hex dump)
    @test our_data[1].nome == "CAMARGOS"
    
    # Check second plant
    # ... (use IDESEM as reference)
end
```

### 3. Round-Trip Test

```julia
# Read → Write → Read → Compare
function test_roundtrip()
    # Read original
    data1 = parse_hidr_binary("hidr.dat")
    
    # Write to new file
    write_hidr_binary("hidr_test.dat", data1)
    
    # Read again
    data2 = parse_hidr_binary("hidr_test.dat")
    
    # Should be identical
    @test data1 == data2
end
```

## Current Status

- ❌ **Not Implemented** - Deferred to focus on text-based files first
- ✅ **Text parsers complete**: TERMDAT, ENTDADOS, OPERUH
- ⏳ **Next priority**: OPERUT, DADVAZ, DEFLANT (all text format)
- 🔮 **Future work**: Implement HIDR binary parser when needed

## Recommendations

1. **Prioritize text files first** ✅ **DONE**
   - TERMDAT.DAT ✅
   - ENTDADOS.XXX ✅
   - OPERUH.XXX ✅
   - OPERUT.XXX ⏳
   - DADVAZ.XXX ⏳

2. **Implement HIDR binary parser when:**
   - All text files are complete
   - User specifically needs hydroelectric plant data
   - Testing against ONS/CCEE cases requires it

3. **Use IDESEM as authoritative reference:**
   - Field positions verified against production data
   - Field types proven to work
   - Python implementation is mature and tested

4. **Alternative approaches:**
   - Request text-format HIDR.DAT from data provider
   - Use IDESEM to convert binary → CSV → read CSV
   - Check if older DESSEM versions output text format

## References

- **IDESEM Project**: https://github.com/rjmalves/idessem
  - Binary parser: `idessem/dessem/modelos/hidr.py`
  - Complete field list with types and positions

- **cfinterface Library**: https://github.com/rjmalves/cfinterface
  - Binary reading framework: `cfinterface/adapters/components/line/repository.py`
  - Field types: `cfinterface/components/floatfield.py`, `integerfield.py`

- **This Project**:
  - Format notes: `docs/FORMAT_NOTES.md`
  - Sample validation: `docs/Sample/SAMPLE_VALIDATION.md`
  - IDESEM comparison: `docs/idessem_comparison.md`

## Summary

**Key Takeaway:** IDESEM successfully reads binary HIDR.DAT using:
1. Fixed record size (792 bytes per plant)
2. NumPy's `frombuffer()` for type-safe binary reading
3. Size-based type mapping (4 bytes → Int32/Float32, 8 bytes → Int64/Float64)

**Julia can do the same using:**
1. `read(io, Type)` for direct binary reading
2. Structs matching C memory layout
3. Same type sizes (Int32, Float32, Int64, Float64)

**Implementation is straightforward** - just needs the complete field list from IDESEM source (which we now have documented above).
