# Instructions for TOLPERD Parser Implementation

## Objective
Implement a parser for `TOLPERD.XXX` (Loss tolerance parameters).

## Steps

1.  **Research**:
    *   Check `idessem` repository for `TOLPERD` model.
    *   Identify fields: Tolerance values, convergence criteria, etc.

2.  **Define Types**:
    *   Edit `src/models/core_types.jl` (or `src/types.jl`).
    *   Create `TolperdRecord` or similar structs.
    *   Create `TolperdData` struct.

3.  **Implement Parser**:
    *   Create `src/parser/tolperd.jl`.
    *   Implement `parse_tolperd(io::IO)` and `parse_tolperd(filename::String)`.
    *   Use `ParserCommon` utilities.

4.  **Register Parser**:
    *   Edit `src/DESSEM2Julia.jl` to include and export the new parser and types.

5.  **Testing**:
    *   Create `test/tolperd_tests.jl`.
    *   Add unit tests.
    *   Add integration tests if sample data is available.
    *   Update `test/runtests.jl`.

6.  **Documentation**:
    *   Update `docs/file_formats.md` to mark `TOLPERD.XXX` as complete.

## Reference
*   **File Format**: Fixed-width.
*   **Key Fields**: Tolerance parameters for loss calculation.
