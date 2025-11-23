# Instructions for Binary DEC Parsers Implementation

## Objective
Implement parsers for the binary DECOMP integration files: `INFOFCF.DEC`, `MAPCUT.DEC`, and `CORTES.DEC`.

## Steps

1.  **Research**:
    *   Check the IDESEM implementation for these files (e.g., `idessem/dessem/modelos/infofcf.py`, etc.).
    *   Identify the binary record structure (byte offsets, data types like Int32, Float64, fixed-length strings).
    *   Refer to `src/parser/hidr_binary.jl` for an example of how to parse binary files in this project.

2.  **Define Types**:
    *   Edit `src/models/core_types.jl` (or `src/types.jl`).
    *   Create structs for each file type (e.g., `InfofcfRecord`, `MapcutRecord`, `CortesRecord`).
    *   Create container structs (e.g., `InfofcfData`, etc.).

3.  **Implement Parsers**:
    *   Create `src/parser/infofcf.jl`.
    *   Create `src/parser/mapcut.jl`.
    *   Create `src/parser/cortes.jl`.
    *   Implement parsing logic using Julia's `read(io, Type)` or `read!(io, buffer)`.

4.  **Register Parsers**:
    *   Edit `src/DESSEM2Julia.jl` to include and export the new parsers and types.

5.  **Testing**:
    *   Create `test/binary_dec_tests.jl` (or separate files).
    *   Add unit tests.
    *   Add integration tests using sample data if available.
    *   Update `test/runtests.jl`.

6.  **Documentation**:
    *   Update `docs/file_formats.md` to mark these files as complete.

## Reference
*   **File Format**: Binary.
*   **Key Fields**: Future cost function coefficients, cut mappings, Benders cuts.
