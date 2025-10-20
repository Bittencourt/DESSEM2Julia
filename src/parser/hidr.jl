"""
Parser for HIDR.DAT (Hydroelectric Plant Registry) files.

This module parses hydroelectric plant registry data including:
- CADUSIH: Basic plant data
- USITVIAG: Travel time data
- POLCOT: Volume-elevation polynomials
- POLARE: Volume-area polynomials
- POLJUS: Tailrace polynomials
- COEFEVA: Evaporation coefficients
- CADCONJ: Unit set definitions

Supports both text and binary formats:
- Text format: Human-readable with record type headers
- Binary format: 792 bytes per plant (ONS official format)
"""
module HidrParser

using ..ParserCommon
using ..Types: CADUSIH, USITVIAG, POLCOT, POLARE, POLJUS, COEFEVA, CADCONJ, HidrData

# Include binary parser
include("hidr_binary.jl")

export parse_hidr

# ============================================================================
# Parser Functions
# ============================================================================

"""
    parse_cadusih(line::AbstractString, file::String, line_num::Int) -> CADUSIH

Parse a CADUSIH record (basic hydroelectric plant data).

# Format
Columns 1-7: Record type "CADUSIH"
Columns 9-11: Plant number (I3)
Columns 13-24: Plant name (A12)
Columns 26-27: Subsystem (I2)
Columns 29-32: Commission year (I4)
Columns 34-35: Commission month (I2)
Columns 37-38: Commission day (I2)
Columns 40-41: Downstream plant (I2)
Columns 43-44: Diversion downstream plant (I2)
Columns 46-46: Plant type (I1)
Columns 48-57: Minimum volume (F10.0)
Columns 59-68: Maximum volume (F10.0)
Columns 70-79: Maximum turbine flow (F10.0)
Columns 81-90: Installed capacity (F10.0)
Columns 92-101: Productivity (F10.0)
"""
function parse_cadusih(line::AbstractString, file::String, line_num::Int)
    specs = [
        FieldSpec(:record_type, 1, 7, String; required=true),
        FieldSpec(:plant_num, 9, 11, Int; required=true),
        FieldSpec(:plant_name, 13, 24, String; required=true),
        FieldSpec(:subsystem, 26, 27, Int; required=true),
        FieldSpec(:commission_year, 29, 32, Int),
        FieldSpec(:commission_month, 34, 35, Int),
        FieldSpec(:commission_day, 37, 38, Int),
        FieldSpec(:downstream_plant, 40, 41, Int),
        FieldSpec(:diversion_downstream, 43, 44, Int),
        FieldSpec(:plant_type, 46, 46, Int),
        FieldSpec(:min_volume, 48, 57, Float64),
        FieldSpec(:max_volume, 59, 68, Float64),
        FieldSpec(:max_turbine_flow, 70, 79, Float64),
        FieldSpec(:installed_capacity, 81, 90, Float64),
        FieldSpec(:productivity, 92, 101, Float64),
    ]
    
    data = extract_fields(line, specs, file=file, line_num=line_num)
    
    # Validate record type
    if data.record_type != "CADUSIH"
        throw(ParserError(file, line_num, line, 
            "Expected CADUSIH record, got $(data.record_type)"))
    end
    
    # Validate plant number
    validate_range(data.plant_num, 1, 999, "plant_num")
    
    # Validate subsystem
    validate_positive(data.subsystem, "subsystem")
    
    # Validate optional fields
    if !isnothing(data.commission_month)
        validate_range(data.commission_month, 1, 12, "commission_month")
    end
    if !isnothing(data.commission_day)
        validate_range(data.commission_day, 1, 31, "commission_day")
    end
    
    # Validate numeric fields
    if !isnothing(data.min_volume)
        validate_nonnegative(data.min_volume, "min_volume")
    end
    if !isnothing(data.max_volume)
        validate_positive(data.max_volume, "max_volume")
    end
    if !isnothing(data.max_turbine_flow)
        validate_positive(data.max_turbine_flow, "max_turbine_flow")
    end
    if !isnothing(data.installed_capacity)
        validate_positive(data.installed_capacity, "installed_capacity")
    end
    if !isnothing(data.productivity)
        validate_positive(data.productivity, "productivity")
    end
    
    return CADUSIH(
        data.plant_num,
        data.plant_name,
        data.subsystem,
        data.commission_year,
        data.commission_month,
        data.commission_day,
        data.downstream_plant,
        data.diversion_downstream,
        data.plant_type,
        data.min_volume,
        data.max_volume,
        data.max_turbine_flow,
        data.installed_capacity,
        data.productivity
    )
end

"""
    parse_usitviag(line::AbstractString, file::String, line_num::Int) -> USITVIAG

Parse a USITVIAG record (travel time between plants).

# Format
Columns 1-8: Record type "USITVIAG"
Columns 10-12: Plant number (I3)
Columns 14-15: Downstream plant (I2)
Columns 17-21: Travel time in hours (F5.0)
"""
function parse_usitviag(line::AbstractString, file::String, line_num::Int)
    specs = [
        FieldSpec(:record_type, 1, 8, String; required=true),
        FieldSpec(:plant_num, 10, 12, Int; required=true),
        FieldSpec(:downstream_plant, 14, 15, Int; required=true),
        FieldSpec(:travel_time, 17, 21, Float64; required=true),
    ]
    
    data = extract_fields(line, specs, file=file, line_num=line_num)
    
    # Validate record type
    if data.record_type != "USITVIAG"
        throw(ParserError(file, line_num, line, 
            "Expected USITVIAG record, got $(data.record_type)"))
    end
    
    # Validate plant numbers
    validate_range(data.plant_num, 1, 999, "plant_num")
    validate_range(data.downstream_plant, 1, 999, "downstream_plant")
    
    # Validate travel time
    validate_positive(data.travel_time, "travel_time")
    
    return USITVIAG(
        data.plant_num,
        data.downstream_plant,
        data.travel_time
    )
end

"""
    parse_polcot(line::AbstractString, file::String, line_num::Int) -> POLCOT

Parse a POLCOT record (volume-elevation polynomial).

# Format
Columns 1-6: Record type "POLCOT"
Columns 8-10: Plant number (I3)
Columns 12-13: Polynomial degree 1-5 (I2)
Columns 15-24: Coefficient 0 (F10.0)
Columns 26-35: Coefficient 1 (F10.0)
Columns 37-46: Coefficient 2 (F10.0)
Columns 48-57: Coefficient 3 (F10.0)
Columns 59-68: Coefficient 4 (F10.0)
Columns 70-79: Coefficient 5 (F10.0)
"""
function parse_polcot(line::AbstractString, file::String, line_num::Int)
    specs = [
        FieldSpec(:record_type, 1, 6, String; required=true),
        FieldSpec(:plant_num, 8, 10, Int; required=true),
        FieldSpec(:degree, 12, 13, Int; required=true),
        FieldSpec(:coef0, 15, 24, Float64; required=true),
        FieldSpec(:coef1, 26, 35, Float64; required=true),
        FieldSpec(:coef2, 37, 46, Float64; required=true),
        FieldSpec(:coef3, 48, 57, Float64; required=true),
        FieldSpec(:coef4, 59, 68, Float64; required=true),
        FieldSpec(:coef5, 70, 79, Float64; required=true),
    ]
    
    data = extract_fields(line, specs, file=file, line_num=line_num)
    
    # Validate record type
    if data.record_type != "POLCOT"
        throw(ParserError(file, line_num, line, 
            "Expected POLCOT record, got $(data.record_type)"))
    end
    
    # Validate plant number
    validate_range(data.plant_num, 1, 999, "plant_num")
    
    # Validate degree
    validate_range(data.degree, 1, 5, "degree")
    
    return POLCOT(
        data.plant_num,
        data.degree,
        data.coef0,
        data.coef1,
        data.coef2,
        data.coef3,
        data.coef4,
        data.coef5
    )
end

"""
    parse_polare(line::AbstractString, file::String, line_num::Int) -> POLARE

Parse a POLARE record (volume-area polynomial).

# Format
Columns 1-6: Record type "POLARE"
Columns 8-10: Plant number (I3)
Columns 12-13: Polynomial degree 1-5 (I2)
Columns 15-24: Coefficient 0 (F10.0)
Columns 26-35: Coefficient 1 (F10.0)
Columns 37-46: Coefficient 2 (F10.0)
Columns 48-57: Coefficient 3 (F10.0)
Columns 59-68: Coefficient 4 (F10.0)
Columns 70-79: Coefficient 5 (F10.0)
"""
function parse_polare(line::AbstractString, file::String, line_num::Int)
    specs = [
        FieldSpec(:record_type, 1, 6, String; required=true),
        FieldSpec(:plant_num, 8, 10, Int; required=true),
        FieldSpec(:degree, 12, 13, Int; required=true),
        FieldSpec(:coef0, 15, 24, Float64; required=true),
        FieldSpec(:coef1, 26, 35, Float64; required=true),
        FieldSpec(:coef2, 37, 46, Float64; required=true),
        FieldSpec(:coef3, 48, 57, Float64; required=true),
        FieldSpec(:coef4, 59, 68, Float64; required=true),
        FieldSpec(:coef5, 70, 79, Float64; required=true),
    ]
    
    data = extract_fields(line, specs, file=file, line_num=line_num)
    
    # Validate record type
    if data.record_type != "POLARE"
        throw(ParserError(file, line_num, line, 
            "Expected POLARE record, got $(data.record_type)"))
    end
    
    # Validate plant number
    validate_range(data.plant_num, 1, 999, "plant_num")
    
    # Validate degree
    validate_range(data.degree, 1, 5, "degree")
    
    return POLARE(
        data.plant_num,
        data.degree,
        data.coef0,
        data.coef1,
        data.coef2,
        data.coef3,
        data.coef4,
        data.coef5
    )
end

"""
    parse_poljus(line::AbstractString, file::String, line_num::Int) -> POLJUS

Parse a POLJUS record (tailrace elevation polynomial).

# Format
Columns 1-6: Record type "POLJUS"
Columns 8-10: Plant number (I3)
Columns 12-13: Polynomial degree 1-5 (I2)
Columns 15-24: Coefficient 0 (F10.0)
Columns 26-35: Coefficient 1 (F10.0)
Columns 37-46: Coefficient 2 (F10.0)
Columns 48-57: Coefficient 3 (F10.0)
Columns 59-68: Coefficient 4 (F10.0)
Columns 70-79: Coefficient 5 (F10.0)
"""
function parse_poljus(line::AbstractString, file::String, line_num::Int)
    specs = [
        FieldSpec(:record_type, 1, 6, String; required=true),
        FieldSpec(:plant_num, 8, 10, Int; required=true),
        FieldSpec(:degree, 12, 13, Int; required=true),
        FieldSpec(:coef0, 15, 24, Float64; required=true),
        FieldSpec(:coef1, 26, 35, Float64; required=true),
        FieldSpec(:coef2, 37, 46, Float64; required=true),
        FieldSpec(:coef3, 48, 57, Float64; required=true),
        FieldSpec(:coef4, 59, 68, Float64; required=true),
        FieldSpec(:coef5, 70, 79, Float64; required=true),
    ]
    
    data = extract_fields(line, specs, file=file, line_num=line_num)
    
    # Validate record type
    if data.record_type != "POLJUS"
        throw(ParserError(file, line_num, line, 
            "Expected POLJUS record, got $(data.record_type)"))
    end
    
    # Validate plant number
    validate_range(data.plant_num, 1, 999, "plant_num")
    
    # Validate degree
    validate_range(data.degree, 1, 5, "degree")
    
    return POLJUS(
        data.plant_num,
        data.degree,
        data.coef0,
        data.coef1,
        data.coef2,
        data.coef3,
        data.coef4,
        data.coef5
    )
end

"""
    parse_coefeva(line::AbstractString, file::String, line_num::Int) -> COEFEVA

Parse a COEFEVA record (monthly evaporation coefficients).

# Format
Columns 1-7: Record type "COEFEVA"
Columns 9-11: Plant number (I3)
Columns 13-17: January coefficient (F5.0)
Columns 19-23: February coefficient (F5.0)
Columns 25-29: March coefficient (F5.0)
Columns 31-35: April coefficient (F5.0)
Columns 37-41: May coefficient (F5.0)
Columns 43-47: June coefficient (F5.0)
Columns 49-53: July coefficient (F5.0)
Columns 55-59: August coefficient (F5.0)
Columns 61-65: September coefficient (F5.0)
Columns 67-71: October coefficient (F5.0)
Columns 73-77: November coefficient (F5.0)
Columns 79-83: December coefficient (F5.0)
"""
function parse_coefeva(line::AbstractString, file::String, line_num::Int)
    specs = [
        FieldSpec(:record_type, 1, 7, String; required=true),
        FieldSpec(:plant_num, 9, 11, Int; required=true),
        FieldSpec(:jan, 13, 17, Float64; required=true),
        FieldSpec(:feb, 19, 23, Float64; required=true),
        FieldSpec(:mar, 25, 29, Float64; required=true),
        FieldSpec(:apr, 31, 35, Float64; required=true),
        FieldSpec(:may, 37, 41, Float64; required=true),
        FieldSpec(:jun, 43, 47, Float64; required=true),
        FieldSpec(:jul, 49, 53, Float64; required=true),
        FieldSpec(:aug, 55, 59, Float64; required=true),
        FieldSpec(:sep, 61, 65, Float64; required=true),
        FieldSpec(:oct, 67, 71, Float64; required=true),
        FieldSpec(:nov, 73, 77, Float64; required=true),
        FieldSpec(:dec, 79, 83, Float64; required=true),
    ]
    
    data = extract_fields(line, specs, file=file, line_num=line_num)
    
    # Validate record type
    if data.record_type != "COEFEVA"
        throw(ParserError(file, line_num, line, 
            "Expected COEFEVA record, got $(data.record_type)"))
    end
    
    # Validate plant number
    validate_range(data.plant_num, 1, 999, "plant_num")
    
    # Validate all coefficients are non-negative
    validate_nonnegative(data.jan, "jan")
    validate_nonnegative(data.feb, "feb")
    validate_nonnegative(data.mar, "mar")
    validate_nonnegative(data.apr, "apr")
    validate_nonnegative(data.may, "may")
    validate_nonnegative(data.jun, "jun")
    validate_nonnegative(data.jul, "jul")
    validate_nonnegative(data.aug, "aug")
    validate_nonnegative(data.sep, "sep")
    validate_nonnegative(data.oct, "oct")
    validate_nonnegative(data.nov, "nov")
    validate_nonnegative(data.dec, "dec")
    
    return COEFEVA(
        data.plant_num,
        data.jan,
        data.feb,
        data.mar,
        data.apr,
        data.may,
        data.jun,
        data.jul,
        data.aug,
        data.sep,
        data.oct,
        data.nov,
        data.dec
    )
end

"""
    parse_cadconj(line::AbstractString, file::String, line_num::Int) -> CADCONJ

Parse a CADCONJ record (unit set definitions).

# Format
Columns 1-7: Record type "CADCONJ"
Columns 9-11: Plant number (I3)
Columns 13-14: Unit set number (I2)
Columns 16-17: Number of units in set (I2)
Columns 19-28: Unit capacity (F10.0)
Columns 30-39: Minimum generation (F10.0)
Columns 41-50: Maximum turbine flow (F10.0)
"""
function parse_cadconj(line::AbstractString, file::String, line_num::Int)
    specs = [
        FieldSpec(:record_type, 1, 7, String; required=true),
        FieldSpec(:plant_num, 9, 11, Int; required=true),
        FieldSpec(:unit_set_num, 13, 14, Int; required=true),
        FieldSpec(:num_units, 16, 17, Int; required=true),
        FieldSpec(:unit_capacity, 19, 28, Float64; required=true),
        FieldSpec(:min_generation, 30, 39, Float64; required=true),
        FieldSpec(:max_turbine_flow, 41, 50, Float64; required=true),
    ]
    
    data = extract_fields(line, specs, file=file, line_num=line_num)
    
    # Validate record type
    if data.record_type != "CADCONJ"
        throw(ParserError(file, line_num, line, 
            "Expected CADCONJ record, got $(data.record_type)"))
    end
    
    # Validate plant number
    validate_range(data.plant_num, 1, 999, "plant_num")
    
    # Validate unit set number
    validate_positive(data.unit_set_num, "unit_set_num")
    
    # Validate number of units
    validate_positive(data.num_units, "num_units")
    
    # Validate numeric fields
    validate_positive(data.unit_capacity, "unit_capacity")
    validate_nonnegative(data.min_generation, "min_generation")
    validate_positive(data.max_turbine_flow, "max_turbine_flow")
    
    return CADCONJ(
        data.plant_num,
        data.unit_set_num,
        data.num_units,
        data.unit_capacity,
        data.min_generation,
        data.max_turbine_flow
    )
end

# ============================================================================
# Main Parser Function
# ============================================================================

"""
    parse_hidr(filename::AbstractString) -> HidrData

Parse a HIDR.DAT file (text or binary format).

Automatically detects file format:
- Binary format: 792 bytes per plant (ONS official format)  
- Text format: Human-readable with record type headers

# Arguments
- `filename`: Path to the HIDR.DAT file

# Returns
- `HidrData`: Container with all parsed records

# Binary Format
Binary files contain only plant registry data (CADUSIH equivalent).
Other record types (USITVIAG, POLCOT, etc.) are not present in binary format.

# Text Format
Text files can contain all record types:
- CADUSIH: Plant registry
- USITVIAG: Travel times
- POLCOT: Volume-elevation polynomials
- POLARE: Volume-area polynomials
- POLJUS: Tailrace polynomials
- COEFEVA: Evaporation coefficients
- CADCONJ: Unit set definitions

# Example
```julia
# Parse any format (auto-detected)
data = parse_hidr("hidr.dat")
println("Number of plants: ", length(data.cadusih))

# Check format
if isempty(data.usitviag)
    println("Binary format (no travel time records)")
else
    println("Text format")
end
```
"""
function parse_hidr(filename::AbstractString)
    # Check if file exists
    if !isfile(filename)
        throw(ArgumentError("File not found: $filename"))
    end
    
    # Detect format
    if is_binary_hidr(filename)
        @info "Detected binary HIDR format (792 bytes/plant)"
        return parse_hidr_binary(filename)
    else
        @info "Detected text HIDR format"
        return parse_hidr_text(filename)
    end
end

"""
    parse_hidr_text(filename::AbstractString) -> HidrData

Parse a text format HIDR.DAT file.

Text format contains record type headers (CADUSIH, USITVIAG, etc.)
followed by fixed-width field data.

# Arguments
- `filename`: Path to the text HIDR.DAT file

# Example
```julia
data = parse_hidr_text("hidr.dat")
println("Number of plants: ", length(data.cadusih))
println("Number of travel time records: ", length(data.usitviag))
```
"""
function parse_hidr_text(filename::AbstractString)
    # Initialize result vectors
    plants = CADUSIH[]
    travel_times = USITVIAG[]
    volume_elevation = POLCOT[]
    volume_area = POLARE[]
    tailrace = POLJUS[]
    evaporation = COEFEVA[]
    unit_sets = CADCONJ[]
    
    # Read all non-blank lines
    lines = read_nonblank_lines(filename)
    
    # Parse each line
    for (line_num, line) in enumerate(lines)
        # Skip comment lines
        if startswith(line, '*') || startswith(line, '&')
            continue
        end
        
        # Determine record type from first 8 characters
        if length(line) < 7
            continue  # Skip lines that are too short
        end
        
        record_type = strip(line[1:min(8, length(line))])
        
        try
            if record_type == "CADUSIH"
                push!(plants, parse_cadusih(line, filename, line_num))
            elseif record_type == "USITVIAG"
                push!(travel_times, parse_usitviag(line, filename, line_num))
            elseif record_type == "POLCOT"
                push!(volume_elevation, parse_polcot(line, filename, line_num))
            elseif record_type == "POLARE"
                push!(volume_area, parse_polare(line, filename, line_num))
            elseif record_type == "POLJUS"
                push!(tailrace, parse_poljus(line, filename, line_num))
            elseif record_type == "COEFEVA"
                push!(evaporation, parse_coefeva(line, filename, line_num))
            elseif record_type == "CADCONJ"
                push!(unit_sets, parse_cadconj(line, filename, line_num))
            else
                @warn "Unknown record type in $filename line $line_num: $record_type"
            end
        catch e
            if isa(e, ParserError)
                rethrow(e)
            else
                throw(ParserError(filename, line_num, line, 
                    "Unexpected error parsing record type '$record_type': $(sprint(showerror, e))"))
            end
        end
    end
    
    return HidrData(
        plants,
        travel_times,
        volume_elevation,
        volume_area,
        tailrace,
        evaporation,
        unit_sets
    )
end

end # module
