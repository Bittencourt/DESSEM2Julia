# RESTSEG.DAT Implementation Guide

## Overview
RESTSEG defines dynamic security table constraints using keyworded, tokenized lines prefixed with `TABSEG`. Unlike most DESSEM files, RESTSEG is not fixed-width; fields are delineated by keywords and token order.

- Record kinds (from samples):
  - `INDICE`: Index and human-readable description
  - `TABELA`: Table metadata (types, parameters)
  - `LIMITE`: Global/table limit value
  - `CELULA`: Cell-level parameters with optional flag and bounds

## Record Forms

Examples observed in production data:

- INDICE
```
TABSEG INDICE 197 RESTRIÇÃO ANGULAR ENTRE ÁREAS SE/NE
```

- TABELA (numeric form)
```
TABSEG TABELA 197 PARAM DREF RE 14 5
```

- TABELA (carga form without numeric code)
```
TABSEG TABELA 197 PARAM CARGA SIN
TABSEG TABELA 197 PARAM CARGA S
```

- LIMITE
```
TABSEG LIMITE 197 200
```

- CELULA
```
TABSEG CELULA 197 1 A 10 20
TABSEG CELULA 197 2
```

## Types

Defined in `src/types.jl`:

- `RestsegIndice(indice::Int, descricao::String)`
- `RestsegTabela(indice::Int, tipo1::String, tipo2::String, num::Union{Int,Nothing}, pcarg::Union{Int,String,Nothing})`
- `RestsegLimite(indice::Int, limite::Int)`
- `RestsegCelula(indice::Int, limite::Int; flag::Union{String,Nothing}=nothing, par1_inf::Union{Int,Nothing}=nothing, par1_sup::Union{Int,Nothing}=nothing)`
- `RestsegData(indices::Vector, tabelas::Vector, limites::Vector, celulas::Vector)`

Design notes:
- Union types reflect mixed numeric/string tokens in TABELA (e.g., `CARGA SIN`).
- Optional tokens default to `nothing` to distinguish from zeros or empty strings.

## Parser

Location: `src/parser/restseg.jl`

Key points:
- Skip comments (`&`, `*`, `#`, `//`) and blank lines via ParserCommon utilities
- Tokenize each `TABSEG` line and branch by second token (record kind)
- Preserve UTF-8 accents in descriptions and string tokens
- Normalize token text to `String` before assigning to Union fields (avoids SubString issues)

Returned container: `RestsegData`

## Tests

File: `test/restseg_tests.jl`
- Unit tests for all record kinds
- TABELA variants (numeric vs carga form)
- CELULA with/without optional flag and bounds
- Integration test against `docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/restseg.dat` when available

Current result: 17/17 tests passing locally

## IDESEM Reference
- Repository: https://github.com/rjmalves/idessem
- File: `idessem/dessem/modelos/restseg.py`

Note: IDESEM expresses token ordering with its field definitions. Remember Python is 0-indexed; when comparing any starting positions in comments, Julia is 1-indexed.

## Rationale: Tokenized Parsing
RESTSEG lines are semantically delimited by keywords and tokens; fixed-width columns are not present or reliable in samples. Tokenized parsing is robust for this file, similar to the documented exception for DESSELET.
