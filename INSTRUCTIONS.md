# Instructions for SOLAR Parser Implementation

## Objective
Implement a parser for `SOLAR.XXX` files (Solar plant data and forecasts).

## Steps

1.  **Research**:
    *   Check `idessem` repository for `SOLAR` model.
    *   Determine if it follows a similar structure to `RENOVAVEIS.DAT` or `EOLICA.XXX`.
    *   Identify key records (e.g., `SOLAR`, `GERACAO`).

2.  **Define Types**:
    *   Edit `src/models/core_types.jl` (or `src/types.jl`).
    *   Create `SolarRecord` or similar structs.
    *   Create `SolarData` struct.

3.  **Implement Parser**:
    *   Create `src/parser/solar.jl`.
    *   Implement `parse_solar(io::IO)` and `parse_solar(filename::String)`.
    *   Use `ParserCommon` utilities (`extract_field`, etc.).

4.  **Register Parser**:
    *   Edit `src/DESSEM2Julia.jl` to include and export the new parser and types.

5.  **Testing**:
    *   Create `test/solar_tests.jl`.
    *   Add unit tests for record parsing.
    *   Add integration tests if sample data is available.
    *   Update `test/runtests.jl`.

6.  **Documentation**:
    *   Update `docs/file_formats.md` to mark `SOLAR.XXX` as complete.

## Reference
*   **File Format**: Likely fixed-width.
*   **Key Fields**: Plant ID, Name, Generation forecast per period.
