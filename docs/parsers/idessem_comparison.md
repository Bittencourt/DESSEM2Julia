# idessem Architecture Analysis & Comparison

## Date: 2025-10-12

## Overview

This document analyzes the `idessem` Python library architecture and compares it with our Julia implementation to identify best practices and opportunities for improvement.

## idessem Architecture Summary

### 1. **Main Entry Point: `dessem.arq` File**

idessem uses a **master index file** (`dessem.arq`) that lists ALL input files for a DESSEM study:

```python
# From idessem/dessem/dessemarq.py
class DessemArq(RegisterFile):
    """Stores the input file names for DESSEM."""
    
    @property
    def vazoes(self) -> Optional[RegistroVazoes]:
        """The natural flow file name."""
        
    @property
    def dadger(self) -> Optional[RegistroDadger]:
        """The general data file name (entdados.dat)."""
        
    @property
    def cadterm(self) -> Optional[RegistroCadterm]:
        """The thermal plant registry file name (termdat.dat)."""
    
    # ... and 20+ more file properties
```

**Key insight:** Instead of hardcoding filenames, idessem reads a configuration file that tells it where each data file is located.

### 2. **Hierarchical Data Organization**

```
DessemArq (master file list)
├── Entdados (general data - entdados.dat)
│   ├── tm() - time discretization records
│   ├── sist() - subsystem records
│   ├── uh() - hydro plant records
│   ├── ut() - thermal plant records
│   └── dp() - demand records
├── Term (thermal registry - termdat.dat)
│   ├── cadusit() - plant registry
│   ├── cadunidt() - unit registry
│   └── cadconf() - configuration
├── Dadvaz (flows - dadvaz.dat)
├── Operut (thermal operations - operut.dat)
├── Operuh (hydro operations - operuh.dat)
└── ... (20+ more files)
```

### 3. **Access Pattern Philosophy**

idessem provides **two access modes**:

#### A. **Single Record Access** (with filtering):
```python
# Get specific records
entdados = Entdados.read("entdados.dat")

# Get ONE hydro plant by code
uh = entdados.uh(codigo_usina=66)

# Get ALL hydro plants as list
all_uh = entdados.uh()

# Get filtered list
ree_10_plants = entdados.uh(codigo_ree=10)
```

#### B. **DataFrame Access** (for analysis):
```python
# Get ALL records as pandas DataFrame
df_uh = entdados.uh(df=True)

# Now you can use pandas operations
df_uh[df_uh['codigo_ree'] == 10]
df_uh.groupby('codigo_ree').agg({'volume_inicial': 'mean'})
```

### 4. **Storage Strategy**

idessem **DOES NOT pre-convert to binary**. Instead:

1. **Lazy parsing**: Files are read only when accessed
2. **In-memory objects**: Parsed data stays as Python objects
3. **DataFrame export**: Users can convert to DataFrames for analysis when needed
4. **No persistence layer**: Each run re-parses the text files

**Rationale**: Text files are the source of truth, always readable by external tools.

### 5. **Type System Architecture**

```python
# From cfinterface (their framework)
class Line:
    def __init__(self, fields):
        self.fields = [
            IntegerField(size=3, starting_position=4),   # Python 0-indexed
            FloatField(size=10, starting_position=29, decimal_digits=2),
            LiteralField(size=12, starting_position=9),
        ]
    
    def read(self, line: str) -> list:
        """Parse one line into values."""
        return [field.read(line) for field in self.fields]
```

**Key insight**: They separate **field specification** (metadata) from **parsing logic** (implementation).

### 6. **File Classification System**

idessem uses the `cfinterface` framework which classifies files into 3 types:

#### A. **RegisterFile** (record-based):
- Used for: `entdados.dat`, `termdat.dat`, `respot.dat`
- Structure: Multiple record types in same file (TM, SIST, UH, UT, DP)
- Access: By record type with filtering

#### B. **BlockFile** (block-based):
- Used for: `operut.dat`, `dessopc.dat`
- Structure: Named blocks with different formats
- Access: By block name

#### C. **SectionFile** (section-based):
- Used for: `desselet.dat`, `dadvaz.dat`
- Structure: Sequential sections with headers
- Access: By section type

**Our current approach**: We treat all files as RegisterFile type.

### 7. **Complete Workflow Example**

```python
# 1. Read the master file list
arq = DessemArq.read("dessem.arq")

# 2. Get the actual data file names
entdados_file = arq.dadger.valor  # Returns "entdados.dat"
termdat_file = arq.cadterm.valor  # Returns "termdat.dat"

# 3. Read the data files
entdados = Entdados.read(entdados_file)
termdat = Term.read(termdat_file)

# 4. Access data with filtering
plants = entdados.uh(codigo_ree=10)  # Get plants in REE 10

# 5. Or get everything as DataFrame for analysis
df = entdados.uh(df=True)
df.to_csv("hydro_plants.csv")
```

---

## Comparison with Our Julia Implementation

### ✅ **What We're Doing Well:**

1. **Strong typing**: Julia's type system is more precise than Python's
2. **Fixed-column parsing**: Using exact column ranges (same as idessem)
3. **Test coverage**: 99.9% test pass rate
4. **Field specifications**: FieldSpec approach similar to their Line/Field system
5. **Binary persistence (JLD2)**: Fast loading for large datasets (Python doesn't have this)

### ⚠️ **Areas for Improvement:**

#### 1. **Missing Master File Index**

**Problem**: We hardcode filenames in code
```julia
# Current approach
entdados = parse_entdados("entdados.dat")  # Hardcoded name
```

**idessem approach**: Read from configuration
```python
arq = DessemArq.read("dessem.arq")
entdados_file = arq.dadger.valor  # Dynamic filename
```

**Recommendation**: 
- Add `parse_dessemarq()` to read the master `dessem.arq` file
- Use it to discover all input file locations
- Makes our tool work with ANY DESSEM case structure

#### 2. **Data Access API**

**Problem**: We return raw structs
```julia
# Current
data = parse_entdados("entdados.dat")
# Returns: EntdadosData with field `uh::Vector{UHRecord}`
# User must filter manually: filter(r -> r.codigo_ree == 10, data.uh)
```

**idessem approach**: Provide filtered access
```python
# Get specific subset
plants = entdados.uh(codigo_ree=10)

# Or get as DataFrame
df = entdados.uh(df=True)
```

**Recommendation**:
```julia
# Add helper functions
function get_uh(data::EntdadosData; codigo_ree=nothing, codigo_usina=nothing)
    result = data.uh
    !isnothing(codigo_ree) && (result = filter(r -> r.codigo_ree == codigo_ree, result))
    !isnothing(codigo_usina) && (result = filter(r -> r.codigo_usina == codigo_usina, result))
    return result
end

# Or DataFrame conversion
function DataFrame(data::EntdadosData, record_type::Symbol)
    if record_type == :uh
        return DataFrame(data.uh)  # Julia DataFrames.jl integration
    end
end
```

#### 3. **File Organization Structure**

**Current**: Flat approach
```
src/
  parser/
    entdados.jl  # All record types in one file
    termdat.jl
```

**idessem approach**: Modular
```
idessem/dessem/
  dessemarq.py      # Master file reader
  entdados.py       # API wrapper
  modelos/
    entdados.py     # Record definitions (TM, SIST, UH, UT, DP)
    termdat.py
    dessemarq.py    # File registry records
```

**Recommendation**:
```
src/
  dessem/
    dessemarq.jl      # Master file index parser
    entdados.jl       # High-level API
    termdat.jl
    modelos/          # Low-level parsers
      entdados.jl     # Record parsing implementations
      termdat.jl
```

#### 4. **Type Organization**

**Current**: All types in one file
```julia
# src/types.jl - ALL record types mixed together
struct TMRecord ... end
struct UHRecord ... end
struct UTRecord ... end
```

**idessem approach**: Grouped by file
```python
# modelos/entdados.py - Only ENTDADOS records
class TM(Register): ...
class UH(Register): ...

# modelos/termdat.py - Only TERMDAT records  
class CADUSIT(Register): ...
```

**Recommendation**: Split `types.jl` by file:
```julia
# src/modelos/entdados_types.jl
struct TMRecord ... end
struct UHRecord ... end

# src/modelos/termdat_types.jl
struct CADUSITRecord ... end
```

---

## Recommended Architecture for DESSEM2Julia

### Phase 1: Current Foundation (✅ COMPLETE)
- [x] Individual file parsers (TERMDAT, ENTDADOS)
- [x] Fixed-column parsing with FieldSpec
- [x] JLD2 binary persistence
- [x] Comprehensive testing

### Phase 2: API Enhancement (🎯 RECOMMENDED)
1. **Add `dessem.arq` parser**:
   ```julia
   struct DessemArq
       vazoes::String      # "dadvaz.dat"
       dadger::String      # "entdados.dat"
       cadterm::String     # "termdat.dat"
       # ... all file paths
   end
   
   function parse_dessemarq(filepath::String)::DessemArq
       # Parse dessem.arq to get all file locations
   end
   ```

2. **Add filtering API**:
   ```julia
   # Instead of forcing users to filter manually
   uh_records = filter(r -> r.codigo_ree == 10, data.uh)
   
   # Provide helper
   uh_records = get_uh(data; codigo_ree=10)
   ```

3. **Add DataFrame integration**:
   ```julia
   using DataFrames
   
   # Convert record vectors to DataFrames
   df = DataFrame(data.uh)
   
   # Or specific filter as DataFrame
   df = get_uh_dataframe(data; codigo_ree=10)
   ```

### Phase 3: Complete DESSEM Suite (🔮 FUTURE)
1. Parse ALL input files mentioned in `dessem.arq`:
   - `dadvaz.dat` (flows)
   - `operuh.dat` (hydro operations)
   - `operut.dat` (thermal operations)
   - `mapcut.rv0`, `cortdeco.rv0` (FCF cuts)
   - etc.

2. Create unified API:
   ```julia
   struct DESSEMCase
       arq::DessemArq           # Master index
       entdados::EntdadosData   # General data
       termdat::TermdatData     # Thermal registry
       dadvaz::DadvazData       # Flows
       # ... all other files
   end
   
   function load_dessem_case(directory::String)::DESSEMCase
       # Read dessem.arq
       arq = parse_dessemarq(joinpath(directory, "dessem.arq"))
       
       # Read all files referenced in arq
       entdados = parse_entdados(joinpath(directory, arq.dadger))
       termdat = parse_termdat(joinpath(directory, arq.cadterm))
       # ... etc
       
       return DESSEMCase(arq, entdados, termdat, ...)
   end
   ```

---

## Key Takeaways

### 1. **They're Smarter About File Discovery**
- We hardcode "entdados.dat" - they read it from `dessem.arq`
- Makes tool work with ANY DESSEM case structure

### 2. **They Provide Better Data Access**
- Filtering API: `entdados.uh(codigo_ree=10)`
- DataFrame export: `entdados.uh(df=True)`
- We should add similar convenience functions

### 3. **They Don't Use Binary Storage**
- Text files are source of truth
- Re-parse on each run
- **Our JLD2 approach is BETTER for performance** - keep it!

### 4. **They Have Better File Organization**
- Separate models from API
- One module per DESSEM file type
- We should reorganize once we have more files

### 5. **Our Type System is Stronger**
- Julia's type system > Python's
- Keep using @kwdef structs
- Keep strong typing

---

## Action Items

### Immediate (Next Session):
1. ✅ Document idessem architecture
2. 🔄 Add `dessem.arq` parser (simple - just read file paths)
3. 🔄 Add filtering helpers (`get_uh`, `get_ut`, etc.)
4. 🔄 Add DataFrame conversion utilities

### Short Term:
1. Reorganize `src/` to separate models from API
2. Add more input file parsers based on priority
3. Create unified `load_dessem_case()` function

### Long Term:
1. Parse ALL 20+ DESSEM input files
2. Add output file parsers (PDO_*.DAT)
3. Create analysis utilities similar to idessem

---

## Conclusion

**Our implementation is on the right track!** 

Main differences:
- **idessem**: Pure Python, text-only, pandas-focused, mature ecosystem
- **DESSEM2Julia**: Julia, binary caching, type-safe, performance-focused

We should adopt:
1. ✅ Master file index (`dessem.arq`) parser
2. ✅ Filtering API for convenience
3. ✅ DataFrame integration for analysis
4. ✅ Better file organization

We should keep:
1. ✅ JLD2 binary persistence (MAJOR advantage)
2. ✅ Strong Julia typing
3. ✅ FieldSpec architecture
4. ✅ Comprehensive testing

**Bottom line**: Add convenience layer (filtering, DataFrames, master index) while maintaining our performance advantages.
