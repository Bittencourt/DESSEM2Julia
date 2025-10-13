# Quick Start Guide for New Contributors

**⏱️ 5-Minute Orientation**

---

## 🎯 What Is This Project?

Parse Brazilian power system DESSEM files (32 complex text/binary formats) into clean Julia objects.

**Status**: 5/32 parsers complete, 2,513+ tests passing

---

## 🏆 Most Important Rule

### ⭐ ALWAYS CHECK IDESEM FIRST! ⭐

**IDESEM** = Python reference library with all format specifications  
**URL**: https://github.com/rjmalves/idessem  
**Why**: Saves hours of debugging (proven in Session 6!)

**Example**:
```python
# IDESEM: idessem/dessem/modelos/operut.py
LiteralField(12, 4)  # Python 0-indexed

# Convert to Julia 1-indexed: add 1 to start
extract_field(line, 5, 16)  # Julia 1-indexed
```

---

## 📂 Key Files

| File | Purpose |
|------|---------|
| `docs/planning/PROJECT_CONTEXT.md` | **READ THIS FIRST** - Complete context |
| `docs/planning/TASKS.md` | Current progress & priorities |
| `src/parser/operut.jl` | Best example parser (latest) |
| `test/operut_tests.jl` | Best example tests (72 tests) |
| `docs/parsers/OPERUT_IMPLEMENTATION.md` | Complete implementation guide |
| `docs/type_system.md` | Type system guide |
| `docs/FORMAT_NOTES.md` | Format quirks & discoveries |

---

## 🚀 Implementing Your First Parser

### 1. Research (30 min)

```bash
# Check IDESEM for format
https://github.com/rjmalves/idessem/blob/main/idessem/dessem/modelos/<filename>.py
```

### 2. Define Types (15 min)

```julia
# src/types.jl
@kwdef struct XxxRecord
    field1::Int
    field2::String
    optional_field::Union{Float64, Nothing} = nothing
end

@kwdef struct XxxData
    records::Vector{XxxRecord} = XxxRecord[]
end
```

### 3. Implement Parser (1-2 hours)

```julia
# src/parser/xxx.jl
module XxxParser
using ..DESSEM2Julia: XxxRecord, XxxData, extract_field, parse_int

function parse_xxx_record(line::String)
    # Use IDESEM column positions!
    field1 = parse_int(extract_field(line, 1, 5))
    field2 = strip(extract_field(line, 7, 20))
    return XxxRecord(field1, field2)
end

function parse_xxx(io::IO, filepath::String)
    records = XxxRecord[]
    for line in eachline(io)
        is_comment(line) && continue
        is_blank(line) && continue
        
        record = parse_xxx_record(line)
        push!(records, record)
    end
    return XxxData(records)
end

export parse_xxx
end
```

### 4. Write Tests (1 hour)

```julia
# test/xxx_tests.jl
@testset "XXX Parser" begin
    @testset "Single Record" begin
        line = "  123  field2_value"
        record = parse_xxx_record(line)
        @test record.field1 == 123
    end
    
    @testset "Real CCEE Data" begin
        path = "docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/xxx.dat"
        result = open(io -> parse_xxx(io, path), path)
        @test length(result.records) > 0
    end
end
```

### 5. Document (30 min)

Update these files:
- `docs/FORMAT_NOTES.md` - Format specs & quirks
- `docs/planning/TASKS.md` - Mark as complete

---

## ⚡ Common Patterns

### Fixed-Width Extraction (Most Common!)

```julia
# If IDESEM uses LiteralField(size, start):
plant_name = strip(extract_field(line, 5, 16))  # FIXED 12 chars

# Don't use split() if fields contain spaces!
# ❌ parts = split(line)  # Fails with "ANGRA 1"
# ✅ extract_field(line, start, end)
```

### Optional Fields

```julia
# Return nothing for missing fields
field_str = strip(extract_field(line, 10, 20))
optional_value = isempty(field_str) ? nothing : parse_float(field_str)
```

### Block Structure

```julia
in_block = false
for line in eachline(io)
    if occursin(r"^\s*INIT", line)
        in_block = true; continue
    end
    if occursin(r"^\s*FIM", line)
        in_block = false; continue
    end
    
    in_block && push!(records, parse_record(line))
end
```

---

## 🎯 Next Parser Priorities

1. **DADVAZ.DAT** - Natural inflows (high priority)
2. **DEFLANT.DAT** - Previous flows (high priority)
3. **HIDR.DAT** - Hydro registry (**BINARY FORMAT!** - challenging)

Check `docs/planning/TASKS.md` for full list.

---

## 🧪 Testing Commands

```bash
# Run all tests
julia --project=. test/runtests.jl

# Run specific parser tests
julia --project=. test/xxx_tests.jl

# Setup git hooks (auto-test on commit)
.\scripts\setup-hooks.ps1
```

---

## 📚 Sample Data

**Real DESSEM cases** for testing:
- `docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/` - CCEE (simpler)
- `docs/Sample/DS_ONS_102025_RV2D11/` - ONS (network-enabled)

**Always test with real data!** Synthetic tests aren't enough.

---

## 🐛 Top 3 Mistakes to Avoid

### 1. Not Checking IDESEM
**Result**: Hours of debugging already-solved problems  
**Solution**: Check IDESEM first, every time!

### 2. Using split() on Fixed-Width Formats
**Result**: Fails when field values contain spaces  
**Solution**: Use `extract_field(line, start, end)` for fixed-width

### 3. Testing Only Synthetic Data
**Result**: Parser works on test data, fails on real files  
**Solution**: Validate with real CCEE/ONS samples

---

## 💡 Pro Tips

1. **Convert IDESEM positions**: Python 0-indexed → Julia 1-indexed (add 1)
2. **Document quirks immediately**: Future you will thank you
3. **Write tests incrementally**: Test as you implement
4. **Check for binary formats**: HIDR.DAT is binary, not text!
5. **Handle special values**: "F" for final, 99.9 for infinity, etc.

---

## 🔗 Essential Links

| Resource | URL |
|----------|-----|
| IDESEM | https://github.com/rjmalves/idessem |
| Complete Context | `docs/planning/PROJECT_CONTEXT.md` |
| Tasks & Progress | `docs/planning/TASKS.md` |
| Example Parser | `src/parser/operut.jl` |
| Example Tests | `test/operut_tests.jl` |

---

## ✅ Pre-Flight Checklist

Before you start:
- [ ] Read `PROJECT_CONTEXT.md` (at least skim it!)
- [ ] Check IDESEM for your target file
- [ ] Understand the format (fixed-width? blocks? binary?)
- [ ] Look at `operut.jl` example
- [ ] Have real sample data ready for testing

---

## 🚀 You're Ready!

1. Pick a parser from `TASKS.md`
2. Check IDESEM for format
3. Follow the 5-step workflow above
4. Test with real data
5. Document your findings
6. Celebrate! 🎉

**Questions?** Check `PROJECT_CONTEXT.md` for detailed explanations.

**Remember**: IDESEM is your friend! 🏆

---

**Good luck! You've got this! 💪**
