module BateriaParser

using ..DESSEM2Julia: BateriaRecord, BateriaData
using ..ParserCommon: extract_field, parse_int, parse_float, is_comment_line, is_blank

export parse_bateria, parse_bateria_record

"""
    parse_bateria_record(line, filename, line_num) -> BateriaRecord

Parse a single BATERIA record from a line.

# IDESEM Reference
idessem/dessem/modelos/bateria.py

# Columns
- 1-3: Battery number (I3)
- 5-16: Battery name (A12)
- 20-21: Subsystem number (I2)
- 25-34: Charging capacity (F10.0)
- 40-49: Discharging capacity (F10.0)
- 55-64: Energy capacity (F10.0)
- 70-79: Initial energy (F10.0)
- 85-94: Charging efficiency (F10.0)
- 100-109: Discharging efficiency (F10.0)
"""
function parse_bateria_record(line::AbstractString, filename::AbstractString, line_num::Int)
    # Required fields
    battery_id = parse_int(extract_field(line, 1, 3))
    name = extract_field(line, 5, 16)
    subsystem_id = parse_int(extract_field(line, 20, 21))
    charging_capacity = parse_float(extract_field(line, 25, 34))
    subsystem_id = parse_int(extract_field(line, 20, 21))
    charging_capacity = parse_float(extract_field(line, 25, 34))
    discharging_capacity = parse_float(extract_field(line, 40, 49))
    energy_capacity = parse_float(extract_field(line, 55, 64))

    # Optional fields
    initial_energy_str = extract_field(line, 70, 79)
    initial_energy = isempty(initial_energy_str) ? nothing : parse_float(initial_energy_str)

    charging_eff_str = extract_field(line, 85, 94)
    charging_efficiency =
        isempty(charging_eff_str) ? nothing : parse_float(charging_eff_str)

    discharging_eff_str = extract_field(line, 100, 109)
    discharging_efficiency =
        isempty(discharging_eff_str) ? nothing : parse_float(discharging_eff_str)

    return BateriaRecord(
        battery_id = battery_id,
        name = name,
        subsystem_id = subsystem_id,
        charging_capacity = charging_capacity,
        discharging_capacity = discharging_capacity,
        energy_capacity = energy_capacity,
        initial_energy = initial_energy,
        charging_efficiency = charging_efficiency,
        discharging_efficiency = discharging_efficiency,
    )
end

"""
    parse_bateria(io, filename) -> BateriaData

Parse complete BATERIA file.
"""
function parse_bateria(io::IO, filename::AbstractString)
    records = BateriaRecord[]

    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue

        # Parse record
        record = parse_bateria_record(line, filename, line_num)
        push!(records, record)
    end

    return BateriaData(records = records)
end

# Convenience method
parse_bateria(filename::AbstractString) = open(io -> parse_bateria(io, filename), filename)

end # module
