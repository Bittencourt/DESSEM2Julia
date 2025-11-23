# Instructions for RIVAR Parser Implementation

## Objective
Implement a parser for `RIVAR.DAT` (Soft variation constraints).

## Steps

1.  **Research**:
    *   Check `idessem` repository for `RIVAR` model.
    *   Identify fields: Variable ID, penalty costs, limits.

2.  **Define Types**:
    *   Edit `src/models/core_types.jl` (or `src/types.jl`).
    *   Create `RivarRecord` or similar structs.
    *   Create `RivarData` struct.

3.  **Implement Parser**:
    *   Create `src/parser/rivar.jl`.
    *   Implement `parse_rivar(io::IO)` and `parse_rivar(filename::String)`.
    *   Use `ParserCommon` utilities.

4.  **Register Parser**:
    *   Edit `src/DESSEM2Julia.jl` to include and export the new parser and types.

5.  **Testing**:
    *   Create `test/rivar_tests.jl`.
    *   Add unit tests.
    *   Add integration tests if sample data is available.
    *   Update `test/runtests.jl`.

6.  **Documentation**:
    *   Update `docs/file_formats.md` to mark `RIVAR.DAT` as complete.

## Reference
*   **File Format**: Fixed-width.
*   **Key Fields**: Variable type, Index, Penalty cost.
