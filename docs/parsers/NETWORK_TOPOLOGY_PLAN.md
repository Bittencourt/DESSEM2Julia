# Network Topology Parser Implementation Plan

## Overview

Based on IDESSEM repository analysis, the network topology and definition in DESSEM is defined through multiple record types in the `entdados.dat` file. This document outlines the implementation plan for parsing these records.

## Key Network Record Types (from IDESSEM)

### 1. **RD** - Rede Elétrica (Electrical Network Options)
Location in IDESSEM: `idessem/dessem/modelos/entdados.py` line 14-60

**Purpose**: Contains options for electrical network representation.

**Fields** (0-indexed in IDESSEM, add 1 for Julia):
```python
# IDESSEM definition
IDENTIFIER = "RD  "
LINE = Line([
    IntegerField(1, 4),   # variaveis_de_folga
    IntegerField(3, 9),   # maximo_circuitos_violados
    IntegerField(1, 14),  # carga_registro_dbar
    IntegerField(1, 16),  # (unused field)
    IntegerField(1, 18),  # (unused field)
    IntegerField(1, 20),  # (unused field)
    IntegerField(1, 22),  # formato_arquivos_rede
])
```

**Example**:
```
RD  1    800  0 1            
```

**Fields**:
- `variaveis_de_folga`: Slack variables for line flow limit restrictions
- `maximo_circuitos_violados`: Maximum number of slack variables for line flow restrictions
- `carga_registro_dbar`: Flag to use DBAR register loads without calculating flows
- `formato_arquivos_rede`: Network file format

---

### 2. **RIVAR** - Restrições de Variação (Variation Restrictions)
Location in IDESSEM: `idessem/dessem/modelos/entdados.py` line 137-197

**Purpose**: Contains configurations for soft variation constraints.

**Fields**:
```python
# IDESSEM definition
IDENTIFIER = "RIVAR  "
LINE = Line([
    IntegerField(3, 7),   # codigo_entidade
    IntegerField(3, 12),  # sistema_para
    IntegerField(2, 15),  # tipo_variavel
    FloatField(10, 19),   # (value field)
])
```

**Example**:
```
RIVAR  999     4
```

---

### 3. **TM** - Tempo/Discretização (Time Discretization)
Location in IDESSEM: `idessem/dessem/modelos/entdados.py` line 201-285

**Purpose**: Defines study time discretization and load patterns.

**Fields**:
```python
# IDESSEM definition
IDENTIFIER = "TM  "
LINE = Line([
    IntegerField(2, 4),             # dia
    IntegerField(2, 9),             # hora_inicial
    IntegerField(1, 12),            # meia_hora_inicial
    FloatField(10, 17, 1),          # duracao
    IntegerField(1, 23),            # considera_rede_eletrica
    LiteralField(6, 28),            # nome_patamar
])
```

**Example**:
```
TM  28    0   0      0.5     0     LEVE
```

**Fields**:
- `dia`: Day of the month
- `hora_inicial`: Starting hour
- `meia_hora_inicial`: Starting half-hour (0 or 1)
- `duracao`: Duration in hours
- `considera_rede_eletrica`: Flag to consider electrical network (0 or 1)
- `nome_patamar`: Load pattern name (LEVE, MEDIA, PESADA)

---

### 4. **SIST** - Sistemas/Submercados (Subsystems/Submarkets)
Location in IDESSEM: `idessem/dessem/modelos/entdados.py` line 287-342

**Purpose**: Defines subsystems/submarkets in the study.

**Fields**:
```python
# IDESSEM definition
IDENTIFIER = "SIST   "
LINE = Line([
    IntegerField(2, 6),      # codigo_submercado
    LiteralField(2, 9),      # mnemonic_submercado
    IntegerField(1, 12),     # ficticioso
    LiteralField(10, 14),    # nome_submercado
])
```

**Example**:
```
SIST    1 SE  0 SUDESTE   
SIST    2 S   0 SUL       
SIST    3 NE  0 NORDESTE  
SIST    4 N   0 NORTE     
SIST   11 FC  0 NOFICT1
```

**Fields**:
- `codigo_submercado`: Subsystem code (integer)
- `mnemonic_submercado`: 2-letter mnemonic (SE, S, NE, N, FC)
- `ficticioso`: Fictitious flag (0 = real, 1 = fictitious)
- `nome_submercado`: Full subsystem name

---

### 5. **REE** - Reservatórios Equivalentes de Energia (Equivalent Energy Reservoirs)
Location in IDESSEM: `idessem/dessem/modelos/entdados.py` line 389-444

**Purpose**: Defines equivalent energy reservoirs grouping hydro plants.

**Fields**:
```python
# IDESSEM definition
IDENTIFIER = "REE   "
LINE = Line([
    IntegerField(2, 6),      # codigo_ree
    IntegerField(2, 9),      # codigo_submercado
    LiteralField(10, 12),    # nome_ree
])
```

**Example**:
```
REE    1  1 SUDESTE   
REE    6  1 MADEIRA   
REE    2  2 SUL       
REE    3  3 NORDESTE  
REE    4  4 NORTE     
```

**Fields**:
- `codigo_ree`: REE identification code
- `codigo_submercado`: Subsystem code (links to SIST)
- `nome_ree`: REE name

---

### 6. **RI** - Restrições de Itaipu (Itaipu Restrictions)
Location in IDESSEM: `idessem/dessem/modelos/entdados.py` line 1777-1823

**Purpose**: Contains Itaipu-specific operational restrictions.

**Fields**:
```python
# IDESSEM definition
IDENTIFIER = "RI  "
LINE = Line([
    StageDateField(starting_position=8, special_day_character="I"),  # dia_inicial
    StageDateField(starting_position=16, special_day_character="F"), # dia_final
    FloatField(10, 26, 2),  # geracao_minima_60hz
    FloatField(10, 36, 2),  # geracao_maxima_60hz
    FloatField(10, 46, 2),  # geracao_minima_50hz
    FloatField(10, 56, 2),  # geracao_maxima_50hz
    FloatField(10, 66, 2),  # geracao_ande
])
```

**Example**:
```
RI      12  0 0 F            2000.00   7000.00   2000.00   7000.00   1532.00
```

---

### 7. **IA** - Intercâmbio (Interconnection Capacity)
Location in IDESSEM: `idessem/dessem/modelos/entdados.py` line 1954-2003

**Purpose**: Defines interconnection capacity limits between subsystems.

**Fields**:
```python
# IDESSEM definition
IDENTIFIER = "IA  "
LINE = Line([
    LiteralField(2, 4),      # nome_submercado_de
    LiteralField(2, 9),      # nome_submercado_para
    StageDateField(starting_position=13, special_day_character="I"), # dia_inicial
    StageDateField(starting_position=21, special_day_character="F"), # dia_final
    FloatField(10, 29, 1),   # limite_inferior
    FloatField(10, 39, 1),   # limite_superior
])
```

**Example**:
```
IA  IV   S    I       F           99999     99999
IA  SE   NE   I       F           99999     99999
```

**Fields**:
- `nome_submercado_de`: Origin subsystem (2-letter code)
- `nome_submercado_para`: Destination subsystem (2-letter code)
- `dia_inicial`/`dia_final`: Date range (I = initial, F = final)
- `limite_inferior`/`limite_superior`: Capacity limits (MW)

---

### 8. **GP** - Gap de Convergência (Convergence Gap)
Location in IDESSEM: `idessem/dessem/modelos/entdados.py` line 2118-2157

**Purpose**: Defines convergence tolerance gaps for PDD or MILP methods.

**Fields**:
```python
# IDESSEM definition
IDENTIFIER = "GP  "
LINE = Line([
    FloatField(10, 4, 8),   # gap_pdd
    FloatField(10, 15, 8),  # gap_milp
])
```

**Example**:
```
GP       0.001      0.001
```

---

### 9. **RE, LU, FH, FT, FI, FE, FR, FC** - Restrições Elétricas (Electrical Restrictions)
Location in IDESSEM: `idessem/dessem/modelos/entdados.py` lines 3500-5000+

**Purpose**: Complex electrical network constraints with multiple record types:

- **RE**: Restriction definition
- **LU**: Lower and upper limits
- **FH**: Hydro plant factor
- **FT**: Thermal plant factor
- **FI**: Interconnection factor (subsystem-to-subsystem flow)
- **FE**: Export contract factor
- **FR**: Renewable plant factor
- **FC**: Demand factor

**Example sequence**:
```
RE  901  12       F
LU  901 12       F          -99999      9000
FI  901 12       F      FC   NE            1
FI  901 12       F      NE   FC           -1
```

These records work together to define complex network constraints like line limits, interconnection limits, and LPP (Linear Piecewise) restrictions.

---

## Implementation Priority

Based on complexity and dependencies:

### Phase 1: Basic Network Definition (PRIORITY HIGH)
1. ✅ **SIST** - Subsystem registry (simple, foundational)
2. ✅ **REE** - Energy reservoir registry (simple, depends on SIST)
3. **TM** - Time discretization (moderate complexity)
4. **RD** - Network options (simple)
5. **RIVAR** - Variation restrictions (simple)

### Phase 2: Interconnections (PRIORITY MEDIUM)
6. **IA** - Interconnection limits (depends on SIST)
7. **RI** - Itaipu restrictions (special case)
8. **GP** - Convergence gaps (simple)

### Phase 3: Complex Electrical Constraints (PRIORITY LOW)
9. **RE/LU/FH/FT/FI/FE/FR/FC** - Electrical restrictions (complex, multi-record)

---

## Type Definitions Needed

### Core Network Types

```julia
# Already exist in entdados.jl
SubsystemRecord (SIST)
REERecord (REE)

# Need to add
Base.@kwdef struct NetworkOptionsRecord  # RD
    slack_variables::Int
    max_violated_circuits::Int
    use_dbar_load::Int
    network_file_format::Int
end

Base.@kwdef struct VariationRestrictionRecord  # RIVAR
    entity_code::Int
    destination_system::Int
    variable_type::Int
    value::Union{Float64, Nothing} = nothing
end

Base.@kwdef struct TimeDiscretizationRecord  # TM
    day::Int
    initial_hour::Int
    initial_half_hour::Int
    duration::Float64
    consider_network::Int
    load_pattern_name::String
end

Base.@kwdef struct ItaipuRestrictionRecord  # RI
    initial_day::Union{Int, String}
    initial_hour::Int
    initial_minute::Int
    final_day::Union{Int, String}
    final_hour::Int
    final_minute::Int
    min_gen_60hz::Float64
    max_gen_60hz::Float64
    min_gen_50hz::Float64
    max_gen_50hz::Float64
    ande_gen::Float64
end

Base.@kwdef struct InterconnectionRecord  # IA
    subsystem_from::String
    subsystem_to::String
    initial_day::Union{Int, String}
    initial_hour::Int
    initial_minute::Int
    final_day::Union{Int, String}
    final_hour::Int
    final_minute::Int
    lower_limit::Float64
    upper_limit::Float64
end

Base.@kwdef struct ConvergenceGapRecord  # GP
    gap_pdd::Float64
    gap_milp::Float64
end
```

---

## Next Steps

1. **Check existing implementations**: Review current `entdados.jl` to see what's already done
2. **Start with SIST/REE**: Verify these are properly parsed (they're already in types)
3. **Implement TM parser**: Time discretization is critical for understanding study periods
4. **Add RD/RIVAR/GP**: Simple single-record types
5. **Implement IA/RI**: Interconnection definitions
6. **Complex constraints**: RE/LU/FH/FT/FI/FE/FR/FC (Phase 3)

---

## References

- **IDESSEM Repository**: https://github.com/rjmalves/idessem
- **IDESSEM entdados.py**: `idessem/dessem/modelos/entdados.py`
- **Sample Data**: `docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/entdados.dat`
- **Current Parser**: `src/parser/entdados.jl`
- **Current Types**: `src/types.jl` and `src/models/core_types.jl`

---

## Status Tracking

- [ ] RD - Network options
- [ ] RIVAR - Variation restrictions  
- [ ] TM - Time discretization
- [x] SIST - Subsystems (exists in entdados.jl)
- [x] REE - Energy reservoirs (exists in entdados.jl)
- [ ] RI - Itaipu restrictions
- [ ] IA - Interconnection limits
- [ ] GP - Convergence gaps
- [ ] RE/LU/FH/FT/FI/FE/FR/FC - Electrical restrictions (complex)
