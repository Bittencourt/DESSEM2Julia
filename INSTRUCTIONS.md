# Instructions for CONFHD.DAT Parser Implementation

## Objective
Implement a parser for the `CONFHD.DAT` file (Hydro Configuration).

## Steps

1.  **Research**:
    *   Check the IDESEM implementation at `idessem/dessem/modelos/confhd.py` (if available) or similar reference.
    *   Identify the record structure (fixed-width fields).
    *   Note any special values or optional fields.

2.  **Define Types**:
    *   Edit `src/models/core_types.jl` (or `src/types.jl`).
    *   Create `ConfhdRecord` struct with appropriate fields.
    *   Create `ConfhdData` struct to hold the records.

3.  **Implement Parser**:
    *   Create `src/parser/confhd.jl`.
    *   Implement `parse_confhd(io::IO)` and `parse_confhd(filename::String)`.
    *   Use `ParserCommon` utilities (`extract_field`, `parse_int`, etc.).

4.  **Register Parser**:
    *   Edit `src/DESSEM2Julia.jl` to include and export the new parser and types.

5.  **Testing**:
    *   Create `test/confhd_tests.jl`.
    *   Add unit tests for individual records.
    *   Add integration tests using sample data if available (check `docs/Sample`).
    *   Update `test/runtests.jl` to include the new test file.

6.  **Documentation**:
    *   Update `docs/file_formats.md` to mark CONFHD as complete.

## Reference
*   **File Format**: Fixed-width text.
*   **Key Fields**: Typically involves hydro plant ID, modification flags, etc.
