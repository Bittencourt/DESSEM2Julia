# DESSEM Format Implementation Notes

This document tracks differences between documented formats and actual file formats found in real DESSEM data.

## TERMDAT.DAT - Thermal Plant Registry

### Summary
Successfully implemented parser for CADUSIT and CADUNIDT records. Parser tested against real CCEE production data (October 2025 case: DS_CCEE_102025_SEMREDE_RV0D28).

**Test Results:**
- ✅ Parsed 98 thermal plants (CADUSIT records)
- ✅ Parsed 387 thermal units (CADUNIDT records)  
- ⚠️ 0 heat curves (CURVACOMB records not present in sample)

### CADUSIT Record Format Differences

**Documentation vs Reality:**

| Field | Documentation | Actual Sample Format | Notes |
|-------|---------------|---------------------|-------|
| `num_units` | Cols 44-46 (I3) | Cols 44-48 (right-aligned) | Values like "1", "20" are right-aligned |
| `heat_rate` | Cols 48-57 (F10.0) | **Not present** | Optional - only in extended format |
| `fuel_cost` | Cols 59-63 (F5.0) | **Not present** | Optional - only in extended format |

**Sample line (48 chars):**
```
CADUSIT   1 ANGRA 1       1 1985 01 01 00 0    1
         10  13         26  29    34  37 40 42 48
```

**Parser Strategy:**
- Base fields always parsed (columns 1-48)
- Optional fields (`heat_rate`, `fuel_cost`) only parsed if line length >= threshold
- Missing fields default to 0.0

### CADUNIDT Record Format Differences

**Documentation vs Reality:**

| Field | Documentation | Actual Sample Format | Notes |
|-------|---------------|---------------------|-------|
| `commission_year` | Cols 29-30 (I2, 2 digits) | Cols 17-20 (I4, 4 digits!) | Major difference |
| `commission_month` | Cols 32-33 | Cols 22-23 | Shifted due to year field |
| `unit_capacity` | Cols 35-41 (F7.0) | Cols 33-43 (F11.3) | Different format, position |
| `min_generation` | Cols 43-49 (F7.0) | Cols 45-54 (F10.3) | Different format, position |
| `min_on_time` | Cols 51-55 (I5) | Cols 56-60 (I5) | Shifted position |
| `min_off_time` | Cols 57-61 (I5) | Cols 62-66 (I5) | Shifted position |
| `cold_startup_cost` | Cols 63-72 (F10.0) | **Not present** | Optional - only in extended format |
| `hot_startup_cost` | Cols 74-83 (F10.0) | **Not present** | Optional |
| `shutdown_cost` | Cols 85-94 (F10.0) | **Not present** | Optional |
| `ramp_up_rate` | Cols 96-105 (F10.0) | **Not present** | Optional |
| `ramp_down_rate` | Cols 107-116 (F10.0) | **Not present** | Optional |
| `unit_name` | Cols 18-27 (A10) | **Not present** | Not in sample format |

**Sample line (66 chars):**
```
CADUNIDT   1  1 2025 04 26 00 0     640.000    520.000   168   168
         10  14  17    22  25  28 31 33         45            56    62
```

**Parser Strategy:**
- Base fields (cols 1-66) always parsed
- Extended fields only parsed if line length > 70 characters
- Missing optional fields default to 0.0 (costs) or Inf (ramp rates)
- Supports both short format (66 chars) and extended format (116+ chars)

### Comment Detection Fix

**Issue:** Original implementation used `startswith(line, "C")` which incorrectly matched data lines like "CADUSIT..."

**Solution:** Changed to exact first-character comparison:
```julia
# Before (buggy):
startswith(stripped, ch)  # Matches "CADUSIT" because it starts with "C"

# After (correct):
first(stripped) == ch[1]  # Only matches if first char is exactly "C"
```

**Comment characters:** `&` (DESSEM files), `*` (generic), `C` (network files)

**Rule:** Comment line must be:
- Just the comment character alone, OR
- Comment character followed by space/tab

This prevents data lines starting with comment characters from being treated as comments.

### Unknown Record Types (Skipped)

The following record types were found in sample files but not yet implemented:
- `CADCONF` - Combined cycle configuration records (~400 lines in sample)
- `CADMIN` - Minimum generation configuration records (~70 lines in sample)

These are correctly skipped with warnings - parser continues successfully.

## HIDR.DAT - Hydroelectric Plant Registry

### Format Discovery

**Status:** ⚠️ **BINARY FORMAT** - Not plain text as documented!

**Evidence:**
- File size: 246,420 bytes (sample with 98 plants)
- Character analysis: 82.9% control characters, 13.3% ASCII text, 3.8% extended ASCII
- Fixed record size: ~2517 bytes per plant (246420 / 98 = 2514.49)
- Hex dump shows: ASCII plant names + IEEE 754 floats + binary integers

**Sample hex dump:**
```
00000000: 00 00 C8 42 41 43 41 52  41 55 20 20 20 20 20 20  ...BACARAU      
00000010: 20 20 20 20 00 00 00 00  01 00 00 00 00 00 00 00      ...........
```

**Implications:**
- Cannot use text-based parser
- Requires binary format reverse engineering OR access to DESSEM source code
- Deferred to future work - focusing on text-based files first

**See:** `docs/Sample/SAMPLE_VALIDATION.md` for detailed analysis

## General Observations

1. **File Format Variability:**
   - Sample files from CCEE use simplified formats
   - Documentation may describe maximal/comprehensive format
   - Production files may omit optional fields to save space

2. **Parser Design Principles:**
   - Always check line length before parsing optional fields
   - Use sensible defaults for missing fields (0.0, Inf)
   - Validate field ranges to catch format errors early
   - Provide clear error messages with file/line context

3. **Testing Strategy:**
   - Test with real production data (CCEE sample)
   - Verify both short and extended formats
   - Check edge cases (minimum values, maximum line lengths)
   - Validate against specification constraints

## References

- Specification: `docs/dessem-complete-specs.md`
- Sample data: `docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/`
- Validation report: `docs/Sample/SAMPLE_VALIDATION.md`
- Implementation: `src/parser/termdat.jl`
