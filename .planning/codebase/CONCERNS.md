# Codebase Concerns

**Analysis Date:** 2026-02-18

## Tech Debt

**Validation Error Handling Inconsistency:**
- Issue: Some validators throw `MethodError` instead of `ParserError`, breaking error handling patterns
- Files: `test/termdat_tests.jl` lines 168, 224 (commented out tests)
- Impact: Tests for validation edge cases cannot run; users may get confusing error messages
- Fix approach: Update validators in `src/parser/termdat.jl` to throw consistent `ParserError` exceptions

**Inconsistent Error Handling Across Parsers:**
- Issue: Mixed use of `error()`, `throw(ParserError())`, and `@warn` + return patterns
- Files: `src/parser/simul.jl` (uses `error()`), `src/parser/hidr.jl` (uses `throw(ParserError())`), `src/parser/operuh.jl` (uses `@warn` + return `nothing`)
- Impact: Inconsistent error behavior; some failures silently return `nothing` while others throw
- Fix approach: Standardize on `ParserError` for parsing failures; use `ArgumentError` for invalid arguments

**Incomplete Binary Type Definitions:**
- Issue: Three binary record types store only raw bytes with TODO comments
- Files: `src/models/core_types.jl` lines 803, 823, 843
- Impact: Cannot access structured data from INFOFCF.DEC, MAPCUT.DEC, CORTES.DEC files
- Fix approach: Define proper fields when binary specifications become available from CEPEL

**Deprecated SIMUL Parser:**
- Issue: SIMUL parser exists but removed from test suite with comment "legacy/deprecated, no production samples exist"
- Files: `test/runtests.jl` line 19 (commented out), `src/parser/simul.jl`
- Impact: Dead code that still ships; may confuse users
- Fix approach: Either remove or document clearly as deprecated with migration path

## Known Bugs

**Capacity Validation Throwing Wrong Exception:**
- Symptoms: `parse_cadunidt()` throws `MethodError` instead of `ParserError` when `min_generation > capacity`
- Files: `src/parser/termdat.jl` (validation logic), `test/termdat_tests.jl` lines 168-172
- Trigger: Parse a CADUNIDT record with `min_generation > capacity`
- Workaround: Test is commented out; validation may not be enforced

**Heat Rate Validation Disabled:**
- Symptoms: Invalid heat rate values (zero, negative) may not be caught
- Files: `test/termdat_tests.jl` lines 224-235 (commented out)
- Trigger: Parse CURVACOMB record with invalid heat rate
- Workaround: None; validation tests disabled

## Security Considerations

**Unsanitized File Path Handling:**
- Risk: File paths passed directly to `open()`, `isfile()`, `read()` without validation
- Files: All parsers in `src/parser/*.jl`, especially `src/parser/hidr.jl` line 561, `src/parser/dadvaz.jl`
- Current mitigation: Files are typically read-only data files; not user-generated
- Recommendations:
  - Validate paths don't contain directory traversal (`..`)
  - Consider using `realpath()` to resolve symlinks
  - Document that parsers expect trusted input

**Binary File Size Validation:**
- Risk: Large or malformed binary files could cause memory exhaustion
- Files: `src/parser/hidr_binary.jl`, `src/parser/binary_dec.jl`, `src/parser/cortdeco.jl`
- Current mitigation: Some size checks exist (e.g., `hidr_binary.jl` line 308 warns on non-multiple sizes)
- Recommendations: Add maximum file size limits; fail fast on obviously corrupt files

## Performance Bottlenecks

**Large Types File Compilation:**
- Problem: `src/types.jl` is 3,114 lines; long compile times when modified
- Files: `src/types.jl`
- Cause: All types in single module; Julia must recompile entire module
- Improvement path: Split into logical sub-modules (e.g., HydroTypes.jl, ThermalTypes.jl, NetworkTypes.jl)

**File Re-reading in Tests:**
- Problem: Multiple tests read same ONS sample files repeatedly
- Files: `test/ons_integration_tests.jl`, multiple `test/*_tests.jl`
- Cause: Each test file reads files independently; no caching
- Improvement path: Use module-level cached fixtures for expensive file reads

## Fragile Areas

**Silent Failures with @warn Logging:**
- Files: `src/parser/operuh.jl` lines 114, 151, 191, 235 - returns `nothing` on parse failure
- Why fragile: Invalid records silently skipped; caller must check for `nothing`
- Safe modification: Return empty result vectors; throw `ParserError` for truly malformed data
- Test coverage: Partial - tests exist but skip when sample files missing

**Unknown Record Type Handling:**
- Files: `src/parser/hidr.jl` line 635, `src/parser/termdat.jl` line 534, `src/parser/entdados.jl` line 1674
- Why fragile: `@warn` used for unknown record types; data silently ignored
- Safe modification: Make behavior configurable (warn vs. error vs. collect for later review)
- Test coverage: No tests for unknown record type scenarios

**PWF Parser Error Handling:**
- Files: `src/parser/pwf.jl` lines 198, 213 - catches and logs exceptions, continues processing
- Why fragile: Malformed bus/branch data silently skipped
- Safe modification: Collect parsing errors for summary; option to fail on any error
- Test coverage: Partial coverage in `test/pwf_tests.jl`

## Scaling Limits

**In-Memory Data Model:**
- Current capacity: All file data loaded into memory; works for single DESSEM case
- Limit: Large multi-case analyses may exceed memory; ~100+ simultaneous cases could be problematic
- Scaling path: Implement streaming/chunked parsing for large files; lazy loading for optional data

**Single-Threaded Parsing:**
- Current capacity: Parsers process files sequentially
- Limit: Large case directories with 30+ files take noticeable time
- Scaling path: Parallel file parsing using Julia's `Threads.@spawn` or `Distributed`

## Dependencies at Risk

**Limited CI Testing:**
- Risk: CI only tests Julia 1.11; compatibility with 1.6-1.10 claimed but not verified
- Files: `.github/workflows/ci.yml` line 47 - single version matrix
- Impact: Breaking changes on older Julia versions may go undetected
- Migration plan: Expand CI matrix to test minimum (1.6) and current LTS (1.10) versions

**JLD2 Version Range:**
- Risk: Broad compatibility range (`0.4, 0.5`) may allow breaking changes
- Files: `Project.toml` line 21
- Impact: Saved JLD2 files may not be readable with newer JLD2 versions
- Migration plan: Pin to specific tested version; implement migration tests for saved files

**GraphPlot Dependency:**
- Risk: Visualization dependency adds weight for users who don't need plotting
- Files: `Project.toml` lines 11-12 (GraphPlot, Compose)
- Impact: Longer install times; potential conflicts with user's environment
- Migration plan: Move visualization to optional extension/package

## Missing Critical Features

**No Batch Processing API:**
- Problem: No high-level API for processing multiple DESSEM cases
- What's missing: Directory scanning, batch parsing, result aggregation
- Blocks: Users cannot efficiently analyze historical case libraries

**No Data Validation Layer:**
- Problem: Parsers extract data but don't validate business rules (e.g., plant capacities match across files)
- What's missing: Cross-file consistency checks, referential integrity validation
- Blocks: Invalid data may pass parsing but fail optimization

**No Write Support:**
- Problem: Parsers only read DESSEM files; cannot write modified data back
- What's missing: Serialization to DESSEM format; file generation
- Blocks: Cannot use for case modification workflows

## Test Coverage Gaps

**Parsers Without Dedicated Tests:**
- What's not tested: `registry.jl` (internal module, 28 lines), `hidr_binary.jl` (tested via `hidr_tests.jl`)
- Files: `src/parser/registry.jl`, `src/parser/hidr_binary.jl`
- Risk: Registry corruption could break parser lookup; binary parsing edge cases untested
- Priority: Medium

**Sample File Dependencies:**
- What's not tested: Many tests skip when ONS/CCEE sample files not present
- Files: `test/ons_integration_tests.jl` lines 18, 50, 81, 125, etc. - 25+ skip points
- Risk: Tests pass locally but may fail in different environments
- Priority: High - use synthetic test data for critical paths

**Error Path Testing:**
- What's not tested: Most error handling paths only have happy-path tests
- Files: Limited `@test_throws` usage across test files
- Risk: Error messages may be unhelpful; edge cases may crash instead of throwing
- Priority: Medium

## Code Quality Concerns

**Large Files Difficult to Maintain:**
- Files: `src/types.jl` (3,114 lines), `src/parser/entdados.jl` (1,735 lines), `src/models/core_types.jl` (1,208 lines)
- Impact: High cognitive load for contributors; slow IDE navigation; merge conflicts likely
- Recommendation: Split into focused modules

**Commented-Out Tests:**
- Files: `test/termdat_tests.jl` lines 169-172, 226-239
- Impact: Disabled tests signal known issues but provide no enforcement
- Recommendation: Create GitHub issues for each; either fix or document as accepted limitation

**Manual Cleanup Files:**
- Files: `MANUAL_ACTIONS_NEEDED.md`, `ISSUE_18_CLOSURE_SUMMARY.md` in project root
- Impact: Clutter; suggests incomplete process automation
- Recommendation: Remove after issues resolved; automate future cleanup

---

*Concerns audit: 2026-02-18*
