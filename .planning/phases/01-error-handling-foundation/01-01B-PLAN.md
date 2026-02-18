---
phase: 01-error-handling-foundation
plan: 01B
type: execute
wave: 1
depends_on: []
files_modified:
  - src/parser/dadvaz.jl
  - src/parser/desselet.jl
  - src/parser/cortdeco.jl
autonomous: true

must_haves:
  truths:
    - "dadvaz.jl throws ParserError for all validation failures"
    - "desselet.jl throws ParserError for all parsing failures"
    - "cortdeco.jl throws ParserError for all validation failures"
    - "ParserError includes file path, line number, and line content"
  artifacts:
    - path: "src/parser/dadvaz.jl"
      provides: "Flow data parser with ParserError handling"
      contains: "throw(ParserError"
    - path: "src/parser/desselet.jl"
      provides: "Electrical data parser with ParserError handling"
      contains: "throw(ParserError"
    - path: "src/parser/cortdeco.jl"
      provides: "FCF cuts parser with ParserError handling"
      contains: "throw(ParserError"
  key_links:
    - from: "error() call sites"
      to: "ParserError struct"
      via: "throw(ParserError(msg, file, line_num, line))"
      pattern: "throw\\(ParserError\\("
---

<objective>
Replace all error() calls with throw(ParserError(...)) across dadvaz.jl, desselet.jl, and cortdeco.jl.

Purpose: Users should catch ParserError (not ErrorException) for all parsing failures, with file/line context.
Output: 3 parser files using ParserError consistently.

**Note:** This is part 2 of 3 split from original Plan 01-01 (dadvaz.jl, desselet.jl, cortdeco.jl).
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
# - sintetizador-dessem: https://github.com/rjmalves/sintetizador-dessem (synthetic data generator)
#
# These provide patterns for error handling and parser structure.
# When modifying parsers, verify alignment with idessem/inewave patterns.

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
  <name>Replace error() calls in dadvaz.jl</name>
  <files>src/parser/dadvaz.jl</files>
  <action>
Replace ~14 error() calls with throw(ParserError(...)).

These are mostly validation checks (lines 57-199):
```julia
# BEFORE:
start_day === nothing && error("Missing start day in DADVAZ record")

# AFTER:
start_day === nothing && throw(ParserError("Missing start day in DADVAZ record", filename, line_num, line))
```

For the header parsing section, ensure filename and line context are available. Pass them through function arguments if needed.

CRITICAL: ParserError argument order is (msg, file, line, content).
  </action>
  <verify>grep -c "error(" src/parser/dadvaz.jl returns 0</verify>
  <done>All error() calls in dadvaz.jl replaced with throw(ParserError(...))</done>
</task>

<task type="auto">
  <name>Replace error() calls in desselet.jl</name>
  <files>src/parser/desselet.jl</files>
  <action>
Replace 3 error() calls (lines 38, 68, 78) with throw(ParserError(...)).

```julia
# BEFORE:
error("Invalid base case line at $line_num: requires at least 3 fields")

# AFTER:
throw(ParserError("Invalid base case line: requires at least 3 fields", filename, line_num, line))
```

CRITICAL: ParserError argument order is (msg, file, line, content).
  </action>
  <verify>grep -c "error(" src/parser/desselet.jl returns 0</verify>
  <done>All error() calls in desselet.jl replaced with throw(ParserError(...))</done>
</task>

<task type="auto">
  <name>Replace error() calls in cortdeco.jl</name>
  <files>src/parser/cortdeco.jl</files>
  <action>
Replace 4 error() calls (lines 134, 309, 318, 322) with throw(ParserError(...)).

These include validation errors for FCF cuts:
```julia
# BEFORE:
error("UHE code $uhe_code not found in FCF cuts. Available: $(cuts.codigos_uhes)")

# AFTER:
throw(ParserError("UHE code $uhe_code not found in FCF cuts. Available: $(cuts.codigos_uhes)", filename, line_num, line))
```

CRITICAL: ParserError argument order is (msg, file, line, content).
  </action>
  <verify>grep -c "error(" src/parser/cortdeco.jl returns 0</verify>
  <done>All error() calls in cortdeco.jl replaced with throw(ParserError(...))</done>
</task>

</tasks>

<verification>
1. Run `grep -r "error(" src/parser/dadvaz.jl src/parser/desselet.jl src/parser/cortdeco.jl | grep -v "ParserError" | grep -v "showerror"` - should return empty
2. Run `julia --project -e 'using Pkg; Pkg.test()'` - all tests should pass
3. Verify error messages include file path and line number when parsing fails
</verification>

<success_criteria>
- Zero error() calls in modified parser files (except ParserError/showerror)
- All parsers throw ParserError with file/line context
- Existing tests continue to pass
</success_criteria>

<output>
After completion, create `.planning/phases/01-error-handling-foundation/01-01B-SUMMARY.md`
</output>
