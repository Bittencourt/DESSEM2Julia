---
phase: quick-002
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - src/models/core_types.jl
  - src/parser/binary_dec.jl
  - test/binary_dec_tests.jl
autonomous: true

must_haves:
  truths:
    - "parse_mapcut returns structured data with header (num_estagios, num_rees, cortes_por_estagio)"
    - "parse_mapcut correctly reads sample files (ONS: 7 stages, 14 REEs; CCEE: 39 stages, 156 REEs)"
    - "Tests verify header parsing and record structure"
  artifacts:
    - path: "src/models/core_types.jl"
      provides: "MapcutHeader, MapcutRecord, MapcutData types"
      contains: "struct MapcutHeader"
    - path: "src/parser/binary_dec.jl"
      provides: "Full binary parsing implementation"
      exports: ["parse_mapcut"]
    - path: "test/binary_dec_tests.jl"
      provides: "Test coverage for mapcut parsing"
  key_links:
    - from: "parse_mapcut"
      to: "binary file format"
      via: "reinterpret Int32 for header, Float64 for coefficients"
---

<objective>
Implement full binary parsing for MAPCUT.DEC files.

Purpose: Replace placeholder implementation that only stores raw bytes with a proper parser that extracts header information (num_estagios, num_rees, cortes_por_estagio) and cut records.

Output: Working binary parser with proper types and tests.
</objective>

<execution_context>
@~/.config/opencode/get-shit-done/workflows/execute-plan.md
@~/.config/opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/STATE.md

# Reference implementations
@src/parser/cortdeco.jl - Similar binary parsing pattern (linked-list, Int32/Float64 reading)
@src/models/core_types.jl - Current placeholder MapcutRecord/MapcutData (lines 816-834)
@src/parser/binary_dec.jl - Current placeholder parser

# Sample files for validation
- docs/Sample/DS_ONS_102025_RV3D21/mapcut.rv3 (7 stages, 14 REEs)
- docs/Sample/DS_CCEE_102025_SEMREDE_RV1D04/mapcut.rv1 (39 stages, 156 REEs)
</context>

<tasks>

<task type="auto">
  <name>Task 1: Define proper Mapcut types in core_types.jl</name>
  <files>src/models/core_types.jl</files>
  <action>
Replace the placeholder MapcutRecord and MapcutData types (lines 816-834) with proper types:

1. **MapcutHeader** struct:
   - `num_estagios::Int32` - Number of stages
   - `num_rees::Int32` - Number of REEs (or UHEs in individualized mode)
   - `cortes_por_estagio::Vector{Int32}` - Cuts per stage (num_estagios values)

2. **MapcutRecord** struct:
   - `stage_idx::Int32` - Stage index (1-based)
   - `ree_idx::Int32` - REE/UHE index (1-based)
   - `cut_idx::Int32` - Cut index within stage
   - `coeficientes::Vector{Float64}` - Cut coefficients (structure depends on mode)

3. **MapcutData** struct:
   - `header::MapcutHeader` - File header
   - `records::Vector{MapcutRecord}` - All cut records
   - `total_cuts::Int` - Total number of cuts (sum of cortes_por_estagio)

Follow the existing pattern from FCFCut/FCFCutsData types (lines 890-933).
Update exports in the module (line 40) to include MapcutHeader.
  </action>
  <verify>
grep -A 20 "struct MapcutHeader" src/models/core_types.jl | head -25
  </verify>
  <done>
MapcutHeader, MapcutRecord, and MapcutData types defined with proper fields. MapcutHeader exported from CoreTypes module.
  </done>
</task>

<task type="auto">
  <name>Task 2: Implement binary parsing in binary_dec.jl</name>
  <files>src/parser/binary_dec.jl</files>
  <action>
Replace the placeholder `parse_mapcut` function with full binary parsing:

1. **Header parsing** (first 8 + num_estagios*4 bytes):
   ```julia
   num_estagios = read(io, Int32)
   num_rees = read(io, Int32)
   cortes_por_estagio = [read(io, Int32) for _ in 1:num_estagios]
   ```

2. **Record parsing** (after header, each record contains):
   - Stage index (Int32)
   - REE/UHE index (Int32)
   - Cut index (Int32)
   - Coefficients (Float64 array - size depends on num_rees and configuration)

3. **Error handling**: Use ParserError for invalid file structure (following cortdeco.jl pattern).

4. **Update imports**: Import the new types from CoreTypes.

Reference the cortdeco.jl implementation pattern:
- Use `reinterpret()` for reading binary data
- Handle empty/invalid files gracefully with warnings
- Return properly structured MapcutData

Note: Both available samples are templates (coefficient data is zeroed), but header and record structure can still be validated.
  </action>
  <verify>
julia --project=. -e 'using DESSEM2Julia; data = parse_mapcut("docs/Sample/DS_ONS_102025_RV3D21/mapcut.rv3"); println("Stages: ", data.header.num_estagios, ", REEs: ", data.header.num_rees)'
  </verify>
  <done>
parse_mapcut correctly parses mapcut.rv3 header (7 stages, 14 REEs) and returns MapcutData with populated header and records.
  </done>
</task>

<task type="auto">
  <name>Task 3: Update tests in binary_dec_tests.jl</name>
  <files>test/binary_dec_tests.jl</files>
  <action>
Update the MAPCUT Parser test section to verify the new implementation:

1. **Synthetic binary file test** (like cortdeco_tests.jl):
   - Create a temp file with known header (e.g., 3 stages, 5 REEs, [2, 3, 2] cuts per stage)
   - Write header: num_estagios, num_rees, cortes_por_estagio
   - Write records with known values
   - Verify parsing returns correct MapcutData

2. **Header parsing test**:
   - Verify num_estagios matches expected
   - Verify num_rees matches expected
   - Verify cortes_por_estagio array is correct

3. **Record structure test**:
   - Verify total cuts = sum(cortes_por_estagio)
   - Verify first record has correct stage_idx, ree_idx, cut_idx

4. **Real sample test** (optional but valuable):
   - Parse docs/Sample/DS_ONS_102025_RV3D21/mapcut.rv3
   - Verify header: 7 stages, 14 REEs

Follow the test patterns from cortdeco_tests.jl (using mktempdir, writing binary data with write()).
  </action>
  <verify>
julia --project=. -e 'using Pkg; Pkg.test(test_args=["Binary DEC Parsers Tests"])'
  </verify>
  <done>
All MAPCUT tests pass. Tests cover header parsing, record parsing, and sample file validation.
  </done>
</task>

</tasks>

<verification>
1. `julia --project=. -e 'using DESSEM2Julia; data = parse_mapcut("docs/Sample/DS_ONS_102025_RV3D21/mapcut.rv3"); @assert data.header.num_estagios == 7; @assert data.header.num_rees == 14'`
2. `julia --project=. -e 'using Pkg; Pkg.test()'` - all tests pass
</verification>

<success_criteria>
- MapcutHeader, MapcutRecord, MapcutData types defined with proper fields
- parse_mapcut correctly reads ONS sample header (7 stages, 14 REEs)
- parse_mapcut correctly reads CCEE sample header (39 stages, 156 REEs)
- Tests cover synthetic binary parsing and sample file validation
- All existing tests continue to pass
</success_criteria>

<output>
After completion, create `.planning/quick/002-implement-full-mapcut-parsing/002-SUMMARY.md`
</output>
