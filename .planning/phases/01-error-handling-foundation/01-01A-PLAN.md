---
phase: 01-error-handling-foundation
plan: 01A
type: execute
wave: 1
depends_on: []
files_modified:
  - src/parser/simul.jl
  - src/parser/renovaveis.jl
  - src/parser/operut.jl
autonomous: true

must_haves:
  truths:
    - "simul.jl throws ParserError for all parsing failures"
    - "renovaveis.jl throws ParserError for all parsing failures"
    - "operut.jl uses ParserCommon helpers or throws ParserError"
    - "ParserError includes file path, line number, and line content"
  artifacts:
    - path: "src/parser/simul.jl"
      provides: "Legacy SIMUL parser with ParserError handling"
      contains: "throw(ParserError"
    - path: "src/parser/renovaveis.jl"
      provides: "Renewables parser with ParserError handling"
      contains: "throw(ParserError"
    - path: "src/parser/operut.jl"
      provides: "Thermal operation parser with ParserError handling"
      contains: "ParserCommon"
  key_links:
    - from: "error() call sites"
      to: "ParserError struct"
      via: "throw(ParserError(msg, file, line_num, line))"
      pattern: "throw\\(ParserError\\("
---

<objective>
Replace all error() calls with throw(ParserError(...)) across simul.jl, renovaveis.jl, and operut.jl.

Purpose: Users should catch ParserError (not ErrorException) for all parsing failures, with file/line context.
Output: 3 parser files using ParserError consistently.

**Note:** This is part 1 of 3 split from original Plan 01-01 (simul.jl, renovaveis.jl, operut.jl).
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
  <name>Replace error() calls in simul.jl</name>
  <files>src/parser/simul.jl</files>
  <action>
Replace 5 error() calls (lines 69, 109, 135, 218, 299) with throw(ParserError(...)).

Pattern transformation:
```julia
# BEFORE:
error("Error parsing SIMUL header at $filename:$line_num: $e\nLine: '$line'")

# AFTER:
if isa(e, ParserError)
    rethrow(e)
else
    throw(ParserError("Error parsing SIMUL header: $(sprint(showerror, e))", filename, line_num, line))
end
```

Line 299 (no catch block, just validation):
```julia
# BEFORE:
error("SIMUL file $filename does not contain a valid header (Record 3)")

# AFTER:
throw(ParserError("SIMUL file does not contain a valid header (Record 3)", filename, line_num, ""))
```

CRITICAL: ParserError argument order is (msg, file, line, content) - message FIRST.
  </action>
  <verify>grep -c "error(" src/parser/simul.jl returns 0</verify>
  <done>All error() calls in simul.jl replaced with throw(ParserError(...))</done>
</task>

<task type="auto">
  <name>Replace error() calls in renovaveis.jl</name>
  <files>src/parser/renovaveis.jl</files>
  <action>
Replace 5 error() calls (lines 82, 90, 147, 184, 227) with throw(ParserError(...)).

For catch blocks, use the rethrow pattern:
```julia
catch e
    if isa(e, ParserError)
        rethrow(e)
    else
        throw(ParserError("Descriptive message: $(sprint(showerror, e))", filename, line_num, line))
    end
end
```

For validation errors (line 90):
```julia
# BEFORE:
error("Line $line_num in $filename: Expected 'EOLICA', got '$record_type'")

# AFTER:
throw(ParserError("Expected 'EOLICA', got '$record_type'", filename, line_num, line))
```

CRITICAL: ParserError argument order is (msg, file, line, content).
  </action>
  <verify>grep -c "error(" src/parser/renovaveis.jl returns 0</verify>
  <done>All error() calls in renovaveis.jl replaced with throw(ParserError(...))</done>
</task>

<task type="auto">
  <name>Replace error() calls and fix helpers in operut.jl</name>
  <files>src/parser/operut.jl</files>
  <action>
1. Replace local helper functions (lines 16, 22) to use ParserCommon or throw ParserError:

```julia
# BEFORE (lines 14-24):
function parse_int(s::AbstractString)
    s_clean = strip(s)
    isempty(s_clean) && error("Cannot parse empty string as Int")
    return parse(Int, s_clean)
end

function parse_float(s::AbstractString)
    s_clean = strip(s)
    isempty(s_clean) && error("Cannot parse empty string as Float64")
    return parse(Float64, s_clean)
end

# OPTION A: Import and use ParserCommon.parse_int, ParserCommon.parse_float
# OPTION B: Make helpers throw ParserError (but they don't have file context)
```

Best approach: Import ParserCommon helpers which already handle ParserError:
```julia
using ..ParserCommon: parse_int, parse_float  # If not already imported
```

Or if local helpers are truly needed, remove the error() calls and let parse() throw naturally (ArgumentError), then catch and wrap in caller.

2. Remove local error() calls, rely on ParserCommon or natural parse() exceptions.
  </action>
  <verify>grep -c "error(" src/parser/operut.jl returns 0</verify>
  <done>operut.jl uses ParserCommon helpers or throws ParserError for parse failures</done>
</task>

</tasks>

<verification>
1. Run `grep -r "error(" src/parser/simul.jl src/parser/renovaveis.jl src/parser/operut.jl | grep -v "ParserError" | grep -v "showerror"` - should return empty
2. Run `julia --project -e 'using Pkg; Pkg.test()'` - all tests should pass
3. Verify error messages include file path and line number when parsing fails
</verification>

<success_criteria>
- Zero error() calls in modified parser files (except ParserError/showerror)
- All parsers throw ParserError with file/line context
- Existing tests continue to pass
</success_criteria>

<output>
After completion, create `.planning/phases/01-error-handling-foundation/01-01A-SUMMARY.md`
</output>
