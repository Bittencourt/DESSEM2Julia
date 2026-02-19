---
phase: quick-001
plan: 01
type: execute
wave: 1
depends_on: []
files_modified: [examples/read_fcf_cuts.jl]
autonomous: true

must_haves:
  truths:
    - "User can read FCF cuts from binary cortdeco.rv2 files"
    - "User can access cut data (RHS, coefficients, iteration info)"
    - "User can get water values for specific hydro plants"
    - "User can see statistics about the cuts"
  artifacts:
    - path: "examples/read_fcf_cuts.jl"
      provides: "Complete FCF cuts reading demonstration"
      min_lines: 80
  key_links:
    - from: "examples/read_fcf_cuts.jl"
      to: "src/parser/cortdeco.jl"
      via: "parse_cortdeco, get_water_value, get_cut_statistics"
---

<objective>
Create a demonstration script showing how to read and analyze FCF (Future Cost Function) Benders cuts from binary cortdeco.rv2 files.

Purpose: Provide a clear, runnable example for users who need to work with FCF cuts data from NEWAVE/DECOMP hydrothermal optimization.

Output: `examples/read_fcf_cuts.jl` with comprehensive demonstration of:
- Binary file parsing
- Cut data access patterns
- Water value extraction
- Statistics computation
</objective>

<execution_context>
@~/.config/opencode/get-shit-done/workflows/execute-plan.md
@~/.config/opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md

# Existing Infrastructure
@src/parser/cortdeco.jl - FCF cuts parser with types and helper functions
@examples/parse_sample_case.jl - Example format reference

# Data Types Available
- `FCFCut`: Single cut with indice_corte, iteracao_construcao, indice_forward, iteracao_desativacao, rhs, coeficientes
- `FCFCutsData`: Container with cortes, tamanho_registro, numero_total_cortes, codigos_uhes, etc.

# Functions Available
- `parse_cortdeco(filepath; kwargs...)` - Parse binary file
- `get_water_value(cuts, uhe_code)` - Get water value for hydro plant
- `get_active_cuts(cuts)` - Filter active cuts
- `get_cut_statistics(cuts)` - Get summary statistics

# Test Data
- docs/Sample/DS_ONS_102025_RV2D11/cortdeco.rv2 - Available test file
</context>

<tasks>

<task type="auto">
  <name>Create FCF cuts reading example script</name>
  <files>examples/read_fcf_cuts.jl</files>
  <action>
Create a comprehensive Julia example script that demonstrates FCF cuts parsing:

1. **Header and setup**:
   - Module docstring explaining FCF cuts purpose (Benders cuts from NEWAVE/DECOMP)
   - Import DESSEM2Julia module
   - Define sample file path using ONS sample data

2. **Step 1: Parse binary file**:
   - Show `parse_cortdeco()` with realistic parameters
   - Use sample path: `docs/Sample/DS_ONS_102025_RV2D11/cortdeco.rv2`
   - Include codigos_uhes for individualized mode (typical Brazilian hydro plants)
   - Display success message and basic info

3. **Step 2: Explore cut structure**:
   - Show first few cuts with their fields (indice_corte, iteracao_construcao, rhs)
   - Explain what each field means
   - Show coefficient vector length and interpretation

4. **Step 3: Water value extraction**:
   - Use `get_water_value()` function for specific plants
   - Show multiple plants' water values
   - Explain water value meaning (marginal cost of water)

5. **Step 4: Active vs inactive cuts**:
   - Use `get_active_cuts()` to filter
   - Show count comparison
   - Explain deactivation iteration

6. **Step 5: Statistics**:
   - Use `get_cut_statistics()` to show summary
   - Pretty-print the statistics dictionary

7. **Follow existing example style**:
   - Match format of `examples/parse_sample_case.jl`
   - Use box drawing characters for sections
   - Include emoji indicators
   - Print summary at the end

DO NOT create test data - use existing sample files only.
DO NOT add new functions to the parser - only use existing exported functions.
</action>
  <verify>
julia -e 'include("examples/read_fcf_cuts.jl")' 2>&1 | head -100
</verify>
  <done>
Example script runs successfully, demonstrates all key functions, and produces formatted output showing cut data access patterns.
</done>
</task>

</tasks>

<verification>
- Example script exists at examples/read_fcf_cuts.jl
- Script runs without errors: `julia examples/read_fcf_cuts.jl`
- Output shows parsed cuts, water values, and statistics
- Code follows existing example conventions (box drawing, emojis, sections)
</verification>

<success_criteria>
- Single example file demonstrating FCF cuts binary file reading
- Covers parse_cortdeco, get_water_value, get_active_cuts, get_cut_statistics
- Uses real sample data from docs/Sample/DS_ONS_102025_RV2D11/
- Runs successfully and produces informative output
</success_criteria>

<output>
After completion, create `.planning/quick/001-make-a-new-example-of-reading-binary-dat/001-SUMMARY.md`
</output>
