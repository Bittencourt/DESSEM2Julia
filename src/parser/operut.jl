# OPERUT.DAT Parser - Fixed-Width Column Format
# Based on IDESEM Python implementation (idessem/dessem/modelos/operut.py)
#
# OPERUT.DAT uses FIXED-WIDTH columns, not space-separated fields.
# Plant names are ALWAYS 12 characters (padded with spaces).

module OperutParser

using ..DESSEM2Julia: INITRecord, OPERRecord, OperutData
using ..ParserCommon: parse_int, parse_float, extract_field

export parse_operut, parse_init_record, parse_oper_record

# Try-parse helpers for optional fields
function tryparse_int(s::AbstractString)
    s_clean = strip(s)
    isempty(s_clean) && return nothing
    return tryparse(Int, s_clean)
end

function tryparse_float(s::AbstractString)
    s_clean = strip(s)
    isempty(s_clean) && return nothing
    return tryparse(Float64, s_clean)
end

"""
    parse_init_record(line::AbstractString) -> INITRecord

Parse an INIT block record using FIXED-WIDTH columns.

Column positions from IDESEM (idessem/dessem/modelos/operut.py BlocoInitUT):
- Positions 1-3: Plant code (IntegerField(3, 0))
- Positions 5-16: Plant name (LiteralField(12, 4)) - ALWAYS 12 chars
- Positions 19-21: Unit number (IntegerField(3, 18))
- Positions 25-26: Status (IntegerField(2, 24))
- Positions 30-39: Initial generation (FloatField(10, 29, 3))
- Positions 42-46: Time in state (IntegerField(5, 41))
- Position 49: MH flag (IntegerField(1, 48))
- Position 52: AD flag (IntegerField(1, 51))
- Position 55: T flag (IntegerField(1, 54))
- Positions 58-67: Inflexible limit (FloatField(10, 57, 0))

Example:
```
&us     nome       ug   st   GerInic     tempo MH A/D T  TITULINFLX
  1  ANGRA 1        1    1      640.000   1879  1  0  1        640.
```
"""
function parse_init_record(line::AbstractString)
    plant_num = parse_int(extract_field(line, 1, 3))
    plant_name = strip(extract_field(line, 5, 16))
    unit_num = parse_int(extract_field(line, 19, 21))
    status = parse_int(extract_field(line, 25, 26))
    initial_gen = parse_float(extract_field(line, 30, 39))
    hours = parse_int(extract_field(line, 42, 46))

    # Optional fields (may be empty)
    mh_flag = tryparse_int(extract_field(line, 49, 49))
    ad_flag = tryparse_int(extract_field(line, 52, 52))
    t_flag = tryparse_int(extract_field(line, 55, 55))
    inflexible_limit = tryparse_float(extract_field(line, 58, 67))

    return INITRecord(
        plant_num = plant_num,
        plant_name = plant_name,
        unit_num = unit_num,
        initial_status = status,
        initial_generation = initial_gen,
        hours_in_state = hours,
        mh_flag = something(mh_flag, 0),
        ad_flag = something(ad_flag, 0),
        t_flag = something(t_flag, 0),
        inflexible_limit = something(inflexible_limit, 0.0),
    )
end

"""
    parse_oper_record(line::AbstractString) -> OPERRecord

Parse an OPER block record using FIXED-WIDTH columns.

Column positions from IDESEM (idessem/dessem/modelos/operut.py BlocoOper):
- Positions 1-3: Plant code (IntegerField(3, 0))
- Positions 5-16: Plant name (LiteralField(12, 4)) - ALWAYS 12 chars
- Positions 18-19: Unit number (IntegerField(2, 17))
- Positions 21-22: Start day (IntegerField(2, 20))
- Positions 24-25: Start hour (IntegerField(2, 23))
- Position 27: Start half (IntegerField(1, 26))
- Positions 29-30: End day (IntegerField(2, 28) OR LiteralField "F")
- Positions 32-33: End hour (IntegerField(2, 31))
- Position 35: End half (IntegerField(1, 34))
- Positions 37-46: Min generation (FloatField(10, 36, 2))
- Positions 47-56: Max generation (FloatField(10, 46, 2))
- Positions 57-66: Cost (FloatField(10, 56, 2))

Example:
```
&us    nome      un di hi m df hf m Gmin     Gmax       Custo
  1 ANGRA 1       1 27  0 0 F                                31.17
```
"""
function parse_oper_record(line::AbstractString)
    plant_num = parse_int(extract_field(line, 1, 3))
    plant_name = strip(extract_field(line, 5, 16))
    unit_num = parse_int(extract_field(line, 18, 19))

    start_day = parse_int(extract_field(line, 21, 22))
    start_hour = parse_int(extract_field(line, 24, 25))
    start_half = parse_int(extract_field(line, 27, 27))

    # End day can be "F" (final) or an integer
    end_day_str = strip(extract_field(line, 29, 30))
    end_day = end_day_str == "F" ? "F" : parse_int(end_day_str)

    end_hour = tryparse_int(extract_field(line, 32, 33))
    end_half = tryparse_int(extract_field(line, 35, 35))

    # Optional generation limits
    min_gen = tryparse_float(extract_field(line, 37, 46))
    max_gen = tryparse_float(extract_field(line, 47, 56))

    # Operating cost (required)
    operating_cost = parse_float(extract_field(line, 57, 66))

    return OPERRecord(
        plant_num = plant_num,
        plant_name = plant_name,
        unit_num = unit_num,
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = something(end_hour, 0),
        end_half = something(end_half, 0),
        min_generation = min_gen,
        max_generation = max_gen,
        operating_cost = operating_cost,
    )
end

"""
    parse_operut(filepath::AbstractString) -> OperutData

Parse OPERUT.DAT file containing thermal unit operational data.

The file contains two main data blocks and 14 configuration blocks:

Configuration blocks (single-line flags):
- UCTPAR: Parallel processing threads
- UCTERM: Unit commitment thermal methodology
- PINT: Interior points method flag
- REGRANPTV: NPTV hydraulic production defaults
- AVLCMO: CMO evaluation printing
- CPLEXLOG: CPLEX logging flag
- UCTBUSLOC: Local search flag
- UCTHEURFP: Feasibility Pump heuristic
- CONSTDADOS: Data consistency
- AJUSTEFCF: FCF adjustments flag
- TOLERILH: Island tolerance
- CROSSOVER: Crossover method
- ENGOLIMENTO: Swallowing method
- TRATA_INVIAB_ILHA: Island infeasibility treatment

Data blocks:
- INIT...FIM: Initial conditions for thermal units
- OPER...FIM: Operating limits and costs by time period

Returns OperutData with all blocks parsed.

# IDESEM Reference
idessem/dessem/modelos/operut.py
"""
function parse_operut(filepath::AbstractString)
    init_records = INITRecord[]
    oper_records = OPERRecord[]

    # Optimization configuration blocks
    uctpar = nothing
    ucterm = nothing
    pint = nothing
    regranptv = Int[]
    avlcmo = nothing
    cplexlog = nothing
    uctbusloc = nothing
    uctheurfp = Int[]
    constdados = Int[]
    ajustefcf = nothing
    tolerilh = nothing
    crossover = Int[]
    engolimento = nothing
    tratainviabilha = nothing

    current_block = :none

    open(filepath, "r") do file
        for line in eachline(file)
            # Skip empty lines and comments
            if isempty(strip(line)) || startswith(strip(line), "&")
                continue
            end

            # Configuration blocks (single-line flags)
            if occursin(r"^UCTPAR\s+", line)
                # UCTPAR <n> - Parallel processing threads
                parts = split(strip(line))
                if length(parts) >= 2
                    uctpar = tryparse_int(parts[2])
                end
                continue
            end

            if occursin(r"^UCTERM\s+", line)
                # UCTERM <n> - Unit commitment methodology
                parts = split(strip(line))
                if length(parts) >= 2
                    ucterm = tryparse_int(parts[2])
                end
                continue
            end

            if occursin(r"^PINT\s*$", line)
                # PINT - Interior points method flag
                pint = true
                continue
            end

            if occursin(r"^REGRANPTV\s+", line)
                # REGRANPTV <n1> [n2] [n3] - NPTV hydraulic production defaults
                parts = split(strip(line))
                if length(parts) >= 2
                    for i in 2:length(parts)
                        val = tryparse_int(parts[i])
                        if val !== nothing
                            push!(regranptv, val)
                        end
                    end
                end
                continue
            end

            if occursin(r"^AVLCMO\s+", line)
                # AVLCMO <n> - CMO evaluation printing
                parts = split(strip(line))
                if length(parts) >= 2
                    avlcmo = tryparse_int(parts[2])
                end
                continue
            end

            if occursin(r"^CPLEXLOG\s*$", line)
                # CPLEXLOG - CPLEX logging flag
                cplexlog = true
                continue
            end

            if occursin(r"^UCTBUSLOC\s*$", line)
                # UCTBUSLOC - Local search flag
                uctbusloc = true
                continue
            end

            if occursin(r"^UCTHEURFP\s+", line)
                # UCTHEURFP <n1> <n2> [n3] - Feasibility Pump heuristic
                parts = split(strip(line))
                if length(parts) >= 2
                    for i in 2:length(parts)
                        val = tryparse_int(parts[i])
                        if val !== nothing
                            push!(uctheurfp, val)
                        end
                    end
                end
                continue
            end

            if occursin(r"^CONSTDADOS\s+", line)
                # CONSTDADOS <n1> [n2] - Data consistency
                parts = split(strip(line))
                if length(parts) >= 2
                    for i in 2:length(parts)
                        val = tryparse_int(parts[i])
                        if val !== nothing
                            push!(constdados, val)
                        end
                    end
                end
                continue
            end

            if occursin(r"^AJUSTEFCF\s*$", line)
                # AJUSTEFCF - FCF adjustments flag
                ajustefcf = true
                continue
            end

            if occursin(r"^TOLERILH\s+", line)
                # TOLERILH <n> - Island tolerance
                parts = split(strip(line))
                if length(parts) >= 2
                    tolerilh = tryparse_int(parts[2])
                end
                continue
            end

            if occursin(r"^CROSSOVER\s+", line)
                # CROSSOVER <n1> <n2> <n3> <n4> - Crossover method
                parts = split(strip(line))
                if length(parts) >= 2
                    for i in 2:length(parts)
                        val = tryparse_int(parts[i])
                        if val !== nothing
                            push!(crossover, val)
                        end
                    end
                end
                continue
            end

            if occursin(r"^ENGOLIMENTO\s+", line)
                # ENGOLIMENTO <n> - Swallowing method
                parts = split(strip(line))
                if length(parts) >= 2
                    engolimento = tryparse_int(parts[2])
                end
                continue
            end

            if occursin(r"^TRATA_INVIAB_ILHA\s+", line)
                # TRATA_INVIAB_ILHA <n> - Island infeasibility treatment
                parts = split(strip(line))
                if length(parts) >= 2
                    tratainviabilha = tryparse_int(parts[2])
                end
                continue
            end

            # Block markers
            if occursin(r"^INIT", line)
                current_block = :init
                continue
            elseif occursin(r"^OPER", line)
                current_block = :oper
                continue
            elseif occursin(r"^FIM", line)
                current_block = :none
                continue
            end

            # Parse data lines
            try
                if current_block == :init
                    push!(init_records, parse_init_record(line))
                elseif current_block == :oper
                    push!(oper_records, parse_oper_record(line))
                end
            catch e
                @warn "Failed to parse line in $current_block block" line exception =
                    (e, catch_backtrace())
            end
        end
    end

    return OperutData(
        init_records = init_records,
        oper_records = oper_records,
        uctpar = uctpar,
        ucterm = ucterm,
        pint = pint,
        regranptv = regranptv,
        avlcmo = avlcmo,
        cplexlog = cplexlog,
        uctbusloc = uctbusloc,
        uctheurfp = uctheurfp,
        constdados = constdados,
        ajustefcf = ajustefcf,
        tolerilh = tolerilh,
        crossover = crossover,
        engolimento = engolimento,
        tratainviabilha = tratainviabilha,
    )
end

end # module
