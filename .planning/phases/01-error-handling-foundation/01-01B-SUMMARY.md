---
phase: 01-error-handling-foundation
plan: 01B
subsystem: parser
tags: [julia, error-handling, parser, ParserError]

# Dependency graph
requires:
  - phase: 01-error-handling-foundation
    provides: ParserError struct definition in common.jl
provides:
  - dadvaz.jl with ParserError handling for all validation failures
  - desselet.jl with ParserError handling for all parsing failures
  - cortdeco.jl with ParserError handling for all validation failures
affects: [parser-error-handling, error-context]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ParserError throw pattern: throw(ParserError(msg, file, line, content))"

key-files:
  created: []
  modified:
    - src/parser/dadvaz.jl
    - src/parser/desselet.jl
    - src/parser/cortdeco.jl

key-decisions:
  - "Binary parser (cortdeco) errors use empty context since they don't have line-based parsing context"
  - "Post-parsing validation errors (get_water_value) use empty context as they operate on parsed data"

patterns-established:
  - "Pattern: Replace error() with throw(ParserError(msg, file, line_num, line))"
  - "Pattern: Pass file context through helper function signatures"

# Metrics
duration: 13 min
completed: 2026-02-18
---

# Phase 1 Plan 01B: Parser Error Replacement Summary

**Replaced error() calls with throw(ParserError(...)) in three parser files for consistent error handling with file/line context.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-02-18T14:14:49Z
- **Completed:** 2026-02-18T14:27:30Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- dadvaz.jl: 14 error() calls replaced, including updated helper function signature for context passing
- desselet.jl: 3 error() calls replaced with file/line context
- cortdeco.jl: 4 error() calls replaced (binary parser, some with empty context)
- All parsers now throw ParserError (not ErrorException) for all parsing failures

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace error() calls in dadvaz.jl** - `bec36eb` (feat)
2. **Task 2: Replace error() calls in desselet.jl** - `eb5336f` (feat)
3. **Task 3: Replace error() calls in cortdeco.jl** - `586d303` (feat)

**Plan metadata:** (pending)

_Note: TDD tasks may have multiple commits (test -> feat -> refactor)_

## Files Created/Modified
- `src/parser/dadvaz.jl` - Flow data parser with ParserError handling (14 calls replaced)
- `src/parser/desselet.jl` - Electrical data parser with ParserError handling (3 calls replaced)
- `src/parser/cortdeco.jl` - FCF cuts parser with ParserError handling (4 calls replaced)

## Decisions Made
- Binary file parser (cortdeco.jl) uses empty string for file context in validation errors since binary files don't have line-based structure
- Post-parsing validation functions (get_water_value) use empty context as they operate on already-parsed data structures

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Part 2 of 3 for error handling in parser files complete
- Ready for 01-01C-PLAN.md (remaining parser files: simul.jl, termdat.jl, relogiol.dat)

---
*Phase: 01-error-handling-foundation*
*Completed: 2026-02-18*
