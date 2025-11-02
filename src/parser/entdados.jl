"""
ENTDADOS.XXX Parser

Parses the general data file containing system configuration, time discretization,
plant definitions, and demand data.

Record types supported:
- TM: Time discretization
- SIST: Subsystem definition
- UH: Hydroelectric plant configuration
- UT: Thermal plant configuration
- DP: Demand data
- DA: Water withdrawal rates
- MH: Hydro unit maintenance windows
- MT: Thermal unit maintenance windows
"""
module EntdadosParser

using ..Types
using ..ParserCommon

# Import types
import ..Types:
    TMRecord, SISTRecord, REERecord, UHRecord, TVIAGRecord, UTRecord, USIERecord, DPRecord
import ..Types: DARecord, MHRecord, MTRecord, GeneralData
import ..Types: RERecord, LURecord, FHRecord, FTRecord, FIRecord, FERecord
import ..Types: FRRecord, FCRecord, TXRecord, EZRecord, R11Record, FPRecord
import ..Types: SECRRecord, CRRecord, ACRecord, AGRecord
import ..Types: IARecord, CDRecord, VERecord, RIRecord, CERecord, CIRecord
import ..Types: DERecord, NIRecord, GPRecord, RIVARRecord, RDRecord

export parse_entdados

# ============================================================================
# Record Parsers
# ============================================================================

"""
    parse_tm(line::AbstractString, filename::AbstractString, line_num::Int) -> TMRecord

Parse TM record (time discretization).

Format columns:
- 1-2: "TM"
- 5-6: day (I2)
- 10-11: hour (I2)
- 15: half_hour (I1)
- 20-24: duration (F5.0)
- 30: network_flag (I1)
- 34-39: load_level (A6)
"""
function parse_tm(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:day, 5, 6, Int),
        FieldSpec(:hour, 10, 11, Int),
        FieldSpec(:half_hour, 15, 15, Int),
        FieldSpec(:duration, 20, 24, Float64),
        FieldSpec(:network_flag, 30, 30, Int),
        FieldSpec(:load_level, 34, 39, String),
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    # Validations
    validate_range(values[:hour], 0, 23, "hour", file = filename, line_num = line_num)
    validate_range(
        values[:half_hour],
        0,
        1,
        "half_hour",
        file = filename,
        line_num = line_num,
    )
    validate_positive(values[:duration], "duration", file = filename, line_num = line_num)
    validate_range(
        values[:network_flag],
        0,
        2,
        "network_flag",
        file = filename,
        line_num = line_num,
    )

    return TMRecord(;
        day = values[:day],
        hour = values[:hour],
        half_hour = values[:half_hour],
        duration = values[:duration],
        network_flag = values[:network_flag],
        load_level = values[:load_level] === nothing ? "" : strip(values[:load_level]),
    )
end

"""
    parse_sist(line::AbstractString, filename::AbstractString, line_num::Int) -> SISTRecord

Parse SIST record (subsystem definition).

Format columns:
- 1-4: "SIST"
- 8-9: subsystem_num (I2)
- 11-12: subsystem_code (A2)
- 14: status (I1)
- 16-25: subsystem_name (A10)
"""
function parse_sist(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:subsystem_num, 8, 9, Int),
        FieldSpec(:subsystem_code, 11, 12, String),
        FieldSpec(:status, 14, 14, Int),
        FieldSpec(:subsystem_name, 16, 25, String),
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    # Validations
    validate_range(
        values[:subsystem_num],
        1,
        99,
        "subsystem_num",
        file = filename,
        line_num = line_num,
    )

    return SISTRecord(;
        subsystem_num = values[:subsystem_num],
        subsystem_code = strip(values[:subsystem_code]),
        status = values[:status] === nothing ? 0 : values[:status],
        subsystem_name = strip(values[:subsystem_name]),
    )
end

"""
    parse_uh(line::AbstractString, filename::AbstractString, line_num::Int) -> UHRecord

Parse UH record (hydroelectric plant configuration).

Format columns (verified against idessem - Python 0-indexed + 1 = Julia 1-indexed):
- 1-2: "UH"
- 5-7: plant_num (I3) - idessem: IntegerField(3, 4) -> Julia columns 5-7
- 10-21: plant_name (A12) - idessem: LiteralField(12, 9) -> Julia columns 10-21
- 25-26: subsystem/REE code (I2) - idessem: IntegerField(2, 24) -> Julia columns 25-26
- 30-39: initial_volume_pct (F10.2) - idessem: FloatField(10, 29, 2) -> Julia columns 30-39
- 40: evaporation flag (I1) - idessem: IntegerField(1, 39) -> Julia column 40
- 42+: StageDateField - idessem: starting_position=41 -> Julia column 42+
- Additional optional fields at 50, 65, 70 per idessem spec
"""
function parse_uh(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:plant_num, 5, 7, Int, required = true),  # IntegerField(3, 4) in idessem
        FieldSpec(:plant_name, 10, 21, String, required = true),  # LiteralField(12, 9)
        FieldSpec(:subsystem, 25, 26, Int, required = true),  # IntegerField(2, 24) - REE code
        FieldSpec(:initial_volume_pct, 30, 39, Float64, required = true),  # FloatField(10, 29, 2)
        FieldSpec(:volume_unit, 40, 40, Int, required = false),  # IntegerField(1, 39) - evaporation
        FieldSpec(:status, 42, 42, String, required = false),  # First char of StageDateField at 41
        FieldSpec(:min_volume, 50, 59, Float64, required = false),  # FloatField(10, 49, 2)
        FieldSpec(:max_volume, 65, 65, Int, required = false),  # IntegerField(1, 64)
        FieldSpec(:initial_volume_abs, 70, 70, Int, required = false),  # IntegerField(1, 69)
        FieldSpec(:spillway_crest, 80, 89, Float64, required = false),
        FieldSpec(:diversion_crest, 95, 104, Float64, required = false),
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    # Validations
    validate_range(
        values[:plant_num],
        1,
        320,
        "plant_num",
        file = filename,
        line_num = line_num,
    )
    validate_range(
        values[:initial_volume_pct],
        0.0,
        200.0,
        "initial_volume_pct",
        file = filename,
        line_num = line_num,
    )
    if values[:volume_unit] !== nothing
        validate_range(
            values[:volume_unit],
            0,
            2,
            "volume_unit",
            file = filename,
            line_num = line_num,
        )
    end

    # Convert status to Int if present, else use 0
    status_val = if values[:status] === nothing
        0
    else
        val_str = strip(values[:status])
        if isempty(val_str)
            0
        else
            # Try to parse as Int, otherwise map 'I' to 1
            try
                parse(Int, val_str)
            catch
                val_str == "I" ? 1 : 0
            end
        end
    end

    return UHRecord(;
        plant_num = values[:plant_num],
        plant_name = strip(values[:plant_name]),
        status = status_val,
        subsystem = values[:subsystem],
        initial_volume_pct = values[:initial_volume_pct],
        volume_unit = values[:volume_unit] === nothing ? 1 : values[:volume_unit],
        min_volume = values[:min_volume],
        max_volume = values[:max_volume],
        initial_volume_abs = values[:initial_volume_abs],
        spillway_crest = values[:spillway_crest],
        diversion_crest = values[:diversion_crest],
    )
end

"""
    parse_ut(line::AbstractString, filename::AbstractString, line_num::Int) -> UTRecord

Parse UT record (thermal plant configuration).

Format columns:
- 1-2: "UT"
- 5-7: plant_num (I3)
- 10-21: plant_name (A12)
- 25: status (I1)
- 27: subsystem (I1)
- 29-30: start_day (I2)
- 32-33: start_hour (I2)
- 35: start_half (I1)
- 37: end_marker (A1) - usually "F"
- 45-54: max_generation (F10.0) - installed capacity
- 60-69: min_generation (F10.0) - minimum generation
"""
function parse_ut(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:plant_num, 5, 7, Int),
        FieldSpec(:plant_name, 10, 21, String),
        FieldSpec(:status, 24, 24, Int),
        FieldSpec(:subsystem, 26, 26, Int),
        FieldSpec(:start_day, 28, 29, Int),
        FieldSpec(:start_hour, 31, 32, Int),
        FieldSpec(:start_half, 34, 34, Int),
        FieldSpec(:end_marker, 37, 37, String),
        FieldSpec(:min_generation, 47, 56, Float64),  # First numeric field - minimum generation (right-aligned, 10 chars)
        FieldSpec(:max_generation, 58, 67, Float64),  # Second numeric field - maximum generation (right-aligned, 10 chars)
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    # Validations
    validate_range(
        values[:plant_num],
        1,
        999,
        "plant_num",
        file = filename,
        line_num = line_num,
    )
    if values[:start_hour] !== nothing
        validate_range(
            values[:start_hour],
            0,
            23,
            "start_hour",
            file = filename,
            line_num = line_num,
        )
    end
    if values[:start_half] !== nothing
        validate_range(
            values[:start_half],
            0,
            1,
            "start_half",
            file = filename,
            line_num = line_num,
        )
    end
    if values[:min_generation] !== nothing
        validate_nonnegative(
            values[:min_generation],
            "min_generation",
            file = filename,
            line_num = line_num,
        )
    end
    if values[:max_generation] !== nothing
        # Allow zero max_generation for offline/unavailable units in real data
        validate_nonnegative(
            values[:max_generation],
            "max_generation",
            file = filename,
            line_num = line_num,
        )
    end

    return UTRecord(;
        plant_num = values[:plant_num],
        plant_name = strip(values[:plant_name]),
        status = values[:status],
        subsystem = values[:subsystem],
        start_day = values[:start_day],
        start_hour = values[:start_hour],
        start_half = values[:start_half],
        end_marker = strip(values[:end_marker]),
        min_generation = something(values[:min_generation], 0.0),
        max_generation = something(values[:max_generation], 0.0),  # Default to 0.0 for blank/offline units
    )
end

"""
    parse_dp(line::AbstractString, filename::AbstractString, line_num::Int) -> DPRecord

Parse DP record (demand data).

Format columns (verified against idessem and actual data):
- 1-2: "DP"
- 5-6: subsystem (I2) - idessem: IntegerField(2, 4) -> Julia columns 5-6
- 9-10: start_day (I2)
- 13: start_hour (I1-2)
- 15: start_half (I1)
- 18-19: end_day (I2 or 'F')
- 21-22: end_hour (I2)
- 24: end_half (I1)
- 25-34: demand (F10.1) - idessem: FloatField(10, 24, 1) -> Julia columns 25-34
"""
function parse_dp(line::AbstractString, filename::AbstractString, line_num::Int)
    # Parse subsystem (columns 5-6, 2 digits) - IntegerField(2, 4) in idessem
    subsystem_str = strip(extract_field(line, 5, 6))
    subsystem = parse_int(subsystem_str)

    # Parse start time
    start_day = parse_int(strip(extract_field(line, 9, 10)))
    start_hour = parse_int(strip(extract_field(line, 12, 13)), allow_blank = true)
    start_half = parse_int(strip(extract_field(line, 15, 15)), allow_blank = true)

    # Parse end time
    # First check for 'F' marker at position 18
    end_day_str = strip(extract_field(line, 18, 19))
    end_day = if end_day_str == "F" || end_day_str == "f"
        "F"
    elseif isempty(end_day_str)
        nothing
    else
        parse_int(end_day_str, allow_blank = true)
    end

    end_hour = parse_int(strip(extract_field(line, 21, 22)), allow_blank = true)
    end_half = parse_int(strip(extract_field(line, 24, 24)), allow_blank = true)

    # Parse demand (columns 25-34, F10 with decimals) - FloatField(10, 24, 1) in idessem
    demand = parse_float(strip(extract_field(line, 25, 34)))

    # Validations - handle optional fields
    if start_hour !== nothing
        validate_range(
            start_hour,
            0,
            23,
            "start_hour",
            file = filename,
            line_num = line_num,
        )
    end
    if start_half !== nothing
        validate_range(start_half, 0, 1, "start_half", file = filename, line_num = line_num)
    end
    if end_hour !== nothing
        validate_range(end_hour, 0, 23, "end_hour", file = filename, line_num = line_num)
    end
    if end_half !== nothing
        validate_range(end_half, 0, 1, "end_half", file = filename, line_num = line_num)
    end
    validate_nonnegative(demand, "demand", file = filename, line_num = line_num)

    return DPRecord(;
        subsystem = subsystem,
        start_day = start_day,
        start_hour = start_hour === nothing ? 0 : start_hour,
        start_half = start_half === nothing ? 0 : start_half,
        end_day = end_day,
        end_hour = end_hour === nothing ? 0 : end_hour,
        end_half = end_half === nothing ? 0 : end_half,
        demand = demand,
    )
end

"""
    parse_da(line, filename, line_num) -> DARecord

Parse DA record (water withdrawal rate).
"""
function parse_da(line::AbstractString, filename::AbstractString, line_num::Int)
    plant_num = parse_int(strip(extract_field(line, 5, 7)))
    start_day, start_hour, start_half =
        parse_stage_date(line, 9; special_char = "I", file = filename, line_num = line_num)
    end_day, end_hour, end_half =
        parse_stage_date(line, 17; special_char = "F", file = filename, line_num = line_num)
    rate_raw = extract_field(line, 30, 41)
    rate_val = parse_float(rate_raw; allow_blank = true)
    withdrawal_rate = rate_val === nothing ? 0.0 : rate_val

    if isa(start_day, Int)
        validate_range(start_day, 0, 99, "start_day"; file = filename, line_num = line_num)
    end
    if isa(end_day, Int)
        validate_range(end_day, 0, 99, "end_day"; file = filename, line_num = line_num)
    end

    return DARecord(
        plant_num = plant_num,
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
        withdrawal_rate = withdrawal_rate,
    )
end

"""
    parse_mh(line, filename, line_num) -> MHRecord

Parse MH record (hydro unit maintenance).
"""
function parse_mh(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:plant_num, 5, 7, Int, required = true),
        FieldSpec(:group_code, 10, 11, Int, required = true),
        FieldSpec(:unit_code, 13, 14, Int, required = true),
        FieldSpec(:available_flag, 30, 30, Int, required = false, default = 0),
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    validate_range(
        values[:plant_num],
        1,
        999,
        "plant_num";
        file = filename,
        line_num = line_num,
    )
    validate_range(
        values[:group_code],
        0,
        99,
        "group_code";
        file = filename,
        line_num = line_num,
    )
    validate_range(
        values[:unit_code],
        0,
        99,
        "unit_code";
        file = filename,
        line_num = line_num,
    )

    start_day, start_hour, start_half =
        parse_stage_date(line, 15; special_char = "I", file = filename, line_num = line_num)
    end_day, end_hour, end_half =
        parse_stage_date(line, 23; special_char = "F", file = filename, line_num = line_num)

    if isa(start_day, Int)
        validate_range(start_day, 0, 99, "start_day"; file = filename, line_num = line_num)
    end
    if isa(end_day, Int)
        validate_range(end_day, 0, 99, "end_day"; file = filename, line_num = line_num)
    end

    available = something(values[:available_flag], 0)
    validate_range(available, 0, 1, "available_flag"; file = filename, line_num = line_num)

    return MHRecord(
        plant_num = values[:plant_num],
        group_code = values[:group_code],
        unit_code = values[:unit_code],
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
        available_flag = available,
    )
end

"""
    parse_mt(line, filename, line_num) -> MTRecord

Parse MT record (thermal unit maintenance).
"""
function parse_mt(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:plant_num, 5, 7, Int, required = true),
        FieldSpec(:unit_code, 9, 11, Int, required = true),
        FieldSpec(:available_flag, 30, 30, Int, required = false, default = 0),
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    validate_range(
        values[:plant_num],
        1,
        999,
        "plant_num";
        file = filename,
        line_num = line_num,
    )
    validate_range(
        values[:unit_code],
        1,
        999,
        "unit_code";
        file = filename,
        line_num = line_num,
    )

    start_day, start_hour, start_half =
        parse_stage_date(line, 14; file = filename, line_num = line_num)
    end_day, end_hour, end_half =
        parse_stage_date(line, 22; special_char = "F", file = filename, line_num = line_num)

    if isa(start_day, Int)
        validate_range(start_day, 0, 99, "start_day"; file = filename, line_num = line_num)
    end
    if isa(end_day, Int)
        validate_range(end_day, 0, 99, "end_day"; file = filename, line_num = line_num)
    end

    available = something(values[:available_flag], 0)
    validate_range(available, 0, 1, "available_flag"; file = filename, line_num = line_num)

    return MTRecord(
        plant_num = values[:plant_num],
        unit_code = values[:unit_code],
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
        available_flag = available,
    )
end

"""
    parse_re(line, filename, line_num) -> RERecord

Parse RE record (electrical constraint definition).
"""
function parse_re(line::AbstractString, filename::AbstractString, line_num::Int)
    constraint_code = parse_int(strip(extract_field(line, 5, 7)))
    start_day, start_hour, start_half =
        parse_stage_date(line, 10; special_char = "I", file = filename, line_num = line_num)
    end_day, end_hour, end_half =
        parse_stage_date(line, 18; special_char = "F", file = filename, line_num = line_num)

    return RERecord(
        constraint_code = constraint_code,
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
    )
end

"""
    parse_lu(line, filename, line_num) -> LURecord

Parse LU record (electrical constraint limits).
"""
function parse_lu(line::AbstractString, filename::AbstractString, line_num::Int)
    constraint_code = parse_int(strip(extract_field(line, 5, 7)))
    start_day, start_hour, start_half =
        parse_stage_date(line, 9; special_char = "I", file = filename, line_num = line_num)
    end_day, end_hour, end_half =
        parse_stage_date(line, 17; special_char = "F", file = filename, line_num = line_num)
    lower_limit = parse_float(strip(extract_field(line, 25, 34)); allow_blank = true)
    upper_limit = parse_float(strip(extract_field(line, 35, 44)); allow_blank = true)

    return LURecord(
        constraint_code = constraint_code,
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
        lower_limit = lower_limit,
        upper_limit = upper_limit,
    )
end

"""
    parse_fh(line, filename, line_num) -> FHRecord

Parse FH record (hydro plant coefficient in electrical constraint).
"""
function parse_fh(line::AbstractString, filename::AbstractString, line_num::Int)
    constraint_code = parse_int(strip(extract_field(line, 5, 7)))
    start_day, start_hour, start_half =
        parse_stage_date(line, 9; special_char = "I", file = filename, line_num = line_num)
    end_day, end_hour, end_half =
        parse_stage_date(line, 17; special_char = "F", file = filename, line_num = line_num)
    plant_code = parse_int(strip(extract_field(line, 25, 27)))
    group_code = parse_int(strip(extract_field(line, 29, 30)), allow_blank = true)
    coefficient = parse_float(strip(extract_field(line, 35, 44)))

    return FHRecord(
        constraint_code = constraint_code,
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
        plant_code = plant_code,
        group_code = something(group_code, 0),
        coefficient = coefficient,
    )
end

"""
    parse_ft(line, filename, line_num) -> FTRecord

Parse FT record (thermal plant coefficient in electrical constraint).
"""
function parse_ft(line::AbstractString, filename::AbstractString, line_num::Int)
    constraint_code = parse_int(strip(extract_field(line, 5, 7)))
    start_day, start_hour, start_half =
        parse_stage_date(line, 9; special_char = "I", file = filename, line_num = line_num)
    end_day, end_hour, end_half =
        parse_stage_date(line, 17; special_char = "F", file = filename, line_num = line_num)
    plant_code = parse_int(strip(extract_field(line, 25, 27)))
    coefficient = parse_float(strip(extract_field(line, 35, 44)))

    return FTRecord(
        constraint_code = constraint_code,
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
        plant_code = plant_code,
        coefficient = coefficient,
    )
end

"""
    parse_fi(line, filename, line_num) -> FIRecord

Parse FI record (interchange flow coefficient in electrical constraint).
"""
function parse_fi(line::AbstractString, filename::AbstractString, line_num::Int)
    constraint_code = parse_int(strip(extract_field(line, 5, 7)))
    start_day, start_hour, start_half =
        parse_stage_date(line, 9; special_char = "I", file = filename, line_num = line_num)
    end_day, end_hour, end_half =
        parse_stage_date(line, 17; special_char = "F", file = filename, line_num = line_num)
    from_subsystem = strip(extract_field(line, 25, 26))
    to_subsystem = strip(extract_field(line, 30, 31))
    coefficient = parse_float(strip(extract_field(line, 35, 44)))

    return FIRecord(
        constraint_code = constraint_code,
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
        from_subsystem = from_subsystem,
        to_subsystem = to_subsystem,
        coefficient = coefficient,
    )
end

"""
    parse_fe(line, filename, line_num) -> FERecord

Parse FE record (energy contract coefficient in electrical constraint).
"""
function parse_fe(line::AbstractString, filename::AbstractString, line_num::Int)
    constraint_code = parse_int(strip(extract_field(line, 5, 7)))
    start_day, start_hour, start_half =
        parse_stage_date(line, 9; special_char = "I", file = filename, line_num = line_num)
    end_day, end_hour, end_half =
        parse_stage_date(line, 17; special_char = "F", file = filename, line_num = line_num)
    contract_code = parse_int(strip(extract_field(line, 25, 27)))
    coefficient = parse_float(strip(extract_field(line, 35, 44)))

    return FERecord(
        constraint_code = constraint_code,
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
        contract_code = contract_code,
        coefficient = coefficient,
    )
end

"""
    parse_fr(line, filename, line_num) -> FRRecord

Parse FR record (renewable plant coefficient in electrical constraint).
"""
function parse_fr(line::AbstractString, filename::AbstractString, line_num::Int)
    constraint_code = parse_int(strip(extract_field(line, 5, 7)))
    start_day, start_hour, start_half =
        parse_stage_date(line, 11; special_char = "I", file = filename, line_num = line_num)
    end_day, end_hour, end_half =
        parse_stage_date(line, 19; special_char = "F", file = filename, line_num = line_num)
    plant_code = parse_int(strip(extract_field(line, 27, 31)))
    coefficient = parse_float(strip(extract_field(line, 37, 46)))

    return FRRecord(
        constraint_code = constraint_code,
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
        plant_code = plant_code,
        coefficient = coefficient,
    )
end

"""
    parse_fc(line, filename, line_num) -> FCRecord

Parse FC record (special load coefficient in electrical constraint).
"""
function parse_fc(line::AbstractString, filename::AbstractString, line_num::Int)
    constraint_code = parse_int(strip(extract_field(line, 5, 7)))
    start_day, start_hour, start_half =
        parse_stage_date(line, 11; special_char = "I", file = filename, line_num = line_num)
    end_day, end_hour, end_half =
        parse_stage_date(line, 19; special_char = "F", file = filename, line_num = line_num)
    load_code = parse_int(strip(extract_field(line, 27, 29)))
    coefficient = parse_float(strip(extract_field(line, 37, 46)))

    return FCRecord(
        constraint_code = constraint_code,
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
        load_code = load_code,
        coefficient = coefficient,
    )
end

"""
    parse_tx(line, filename, line_num) -> TXRecord

Parse TX record (discount rate).
"""
function parse_tx(line::AbstractString, filename::AbstractString, line_num::Int)
    rate = parse_float(strip(extract_field(line, 5, 14)))
    return TXRecord(rate = rate)
end

"""
    parse_ez(line, filename, line_num) -> EZRecord

Parse EZ record (maximum useful volume percentage for coupling).
"""
function parse_ez(line::AbstractString, filename::AbstractString, line_num::Int)
    plant_code = parse_int(strip(extract_field(line, 5, 7)))
    volume_pct = parse_float(strip(extract_field(line, 10, 14)))
    return EZRecord(plant_code = plant_code, volume_pct = volume_pct)
end

"""
    parse_r11(line, filename, line_num) -> R11Record

Parse R11 record (Gauge 11 level variation constraints).
"""
function parse_r11(line::AbstractString, filename::AbstractString, line_num::Int)
    start_day, start_hour, start_half =
        parse_stage_date(line, 5; special_char = "I", file = filename, line_num = line_num)
    end_day, end_hour, end_half =
        parse_stage_date(line, 13; special_char = "F", file = filename, line_num = line_num)
    initial_level = parse_float(strip(extract_field(line, 21, 30)))
    max_hourly_variation = parse_float(strip(extract_field(line, 31, 40)))
    max_daily_variation = parse_float(strip(extract_field(line, 41, 50)))

    return R11Record(
        start_day = start_day,
        start_hour = start_hour,
        start_half = start_half,
        end_day = end_day,
        end_hour = end_hour,
        end_half = end_half,
        initial_level = initial_level,
        max_hourly_variation = max_hourly_variation,
        max_daily_variation = max_daily_variation,
    )
end

"""
    parse_fp(line, filename, line_num) -> FPRecord

Parse FP record (production function approximation parameters).

# IDESEM Reference
idessem/dessem/modelos/entdados.py - FP class
"""
function parse_fp(line::AbstractString, filename::AbstractString, line_num::Int)
    plant_code = parse_int(strip(extract_field(line, 4, 6)))
    volume_treatment = parse_int(strip(extract_field(line, 8, 8)))
    turbine_points = parse_int(strip(extract_field(line, 11, 13)))
    volume_points = parse_int(strip(extract_field(line, 16, 18)))
    # Optional fields - can be blank
    check_concavity = parse_int(strip(extract_field(line, 21, 21)), allow_blank = true)
    least_squares = parse_int(strip(extract_field(line, 25, 25)), allow_blank = true)
    volume_window_pct = parse_float(strip(extract_field(line, 30, 39)), allow_blank = true)
    deviation_tolerance =
        parse_float(strip(extract_field(line, 40, 49)), allow_blank = true)

    return FPRecord(
        plant_code = plant_code,
        volume_treatment = volume_treatment,
        turbine_points = turbine_points,
        volume_points = volume_points,
        check_concavity = check_concavity,
        least_squares = least_squares,
        volume_window_pct = volume_window_pct,
        deviation_tolerance = deviation_tolerance,
    )
end

"""
    parse_secr(line, filename, line_num) -> SECRRecord

Parse SECR record (river section definition).
"""
function parse_secr(line::AbstractString, filename::AbstractString, line_num::Int)
    section_code = parse_int(strip(extract_field(line, 6, 8)))
    section_name = strip(extract_field(line, 10, 21))

    upstream_plant_1 = parse_int(strip(extract_field(line, 25, 27)), allow_blank = true)
    participation_1 = parse_float(strip(extract_field(line, 29, 33)), allow_blank = true)
    upstream_plant_2 = parse_int(strip(extract_field(line, 35, 37)), allow_blank = true)
    participation_2 = parse_float(strip(extract_field(line, 39, 43)), allow_blank = true)
    upstream_plant_3 = parse_int(strip(extract_field(line, 45, 47)), allow_blank = true)
    participation_3 = parse_float(strip(extract_field(line, 49, 53)), allow_blank = true)
    upstream_plant_4 = parse_int(strip(extract_field(line, 55, 57)), allow_blank = true)
    participation_4 = parse_float(strip(extract_field(line, 59, 63)), allow_blank = true)
    upstream_plant_5 = parse_int(strip(extract_field(line, 65, 67)), allow_blank = true)
    participation_5 = parse_float(strip(extract_field(line, 69, 73)), allow_blank = true)

    return SECRRecord(
        section_code = section_code,
        section_name = section_name,
        upstream_plant_1 = upstream_plant_1,
        participation_1 = participation_1,
        upstream_plant_2 = upstream_plant_2,
        participation_2 = participation_2,
        upstream_plant_3 = upstream_plant_3,
        participation_3 = participation_3,
        upstream_plant_4 = upstream_plant_4,
        participation_4 = participation_4,
        upstream_plant_5 = upstream_plant_5,
        participation_5 = participation_5,
    )
end

"""
    parse_cr(line, filename, line_num) -> CRRecord

Parse CR record (river section head-flow polynomial).
"""
function parse_cr(line::AbstractString, filename::AbstractString, line_num::Int)
    section_code = parse_int(strip(extract_field(line, 5, 7)))
    section_name = strip(extract_field(line, 10, 21))
    polynomial_degree = parse_int(strip(extract_field(line, 25, 26)))

    # Parse coefficients (in scientific notation format "E")
    a0 = parse_float(strip(extract_field(line, 28, 42)), allow_blank = true)
    a1 = parse_float(strip(extract_field(line, 44, 58)), allow_blank = true)
    a2 = parse_float(strip(extract_field(line, 60, 74)), allow_blank = true)
    a3 = parse_float(strip(extract_field(line, 76, 90)), allow_blank = true)
    a4 = parse_float(strip(extract_field(line, 92, 106)), allow_blank = true)
    a5 = parse_float(strip(extract_field(line, 108, 122)), allow_blank = true)
    a6 = parse_float(strip(extract_field(line, 124, 138)), allow_blank = true)

    return CRRecord(
        section_code = section_code,
        section_name = section_name,
        polynomial_degree = polynomial_degree,
        a0 = something(a0, 0.0),
        a1 = something(a1, 0.0),
        a2 = something(a2, 0.0),
        a3 = something(a3, 0.0),
        a4 = something(a4, 0.0),
        a5 = something(a5, 0.0),
        a6 = something(a6, 0.0),
    )
end

"""
    parse_ac(line, filename, line_num) -> ACRecord

Parse AC record (plant configuration adjustment).
AC records have variable formats depending on the adjustment type.
"""
function parse_ac(line::AbstractString, filename::AbstractString, line_num::Int)
    plant_code = parse_int(strip(extract_field(line, 5, 7)))
    ac_type = strip(extract_field(line, 10, 20))

    # Parse values - the values start around column 21
    remainder = strip(line[min(21, length(line)):end])
    parts = split(remainder)

    local int_value = nothing
    local int_value2 = nothing
    local float_value = nothing

    # Try parsing each part individually
    if length(parts) >= 2
        # Two values
        try
            int_value = parse_int(parts[1], allow_blank = true)
        catch
            # First value is a float
            float_value = parse_float(parts[1], allow_blank = true)
        end

        # Try parsing second value
        try
            int_value2 = parse_int(parts[2], allow_blank = true)
        catch
            # Second value is a float - if first was also parsed, this is float_value
            if int_value === nothing
                # Already got the float in the first position
            else
                # int + float case
                float_value = parse_float(parts[2], allow_blank = true)
            end
        end
    elseif length(parts) == 1
        # Single value - try as integer first, then as float
        try
            int_value = parse_int(parts[1], allow_blank = true)
        catch
            float_value = parse_float(parts[1], allow_blank = true)
        end
    end

    return ACRecord(
        plant_code = plant_code,
        ac_type = ac_type,
        int_value = int_value,
        float_value = float_value,
        int_value2 = int_value2,
    )
end

"""
    parse_ag(line, filename, line_num) -> AGRecord

Parse AG record (aggregate/group record).
"""
function parse_ag(line::AbstractString, filename::AbstractString, line_num::Int)
    group_type = strip(extract_field(line, 5, 8))
    group_id = parse_int(strip(extract_field(line, 10, 12)), allow_blank = true)
    description = strip(extract_field(line, 15, 40))

    return AGRecord(group_type = group_type, group_id = group_id, description = description)
end

"""
    parse_ia(line, filename, line_num) -> IARecord

Parse IA record (interchange limits between subsystems).
"""
function parse_ia(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:subsystem_from, 5, 6, String, required = true),
        FieldSpec(:subsystem_to, 10, 11, String, required = true),
        FieldSpec(:capacity_from_to, 30, 39, Float64, required = true),
        FieldSpec(:capacity_to_from, 40, 49, Float64, required = true),
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    day_start, hour_start, half_start =
        parse_stage_date(line, 14; special_char = "I", file = filename, line_num = line_num)
    day_end, hour_end, half_end =
        parse_stage_date(line, 22; special_char = "F", file = filename, line_num = line_num)

    return IARecord(
        subsystem_from = strip(values[:subsystem_from]),
        subsystem_to = strip(values[:subsystem_to]),
        day_start = day_start,
        hour_start = hour_start,
        half_hour_start = half_start,
        day_end = day_end,
        hour_end = hour_end,
        half_hour_end = half_end,
        capacity_from_to = values[:capacity_from_to],
        capacity_to_from = values[:capacity_to_from],
    )
end

"""
    parse_cd(line, filename, line_num) -> CDRecord

Parse CD record (deficit cost curves).
"""
function parse_cd(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:subsystem, 5, 6, Int, required = true),
        FieldSpec(:curve_number, 8, 9, Int, required = true),
        FieldSpec(:cost, 28, 37, Float64, required = true),
        FieldSpec(:upper_limit, 39, 48, Float64, required = true),
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    day_start, hour_start, half_start =
        parse_stage_date(line, 11; special_char = "I", file = filename, line_num = line_num)
    day_end, hour_end, half_end =
        parse_stage_date(line, 19; special_char = "F", file = filename, line_num = line_num)

    return CDRecord(
        subsystem = values[:subsystem],
        curve_number = values[:curve_number],
        day_start = day_start,
        hour_start = hour_start,
        half_hour_start = half_start,
        day_end = day_end,
        hour_end = hour_end,
        half_hour_end = half_end,
        cost = values[:cost],
        upper_limit = values[:upper_limit],
    )
end

"""
    parse_ve(line, filename, line_num) -> VERecord

Parse VE record (flood control volumes).
"""
function parse_ve(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:plant_num, 5, 7, Int, required = true),
        FieldSpec(:volume, 26, 35, Float64, required = true),
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    day_start, hour_start, half_start =
        parse_stage_date(line, 9; special_char = "I", file = filename, line_num = line_num)
    day_end, hour_end, half_end =
        parse_stage_date(line, 17; special_char = "F", file = filename, line_num = line_num)

    return VERecord(
        plant_num = values[:plant_num],
        day_start = day_start,
        hour_start = hour_start,
        half_hour_start = half_start,
        day_end = day_end,
        hour_end = hour_end,
        half_hour_end = half_end,
        volume = values[:volume],
    )
end

"""
    parse_ri(line, filename, line_num) -> RIRecord

Parse RI record (Itaipu restrictions).
"""
function parse_ri(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:gen_min_50hz, 29, 36, Float64, required = true),
        FieldSpec(:gen_max_50hz, 39, 46, Float64, required = true),
        FieldSpec(:gen_min_60hz, 49, 56, Float64, required = true),
        FieldSpec(:gen_max_60hz, 59, 66, Float64, required = true),
        FieldSpec(:ande_load, 69, 76, Float64, required = true),
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    day_start, hour_start, half_start =
        parse_stage_date(line, 2; special_char = "I", file = filename, line_num = line_num)
    day_end, hour_end, half_end =
        parse_stage_date(line, 10; special_char = "F", file = filename, line_num = line_num)

    return RIRecord(
        day_start = day_start,
        hour_start = hour_start,
        half_hour_start = half_start,
        day_end = day_end,
        hour_end = hour_end,
        half_hour_end = half_end,
        gen_min_50hz = values[:gen_min_50hz],
        gen_max_50hz = values[:gen_max_50hz],
        gen_min_60hz = values[:gen_min_60hz],
        gen_max_60hz = values[:gen_max_60hz],
        ande_load = values[:ande_load],
    )
end

"""
    parse_ce(line, filename, line_num) -> CERecord

Parse CE record (export energy contracts).
"""
function parse_ce(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:contract_num, 4, 6, Int, required = true),
        FieldSpec(:contract_name, 8, 17, String, required = true),
        FieldSpec(:year, 19, 23, Int, required = true),
        FieldSpec(:submkt_code, 24, 24, Int, required = true),
        FieldSpec(:modulation_flag, 42, 42, Int, required = false, default = 0),
        FieldSpec(:min_value, 44, 53, Float64, required = false, default = 0.0),
        FieldSpec(:max_value, 54, 63, Float64, required = false, default = 0.0),
        FieldSpec(:inflexibility, 64, 73, Float64, required = false, default = 0.0),
        FieldSpec(:priority, 74, 83, Float64, required = false, default = 0.0),
        FieldSpec(:availability_flag, 86, 86, Int, required = false, default = 0),
        FieldSpec(:cost, 89, 98, Float64, required = false, default = 0.0),
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    day_start, hour_start, half_start =
        parse_stage_date(line, 26; special_char = "I", file = filename, line_num = line_num)
    day_end, hour_end, half_end =
        parse_stage_date(line, 34; special_char = "F", file = filename, line_num = line_num)

    return CERecord(
        contract_num = values[:contract_num],
        contract_name = strip(values[:contract_name]),
        year = values[:year],
        submkt_code = values[:submkt_code],
        day_start = day_start,
        hour_start = hour_start,
        half_hour_start = half_start,
        day_end = day_end,
        hour_end = hour_end,
        half_hour_end = half_end,
        modulation_flag = something(values[:modulation_flag], 0),
        min_value = something(values[:min_value], 0.0),
        max_value = something(values[:max_value], 0.0),
        inflexibility = something(values[:inflexibility], 0.0),
        priority = something(values[:priority], 0.0),
        availability_flag = something(values[:availability_flag], 0),
        cost = something(values[:cost], 0.0),
    )
end

"""
    parse_ci(line, filename, line_num) -> CIRecord

Parse CI record (import energy contracts).
"""
function parse_ci(line::AbstractString, filename::AbstractString, line_num::Int)
    # Same structure as CE records
    fields = [
        FieldSpec(:contract_num, 4, 6, Int, required = true),
        FieldSpec(:contract_name, 8, 17, String, required = true),
        FieldSpec(:year, 19, 23, Int, required = true),
        FieldSpec(:submkt_code, 24, 24, Int, required = true),
        FieldSpec(:modulation_flag, 42, 42, Int, required = false, default = 0),
        FieldSpec(:min_value, 44, 53, Float64, required = false, default = 0.0),
        FieldSpec(:max_value, 54, 63, Float64, required = false, default = 0.0),
        FieldSpec(:inflexibility, 64, 73, Float64, required = false, default = 0.0),
        FieldSpec(:priority, 74, 83, Float64, required = false, default = 0.0),
        FieldSpec(:availability_flag, 86, 86, Int, required = false, default = 0),
        FieldSpec(:cost, 89, 98, Float64, required = false, default = 0.0),
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    day_start, hour_start, half_start =
        parse_stage_date(line, 26; special_char = "I", file = filename, line_num = line_num)
    day_end, hour_end, half_end =
        parse_stage_date(line, 34; special_char = "F", file = filename, line_num = line_num)

    return CIRecord(
        contract_num = values[:contract_num],
        contract_name = strip(values[:contract_name]),
        year = values[:year],
        submkt_code = values[:submkt_code],
        day_start = day_start,
        hour_start = hour_start,
        half_hour_start = half_start,
        day_end = day_end,
        hour_end = hour_end,
        half_hour_end = half_end,
        modulation_flag = something(values[:modulation_flag], 0),
        min_value = something(values[:min_value], 0.0),
        max_value = something(values[:max_value], 0.0),
        inflexibility = something(values[:inflexibility], 0.0),
        priority = something(values[:priority], 0.0),
        availability_flag = something(values[:availability_flag], 0),
        cost = something(values[:cost], 0.0),
    )
end

"""
    parse_de(line, filename, line_num) -> DERecord

Parse DE record (special demand).
"""
function parse_de(line::AbstractString, filename::AbstractString, line_num::Int)
    fields = [
        FieldSpec(:demand_code, 5, 7, Int, required = true),
        FieldSpec(:description, 9, 40, String, required = true),
    ]

    values = extract_fields(line, fields, file = filename, line_num = line_num)

    return DERecord(
        demand_code = values[:demand_code],
        description = strip(values[:description]),
    )
end

"""
    parse_ni(line, filename, line_num) -> NIRecord

Parse NI record (network configuration).
"""
function parse_ni(line::AbstractString, filename::AbstractString, line_num::Int)
    # NI records contain configuration text
    option_text = strip(extract_field(line, 5, 80))

    return NIRecord(option_text = option_text)
end

"""
    parse_gp(line, filename, line_num) -> GPRecord

Parse GP record (convergence tolerance gaps for PDD or MILP methods).

# Format
Columns 1-4: Record type "GP  "
Columns 5-14: PDD gap (FloatField(10, 4, 8))
Columns 15-24: MILP gap (FloatField(10, 14, 8))
"""
function parse_gp(line::AbstractString, filename::AbstractString, line_num::Int)
    # Parse PDD gap (columns 5-14)
    gap_pdd_str = strip(extract_field(line, 5, 14))
    gap_pdd = isempty(gap_pdd_str) ? nothing : tryparse(Float64, gap_pdd_str)

    # Parse MILP gap (columns 15-24)
    gap_milp_str = strip(extract_field(line, 15, 24))
    gap_milp = isempty(gap_milp_str) ? nothing : tryparse(Float64, gap_milp_str)

    return GPRecord(gap_pdd = gap_pdd, gap_milp = gap_milp)
end

"""
    parse_ree(line::AbstractString, filename::AbstractString, line_num::Int) -> REERecord

Parse REE record (energy reservoir equivalent).

# IDESEM Reference
idessem/dessem/modelos/entdados.py - REE class:
- IntegerField(2, 6): ree_code (0-indexed positions 6-7 → 1-indexed 7-8)
- IntegerField(2, 9): subsystem_code (0-indexed 9-10 → 1-indexed 10-11)  
- LiteralField(10, 12): ree_name (0-indexed 12-21 → 1-indexed 13-22)

# Format
- Columns 7-8: ree_code (I2)
- Columns 10-11: subsystem_code (I2)
- Columns 13-22: ree_name (A10)
"""
function parse_ree(line::AbstractString, filename::AbstractString, line_num::Int)
    ree_code = parse_int(strip(extract_field(line, 7, 8)))
    subsystem_code = parse_int(strip(extract_field(line, 10, 11)))
    ree_name = strip(extract_field(line, 13, 22))

    return REERecord(
        ree_code = ree_code,
        subsystem_code = subsystem_code,
        ree_name = ree_name,
    )
end

"""
    parse_tviag(line::AbstractString, filename::AbstractString, line_num::Int) -> TVIAGRecord

Parse TVIAG record (water travel time).

# IDESEM Reference
idessem/dessem/modelos/entdados.py - TVIAG class:
- IntegerField(3, 6): upstream_plant (0-indexed 6-8 → 1-indexed 7-9)
- IntegerField(3, 10): downstream_element (0-indexed 10-12 → 1-indexed 11-13)
- LiteralField(1, 14): element_type (0-indexed 14 → 1-indexed 15)
- IntegerField(3, 19): duration (0-indexed 19-21 → 1-indexed 20-22)
- IntegerField(1, 24): travel_type (0-indexed 24 → 1-indexed 25)

# Format
- Columns 7-9: upstream_plant (I3)
- Columns 11-13: downstream_element (I3)
- Column 15: element_type (A1) - "H" for hydro, "S" for section
- Columns 20-22: duration in hours (I3)
- Column 25: travel_type (I1) - 1=translation, 2=propagation
"""
function parse_tviag(line::AbstractString, filename::AbstractString, line_num::Int)
    upstream_plant = parse_int(strip(extract_field(line, 7, 9)))
    downstream_element = parse_int(strip(extract_field(line, 11, 13)))
    element_type = strip(extract_field(line, 15, 15))
    duration = parse_int(strip(extract_field(line, 20, 22)))
    travel_type = parse_int(strip(extract_field(line, 25, 25)))

    return TVIAGRecord(
        upstream_plant = upstream_plant,
        downstream_element = downstream_element,
        element_type = element_type,
        duration = duration,
        travel_type = travel_type,
    )
end

"""
    parse_rivar(line::AbstractString, filename::AbstractString, line_num::Int) -> RIVARRecord

Parse RIVAR record (variable restriction).

# IDESEM Reference
idessem/dessem/modelos/entdados.py - RIVAR class:
- IntegerField(3, 7): entity_code (0-indexed 7-9 → 1-indexed 8-10)
- IntegerField(3, 12): to_system (0-indexed 12-14 → 1-indexed 13-15)
- IntegerField(2, 15): variable_type (0-indexed 15-16 → 1-indexed 16-17)
- FloatField(10, 19): penalty (0-indexed 19-28 → 1-indexed 20-29)

# Format
- Columns 8-10: entity_code (I3) 
- Columns 13-15: to_system (I3) - optional for interchange restrictions
- Columns 16-17: variable_type (I2)
- Columns 20-29: penalty (F10.x) - optional
"""
function parse_rivar(line::AbstractString, filename::AbstractString, line_num::Int)
    entity_code = parse_int(strip(extract_field(line, 8, 10)))

    # to_system is optional - may be empty for non-interchange restrictions
    to_system_str = strip(extract_field(line, 13, 15))
    to_system = parse_int(to_system_str, allow_blank = true)

    variable_type = parse_int(strip(extract_field(line, 16, 17)))

    # penalty is optional - may not be present if line is short
    penalty = if length(line) >= 29
        penalty_str = strip(extract_field(line, 20, 29))
        parse_float(penalty_str, allow_blank = true)
    else
        nothing
    end

    return RIVARRecord(
        entity_code = entity_code,
        to_system = to_system,
        variable_type = variable_type,
        penalty = penalty,
    )
end

"""
    parse_usie(line::AbstractString, filename::AbstractString, line_num::Int) -> USIERecord

Parse USIE record (pump station).

# IDESEM Reference
idessem/dessem/modelos/entdados.py - USIE class:
- IntegerField(3, 5): plant_code (0-indexed 5-7 → 1-indexed 6-8)
- IntegerField(2, 9): subsystem_code (0-indexed 9-10 → 1-indexed 10-11)
- LiteralField(12, 14): plant_name (0-indexed 14-25 → 1-indexed 15-26)
- IntegerField(3, 29): upstream_plant (0-indexed 29-31 → 1-indexed 30-32)
- IntegerField(3, 34): downstream_plant (0-indexed 34-36 → 1-indexed 35-37)
- FloatField(10, 39, 3): min_pump_flow (0-indexed 39-48 → 1-indexed 40-49)
- FloatField(10, 49, 3): max_pump_flow (0-indexed 49-58 → 1-indexed 50-59)
- FloatField(10, 59, 3): consumption_rate (0-indexed 59-68 → 1-indexed 60-69)

# Format
- Columns 6-8: plant_code (I3)
- Columns 10-11: subsystem_code (I2)
- Columns 15-26: plant_name (A12)
- Columns 30-32: upstream_plant (I3)
- Columns 35-37: downstream_plant (I3)
- Columns 40-49: min_pump_flow in m³/s (F10.3)
- Columns 50-59: max_pump_flow in m³/s (F10.3)
- Columns 60-69: consumption_rate in MWmed/m³/s (F10.3)
"""
function parse_usie(line::AbstractString, filename::AbstractString, line_num::Int)
    plant_code = parse_int(strip(extract_field(line, 6, 8)))
    subsystem_code = parse_int(strip(extract_field(line, 10, 11)))
    plant_name = strip(extract_field(line, 15, 26))
    upstream_plant = parse_int(strip(extract_field(line, 30, 32)))
    downstream_plant = parse_int(strip(extract_field(line, 35, 37)))
    min_pump_flow = parse_float(strip(extract_field(line, 40, 49)))
    max_pump_flow = parse_float(strip(extract_field(line, 50, 59)))
    consumption_rate = parse_float(strip(extract_field(line, 60, 69)))

    return USIERecord(
        plant_code = plant_code,
        subsystem_code = subsystem_code,
        plant_name = plant_name,
        upstream_plant = upstream_plant,
        downstream_plant = downstream_plant,
        min_pump_flow = min_pump_flow,
        max_pump_flow = max_pump_flow,
        consumption_rate = consumption_rate,
    )
end

"""
    parse_rd(line::AbstractString, filename::AbstractString, line_num::Int) -> RDRecord

Parse RD record (network representation options).

# IDESEM Reference
idessem/dessem/modelos/entdados.py - RD class:
- IntegerField(1, 4): slack_variables (0-indexed 4 → 1-indexed 5)
- IntegerField(3, 9): max_violated_circuits (0-indexed 9-11 → 1-indexed 10-12)
- IntegerField(1, 14): load_dbar_register (0-indexed 14 → 1-indexed 15)
- IntegerField(1, 16): ignore_bars (0-indexed 16 → 1-indexed 17)
- IntegerField(1, 18): circuit_limits_drefs (0-indexed 18 → 1-indexed 19)
- IntegerField(1, 20): consider_losses (0-indexed 20 → 1-indexed 21)
- IntegerField(1, 22): network_file_format (0-indexed 22 → 1-indexed 23)

# Format
- Column 5: slack_variables (I1)
- Columns 10-12: max_violated_circuits (I3)
- Column 15: load_dbar_register (I1)
- Column 17: ignore_bars (I1)
- Column 19: circuit_limits_drefs (I1)
- Column 21: consider_losses (I1)
- Column 23: network_file_format (I1)
"""
function parse_rd(line::AbstractString, filename::AbstractString, line_num::Int)
    slack_variables = parse_int(strip(extract_field(line, 5, 5)))
    max_violated_circuits = parse_int(strip(extract_field(line, 10, 12)))
    load_dbar_register = parse_int(strip(extract_field(line, 15, 15)))

    # Optional fields - may not be present in all records (check line length)
    ignore_bars = if length(line) >= 17
        parse_int(strip(extract_field(line, 17, 17)), allow_blank = true)
    else
        nothing
    end

    circuit_limits_drefs = if length(line) >= 19
        parse_int(strip(extract_field(line, 19, 19)), allow_blank = true)
    else
        nothing
    end

    consider_losses = if length(line) >= 21
        parse_int(strip(extract_field(line, 21, 21)), allow_blank = true)
    else
        nothing
    end

    network_file_format = if length(line) >= 23
        parse_int(strip(extract_field(line, 23, 23)), allow_blank = true)
    else
        nothing
    end

    return RDRecord(
        slack_variables = slack_variables,
        max_violated_circuits = max_violated_circuits,
        load_dbar_register = load_dbar_register,
        ignore_bars = ignore_bars,
        circuit_limits_drefs = circuit_limits_drefs,
        consider_losses = consider_losses,
        network_file_format = network_file_format,
    )
end

# ============================================================================
# Main Parser
# ============================================================================

"""
    parse_entdados(filepath::AbstractString) -> GeneralData

Parse ENTDADOS.XXX file and return GeneralData structure.

Processes TM, SIST, UH, UT, and DP records. Skips unknown record types with warning.
"""
function parse_entdados(filepath::AbstractString)
    filename = basename(filepath)
    open(filepath, "r") do io
        parse_entdados(io, filename)
    end
end

"""
    parse_entdados(io::IO, filename::AbstractString="entdados.dat") -> GeneralData

Parse ENTDADOS data from an IO stream and return GeneralData structure.

Processes TM, SIST, UH, UT, and DP records. Skips unknown record types with warning.
"""
function parse_entdados(io::IO, filename::AbstractString = "entdados.dat")
    time_periods = TMRecord[]
    subsystems = SISTRecord[]
    energy_reservoirs = REERecord[]
    hydro_plants = UHRecord[]
    travel_times = TVIAGRecord[]
    thermal_plants = UTRecord[]
    pump_stations = USIERecord[]
    demands = DPRecord[]
    diversions = DARecord[]
    hydro_maint = MHRecord[]
    thermal_maint = MTRecord[]
    electrical_constraints = RERecord[]
    constraint_limits = LURecord[]
    hydro_coefficients = FHRecord[]
    thermal_coefficients = FTRecord[]
    interchange_coefficients = FIRecord[]
    contract_coefficients = FERecord[]
    renewable_coefficients = FRRecord[]
    load_coefficients = FCRecord[]
    discount_rate = TXRecord[]
    coupling_volumes = EZRecord[]
    gauge11_constraints = R11Record[]
    fpha_parameters = FPRecord[]
    river_sections = SECRRecord[]
    section_polynomials = CRRecord[]
    plant_adjustments = ACRecord[]
    aggregate_groups = AGRecord[]
    interchange_limits = IARecord[]
    deficit_costs = CDRecord[]
    flood_volumes = VERecord[]
    itaipu_restrictions = RIRecord[]
    export_contracts = CERecord[]
    import_contracts = CIRecord[]
    special_demands = DERecord[]
    network_config = NIRecord[]
    tolerance_gaps = GPRecord[]
    variable_restrictions = RIVARRecord[]
    network_options = RDRecord[]
    fpha_parameters = FPRecord[]
    river_sections = SECRRecord[]
    section_polynomials = CRRecord[]
    plant_adjustments = ACRecord[]
    aggregate_groups = AGRecord[]
    interchange_limits = IARecord[]
    deficit_costs = CDRecord[]
    flood_volumes = VERecord[]
    itaipu_restrictions = RIRecord[]
    export_contracts = CERecord[]
    import_contracts = CIRecord[]
    special_demands = DERecord[]
    network_config = NIRecord[]
    tolerance_gaps = GPRecord[]

    line_num = 0
    for line in eachline(io)
        line_num += 1

        # Skip blank lines and comments
        is_blank(line) && continue
        is_comment_line(line) && continue

        # Extract record type - get first 2-6 chars up to first space/digit
        # Need to handle longer record types like "TVIAG" (5 chars), "RIVAR" (5 chars)
        record_type_raw = uppercase(strip(extract_field(line, 1, 6)))
        # Keep only alphabetic characters (handles "CE 3" → "CE", "SIST" → "SIST", "TVIAG" → "TVIAG")
        record_type = match(r"^([A-Z]+)", record_type_raw)
        record_type = record_type === nothing ? record_type_raw : record_type.captures[1]

        try
            if record_type == "TM"
                push!(time_periods, parse_tm(line, filename, line_num))
            elseif record_type == "SIST"
                push!(subsystems, parse_sist(line, filename, line_num))
            elseif record_type == "REE"
                push!(energy_reservoirs, parse_ree(line, filename, line_num))
            elseif record_type == "UH"
                push!(hydro_plants, parse_uh(line, filename, line_num))
            elseif record_type == "TVIAG"
                push!(travel_times, parse_tviag(line, filename, line_num))
            elseif record_type == "UT"
                push!(thermal_plants, parse_ut(line, filename, line_num))
            elseif record_type == "USIE"
                push!(pump_stations, parse_usie(line, filename, line_num))
            elseif record_type == "RIVAR" || record_type == "RIVA"
                push!(variable_restrictions, parse_rivar(line, filename, line_num))
            elseif record_type == "DP"
                push!(demands, parse_dp(line, filename, line_num))
            elseif record_type == "DA"
                push!(diversions, parse_da(line, filename, line_num))
            elseif record_type == "MH"
                push!(hydro_maint, parse_mh(line, filename, line_num))
            elseif record_type == "MT"
                push!(thermal_maint, parse_mt(line, filename, line_num))
            elseif record_type == "RE"
                push!(electrical_constraints, parse_re(line, filename, line_num))
            elseif record_type == "LU"
                push!(constraint_limits, parse_lu(line, filename, line_num))
            elseif record_type == "FH"
                push!(hydro_coefficients, parse_fh(line, filename, line_num))
            elseif record_type == "FT"
                push!(thermal_coefficients, parse_ft(line, filename, line_num))
            elseif record_type == "FI"
                push!(interchange_coefficients, parse_fi(line, filename, line_num))
            elseif record_type == "FE"
                push!(contract_coefficients, parse_fe(line, filename, line_num))
            elseif record_type == "FR"
                push!(renewable_coefficients, parse_fr(line, filename, line_num))
            elseif record_type == "FC"
                push!(load_coefficients, parse_fc(line, filename, line_num))
            elseif record_type == "TX"
                push!(discount_rate, parse_tx(line, filename, line_num))
            elseif record_type == "EZ"
                push!(coupling_volumes, parse_ez(line, filename, line_num))
            elseif record_type == "R11"
                push!(gauge11_constraints, parse_r11(line, filename, line_num))
            elseif record_type == "FP"
                push!(fpha_parameters, parse_fp(line, filename, line_num))
            elseif record_type == "SECR"
                push!(river_sections, parse_secr(line, filename, line_num))
            elseif record_type == "CR"
                push!(section_polynomials, parse_cr(line, filename, line_num))
            elseif record_type == "AC"
                push!(plant_adjustments, parse_ac(line, filename, line_num))
            elseif record_type == "AG"
                push!(aggregate_groups, parse_ag(line, filename, line_num))
            elseif record_type == "IA"
                push!(interchange_limits, parse_ia(line, filename, line_num))
            elseif record_type == "CD"
                push!(deficit_costs, parse_cd(line, filename, line_num))
            elseif record_type == "VE"
                push!(flood_volumes, parse_ve(line, filename, line_num))
            elseif record_type == "RI"
                push!(itaipu_restrictions, parse_ri(line, filename, line_num))
            elseif record_type == "CE"
                push!(export_contracts, parse_ce(line, filename, line_num))
            elseif record_type == "CI"
                push!(import_contracts, parse_ci(line, filename, line_num))
            elseif record_type == "DE"
                push!(special_demands, parse_de(line, filename, line_num))
            elseif record_type == "NI"
                push!(network_config, parse_ni(line, filename, line_num))
            elseif record_type == "RD"
                push!(network_options, parse_rd(line, filename, line_num))
            elseif record_type == "GP"
                push!(tolerance_gaps, parse_gp(line, filename, line_num))
            else
                # Skip unknown record types
                if !startswith(record_type, "&")  # Don't warn for comment lines
                    @warn "Unknown record type in $filename line $line_num: $record_type"
                end
            end
        catch e
            if isa(e, ParserError)
                rethrow(e)
            else
                throw(
                    ParserError(
                        "Error parsing $record_type record: $(e)",
                        filename,
                        line_num,
                        line,
                    ),
                )
            end
        end
    end

    return GeneralData(
        time_periods = time_periods,
        subsystems = subsystems,
        energy_reservoirs = energy_reservoirs,
        hydro_plants = hydro_plants,
        travel_times = travel_times,
        thermal_plants = thermal_plants,
        pump_stations = pump_stations,
        demands = demands,
        diversions = diversions,
        hydro_maintenance = hydro_maint,
        thermal_maintenance = thermal_maint,
        electrical_constraints = electrical_constraints,
        constraint_limits = constraint_limits,
        hydro_coefficients = hydro_coefficients,
        thermal_coefficients = thermal_coefficients,
        interchange_coefficients = interchange_coefficients,
        contract_coefficients = contract_coefficients,
        renewable_coefficients = renewable_coefficients,
        load_coefficients = load_coefficients,
        discount_rate = discount_rate,
        coupling_volumes = coupling_volumes,
        gauge11_constraints = gauge11_constraints,
        fpha_parameters = fpha_parameters,
        river_sections = river_sections,
        section_polynomials = section_polynomials,
        plant_adjustments = plant_adjustments,
        aggregate_groups = aggregate_groups,
        interchange_limits = interchange_limits,
        deficit_costs = deficit_costs,
        flood_volumes = flood_volumes,
        itaipu_restrictions = itaipu_restrictions,
        export_contracts = export_contracts,
        import_contracts = import_contracts,
        special_demands = special_demands,
        network_config = network_config,
        network_options = network_options,
        variable_restrictions = variable_restrictions,
        tolerance_gaps = tolerance_gaps,
    )
end

end # module
