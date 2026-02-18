---
phase: 01-error-handling-foundation
plan: 01C
subsystem: parser
tags: [parser, error-handling, ParserError, hidr_binary, pwf]

# Dependency graph
requires:
  - phase: 01-error-handling-foundation
    provides: ParserError struct in common.jl
provides:
  - ParserError handling in hidr_binary.jl (binary HIDR parser)
  - ParserError handling in pwf.jl (network file parser)
affects: [validation, error-reporting]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "throw(ParserError(msg, file, line, content)) for all parsing errors"
    - "Rethrow ParserError in catch blocks to preserve context"

key-files:
  created: []
  modified:
    - src/parser/hidr_binary.jl
    - src/parser/pwf.jl

key-decisions:
  - "Use line=0 and content=\"\" for file-not-found errors (no line context)"
  - "Use line=0 and content=\"\" for helper function errors (no direct file context)"

patterns-established:
  - "Pattern: ParserError in catch blocks checks `isa(e, ParserError)` before wrapping"

# Metrics
duration: 30min
completed: 2026-02-18
---

# Phase 1 Plan 01C: Parser Error Replacement Summary

**Replace error() and @warn calls with ParserError in hidr_binary.jl and pwf.jl**

## Performance

- **Duration:** 30 min
- **Started:** 2026-02-18T14:16:46Z
- **Completed:** 2026-02-18T14:46:59Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Converted hidr_binary.jl file-not-found error to ParserError with file context
- Converted pwf.jl parsing errors and warnings to ParserError
- Eliminated @warn + continue patterns in pwf.jl - now throws ParserError instead
- All parser files in phase 1 now use consistent ParserError type

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace error() call in hidr_binary.jl** - `6eb2f6f` (fix)
2. **Task 2: Replace error() and @warn calls in pwf.jl** - `b9153c7` (fix)

**Additional fixes:**
- `ce94f94` - fix(tests): update operuh_tests to use new function signatures

## Files Created/Modified
- `src/parser/hidr_binary.jl` - Replace error() with throw(ParserError(...)) for file-not-found
- `src/parser/pwf.jl` - Replace error() and @warn with throw(ParserError(...)), add ParserCommon import

## Decisions Made
- Use `filepath, 0, ""` for file-not-found errors (no line number or content available)
- Helper functions in pwf.jl use `"", 0, ""` for file/line/content since they don't have direct file context
- Rethrow ParserError in catch blocks to preserve error context from nested calls

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed operuh_tests.jl function signatures**

- **Found during:** Task verification (test run)
- **Issue:** operuh_tests.jl was calling parse_*_record functions with only line argument, but functions now require (line, file, line_num) - signature change from previous plan 01-03
- **Fix:** Updated all 11 function calls in operuh_tests.jl to include "test.dat" and line number arguments
- **Files modified:** test/operuh_tests.jl
- **Verification:** All tests pass
- **Committed in:** ce94f94

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Test fix was required to verify main plan changes work correctly. No scope creep.

## Issues Encountered
None - plan executed as specified with one test compatibility fix.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 1 parser error handling is now complete across all parser files
- All parsing errors use consistent ParserError type with file/line context
- Ready for validation layer phase or API hygiene improvements
