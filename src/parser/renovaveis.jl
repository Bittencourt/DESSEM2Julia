"""
Parser for RENOVAVEIS.DAT - Renewable plant data and characteristics

This file contains renewable energy plant registrations (wind, solar, biomass, etc.)
with their maximum power and capacity factors.

# IDESEM Reference
idessem/dessem/modelos/renovaveis.py

# Format
- Semicolon-delimited fields (NOT fixed-width for this file!)
- Record type: EOLICA
- Fields: codigo_usina, nome, pmax, fcap, cadastro

# Field Specifications (IDESEM - Python 0-indexed)
From IDESEM renovaveis.py:
- IntegerField(5, 0)  - Plant code (5 digits)
- LiteralField(40, 0) - Plant name (40 characters)
- FloatField(10, 0, decimal_digits=0) - Max power in MW (PMAX)
- FloatField(10, 0, decimal_digits=0) - Capacity factor (FCAP)
- IntegerField(1, 0)  - Cadastro flag (0 or 1)
- delimiter=";"

# Notes
- Unlike other DESSEM files, this uses semicolon delimiters!
- Comment lines start with &
- Renewable plants can be wind (UEE), solar (UFV), biomass (UTE), etc.
- PMAX often set to 9999 as placeholder
- FCAP is capacity factor (0.0 to 1.0)
- Cadastro: 0 = not registered, 1 = registered
"""

module RenovaveisParser

using ..DESSEM2Julia:
    RenovaveisRecord,
    RenovaveisSubsystemRecord,
    RenovaveisBusRecord,
    RenovaveisGenerationRecord,
    RenovaveisData
using ..ParserCommon: is_comment_line, is_blank, ParserError

"""
    parse_renovaveis_record(line, filename, line_num) -> RenovaveisRecord

Parse a single EOLICA (renewable plant) record from a semicolon-delimited line.

# IDESEM Reference
idessem/dessem/modelos/renovaveis.py

# Field Order (semicolon-delimited)
1. Record type ("EOLICA")
2. Plant code (Integer, 5 digits)
3. Plant name (String, 40 characters)
4. Maximum power PMAX (Float, MW)
5. Capacity factor FCAP (Float, 0.0-1.0)
6. Cadastro flag (Integer, 0 or 1)

# Example
```
EOLICA ;    1 ;5G260  _MMGD_F_260_00260_MGD             ;      9999 ;1.0 ;0; 
```

# Arguments
- `line`: The line to parse
- `filename`: Source filename for error messages
- `line_num`: Line number for error messages

# Returns
- `RenovaveisRecord` with parsed fields
"""
function parse_renovaveis_record(
    line::AbstractString,
    filename::AbstractString,
    line_num::Int,
)
    # Split by semicolon
    parts = split(line, ';')

    # Should have at least 7 parts (record type + 5 fields + trailing empty)
    if length(parts) < 6
        throw(ParserError("Expected at least 6 semicolon-separated fields, got $(length(parts))", filename, line_num, line))
    end

    # Extract and parse fields
    record_type = strip(parts[1])
    if record_type != "EOLICA"
        throw(ParserError("Expected 'EOLICA', got '$record_type'", filename, line_num, line))
    end

    # Plant code (field 2)
    plant_code_str = strip(parts[2])
    plant_code = parse(Int, plant_code_str)

    # Plant name (field 3) - keep original spacing
    plant_name = strip(parts[3])

    # Maximum power (field 4)
    pmax_str = strip(parts[4])
    pmax = parse(Float64, pmax_str)

    # Capacity factor (field 5)
    fcap_str = strip(parts[5])
    fcap = parse(Float64, fcap_str)

    # Cadastro flag (field 6)
    cadastro_str = strip(parts[6])
    cadastro = parse(Int, cadastro_str)

    return RenovaveisRecord(
        plant_code = plant_code,
        plant_name = plant_name,
        pmax = pmax,
        fcap = fcap,
        cadastro = cadastro,
    )
end

"""
    parse_renovaveis_subsystem_record(line, filename, line_num) -> RenovaveisSubsystemRecord

Parse a single EOLICASUBM (plant-subsystem mapping) record.

# IDESEM Reference
idessem/dessem/modelos/renovaveis.py - EOLICASUBM class

# Field Order
1. Record type ("EOLICASUBM")
2. Plant code (Integer, 5 digits)
3. Subsystem (String, 2 characters: "SE", "S", "NE", "N")

# Example
```
EOLICASUBM ;    1 ;SE ;
```
"""
function parse_renovaveis_subsystem_record(
    line::AbstractString,
    filename::AbstractString,
    line_num::Int,
)
    parts = split(line, ';')

    if length(parts) < 3
        throw(ParserError("Expected at least 3 fields for EOLICASUBM, got $(length(parts))", filename, line_num, line))
    end

    plant_code = parse(Int, strip(parts[2]))
    subsystem = strip(parts[3])

    return RenovaveisSubsystemRecord(plant_code = plant_code, subsystem = subsystem)
end

"""
    parse_renovaveis_bus_record(line, filename, line_num) -> RenovaveisBusRecord

Parse a single EOLICABARRA (plant-bus mapping) record.

# IDESEM Reference
idessem/dessem/modelos/renovaveis.py - EOLICABARRA class

# Field Order
1. Record type ("EOLICABARRA")
2. Plant code (Integer, 5 digits)
3. Bus code (Integer, 5 digits)

# Example
```
EOLICABARRA ;    1 ;00260 ;
```
"""
function parse_renovaveis_bus_record(
    line::AbstractString,
    filename::AbstractString,
    line_num::Int,
)
    parts = split(line, ';')

    if length(parts) < 3
        throw(ParserError("Expected at least 3 fields for EOLICABARRA, got $(length(parts))", filename, line_num, line))
    end

    plant_code = parse(Int, strip(parts[2]))
    bus_code = parse(Int, strip(parts[3]))

    return RenovaveisBusRecord(plant_code = plant_code, bus_code = bus_code)
end

"""
    parse_renovaveis_generation_record(line, filename, line_num) -> RenovaveisGenerationRecord

Parse a single EOLICA-GERACAO (generation forecast) record.

# IDESEM Reference
idessem/dessem/modelos/renovaveis.py - EOLICAGERACAO class

# Field Order
1. Record type ("EOLICA-GERACAO")
2. Plant code (Integer, 5 digits)
3. Start day (Integer)
4. Start hour (Integer, 0-23)
5. Start half-hour flag (Integer, 0 or 1)
6. End day (Integer)
7. End hour (Integer, 0-23)
8. End half-hour flag (Integer, 0 or 1)
9. Generation (Float, MW)

# Example
```
EOLICA-GERACAO ;    1 ;28 ; 0 ;0 ;28 ; 6 ;0 ;         0 ;
```
"""
function parse_renovaveis_generation_record(
    line::AbstractString,
    filename::AbstractString,
    line_num::Int,
)
    parts = split(line, ';')

    if length(parts) < 9
        throw(ParserError("Expected at least 9 fields for EOLICA-GERACAO, got $(length(parts))", filename, line_num, line))
    end

    plant_code = parse(Int, strip(parts[2]))
    start_day = parse(Int, strip(parts[3]))
    start_hour = parse(Int, strip(parts[4]))
    start_half_hour = parse(Int, strip(parts[5]))
    end_day = parse(Int, strip(parts[6]))
    end_hour = parse(Int, strip(parts[7]))
    end_half_hour = parse(Int, strip(parts[8]))
    generation = parse(Float64, strip(parts[9]))

    return RenovaveisGenerationRecord(
        plant_code = plant_code,
        start_day = start_day,
        start_hour = start_hour,
        start_half_hour = start_half_hour,
        end_day = end_day,
        end_hour = end_hour,
        end_half_hour = end_half_hour,
        generation = generation,
    )
end

"""
    parse_renovaveis(io, filename) -> RenovaveisData

Parse complete RENOVAVEIS.DAT file containing renewable plant registrations
and related mappings.

Processes four record types:
- EOLICA: Plant registrations (capacity, factors)
- EOLICASUBM: Plant-to-subsystem mappings
- EOLICABARRA: Plant-to-bus electrical connections
- EOLICA-GERACAO: Time series generation forecasts

# IDESEM Reference
idessem/dessem/modelos/renovaveis.py

# Format
- Semicolon-delimited fields
- Comment lines start with '&'
- Multiple record types in single file

# Arguments
- `io`: IO stream to read from
- `filename`: Filename for error reporting

# Returns
- `RenovaveisData` containing all four data types

# Example
```julia
data = parse_renovaveis("renovaveis.dat")
println("Parsed \$(length(data.plants)) renewable plants")
println("Subsystem mappings: \$(length(data.subsystem_mappings))")
println("Bus mappings: \$(length(data.bus_mappings))")
println("Generation forecasts: \$(length(data.generation_forecasts))")
```
"""
function parse_renovaveis(io::IO, filename::AbstractString)
    plants = RenovaveisRecord[]
    subsystem_mappings = RenovaveisSubsystemRecord[]
    bus_mappings = RenovaveisBusRecord[]
    generation_forecasts = RenovaveisGenerationRecord[]

    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue

        # Determine record type
        record_type = strip(split(line, ';')[1])

        try
            if record_type == "EOLICA"
                record = parse_renovaveis_record(line, filename, line_num)
                push!(plants, record)
            elseif record_type == "EOLICASUBM"
                record = parse_renovaveis_subsystem_record(line, filename, line_num)
                push!(subsystem_mappings, record)
            elseif record_type == "EOLICABARRA"
                record = parse_renovaveis_bus_record(line, filename, line_num)
                push!(bus_mappings, record)
            elseif record_type == "EOLICA-GERACAO"
                record = parse_renovaveis_generation_record(line, filename, line_num)
                push!(generation_forecasts, record)
            else
                @warn "Unknown record type '$record_type' at line $line_num in $filename"
            end
        catch e
            @warn "Failed to parse line $line_num in $filename: $line" exception =
                (e, catch_backtrace())
            continue
        end
    end

    return RenovaveisData(
        plants = plants,
        subsystem_mappings = subsystem_mappings,
        bus_mappings = bus_mappings,
        generation_forecasts = generation_forecasts,
    )
end

# Convenience method for filename input
"""
    parse_renovaveis(filename) -> RenovaveisData

Parse RENOVAVEIS.DAT file from filename.

# Arguments
- `filename`: Path to renovaveis.dat file

# Returns
- `RenovaveisData` with all renewable plant records
"""
function parse_renovaveis(filename::AbstractString)
    return open(io -> parse_renovaveis(io, filename), filename)
end

export parse_renovaveis,
    parse_renovaveis_record,
    parse_renovaveis_subsystem_record,
    parse_renovaveis_bus_record,
    parse_renovaveis_generation_record

end  # module RenovaveisParser
