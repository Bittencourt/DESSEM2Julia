# BATERIA.XXX Parser - Fixed-Width Column Format
# Based on dessem-complete-specs.md § 13 - Battery Storage Data
#
# BATERIA.XXX uses FIXED-WIDTH columns format.

module BateriaParser

using ..DESSEM2Julia: BateriaRecord, BateriaData
using ..ParserCommon: extract_field, is_comment_line, is_blank

"""
    parse_bateria_record(line, filename, line_num) -> BateriaRecord

Parse a single BATERIA record from a line using FIXED-WIDTH columns.

# Column positions (from dessem-complete-specs.md):
- Columns 1-3: Battery number (I3)
- Columns 5-16: Battery name (A12)
- Columns 20-21: Subsystem number (I2)
- Columns 25-34: Charging capacity (F10.0)
- Columns 40-49: Discharging capacity (F10.0)
- Columns 55-64: Energy capacity (F10.0)
- Columns 70-79: Initial energy (F10.0, optional)
- Columns 85-94: Charging efficiency (F10.0, optional)
- Columns 100-109: Discharging efficiency (F10.0, optional)

# Example:
```
  1  BATERIA-1     1     100.000      100.000      500.000        0.000          0.90           0.90
```
"""
function parse_bateria_record(line::AbstractString, filename::AbstractString, line_num::Int)
    # Required fields
    battery_num = parse(Int, strip(extract_field(line, 1, 3)))
    battery_name = strip(extract_field(line, 5, 16))
    subsystem_num = parse(Int, strip(extract_field(line, 20, 21)))
    charging_capacity = parse(Float64, strip(extract_field(line, 25, 34)))
    discharging_capacity = parse(Float64, strip(extract_field(line, 40, 49)))
    energy_capacity = parse(Float64, strip(extract_field(line, 55, 64)))
    
    # Optional fields - return nothing if empty
    initial_energy_str = strip(extract_field(line, 70, 79))
    initial_energy = isempty(initial_energy_str) ? nothing : parse(Float64, initial_energy_str)
    
    charging_efficiency_str = strip(extract_field(line, 85, 94))
    charging_efficiency = isempty(charging_efficiency_str) ? nothing : parse(Float64, charging_efficiency_str)
    
    discharging_efficiency_str = strip(extract_field(line, 100, 109))
    discharging_efficiency = isempty(discharging_efficiency_str) ? nothing : parse(Float64, discharging_efficiency_str)
    
    return BateriaRecord(
        battery_num = battery_num,
        battery_name = battery_name,
        subsystem_num = subsystem_num,
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

Parse complete BATERIA.XXX file.
"""
function parse_bateria(io::IO, filename::AbstractString)
    records = BateriaRecord[]
    
    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue
        
        # Check for common end markers
        stripped = strip(line)
        (startswith(stripped, "FIM") || startswith(stripped, "9999")) && break
        
        # Skip header line (usually just "BATERIA")
        if occursin(r"^BATERIA$"i, stripped)
            continue
        end
        
        # Parse record
        try
            record = parse_bateria_record(line, filename, line_num)
            push!(records, record)
        catch e
            # Provide context for parsing errors
            rethrow(
                ErrorException(
                    "Error parsing line $line_num in $filename: $line. Error: $e",
                ),
            )
        end
    end
    
    return BateriaData(records = records)
end

# Convenience method for filename
parse_bateria(filename::AbstractString) = open(io -> parse_bateria(io, filename), filename)

export parse_bateria, parse_bateria_record

end # module
