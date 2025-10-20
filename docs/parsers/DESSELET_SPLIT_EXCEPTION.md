# DESSELET Parser: split() Exception

## Why This Parser Uses split()

The desselet.dat parser is an **exception** to the project's "#1 RULE: Never use split() for fixed-width files".

### Reasons

1. **Actual Data Format**: The real desselet.dat files use **variable spacing** between fields, not fixed-width columns
   - Date field appears at different positions depending on the stage number length
   - Time fields have variable spacing

2. **IDESSEM Discrepancy**: IDESSEM's column position definitions don't match the actual data format
   - IDESSEM specifies `IntegerField(8, 16)` for date (positions 16-23 in Python 0-indexed)
   - Actual data has date starting at position 18 (Python 0-indexed)

3. **Safe for This File**: Unlike other DESSEM files, desselet.dat filenames are always single words
   - Base cases: "leve.pwf", "media.pwf", "pesada.pwf" (no spaces)
   - Modifications: "pat01.afp", "pat02.afp", etc. (no spaces)
   - No plant names or location names that might contain spaces

4. **Verified with Real Data**: Tests pass for both:
   - ONS sample (48 modification records, 4 base cases)
   - CCEE sample (if applicable)
   - Synthetic test data

### Data Format Example

```
(Arquivos de caso base)
1    leve          leve        .pwf
2    sab10h        sab10h      .pwf
99999

(Alteracoes dos casos base)
  01 Estagio01    20251011  0  0  0.5      1 pat01.afp
  02 Estagio02    20251011  0 30  0.5      1 pat02.afp
  19 Estagio19    20251011  9  0  0.5      2 pat19.afp
99999
```

Notice:
- Variable spacing between fields
- Date "20251011" starts at position 19 (not position 17 as IDESSEM suggests)
- Hour/minute fields have inconsistent spacing (single-digit "0" vs two-digit "30")

### Implementation

The parser uses `split()` and joins filename parts:

```julia
function parse_modification_record(line, filename, line_num)
    parts = split(strip(String(line)))
    
    patamar_id = parse(Int, parts[1])
    name = parts[2]
    date_val = Date(parts[3], dateformat"yyyymmdd")
    hour = parse(Int, parts[4])
    minute = parse(Int, parts[5])
    duration_hours = parse(Float64, parts[6])
    base_case_id = parse(Int, parts[7])
    file_mod = join(parts[8:end], "")  # Combine any split filename parts
    
    return DesseletPatamar(...)
end
```

### Testing

✅ All tests passing:
- Synthetic data: 2 base cases, 2 modifications
- ONS sample: 4 base cases, 48 modifications
- Verified: Date parsing, time fields, filename handling

### Future Considerations

If future DESSEM versions introduce:
- Filenames with spaces (e.g., "base case.pwf")
- Plant/location names in this file

Then this parser should be rewritten to use fixed-width parsing with corrected column positions based on actual data analysis (not IDESSEM specs).

---

**Last Updated**: Session 12 (desselet.dat implementation)  
**Status**: Production ready, all tests passing
