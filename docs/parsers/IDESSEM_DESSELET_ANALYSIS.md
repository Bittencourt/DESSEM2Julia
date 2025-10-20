# IDESSEM desselet.dat Analysis

## Overview

This document analyzes how the IDESSEM reference implementation handles `desselet.dat` and the Anarede network files (PWF/AFP).

**Source**: https://github.com/rjmalves/idessem

## Key Findings

### 1. IDESSEM Parses desselet.dat, NOT PWF/AFP Files

**Important**: IDESSEM **only parses** `desselet.dat`. It **does not parse** PWF or AFP files (Anarede power flow format).

### 2. desselet.dat Parser Location

- **File**: `idessem/dessem/desselet.py`
- **Model**: `idessem/dessem/modelos/desselet.py`
- **Documentation**: `docs/source/referencia/dessem/arquivos/desselet.rst`

### 3. desselet.dat Structure

IDESSEM identifies **two main sections** in `desselet.dat`:

#### Section 1: Base Cases (`BlocoCasosBase`)

```python
# idessem/dessem/modelos/desselet.py (lines 15-83)
class BlocoCasosBase(Section):
    """
    Bloco com os arquivos dos casos base.
    """
    FIM_BLOCO = "99999"
    
    # Returns DataFrame with columns:
    # - indice_caso_base (int)
    # - nome_caso_base (str)
    # - arquivo (str)
```

**Example from test mock** (`tests/mocks/arquivos/desselet.py`):
```
1    leve          leve        .pwf
2    media         media       .pwf
3    pesada        pesada      .pwf
99999
```

**Parsed columns**:
- `indice_caso_base`: Base case index (1, 2, 3, 4)
- `nome_caso_base`: Base case name ("leve", "media", "sab10h", "sab19h")
- `arquivo`: Filename with extension ("leve.pwf", "media.pwf")

#### Section 2: Stage Modifications (`BlocoCasosModificacao`)

```python
# idessem/dessem/modelos/desselet.py (lines 161-171)
class BlocoCasosModificacao(Section):
    """
    Bloco com os arquivos de modificação do caso base por estágio.
    """
    FIM_BLOCO = "99999"
    
    # Returns DataFrame with columns:
    # - codigo_estagio (int)
    # - nome_estagio (str)
    # - data (int, YYYYMMDD)
    # - hora (int)
    # - minuto (int)
    # - duracao (float, hours)
    # - indice_caso_base (int, references base case)
    # - arquivo_modificacao (str, .afp file)
```

**Example from ONS sample**:
```
  01 Estagio01    20251011  0  0  0.5      1 pat01.afp
  02 Estagio02    20251011  0 30  0.5      1 pat02.afp
  ...
  15 Estagio15    20251011  7  0  0.5      2 pat15.afp  # Uses base 2 (sab10h)
  ...
  35 Estagio35    20251011 17  0  0.5      3 pat35.afp  # Uses base 3 (sab19h)
  ...
  48 Estagio48    20251011 23 30  0.5      4 pat48.afp  # Uses base 4 (media)
99999
```

**Parsed columns**:
- `codigo_estagio`: Stage number (1-48)
- `nome_estagio`: Stage name ("Estagio01", "Estagio02", ...)
- `data`: Date in YYYYMMDD format (20251011)
- `hora`: Hour (0-23)
- `minuto`: Minute (0, 30)
- `duracao`: Duration in hours (0.5 = 30 minutes)
- `indice_caso_base`: Which base case to use (1=leve, 2=sab10h, 3=sab19h, 4=media)
- `arquivo_modificacao`: AFP pattern file ("pat01.afp", "pat02.afp", ...)

### 4. IDESSEM API Usage

```python
from idessem.dessem import Desselet

# Read desselet.dat
desselet = Desselet.read("desselet.dat")

# Access base cases as DataFrame
base_cases = desselet.dados_casos_base
# Returns:
#    indice_caso_base  nome_caso_base  arquivo
# 0                 1  leve            leve.pwf
# 1                 2  media           media.pwf
# 2                 3  sab10h          sab10h.pwf
# 3                 4  sab19h          sab19h.pwf

# Access stage modifications as DataFrame
modifications = desselet.dados_modificacao
# Returns 48 rows with columns:
# - codigo_estagio, nome_estagio, data, hora, minuto, duracao, 
#   indice_caso_base, arquivo_modificacao

# Modify and write back
desselet.dados_casos_base.at[0, "arquivo"] = "new_leve.pwf"
desselet.write("desselet_modified.dat")
```

### 5. Line Parsing Details

#### Base Case Line Format

```python
# idessem/dessem/modelos/desselet.py
self.__linha = Line([
    IntegerField(size=4, starting_position=0),   # indice_caso_base
    LiteralField(size=14, starting_position=5),  # nome_caso_base
    LiteralField(size=16, starting_position=20), # arquivo
])
```

**Format**: `INDEX    NAME            FILENAME.pwf`

#### Modification Line Format

```python
# idessem/dessem/modelos/desselet.py
self.__linha = Line([
    IntegerField(size=4, starting_position=0),    # codigo_estagio
    LiteralField(size=10, starting_position=5),   # nome_estagio
    IntegerField(size=8, starting_position=16),   # data (YYYYMMDD)
    IntegerField(size=2, starting_position=25),   # hora
    IntegerField(size=2, starting_position=28),   # minuto
    FloatField(size=4, starting_position=31, decimal_digits=1),  # duracao
    IntegerField(size=7, starting_position=36),   # indice_caso_base
    LiteralField(size=12, starting_position=44),  # arquivo_modificacao
])
```

**Format**: `  ## EtagioNN    YYYYMMDD HH MM D.D      # filename.afp`

### 6. PWF/AFP Files: NOT PARSED by IDESSEM

**Critical Point**: IDESSEM treats PWF and AFP files as **opaque references**.

- PWF files contain Anarede power flow network topology
- AFP files contain Anarede pattern modifications (security constraints, generation limits)
- IDESSEM **only stores the filenames**, does not parse their contents
- The DESSEM solver itself reads these files directly

**Why?**
1. PWF/AFP are in Anarede format (complex, proprietary-ish Brazilian power flow software format)
2. DESSEM solver has built-in Anarede file reader
3. Network topology is pre-solved power flow data, not optimization input
4. IDESSEM focuses on DESSEM input/output, not intermediate network files

### 7. dessem.arq Integration

In `dessem.arq`, the network is enabled via:

```python
# idessem/dessem/modelos/dessemarq.py (lines 491-531)
class RegistroIndelet(Register):
    """
    Registro com o índice da rede elétrica.
    """
    IDENTIFIER = "INDELET  "
    LINE = Line([
        LiteralField(size=38, starting_position=10),  # descrição
        LiteralField(size=80, starting_position=49),  # valor (filename)
    ])
```

**Example**:
```
INDELET   ARQ. INDICE DA REDE ELETRICA   (F)      desselet.dat
```

**Usage**:
```python
from idessem.dessem import DessemArq

arq = DessemArq.read("dessem.arq")

# Check if network is enabled
if arq.indelet:
    network_file = arq.indelet.valor  # "desselet.dat"
    print(f"Network enabled, using: {network_file}")
```

### 8. IDESSEM Test Data

**Test Mock** (`tests/mocks/arquivos/desselet.py`):

```python
MockBlocoCasoBase = [
    "1    leve          leve        .pwf\n",
    "2    media         media       .pwf\n",
    "3    pesada        pesada      .pwf\n",
    "99999\n",
]

MockBlocoCasosModificacao = [
    "  01 Estagio01    20240627  0  0  0.5      1 pat01.afp\n",
    "  02 Estagio02    20240627  0 30  0.5      1 pat02.afp\n",
    # ... 48 stages total
    "  48 Estagio48    20240627 23 30  0.5      2 pat48.afp\n",
    "99999\n",
]
```

**Tests** (`tests/dessem/test_desselet.py`):
- `test_atributos_encontrados_desselet()` - Verifies both sections are parsed
- `test_blocos()` - Tests DataFrame access and modification
- `test_leitura_escrita_desselet()` - Tests round-trip read/write

### 9. Encoding

```python
# No special encoding specified for desselet.dat
# Uses default system encoding (typically UTF-8 or Latin-1)
```

## Implementation Recommendations for DESSEM2Julia

### 1. Implement desselet.dat Parser (HIGH PRIORITY)

```julia
# src/parser/desselet.jl

module DesseleTParser

using ..DESSEM2Julia: DesseleTData, DesseleTBaseCaseRecord, DesseleTModificationRecord
using ..ParserCommon: extract_field

"""
Parse base case record from desselet.dat

Format: INDEX    NAME            FILENAME.pwf
"""
function parse_base_case_record(line::AbstractString, filename::AbstractString, line_num::Int)
    indice = parse(Int, strip(extract_field(line, 1, 4)))
    nome = strip(extract_field(line, 6, 19))
    arquivo = strip(extract_field(line, 21, 36))
    
    return DesseleTBaseCaseRecord(
        indice_caso_base=indice,
        nome_caso_base=nome,
        arquivo=arquivo
    )
end

"""
Parse stage modification record from desselet.dat

Format:   ## EtagioNN    YYYYMMDD HH MM D.D      # filename.afp
"""
function parse_modification_record(line::AbstractString, filename::AbstractString, line_num::Int)
    codigo_estagio = parse(Int, strip(extract_field(line, 1, 4)))
    nome_estagio = strip(extract_field(line, 6, 15)))
    data = parse(Int, strip(extract_field(line, 17, 24)))
    hora = parse(Int, strip(extract_field(line, 26, 27)))
    minuto = parse(Int, strip(extract_field(line, 29, 30)))
    duracao = parse(Float64, strip(extract_field(line, 32, 35)))
    indice_base = parse(Int, strip(extract_field(line, 37, 43)))
    arquivo_mod = strip(extract_field(line, 45, 56))
    
    return DesseleTModificationRecord(
        codigo_estagio=codigo_estagio,
        nome_estagio=nome_estagio,
        data=data,
        hora=hora,
        minuto=minuto,
        duracao=duracao,
        indice_caso_base=indice_base,
        arquivo_modificacao=arquivo_mod
    )
end

"""
Parse complete desselet.dat file
"""
function parse_desselet(io::IO, filename::AbstractString)
    base_cases = DesseleTBaseCaseRecord[]
    modifications = DesseleTModificationRecord[]
    
    in_base_section = false
    in_mod_section = false
    
    for (line_num, line) in enumerate(eachline(io))
        # Skip comments
        startswith(strip(line), "(") && continue
        
        # Check for end markers
        if startswith(strip(line), "99999")
            if !in_mod_section
                in_base_section = false
                in_mod_section = true  # Switch to modifications section
            else
                break  # End of file
            end
            continue
        end
        
        # Parse base cases first
        if !in_base_section && !in_mod_section
            # First numeric line starts base cases
            if occursin(r"^\s*\d", line)
                in_base_section = true
            end
        end
        
        if in_base_section
            record = parse_base_case_record(line, filename, line_num)
            push!(base_cases, record)
        elseif in_mod_section
            record = parse_modification_record(line, filename, line_num)
            push!(modifications, record)
        end
    end
    
    return DesseleTData(
        casos_base=base_cases,
        modificacoes=modifications
    )
end

parse_desselet(filename::AbstractString) = open(io -> parse_desselet(io, filename), filename)

export parse_desselet, parse_base_case_record, parse_modification_record

end  # module
```

### 2. Define Types

```julia
# src/types.jl or src/models/core_types.jl

Base.@kwdef struct DesseleTBaseCaseRecord
    indice_caso_base::Int
    nome_caso_base::String
    arquivo::String
end

Base.@kwdef struct DesseleTModificationRecord
    codigo_estagio::Int
    nome_estagio::String
    data::Int  # YYYYMMDD
    hora::Int
    minuto::Int
    duracao::Float64
    indice_caso_base::Int  # References base case
    arquivo_modificacao::String
end

Base.@kwdef struct DesseleTData
    casos_base::Vector{DesseleTBaseCaseRecord} = DesseleTBaseCaseRecord[]
    modificacoes::Vector{DesseleTModificationRecord} = DesseleTModificationRecord[]
end
```

### 3. DO NOT Parse PWF/AFP Files

**Rationale**:
- Anarede-specific format
- Not needed for DESSEM2Julia's core purpose
- DESSEM solver reads them directly
- Would require significant reverse engineering

**Alternative**: Document that PWF/AFP files are opaque references.

### 4. Integration with dessemarq.dat

```julia
# When parsing dessem.arq, check for INDELET record
if haskey(arq_data, :indelet) && !isnothing(arq_data.indelet)
    desselet_file = arq_data.indelet.valor
    desselet_data = parse_desselet(joinpath(dirname(arq_path), desselet_file))
    # Store reference or merge into main data structure
end
```

## Summary Table: What IDESSEM Parses

| File Type | IDESSEM Parses? | Content | Format |
|-----------|-----------------|---------|--------|
| **desselet.dat** | ✅ YES | Links stages to PWF/AFP files | Text, fixed-width |
| **dessem.arq** | ✅ YES | INDELET record with desselet.dat filename | Text, fixed-width |
| **PWF files** | ❌ NO | Anarede power flow base cases | Anarede binary/text |
| **AFP files** | ❌ NO | Anarede pattern modifications | Anarede text |
| **entdados.dat** | ✅ YES | High-level network topology (RD, TM, SIST, REE) | Text, fixed-width |

## Conclusion for DESSEM2Julia

**Recommended Implementation**:

1. ✅ **Parse desselet.dat** - HIGH PRIORITY
   - Provides stage-to-network-file mapping
   - Relatively simple format (two sections, fixed-width)
   - Required for understanding ONS network cases

2. ❌ **Skip PWF/AFP parsing** - LOW PRIORITY / OUT OF SCOPE
   - Anarede-specific format
   - Not needed for reading DESSEM input data
   - DESSEM solver handles these internally
   - Document as "opaque network references"

3. ✅ **Already done: entdados.dat network records**
   - RD, RIVAR, TM, SIST, REE, IA, RI, GP already parsed
   - Provides high-level network configuration
   - Sufficient for most use cases

**Result**: DESSEM2Julia will be able to:
- ✅ Identify which time stages use network simulation
- ✅ Map stages to base cases and pattern files
- ✅ Understand network topology at high level (subsystems, reservoirs)
- ❌ Parse detailed electrical network (but this is OK - not the project's goal)

This matches IDESSEM's approach: parse DESSEM I/O, treat Anarede files as black boxes.
