# Instructions for MODIF.DAT Parser Implementation

## Objective
Implement a parser for the `MODIF.DAT` file (Modifications).

## Steps

1.  **Research**:
    *   Check the IDESEM implementation at `idessem/dessem/modelos/modif.py` (if available).
    *   Identify the record structure. This file typically contains modifications to other data, so it might have a flexible format or specific keywords.

2.  **Define Types**:
    *   Edit `src/models/core_types.jl` (or `src/types.jl`).
    *   Create `ModifRecord` struct.
    *   Create `ModifData` struct.

3.  **Implement Parser**:
    *   Create `src/parser/modif.jl`.
    *   Implement `parse_modif(io::IO)` and `parse_modif(filename::String)`.
    *   Use `ParserCommon` utilities.

4.  **Register Parser**:
    *   Edit `src/DESSEM2Julia.jl` to include and export the new parser and types.

5.  **Testing**:
    *   Create `test/modif_tests.jl`.
    *   Add unit tests.
    *   Add integration tests using sample data if available.
    *   Update `test/runtests.jl`.

6.  **Documentation**:
    *   Update `docs/file_formats.md` to mark MODIF as complete.

## Reference
*   **File Format**: Likely fixed-width or keyword-based.
*   **Key Fields**: Modification type, element ID, new value, etc.
