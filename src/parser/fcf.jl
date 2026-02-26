"""
FCF (Função de Custo Futuro) Evaluation Module

Provides functions to:
1. Parse and combine mapcut + cortdeco files into structured FCFData
2. Evaluate the Future Cost Function at given reservoir volumes
3. Compute marginal water values for individual reservoirs

The FCF is a piecewise-linear approximation (Benders cuts) of the form:
    α ≥ α₀_k + Σᵢ πᵢ_k · Vᵢ    for each cut k

Where:
- πᵢ_k = coefficient for reservoir i in cut k (marginal water value, R\$/hm³)
- Vᵢ = volume stored in reservoir i (hm³)
- α₀_k = RHS constant for cut k
- FCF value = max_k { α₀_k + Σᵢ πᵢ_k · Vᵢ }

# Reference
Based on IDESEM: https://github.com/rjmalves/idecomp
"""
module FCFModule

using ..DESSEM2Julia:
    BendersCut,
    FCFData,
    FCFCut,
    FCFCutsData,
    MapcutGeneralData,
    MapcutCaseData,
    MapcutStageData
using ..ParserCommon: ParserError
using ..CortdecoParser: parse_cortdeco

export parse_fcf, evaluate_fcf, water_value, build_fcf_from_cuts

# ============================================================================
# MAPCUT ENHANCED PARSER
# ============================================================================

const MAPCUT_REGISTER_SIZE = 48020

"""
    parse_mapcut_enhanced(filepath::String) -> (general, case_data, uhes, stage_data)

Parse MAPCUT binary file following IDESEM reference implementation.

Returns structured data from the multi-record MAPCUT file:
- `general::MapcutGeneralData`: General data (iterations, cuts, UHEs, scenarios)
- `case_data::MapcutCaseData`: Case parameters (record size, start date)
- `uhes::Vector{Int32}`: UHE codes
- `stage_data::MapcutStageData`: Stage configuration

# IDESEM Reference
idecomp/decomp/modelos/mapcut.py - SecaoDadosMapcut class
"""
function parse_mapcut_enhanced(filepath::String)
    general = MapcutGeneralData()
    case_data = MapcutCaseData()
    uhes = Int32[]
    stage_data = MapcutStageData()

    open(filepath, "r") do io
        seekend(io)
        file_size = position(io)
        seek(io, 0)

        if file_size < 20
            @warn "MAPCUT file too small: $file_size bytes"
            return (general, case_data, uhes, stage_data)
        end

        # Record 1: General data (dados_gerais)
        # First 5 Int32 values: iterations, cuts, submarkets, uhes, scenarios
        primeiro_bloco = Vector{Int32}(undef, 5)
        read!(io, primeiro_bloco)

        numero_iteracoes = primeiro_bloco[1]
        numero_cortes = primeiro_bloco[2]
        numero_submercados = primeiro_bloco[3]
        numero_uhes = primeiro_bloco[4]
        numero_cenarios = primeiro_bloco[5]

        # Then ncen Int32 values: last cut index for each scenario node
        registro_ultimo_corte = Vector{Int32}(undef, numero_cenarios)
        read!(io, registro_ultimo_corte)

        general = MapcutGeneralData(
            numero_iteracoes = numero_iteracoes,
            numero_cortes = numero_cortes,
            numero_submercados = numero_submercados,
            numero_uhes = numero_uhes,
            numero_cenarios = numero_cenarios,
            registro_ultimo_corte_no = registro_ultimo_corte,
        )

        # Record 2: Case data (dados_caso)
        seek(io, 1 * MAPCUT_REGISTER_SIZE)
        caso_data = Vector{Int32}(undef, 4)
        read!(io, caso_data)

        case_data = MapcutCaseData(
            tamanho_corte = caso_data[1],
            dia_inicio = caso_data[2],
            mes_inicio = caso_data[3],
            ano_inicio = caso_data[4],
        )

        # Record 3: UHE codes (dados_uhes)
        seek(io, 2 * MAPCUT_REGISTER_SIZE)
        uhes = Vector{Int32}(undef, numero_uhes)
        read!(io, uhes)

        # Record 6: Stage data (dados_estagios) - at record offset after topology + tree
        # Skip records 4 (topology), 5 (14 skip + tree)
        # Record 4 is at offset 3
        # Records 5-18 are skipped (14 records for tree)
        # Record 19 is tree data
        # Record 20 is stage data
        # Based on IDESEM: counter starts at 2 (after record 2), reads record 3,
        # then record 4 (topology), then skips 14 records, reads record 5 (tree),
        # then reads record 6 (stages)
        stage_record_offset = 2 + 1 + 1 + 14 + 1  # = 19
        if file_size > stage_record_offset * MAPCUT_REGISTER_SIZE
            seek(io, stage_record_offset * MAPCUT_REGISTER_SIZE)
            stage_header = Vector{Int32}(undef, 5)
            try
                read!(io, stage_header)

                numero_estagios = stage_header[2]
                numero_semanas = stage_header[3]
                numero_uhes_tv = stage_header[4]
                maximo_lag_tv = stage_header[5]

                # First node index per stage
                primeiro_no = Vector{Int32}(undef, numero_estagios)
                read!(io, primeiro_no)

                # Load levels per stage
                patamares = Vector{Int32}(undef, numero_estagios)
                read!(io, patamares)

                stage_data = MapcutStageData(
                    numero_estagios = numero_estagios,
                    numero_semanas = numero_semanas,
                    numero_uhes_tempo_viagem = numero_uhes_tv,
                    maximo_lag_tempo_viagem = maximo_lag_tv,
                    indice_primeiro_no_estagio = primeiro_no,
                    patamares_por_estagio = patamares,
                )
            catch e
                @warn "Failed to read stage data from MAPCUT: $e"
            end
        end
    end

    return (general, case_data, uhes, stage_data)
end

# ============================================================================
# FCF CONSTRUCTION
# ============================================================================

"""
    build_fcf_from_cuts(cuts_data::FCFCutsData, reservoir_ids::Vector{Int}) -> FCFData

Build a structured FCFData from raw FCFCutsData and reservoir ID mapping.

# Arguments
- `cuts_data::FCFCutsData`: Raw parsed cuts from cortdeco parser
- `reservoir_ids::Vector{Int}`: Ordered list of reservoir codes (from mapcut or user)

# Returns
- `FCFData`: Structured FCF with BendersCut objects containing reservoir ID mappings
"""
function build_fcf_from_cuts(cuts_data::FCFCutsData, reservoir_ids::Vector{Int})
    benders_cuts = BendersCut[]

    for (i, cut) in enumerate(cuts_data.cortes)
        # Map coefficients to reservoir IDs
        res_coeffs = Dict{Int,Float64}()
        for (j, res_id) in enumerate(reservoir_ids)
            if j <= length(cut.coeficientes)
                coeff = cut.coeficientes[j]
                if coeff != 0.0
                    res_coeffs[res_id] = coeff
                end
            end
        end

        # Remaining coefficients after reservoir values are travel-time and GNL
        n_res = length(reservoir_ids)
        remaining = if n_res < length(cut.coeficientes)
            cut.coeficientes[(n_res+1):end]
        else
            Float64[]
        end

        bc = BendersCut(
            id = i,
            stage = 0,  # Stage info would come from mapcut
            rhs = cut.rhs,
            reservoir_coefficients = res_coeffs,
            travel_time_coefficients = Float64[],
            gnl_coefficients = remaining,
        )
        push!(benders_cuts, bc)
    end

    return FCFData(
        cuts = benders_cuts,
        reservoir_ids = reservoir_ids,
        n_stages = 0,
        n_cuts = length(benders_cuts),
        record_length = cuts_data.tamanho_registro,
        source_model = :decomp,
    )
end

"""
    parse_fcf(mapcut_path::String, cortdeco_path::String; kwargs...) -> FCFData

Parse mapcut + cortdeco binary files into a structured FCFData.

This is the main entry point for building a complete FCF from DECOMP binary files.
The mapcut file provides the "Rosetta Stone" for interpreting cortdeco coefficients.

# Arguments
- `mapcut_path::String`: Path to mapcut.rvX file
- `cortdeco_path::String`: Path to cortdeco.rvX file

# Keyword Arguments
Passed through to `parse_cortdeco`:
- `indice_ultimo_corte::Int`: Index of last cut (default: from mapcut)
- `numero_total_cortes::Int`: Max cuts to read

# Returns
- `FCFData`: Complete structured FCF data

# Example
```julia
fcf = parse_fcf("mapcut.rv2", "cortdeco.rv2")
cost, active = evaluate_fcf(fcf, Dict(1 => 50.0, 2 => 30.0))
```
"""
function parse_fcf(mapcut_path::String, cortdeco_path::String; kwargs...)
    # Import the parsers we need
    # parse_cortdeco is imported at module level from CortdecoParser

    # Parse mapcut to get metadata
    general, case_data, uhes, stage_data = parse_mapcut_enhanced(mapcut_path)

    # Determine record size and last cut index
    tamanho_registro = Int(case_data.tamanho_corte)
    if tamanho_registro <= 0
        tamanho_registro = 1664  # Default NEWAVE/DECOMP standard
    end

    # Find the last cut index from scenario data
    indice_ultimo_corte = get(kwargs, :indice_ultimo_corte, 0)
    if indice_ultimo_corte <= 0 && !isempty(general.registro_ultimo_corte_no)
        indice_ultimo_corte = Int(maximum(general.registro_ultimo_corte_no))
    end
    if indice_ultimo_corte <= 0
        indice_ultimo_corte = 1
    end

    numero_total_cortes = get(kwargs, :numero_total_cortes, Int(general.numero_cortes))
    if numero_total_cortes <= 0
        numero_total_cortes = 10000
    end

    # Parse cortdeco cuts
    cuts_data = parse_cortdeco(
        cortdeco_path;
        tamanho_registro = tamanho_registro,
        indice_ultimo_corte = indice_ultimo_corte,
        numero_total_cortes = numero_total_cortes,
        codigos_uhes = Int.(uhes),
    )

    # Build structured FCF
    fcf = build_fcf_from_cuts(cuts_data, Int.(uhes))

    # Enrich with mapcut metadata
    return FCFData(
        cuts = fcf.cuts,
        reservoir_ids = Int.(uhes),
        n_stages = Int(stage_data.numero_estagios),
        n_cuts = length(fcf.cuts),
        record_length = tamanho_registro,
        source_model = :decomp,
    )
end

# ============================================================================
# FCF EVALUATION API
# ============================================================================

"""
    evaluate_fcf(fcf::FCFData, volumes::Dict{Int, Float64}) -> (cost::Float64, active_cut::Int)

Evaluate the Future Cost Function at a given vector of reservoir volumes.

The FCF is: max_k { α₀_k + Σᵢ πᵢ_k · Vᵢ }

# Arguments
- `fcf::FCFData`: Structured FCF data
- `volumes::Dict{Int, Float64}`: Map of reservoir_id → stored volume (hm³)

# Returns
- `cost::Float64`: The future cost value
- `active_cut::Int`: Index of the binding (active) cut

# Example
```julia
fcf = build_fcf_from_cuts(cuts_data, [1, 2, 3])
cost, active = evaluate_fcf(fcf, Dict(1 => 50.0, 2 => 30.0, 3 => 40.0))
println("Future cost: \$cost R\$, binding cut: \$active")
```
"""
function evaluate_fcf(fcf::FCFData, volumes::Dict{Int,Float64})
    if isempty(fcf.cuts)
        return (0.0, 0)
    end

    max_cost = -Inf
    active_cut = 0

    for (i, cut) in enumerate(fcf.cuts)
        cost = cut.rhs
        for (res_id, coeff) in cut.reservoir_coefficients
            cost += coeff * get(volumes, res_id, 0.0)
        end
        if cost > max_cost
            max_cost = cost
            active_cut = i
        end
    end

    return (max_cost, active_cut)
end

"""
    water_value(fcf::FCFData, volumes::Dict{Int, Float64}, reservoir_id::Int) -> Float64

Get the marginal water value (R\$/hm³) for a specific reservoir at the given operating point.

This returns the πᵢ coefficient of the active (binding) cut at the given volumes.
The water value represents the economic benefit of storing one additional hm³.

# Arguments
- `fcf::FCFData`: Structured FCF data
- `volumes::Dict{Int, Float64}`: Map of reservoir_id → stored volume (hm³)
- `reservoir_id::Int`: The reservoir to query

# Returns
- `Float64`: Marginal water value in R\$/hm³

# Example
```julia
fcf = build_fcf_from_cuts(cuts_data, [1, 2, 3])
wv = water_value(fcf, Dict(1 => 50.0, 2 => 30.0, 3 => 40.0), 1)
println("Water value for reservoir 1: \$wv R\$/hm³")
```
"""
function water_value(fcf::FCFData, volumes::Dict{Int,Float64}, reservoir_id::Int)
    if isempty(fcf.cuts)
        return 0.0
    end

    _, active_cut_idx = evaluate_fcf(fcf, volumes)
    if active_cut_idx == 0
        return 0.0
    end

    return get(fcf.cuts[active_cut_idx].reservoir_coefficients, reservoir_id, 0.0)
end

"""
    water_values(fcf::FCFData, volumes::Dict{Int, Float64}) -> Dict{Int, Float64}

Get all marginal water values at the given operating point.

Returns the πᵢ coefficients of the active (binding) cut for all reservoirs.

# Arguments
- `fcf::FCFData`: Structured FCF data
- `volumes::Dict{Int, Float64}`: Map of reservoir_id → stored volume (hm³)

# Returns
- `Dict{Int, Float64}`: Map of reservoir_id → water value (R\$/hm³)
"""
function water_values(fcf::FCFData, volumes::Dict{Int,Float64})
    if isempty(fcf.cuts)
        return Dict{Int,Float64}()
    end

    _, active_cut_idx = evaluate_fcf(fcf, volumes)
    if active_cut_idx == 0
        return Dict{Int,Float64}()
    end

    return copy(fcf.cuts[active_cut_idx].reservoir_coefficients)
end

end # module FCFModule
