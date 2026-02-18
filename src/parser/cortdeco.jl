"""
Binary FCF Cuts Parser for DESSEM

Parses cortdeco.rv2 binary files containing Future Cost Function (FCF) Benders cuts
from NEWAVE/DECOMP. These cuts represent the marginal water values for hydro plants
in the hydrothermal optimization.

# Binary Format Specification

Based on inewave implementation: https://github.com/rjmalves/inewave

## Record Structure
- **Total size**: Configurable (typically 1664 bytes)
- **Header**: 4 × Int32 = 16 bytes
  - `indice_corte`: Linked list pointer to previous cut (0-indexed in file)
  - `iteracao_construcao`: Construction iteration number
  - `indice_forward`: Forward pass index
  - `iteracao_desativacao`: Deactivation iteration (0 = active cut)
- **Coefficients**: N × Float64 = 8N bytes
  - First: RHS (independent term)
  - Remaining: Cut coefficients

## Linked List Structure
Cuts are stored in a linked list via `indice_corte` field:
- Start from last cut index (typically at end of file)
- Each cut points to the previous cut
- Chain terminates when `indice_corte == 0`

## Reading Algorithm
```
1. Seek to last cut position: (last_index - 1) × record_size
2. Read header (16 bytes) and coefficients (remaining bytes)
3. Get previous_index from indice_corte field
4. If previous_index != 0, seek to that cut and repeat
5. Reverse final list to get chronological order
```

# Reference Implementation
- inewave: `inewave/newave/modelos/cortes.py` (SecaoDadosCortes class)
- Uses NumPy's `frombuffer()` for binary reading
- Supports both REE aggregated and UHE individualized modes
"""
module CortdecoParser

using ..DESSEM2Julia: FCFCut, FCFCutsData
using ..ParserCommon: ParserError

export parse_cortdeco

"""
    parse_cortdeco(filepath::String; kwargs...) -> FCFCutsData

Parse FCF (Future Cost Function) cuts from cortdeco.rv2 binary file.

This function reads Benders cuts in binary format using a linked-list structure.
Each cut contains an integer header (4×Int32) and float coefficients (N×Float64).

# Arguments
- `filepath::String`: Path to cortdeco.rv2 or cortdeco.rv0 file

# Keyword Arguments
- `tamanho_registro::Int=1664`: Record size in bytes (1664 is NEWAVE/DECOMP standard)
- `indice_ultimo_corte::Int=1`: Index of last cut to start reading (1-based)
- `numero_total_cortes::Int=10000`: Maximum number of cuts to read
- `codigos_rees::Vector{Int}=Int[]`: REE codes for aggregated mode
- `codigos_uhes::Vector{Int}=Int[]`: UHE codes for individualized mode
- `codigos_submercados::Vector{Int}=[1,2,3,4]`: Submarket codes
- `ordem_maxima_parp::Int=12`: Maximum PAR(p) order for inflow models
- `numero_patamares_carga::Int=3`: Number of load levels
- `lag_maximo_gnl::Int=2`: Maximum GNL thermal generation lag

# Returns
- `FCFCutsData`: Container with all parsed cuts and metadata

# Record Size Calculation
The record size determines how many coefficients per cut:
- Header: 4 integers × 4 bytes = 16 bytes
- Coefficients: (record_size - 16) ÷ 8 floats

Standard 1664 bytes → (1664-16)÷8 = 206 float coefficients

# Coefficient Structure
For **individualized mode** (UHE codes provided):
1. RHS (independent term)
2. pi_varm_uhe{i} - Volume marginal values
3. pi_qafl_uhe{i}_lag{j} - Inflow coefficients with lags
4. pi_gnl_sbm{s}_pat{p}_lag{l} - GNL thermal coefficients

For **aggregated mode** (REE codes provided):
1. RHS (independent term)  
2. pi_earm_ree{i} - Energy stored marginal values
3. pi_ena_ree{i}_lag{j} - Energy inflow coefficients with lags
4. pi_gnl_sbm{s}_pat{p}_lag{l} - GNL thermal coefficients

# Example
```julia
# Read cuts for specific hydro plants
cuts = parse_cortdeco("cortdeco.rv2",
    tamanho_registro=1664,
    codigos_uhes=[1, 2, 4, 6, 7, 8, 9, 10, 11, 12]
)
println("Loaded \$(length(cuts.cortes)) cuts")
println("First cut RHS: \$(cuts.cortes[1].rhs)")
```

# Notes
- File positions are 0-based in the binary format, but Julia indices are 1-based
- The function automatically converts indices during parsing
- Inactive cuts (iteracao_desativacao > 0) are included but marked
- Reading stops at first null pointer (indice_corte == 0) or max cuts reached

# Reference
Based on inewave implementation:
https://github.com/rjmalves/inewave/blob/main/inewave/newave/modelos/cortes.py
"""
function parse_cortdeco(
    filepath::String;
    tamanho_registro::Int = 1664,
    indice_ultimo_corte::Int = 1,
    numero_total_cortes::Int = 10000,
    codigos_rees::Vector{Int} = Int[],
    codigos_uhes::Vector{Int} = Int[],
    codigos_submercados::Vector{Int} = [1, 2, 3, 4],
    ordem_maxima_parp::Int = 12,
    numero_patamares_carga::Int = 3,
    lag_maximo_gnl::Int = 2,
)
    # Calculate number of coefficients from record size
    # Header: 4 integers × 4 bytes = 16 bytes
    # Remaining bytes: coefficients as Float64 (8 bytes each)
    bytes_header = 16
    numero_coeficientes = (tamanho_registro - bytes_header) ÷ 8

    if numero_coeficientes <= 0
        throw(
            ParserError(
                "Invalid record size $tamanho_registro: must be at least 24 bytes (16 header + 8 for RHS)",
                filepath,
                0,
                "",
            ),
        )
    end

    # Pre-allocate vector for cuts
    # Use file size to estimate capacity when possible
    cortes = FCFCut[]
    # Will be sized correctly after determining actual cut count

    open(filepath, "r") do io
        # Determine file size to calculate actual number of records
        seekend(io)
        file_size = position(io)
        max_records_in_file = file_size ÷ tamanho_registro

        if max_records_in_file == 0
            @warn "Empty or invalid cortdeco file: $filepath (size: $file_size bytes)"
            return FCFCutsData(
                cortes = cortes,
                tamanho_registro = tamanho_registro,
                numero_total_cortes = 0,
                codigos_rees = codigos_rees,
                codigos_uhes = codigos_uhes,
                codigos_submercados = codigos_submercados,
                ordem_maxima_parp = ordem_maxima_parp,
                numero_patamares_carga = numero_patamares_carga,
                lag_maximo_gnl = lag_maximo_gnl,
            )
        end

        # Start from the last cut
        indice_proximo = min(indice_ultimo_corte, max_records_in_file)
        cortes_lidos = 0

        # Read cuts following the linked list
        while indice_proximo != 0 && cortes_lidos < numero_total_cortes
            # Calculate file offset (0-based indexing in file)
            offset = (indice_proximo - 1) * tamanho_registro

            # Check if offset is valid
            if offset < 0 || offset >= file_size
                @warn "Invalid cut index $indice_proximo (offset $offset, file size $file_size)"
                break
            end

            # Seek to cut position
            seek(io, offset)

            # Read integer header (4 × Int32 = 16 bytes)
            try
                int_bytes = read(io, 16)
                if length(int_bytes) < 16
                    @warn "Incomplete header at offset $offset"
                    break
                end

                int_values = reinterpret(Int32, int_bytes)

                indice_corte_anterior = int_values[1]  # 0-based index of previous cut
                iteracao_construcao = int_values[2]
                indice_forward = int_values[3]
                iteracao_desativacao = int_values[4]

                # Read float coefficients (numero_coeficientes × Float64 = 8N bytes)
                float_bytes_to_read = numero_coeficientes * 8
                float_bytes = read(io, float_bytes_to_read)

                if length(float_bytes) < float_bytes_to_read
                    @warn "Incomplete coefficient data at offset $offset"
                    break
                end

                float_values = reinterpret(Float64, float_bytes)

                # Extract RHS and coefficients
                rhs = float_values[1]
                coeficientes =
                    length(float_values) > 1 ? collect(float_values[2:end]) : Float64[]

                # Create cut with temporary sequential index
                # (will be replaced with chronological index after reversal)
                cut = FCFCut(
                    indice_corte = Int32(0),  # Placeholder, set after reversal
                    iteracao_construcao = iteracao_construcao,
                    indice_forward = indice_forward,
                    iteracao_desativacao = iteracao_desativacao,
                    rhs = rhs,
                    coeficientes = coeficientes,
                )
                push!(cortes, cut)

                # Move to previous cut in linked list
                indice_proximo = indice_corte_anterior
                cortes_lidos += 1

            catch e
                @warn "Error reading cut at offset $offset: $e"
                break
            end
        end
    end

    # Reverse the list because we read backwards through linked list
    reverse!(cortes)

    # Update cut indices to be in chronological order
    for (i, cut) in enumerate(cortes)
        # Create new cut with correct index (can't mutate immutable struct)
        cortes[i] = FCFCut(
            indice_corte = Int32(i),
            iteracao_construcao = cut.iteracao_construcao,
            indice_forward = cut.indice_forward,
            iteracao_desativacao = cut.iteracao_desativacao,
            rhs = cut.rhs,
            coeficientes = cut.coeficientes,
        )
    end

    return FCFCutsData(
        cortes = cortes,
        tamanho_registro = tamanho_registro,
        numero_total_cortes = length(cortes),
        codigos_rees = codigos_rees,
        codigos_uhes = codigos_uhes,
        codigos_submercados = codigos_submercados,
        ordem_maxima_parp = ordem_maxima_parp,
        numero_patamares_carga = numero_patamares_carga,
        lag_maximo_gnl = lag_maximo_gnl,
    )
end

"""
    get_water_value(cuts::FCFCutsData, uhe_code::Int) -> Float64

Get average water value for a hydro plant across all cuts.

This function extracts the water value coefficient (pi_varm_uhe) for a specific
hydro plant from the FCF cuts. The water value represents the marginal cost of
water, i.e., the opportunity cost of using water now versus saving it for the future.

# Arguments
- `cuts::FCFCutsData`: Parsed FCF cuts container
- `uhe_code::Int`: Hydro plant code (must be in cuts.codigos_uhes)

# Returns
- `Float64`: Average water value in R\$/hm³ across all active cuts

# Algorithm
1. Find the coefficient index for the specified UHE code
2. For individualized mode, coefficients are ordered as:
   - RHS at index 1 (stored separately in cut.rhs)
   - pi_varm_uhe coefficients starting at index 1 of coeficientes vector
3. Extract the coefficient from each cut
4. Return the average across all cuts

# Example
```julia
cuts = parse_cortdeco("cortdeco.rv2", codigos_uhes=[1, 2, 4, 6, 7])
wv = get_water_value(cuts, 6)  # Get water value for plant 6
println("Water value for plant 6: \$wv R\$/hm³")
```

# Notes
- Only works with individualized mode (codigos_uhes must be non-empty)
- Returns average across all cuts (active and inactive)
- Future versions may support storage-based interpolation with additional parameter
- If plant not found, throws an error

# Reference
Water values represent dual variables (shadow prices) from the hydrothermal
optimization problem, indicating the marginal cost of water usage.
"""
function get_water_value(cuts::FCFCutsData, uhe_code::Int)
    if isempty(cuts.codigos_uhes)
        throw(
            ParserError(
                "Water value lookup requires individualized mode (codigos_uhes must be non-empty)",
                "",
                0,
                "",
            ),
        )
    end

    # Find index of this UHE in the list
    uhe_idx = findfirst(==(uhe_code), cuts.codigos_uhes)

    if uhe_idx === nothing
        throw(
            ParserError(
                "UHE code $uhe_code not found in FCF cuts. Available: $(cuts.codigos_uhes)",
                "",
                0,
                "",
            ),
        )
    end

    if isempty(cuts.cortes)
        throw(ParserError("No cuts available for water value calculation", "", 0, ""))
    end

    # In individualized mode, coefficient structure is:
    # coeficientes[1:N_uhes] = pi_varm_uhe (water values)
    # coeficientes[N_uhes+1:...] = pi_qafl_uhe (inflow coefficients)
    # ...
    # Water value is at position uhe_idx in coeficientes vector

    coef_idx = uhe_idx

    # Calculate average water value across all cuts
    total_wv = 0.0
    valid_cuts = 0

    for cut in cuts.cortes
        if coef_idx <= length(cut.coeficientes)
            total_wv += cut.coeficientes[coef_idx]
            valid_cuts += 1
        end
    end

    if valid_cuts == 0
        @warn "No valid water value coefficients found for UHE $uhe_code"
        return 0.0
    end

    return total_wv / valid_cuts
end

"""
    get_active_cuts(cuts::FCFCutsData) -> Vector{FCFCut}

Filter and return only active cuts (iteracao_desativacao == 0).

# Arguments
- `cuts::FCFCutsData`: Parsed FCF cuts container

# Returns
- `Vector{FCFCut}`: Vector containing only cuts that are currently active

# Example
```julia
cuts = parse_cortdeco("cortdeco.rv2")
active = get_active_cuts(cuts)
println("Active cuts: \$(length(active)) out of \$(length(cuts.cortes)) total")
```
"""
function get_active_cuts(cuts::FCFCutsData)
    return filter(c -> c.iteracao_desativacao == 0, cuts.cortes)
end

"""
    get_cut_statistics(cuts::FCFCutsData) -> Dict{String, Any}

Compute summary statistics for the FCF cuts.

# Returns
Dictionary with statistics:
- `total_cuts`: Total number of cuts
- `active_cuts`: Number of active cuts (iteracao_desativacao == 0)
- `inactive_cuts`: Number of inactive cuts
- `avg_rhs`: Average RHS value
- `min_rhs`: Minimum RHS value
- `max_rhs`: Maximum RHS value
- `num_coefficients`: Number of coefficients per cut
"""
function get_cut_statistics(cuts::FCFCutsData)
    if isempty(cuts.cortes)
        return Dict{String,Any}("total_cuts" => 0, "active_cuts" => 0, "inactive_cuts" => 0)
    end

    active = get_active_cuts(cuts)
    rhs_values = [c.rhs for c in cuts.cortes]

    # Use simple calculations instead of Statistics.mean
    avg_rhs = sum(rhs_values) / length(rhs_values)

    return Dict{String,Any}(
        "total_cuts" => length(cuts.cortes),
        "active_cuts" => length(active),
        "inactive_cuts" => length(cuts.cortes) - length(active),
        "avg_rhs" => avg_rhs,
        "min_rhs" => minimum(rhs_values),
        "max_rhs" => maximum(rhs_values),
        "num_coefficients" => length(cuts.cortes[1].coeficientes),
    )
end

export get_water_value, get_active_cuts, get_cut_statistics

end # module CortdecoParser
