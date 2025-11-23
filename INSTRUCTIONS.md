# Instructions for ANAREDE Parser Implementation

## Objective
Implement a parser for ANAREDE format files (`leve.dat`, `media.dat`, `pesada.dat`).

## Steps

1.  **Research**:
    *   These files follow the standard ANAREDE format (DBAR, DLIN, DGLT, etc.).
    *   Check if there is an existing Julia package (e.g., PowerModels.jl, PowerFlows.jl) that can parse this format. If so, consider using it or adapting its logic.
    *   If implementing from scratch, identify the key blocks (DBAR for buses, DLIN for lines).

2.  **Define Types**:
    *   Edit `src/models/core_types.jl` (or `src/types.jl`).
    *   Create `AnaredeRecord` or specific structs for DBAR, DLIN, etc.
    *   Create `AnaredeData` struct.

3.  **Implement Parser**:
    *   Create `src/parser/anarede.jl`.
    *   Implement `parse_anarede(io::IO)` and `parse_anarede(filename::String)`.
    *   Handle the block-based structure (DBAR, DLIN, etc.).

4.  **Register Parser**:
    *   Edit `src/DESSEM2Julia.jl` to include and export the new parser and types.

5.  **Testing**:
    *   Create `test/anarede_tests.jl`.
    *   Add unit tests.
    *   Add integration tests using sample data if available.
    *   Update `test/runtests.jl`.

6.  **Documentation**:
    *   Update `docs/file_formats.md` to mark ANAREDE files as complete.

## Reference
*   **File Format**: Fixed-width, block-based (DBAR, DLIN).
*   **Key Fields**: Bus ID, voltage, generation, load (DBAR); From bus, To bus, resistance, reactance (DLIN).
