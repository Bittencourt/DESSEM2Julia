# Instructions for BATERIA Parser Implementation

## Objective
Implement a parser for `BATERIA.XXX` files (Battery storage characteristics and operation).

## Steps

1.  **Research**:
    *   Check `idessem` repository for `BATERIA` model.
    *   Identify the structure (likely fixed-width).
    *   Look for records defining battery ID, capacity, efficiency, initial state, etc.

2.  **Define Types**:
    *   Edit `src/models/core_types.jl` (or `src/types.jl`).
    *   Create `BateriaRecord` or similar structs.
    *   Create `BateriaData` struct.

3.  **Implement Parser**:
    *   Create `src/parser/bateria.jl`.
    *   Implement `parse_bateria(io::IO)` and `parse_bateria(filename::String)`.
    *   Use `ParserCommon` utilities.

4.  **Register Parser**:
    *   Edit `src/DESSEM2Julia.jl` to include and export the new parser and types.

5.  **Testing**:
    *   Create `test/bateria_tests.jl`.
    *   Add unit tests.
    *   Add integration tests if sample data is available.
    *   Update `test/runtests.jl`.

6.  **Documentation**:
    *   Update `docs/file_formats.md` to mark `BATERIA.XXX` as complete.

## Reference
*   **File Format**: Fixed-width.
*   **Key Fields**: Battery ID, Max Capacity, Max Charge/Discharge Rate, Efficiency.
