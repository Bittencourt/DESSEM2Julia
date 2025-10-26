# RESPOT.DAT Parser - Next Priority

## Status
**Priority**: HIGH (power reserve constraints - critical for dispatch)  
**Sample Data**: ✅ Available in ONS sample (`DS_ONS_102025_RV2D11/respot.dat`)  
**IDESEM Reference**: https://github.com/rjmalves/idessem/blob/main/idessem/dessem/modelos/respot.py

## File Overview
RESPOT.DAT defines power reserve requirements and limits for system reliability.

## Record Types (from sample inspection)

### 1. RP Record - Reserve Pool Definition
```
RP    1  11  0 0  F           5% CARGA DO SECO+SUL NO CAG SECO
```
**Fields**:
- `RP`: Record identifier
- Index number: `1`
- Month: `11` (November)
- Day: `0`, Hour: `0`, Half: (symbolic date)
- Special marker: `F` (final)
- Description: Text description of reserve requirement

### 2. LM Record - Limit Values
```
LM    1  11  0 0  F            2732
LM    1  11  0 1  F            2632
...
```
**Fields**:
- `LM`: Record identifier  
- Index: `1` (links to RP record)
- Month: `11`
- Day: `0`
- Hour: `0-23`
- Half: `0` or `1` (half-hour indicator)
- Special marker: `F`
- Limit value: `2732` (MW - reserve requirement)

**Pattern**: Half-hourly time series of reserve requirements (48 periods per day)

## Format Notes
- **Fixed-width columns** (not space-separated)
- **StageDateField** pattern (month, day, hour, half, special_marker)
- Time series structure (48 half-hourly values per reserve pool)
- Text descriptions on RP records

## Implementation Strategy

### Step 1: Check IDESEM Reference
```bash
# Visit IDESEM repository
https://github.com/rjmalves/idessem/blob/main/idessem/dessem/modelos/respot.py
```
**Look for**:
- `RegistroRP` class definition (reserve pool)
- `RegistroLM` class definition (limit values)
- Field positions using `LiteralField`, `IntegerField`, `FloatField`
- StageDateField usage

### Step 2: Define Types
Location: `src/types.jl`

```julia
Base.@kwdef struct RespotRP
    index::Int
    month::Int
    day::Union{Int, String}  # Can be "F"
    hour::Union{Int, String}
    half::Union{Int, String}
    description::String
end

Base.@kwdef struct RespotLM
    index::Int
    month::Int
    day::Union{Int, String}
    hour::Int
    half::Int
    limit::Float64
end

Base.@kwdef struct RespotData
    rp_records::Vector{RespotRP} = RespotRP[]
    lm_records::Vector{RespotLM} = RespotLM[]
end
```

### Step 3: Implement Parser
Location: `src/parser/respot.jl`

**Key Functions**:
- `parse_rp_record(line)` - Parse reserve pool definitions
- `parse_lm_record(line)` - Parse limit time series
- `parse_respot(io, filename)` - Main parser

**Fixed-Width Extraction** (verify with IDESEM):
```julia
# Example field positions (VERIFY WITH IDESEM!)
index = parse(Int, strip(extract_field(line, 7, 9)))
month = parse(Int, strip(extract_field(line, 11, 12)))
day_str = strip(extract_field(line, 14, 15))
hour = parse(Int, strip(extract_field(line, 17, 18)))
half = parse(Int, strip(extract_field(line, 20, 20)))
```

### Step 4: Write Tests
Location: `test/respot_tests.jl`

**Test Coverage**:
1. RP record parsing (single record)
2. LM record parsing (single record)
3. Half-hourly time series validation
4. Symbolic date handling ("F" markers)
5. Real ONS data validation (full file)
6. Edge cases (comments, blank lines)

### Step 5: Validate Against Real Data
```julia
# In test file
filepath = "docs/Sample/DS_ONS_102025_RV2D11/respot.dat"
if isfile(filepath)
    result = parse_respot(filepath)
    @test length(result.rp_records) > 0
    @test length(result.lm_records) > 0
    # Validate time series completeness (48 periods per reserve pool)
end
```

## Expected Complexity
- **Low-Medium**: Similar structure to OPERUH.DAT (record type + time series)
- **Format**: Fixed-width columns with StageDateField pattern
- **Validation**: Check half-hourly completeness (48 periods)
- **Time Estimate**: 2-3 hours with IDESEM reference

## Reference Files
- **IDESEM**: `idessem/dessem/modelos/respot.py`
- **Sample**: `docs/Sample/DS_ONS_102025_RV2D11/respot.dat`
- **Spec**: `docs/dessem-complete-specs.md` (search for RESPOT section)

## Success Criteria
- [ ] All field positions verified against IDESEM
- [ ] RP and LM record types implemented
- [ ] Tests passing (synthetic + real ONS data)
- [ ] Half-hourly time series validated (48 periods)
- [ ] 100% test coverage achieved

## Notes
- Power reserves are critical for system reliability
- Half-hourly granularity matches dispatch resolution
- Reserve pools can span multiple subsystems (e.g., "SECO+SUL")
- Similar pattern to OPERUH constraints (record type + time series)
