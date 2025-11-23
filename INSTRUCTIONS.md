# Instructions for MLT.DAT Parser Implementation

## Objective
Implement a parser for the `MLT.DAT` file (Long-term average flows).

## Steps

1.  **Research**:
    *   Check the IDESEM implementation at `idessem/dessem/modelos/mlt.py` (if available).
    *   Identify the record structure. This file typically contains monthly average flows.

2.  **Define Types**:
    *   Edit `src/models/core_types.jl` (or `src/types.jl`).
    *   Create `MltRecord` struct.
    *   Create `MltData` struct.

3.  **Implement Parser**:
    *   Create `src/parser/mlt.jl`.
    *   Implement `parse_mlt(io::IO)` and `parse_mlt(filename::String)`.
    *   Use `ParserCommon` utilities.

4.  **Register Parser**:
    *   Edit `src/DESSEM2Julia.jl` to include and export the new parser and types.

5.  **Testing**:
    *   Create `test/mlt_tests.jl`.
    *   Add unit tests.
    *   Add integration tests using sample data if available.
    *   Update `test/runtests.jl`.

6.  **Documentation**:
    *   Update `docs/file_formats.md` to mark MLT as complete.

## Reference
*   **File Format**: Fixed-width.
*   **Key Fields**: Plant ID, monthly flow values (12 months).
