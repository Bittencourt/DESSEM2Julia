# Instructions for ILSTRI Parser Implementation

## Objective
Implement a parser for `ILSTRI.DAT` (Ilha Solteira - Três Irmãos channel data).

## Steps

1.  **Research**:
    *   Check `idessem` repository for `ILSTRI` model.
    *   This file likely describes the hydraulic coupling between Ilha Solteira and Três Irmãos plants.
    *   Identify fields: Plant IDs, flow limits, travel times, etc.

2.  **Define Types**:
    *   Edit `src/models/core_types.jl` (or `src/types.jl`).
    *   Create `IlstriRecord` or similar structs.
    *   Create `IlstriData` struct.

3.  **Implement Parser**:
    *   Create `src/parser/ilstri.jl`.
    *   Implement `parse_ilstri(io::IO)` and `parse_ilstri(filename::String)`.
    *   Use `ParserCommon` utilities.

4.  **Register Parser**:
    *   Edit `src/DESSEM2Julia.jl` to include and export the new parser and types.

5.  **Testing**:
    *   Create `test/ilstri_tests.jl`.
    *   Add unit tests.
    *   Add integration tests if sample data is available.
    *   Update `test/runtests.jl`.

6.  **Documentation**:
    *   Update `docs/file_formats.md` to mark `ILSTRI.DAT` as complete.

## Reference
*   **File Format**: Fixed-width.
*   **Key Fields**: Plant IDs, Channel Capacity, Coefficients.
