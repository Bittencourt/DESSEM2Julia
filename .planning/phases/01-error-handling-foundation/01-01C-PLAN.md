---
phase: 01-error-handling-foundation
plan: 01C
type: execute
wave: 1
depends_on: []
files_modified:
  - src/parser/hidr_binary.jl
  - src/parser/pwf.jl
autonomous: true

must_haves:
  truths:
    - "hidr_binary.jl throws ParserError for file not found"
    - "pwf.jl throws ParserError for all parsing failures"
    - "pwf.jl eliminates @warn + continue patterns"
    - "ParserError includes file path, line number, and line content"
  artifacts:
    - path: "src/parser/hidr_binary.jl"
      provides: "Binary HIDR parser with ParserError handling"
      contains: "throw(ParserError"
    - path: "src/parser/pwf.jl"
      provides: "Network file parser with ParserError handling"
      contains: "throw(ParserError"
  key_links:
    - from: "error() and @warn call sites"
      to: "ParserError struct"
      via: "throw(ParserError(msg, file, line_num, line))"
      pattern: "throw\\(ParserError\\("
---

<objective>
Replace all error() and @warn calls with throw(ParserError(...)) across hidr_binary.jl and pwf.jl.

Purpose: Users should catch ParserError (not ErrorException) for all parsing failures, with file/line context.
Output: 2 parser files using ParserError consistently.

**Note:** This is part 3 of 3 split from original Plan 01-01 (hidr_binary.jl, pwf.jl).
</objective>

<execution_context>
@~/.config/opencode/get-shit-done/workflows/execute-plan.md
@~/.config/opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/01-error-handling-foundation/01-RESEARCH.md

# Reference Implementations
# - idessem: https://github.com/rjmalves/idessem (DESSEM parsing reference)
# - inewave: https://github.com/rjmalves/inewave (NEWAVE parsing reference, related ecosystem)
# - PWF.jl: https://github.com/Bittencourt/PWF.jl (PWF network file parser - direct dependency)
# - sintetizador-dessem: https://github.com/rjmalves/sintetizador-dessem (synthetic data generator)
#
# When modifying pwf.jl error handling, verify alignment with PWF.jl library patterns.
# The PWF.jl dependency provides the core PWF parsing functionality.

# ParserError struct definition (correct argument order)
# struct ParserError <: Exception
#     msg::String      # FIRST: Error message
#     file::String     # SECOND: File path
#     line::Int        # THIRD: Line number
#     content::String  # FOURTH: Line content
# end
</context>

<tasks>

<task type="auto">
  <name>Replace error() call in hidr_binary.jl</name>
  <files>src/parser/hidr_binary.jl</files>
  <action>
Replace 1 error() call (line 211):

```julia
# BEFORE:
error("File not found: $filepath")

# AFTER:
throw(ParserError("File not found: $filepath", filepath, 0, ""))
```

Note: For file not found, line number is 0 and content is empty.
  </action>
  <verify>grep -c "error(" src/parser/hidr_binary.jl returns 0</verify>
  <done>error() call in hidr_binary.jl replaced with throw(ParserError(...))</done>
</task>

<task type="auto">
  <name>Replace error() and @warn calls in pwf.jl</name>
  <files>src/parser/pwf.jl</files>
  <action>
Replace 4 error() calls (lines 100, 266, 360, 370) AND 2 @warn patterns (lines 198, 213).

**error() replacements:**
```julia
# Line 100 - catch block:
# BEFORE:
error("Failed to parse PWF file '$filepath': $e")

# AFTER:
if isa(e, ParserError)
    rethrow(e)
else
    throw(ParserError("Failed to parse PWF file: $(sprint(showerror, e))", filepath, 0, ""))
end
```

**@warn replacements (lines 198, 213):**
```julia
# BEFORE:
@warn "Failed to convert bus data" bus_data exception = e

# AFTER:
if isa(e, ParserError)
    rethrow(e)
else
    throw(ParserError("Failed to convert bus data: $(sprint(showerror, e))", filepath, line_num, string(bus_data)))
end
```

CRITICAL: 
- ParserError argument order is (msg, file, line, content)
- Remove @warn + continue patterns - they must throw instead
  </action>
  <verify>
grep -c "error(" src/parser/pwf.jl returns 0
grep -c "@warn" src/parser/pwf.jl returns 0
  </verify>
  <done>All error() and @warn calls in pwf.jl replaced with throw(ParserError(...))</done>
</task>

</tasks>

<verification>
1. Run `grep -r "error(" src/parser/hidr_binary.jl src/parser/pwf.jl | grep -v "ParserError" | grep -v "showerror"` - should return empty
2. Run `grep -r "@warn" src/parser/pwf.jl` - should return empty
3. Run `julia --project -e 'using Pkg; Pkg.test()'` - all tests should pass
4. Verify error messages include file path and line number when parsing fails
</verification>

<success_criteria>
- Zero error() calls in modified parser files (except ParserError/showerror)
- Zero @warn patterns in pwf.jl
- All parsers throw ParserError with file/line context
- Existing tests continue to pass
</success_criteria>

<output>
After completion, create `.planning/phases/01-error-handling-foundation/01-01C-SUMMARY.md`
</output>
