# Instructions for RESPOTELE.DAT Parser Implementation

## Objective
Implement a parser for the `RESPOTELE.DAT` file (Electrical Reserve Constraints).

## Steps

1.  **Research**:
    *   Check the IDESEM implementation at `idessem/dessem/modelos/respotele.py` (if available).
    *   Identify the record structure. This file is likely similar to `RESPOT.DAT` but for electrical reserves.

2.  **Define Types**:
    *   Edit `src/models/core_types.jl` (or `src/types.jl`).
    *   Create `RespoteleRecord` struct.
    *   Create `RespoteleData` struct.

3.  **Implement Parser**:
    *   Create `src/parser/respotele.jl`.
    *   Implement `parse_respotele(io::IO)` and `parse_respotele(filename::String)`.
    *   Use `ParserCommon` utilities.

4.  **Register Parser**:
    *   Edit `src/DESSEM2Julia.jl` to include and export the new parser and types.

5.  **Testing**:
    *   Create `test/respotele_tests.jl`.
    *   Add unit tests.
    *   Add integration tests using sample data if available.
    *   Update `test/runtests.jl`.

6.  **Documentation**:
    *   Update `docs/file_formats.md` to mark RESPOTELE as complete.

## Reference
*   **File Format**: Fixed-width.
*   **Key Fields**: Area, reserve type, limits.
