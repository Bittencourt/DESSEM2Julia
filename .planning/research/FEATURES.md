# Feature Research

**Domain:** Data Parser/Validator Library (Fixed-width & Binary files)
**Researched:** 2026-02-18
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Typed field extraction** | Parsers must convert text to appropriate types (Int, Float, String, Date) | LOW | Already have FieldSpec system |
| **Error with file/line context** | Users need to locate the source of parsing errors | LOW | Already have ParserError with location |
| **Required vs optional fields** | Not all fields are mandatory; defaults needed for blanks | LOW | Already in FieldSpec (required, default) |
| **Value range validation** | Numbers often have valid ranges (e.g., hour 0-23) | LOW | Already have validate_range, validate_positive |
| **Multiple file format support** | Real datasets span multiple file types | MEDIUM | Already have 32+ parsers |
| **Serialize to standard format** | Parsed data must be persistable | LOW | Already have JLD2 output |
| **Silent failure handling** | Parser shouldn't crash on unknown files | LOW | Current fallback stores raw content |
| **Basic documentation** | Users need to know what types exist and how to use API | MEDIUM | Needed for v1.0 release |
| **Consistent error types** | Single exception type for all parsing errors | MEDIUM | Need to standardize ParserError everywhere |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Cross-file referential integrity** | Validate that IDs referenced in one file exist in another (e.g., thermal plant ID in OPERUT exists in TERMDAT) | HIGH | Critical for data quality; most parsers skip this |
| **Lazy validation with error aggregation** | Collect ALL validation errors before reporting, not fail-fast | MEDIUM | Pydantic/pandera pattern; better DX for debugging |
| **Structured error reports** | Errors grouped by category (SCHEMA vs DATA), with failure cases | MEDIUM | Like pandera's error reports; programmatic access |
| **Custom validation rules** | User-provided validation functions beyond type/range checks | MEDIUM | Extensibility hook; validators receive parsed data |
| **Validation severity levels** | Distinguish errors (must fix) from warnings (anomalies but valid) | LOW | Some inconsistencies are data quirks, not errors |
| **Schema inference** | Auto-detect field types/widths from sample data | HIGH | Useful for new file versions; reduces maintenance |
| **Data summary/reports** | Quick statistics on parsed data (row counts, value ranges, missing fields) | LOW | Helps users understand their data |
| **Streaming/chunked parsing** | Handle large files without loading entirely into memory | MEDIUM | Important for production workloads |
| **Round-trip verification** | Serialize back to original format, compare byte-for-byte | MEDIUM | Confidence that parsing captured everything |
| **Version-aware parsing** | Handle format changes across DESSEM versions gracefully | HIGH | Reduce breakage when CEPEL updates formats |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Write support (creating DESSEM files)** | Users want to modify data and write back | Requires CEPEL format specs we don't have; liability if files break production runs | Keep read-only; provide data transformation utilities |
| **Automatic format detection** | "Just figure out what file this is" | Ambiguous; leads to silent mis-parsing | Require explicit file-type registration or naming convention |
| **Silent coercion with logging** | "Fix the data and tell me what you changed" | Hides data quality issues; downstream depends on "fixed" behavior | Fail explicitly; let user decide how to handle anomalies |
| **Parallel parsing by default** | "Make it faster" | Adds complexity; file dependencies require ordering; race conditions | Offer as opt-in after single-threaded correctness proven |
| **Legacy format support** | "We have old data" | CEPEL changes formats; supporting all versions is unmaintainable | Support current version; provide migration utilities |
| **GUI/file browser** | "Easier to explore data" | Out of scope for a parsing library; creates maintenance burden | Provide good programmatic API; suggest external tools |
| **Database output** | "Store directly in PostgreSQL" | Adds heavy dependencies; schema migration complexity | Output to JLD2/DataFrames; users handle persistence |

## Feature Dependencies

```
Typed Field Extraction
    └──requires──> Error with file/line context

Cross-File Referential Integrity
    └──requires──> Typed Field Extraction (all files parsed first)
    └──requires──> Consistent Error Types

Lazy Validation
    └──requires──> Consistent Error Types
    └──enhances──> Cross-File Referential Integrity (collect all issues)

Structured Error Reports
    └──requires──> Lazy Validation
    └──requires──> Consistent Error Types

Custom Validation Rules
    └──requires──> Typed Field Extraction
    └──enhances──> Cross-File Referential Integrity (user-defined checks)

Schema Inference
    └──conflicts──> Explicit FieldSpec (different paradigm)

Streaming Parsing
    └──conflicts──> Cross-File Referential Integrity (needs all data)
```

### Dependency Notes

- **Cross-File Referential Integrity requires Typed Field Extraction:** Can't validate foreign keys until all files are parsed with correct types
- **Lazy Validation enhances Cross-File Referential Integrity:** Collect integrity violations across all files before reporting
- **Structured Error Reports requires Lazy Validation:** Error reports aggregate multiple failures; lazy mode collects them
- **Custom Validation Rules enhances Cross-File Referential Integrity:** Users can add domain-specific integrity checks
- **Schema Inference conflicts with Explicit FieldSpec:** Different philosophies; inference is for unknown formats, FieldSpec is for known formats
- **Streaming Parsing conflicts with Cross-File Referential Integrity:** Can't validate cross-file references without holding all data

## MVP Definition

### Launch With (v1.0)

Minimum viable product — what's needed to validate the concept.

- [x] **Typed field extraction** — Core functionality; already implemented
- [x] **Error with file/line context** — Already have ParserError
- [ ] **Consistent error types everywhere** — Standardize on ParserError across all parsers (in progress)
- [ ] **Cross-file referential integrity (basic)** — Validate that referenced IDs exist (critical for trust)
- [ ] **Lazy validation** — Collect multiple errors before failing
- [ ] **Structured error reports** — Programmatic access to all errors
- [ ] **API documentation** — Users need to know what's available

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] **Validation severity levels** — Distinguish errors from warnings
- [ ] **Custom validation rules API** — User-extensible validation hooks
- [ ] **Data summary/reports** — Quick data quality overview
- [ ] **Streaming parsing (opt-in)** — For large file handling
- [ ] **Round-trip verification** — Confidence in parsing accuracy

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Schema inference** — For unknown/new file formats
- [ ] **Version-aware parsing** — Handle format evolution
- [ ] **Batch processing API** — Multiple cases at once

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Consistent error types | HIGH | LOW | P1 |
| Cross-file referential integrity | HIGH | MEDIUM | P1 |
| Lazy validation | HIGH | MEDIUM | P1 |
| Structured error reports | HIGH | MEDIUM | P1 |
| API documentation | HIGH | MEDIUM | P1 |
| Validation severity levels | MEDIUM | LOW | P2 |
| Custom validation rules | MEDIUM | MEDIUM | P2 |
| Data summary/reports | MEDIUM | LOW | P2 |
| Streaming parsing | LOW | MEDIUM | P3 |
| Schema inference | LOW | HIGH | P3 |
| Version-aware parsing | LOW | HIGH | P3 |

**Priority key:**
- P1: Must have for launch (v1.0)
- P2: Should have, add when possible (v1.x)
- P3: Nice to have, future consideration (v2+)

## Competitor Feature Analysis

| Feature | Pydantic | Pandera | Marshmallow | Serde | Our Approach |
|---------|----------|---------|-------------|-------|--------------|
| Type validation | ✓ type hints | ✓ dtypes | ✓ fields | ✓ traits | ✓ FieldSpec |
| Custom validators | ✓ @validator | ✓ Check | ✓ validates_schema | ✓ custom | Partial (need API) |
| Lazy validation | ✓ model_validate | ✓ lazy=True | Partial | ✗ | Need to add |
| Error location | ✓ loc tuple | ✓ column/index | ✓ field name | ✗ | ✓ file:line |
| Cross-field validation | ✓ model validators | ✓ dataframe checks | ✓ schema validation | ✗ | Need to add |
| Nested structures | ✓ Nested | ✓ Struct | ✓ Nested | ✓ nested | ✓ in types |
| Severity levels | ✗ | ✗ | ✗ | ✗ | Differentiator |
| Referential integrity | ✗ | ✗ | ✗ | ✗ | Differentiator |

## Validation Feature Patterns

### Pattern 1: Fail-Fast vs Lazy Validation

**Pydantic/pandera approach:**
- Default: fail on first error
- Opt-in: `lazy=True` to collect all errors
- Best practice: Lazy mode for development, fail-fast for production

**Recommendation:** Implement lazy mode as opt-in via `validate(data; lazy=true)`

### Pattern 2: Error Information Structure

**Pydantic ErrorDetails:**
```python
{
    'type': 'int_parsing',      # Machine-readable
    'loc': ('field', 'nested'),  # Location path
    'msg': '...',               # Human-readable
    'input': 'bad_value',       # What was provided
    'url': 'https://...'        # Documentation link
}
```

**Recommendation:** Our ParserError should include:
- `type::Symbol` (e.g., `:missing_field`, `:type_error`, `:range_violation`)
- `file::String`, `line::Int` (location)
- `field::Symbol` (field name)
- `msg::String` (human message)
- `input::Any` (actual value)
- `expected::String` (what was expected)

### Pattern 3: Cross-File Validation

**Pattern:** Parse all files first, then run cross-file validators with access to all data.

**Example rules for DESSEM:**
- Thermal plant IDs in OPERUT must exist in TERMDAT CADUSIT
- Hydro plant IDs in OPERUH must exist in HIDR
- Bus IDs in network files must exist in ENTDADOS
- Subsystem codes must be consistent across all files

**Implementation:**
```julia
# After all files parsed
function validate_integrity(data::DessemData)
    errors = ValidationError[]
    
    # Check thermal plant references
    thermal_ids = Set(data["TERMDAT.DAT"].plants .|> p -> p.code)
    for unit in data["OPERUT.DAT"].units
        if unit.plant_code ∉ thermal_ids
            push!(errors, ValidationError(...))
        end
    end
    
    # ... more checks
    
    return errors
end
```

## Sources

- Pydantic documentation (https://docs.pydantic.dev/latest/) - HIGH confidence
- Pandera documentation (https://pandera.readthedocs.io/en/stable/) - HIGH confidence
- Serde documentation (https://serde.rs/) - HIGH confidence
- Marshmallow documentation (https://marshmallow.readthedocs.io/en/stable/) - HIGH confidence
- DESSEM2Julia codebase analysis - HIGH confidence

---
*Feature research for: Data Parser/Validator Library*
*Researched: 2026-02-18*
