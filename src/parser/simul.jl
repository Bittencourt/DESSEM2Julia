"""
SIMUL.XXX Parser

Parses simulation data file containing:
- Header: simulation start date/time and OPERUH flag
- DISC block: time discretization periods
- VOLI block: initial reservoir volumes
- OPER block: simulation operation data for plants

IDESEM Reference: No dedicated simul.py file exists in IDESSEM
Specification: docs/dessem-complete-specs.md lines 325-475
"""
module SimulParser

using ..DESSEM2Julia: SimulData, SimulHeader, DiscRecord, VoliRecord, OperRecord
using ..ParserCommon

# Import functions explicitly
import ..ParserCommon: extract_field, is_comment_line, is_blank, parse_int, parse_float

"""
    parse_simul_header(line::AbstractString, filename::AbstractString, line_num::Int) -> SimulHeader

Parse the simulation header (Record 3) containing start date/time and OPERUH flag.

# Format (Fixed-width columns)
- Col 5-6: I2 - Start day
- Col 8-9: I2 - Start hour
- Col 11: I1 - Start half-hour (0 or 1)
- Col 14-15: I2 - Start month
- Col 18-21: I4 - Start year
- Col 23: I1 - OPERUH constraints flag (0=exclude, 1=include)

# IDESEM Reference
No dedicated simul.py file in IDESSEM
"""
function parse_simul_header(line::AbstractString, filename::AbstractString, line_num::Int)
    try
        start_day = parse(Int, strip(extract_field(line, 5, 6)))
        start_hour_str = strip(extract_field(line, 8, 9))
        start_hour = isempty(start_hour_str) ? 0 : parse(Int, start_hour_str)
        
        start_half_hour_str = strip(extract_field(line, 11, 11))
        start_half_hour = isempty(start_half_hour_str) ? 0 : parse(Int, start_half_hour_str)
        
        start_month = parse(Int, strip(extract_field(line, 14, 15)))  # Per specification
        start_year = parse(Int, strip(extract_field(line, 17, 20)))  # Per specification
        
        operuh_flag_str = strip(extract_field(line, 22, 22))  # Per specification
        operuh_flag = isempty(operuh_flag_str) ? nothing : parse(Int, operuh_flag_str)
        
        return SimulHeader(
            start_day=start_day,
            start_hour=start_hour,
            start_half_hour=start_half_hour,
            start_month=start_month,
            start_year=start_year,
            operuh_flag=operuh_flag
        )
    catch e
        error("Error parsing SIMUL header at $filename:$line_num: $e\nLine: '$line'")
    end
end

"""
    parse_disc_record(line::AbstractString, filename::AbstractString, line_num::Int) -> DiscRecord

Parse a DISC (time discretization) record.

# Format (Fixed-width columns)
- Col 5-6: I2 - Day number
- Col 8-9: I2 - Hour (0-23)
- Col 11: I1 - Half-hour flag (0 or 1)
- Col 15-19: F5.0 - Period duration (hours)
- Col 21: I1 - Period constraints flag (0=exclude, 1=include)
"""
function parse_disc_record(line::AbstractString, filename::AbstractString, line_num::Int)
    try
        day = parse(Int, strip(extract_field(line, 5, 6)))
        
        hour_str = strip(extract_field(line, 8, 9))
        hour = isempty(hour_str) ? 0 : parse(Int, hour_str)
        
        half_hour_str = strip(extract_field(line, 11, 11))
        half_hour = isempty(half_hour_str) ? 0 : parse(Int, half_hour_str)
        
        duration = parse(Float64, strip(extract_field(line, 14, 18)))  # Adjusted: actual data has duration around 14-18
        
        constraints_flag_str = strip(extract_field(line, 20, 20))  # Adjusted: actual data has flag at position 20
        constraints_flag = isempty(constraints_flag_str) ? nothing : parse(Int, constraints_flag_str)
        
        return DiscRecord(
            day=day,
            hour=hour,
            half_hour=half_hour,
            duration=duration,
            constraints_flag=constraints_flag
        )
    catch e
        error("Error parsing DISC record at $filename:$line_num: $e\nLine: '$line'")
    end
end

"""
    parse_voli_record(line::AbstractString, filename::AbstractString, line_num::Int) -> VoliRecord

Parse a VOLI (initial reservoir volumes) record.

# Format (Fixed-width columns)
- Col 5-7: I3 - Plant number
- Col 10-21: A12 - Plant name
- Col 25-34: F10.0 - Initial volume (% useful)
"""
function parse_voli_record(line::AbstractString, filename::AbstractString, line_num::Int)
    try
        plant_number = parse(Int, strip(extract_field(line, 5, 7)))
        plant_name = strip(extract_field(line, 9, 20))  # Adjusted: was 10-21
        initial_volume_percent = parse(Float64, strip(extract_field(line, 26, 34)))  # Adjusted: was 25-34
        
        return VoliRecord(
            plant_number=plant_number,
            plant_name=plant_name,
            initial_volume_percent=initial_volume_percent
        )
    catch e
        error("Error parsing VOLI record at $filename:$line_num: $e\nLine: '$line'")
    end
end

"""
    parse_oper_record(line::AbstractString, filename::AbstractString, line_num::Int) -> OperRecord

Parse an OPER (simulation operation data) record.

# Format (Fixed-width columns)
- Col 5-7: I3 - Plant number
- Col 8: A1 - Plant type ("H"=hydro, "E"=pumping)
- Col 10-22: A12 - Plant name
- Col 24-25: I2 - Initial day
- Col 27-28: I2 - Initial hour
- Col 30: I1 - Initial half-hour
- Col 32-33: I2 - Final day
- Col 35-36: I2 - Final hour
- Col 38: I1 - Final half-hour
- Col 40: I1 - Natural flow type (1=incremental, 2=total)
- Col 42-51: F10.0 - Natural inflow (m³/s)
- Col 53: I1 - Withdrawal type (1=incremental, 2=total)
- Col 55-64: F10.0 - Withdrawal flow (m³/s)
- Col 65-74: F10.0 - Generation target (MW)
"""
function parse_oper_record(line::AbstractString, filename::AbstractString, line_num::Int)
    try
        plant_number = parse(Int, strip(extract_field(line, 5, 7)))
        
        plant_type_str = strip(extract_field(line, 8, 8))
        plant_type = isempty(plant_type_str) ? "H" : plant_type_str
        
        plant_name = strip(extract_field(line, 9, 20))  # Adjusted: actual data has name at 9-20
        
        initial_day = parse(Int, strip(extract_field(line, 21, 23)))  # Adjusted: actual data has day at 21-23
        
        initial_hour_str = strip(extract_field(line, 25, 26))  # Adjusted: actual data has hour at 25-26
        initial_hour = isempty(initial_hour_str) ? 0 : parse(Int, initial_hour_str)
        
        initial_half_hour_str = strip(extract_field(line, 28, 28))  # Adjusted: actual data has half-hour at 28
        initial_half_hour = isempty(initial_half_hour_str) ? 0 : parse(Int, initial_half_hour_str)
        
        final_day = parse(Int, strip(extract_field(line, 30, 31)))  # Adjusted: actual data has final day at 30-31
        
        final_hour_str = strip(extract_field(line, 34, 34))  # Adjusted: actual data has final hour at 34
        final_hour = isempty(final_hour_str) ? 0 : parse(Int, final_hour_str)
        
        final_half_hour_str = strip(extract_field(line, 36, 36))  # Adjusted: actual data has final half-hour at 36
        final_half_hour = isempty(final_half_hour_str) ? 0 : parse(Int, final_half_hour_str)
        
        flow_type = parse(Int, strip(extract_field(line, 38, 38)))  # Adjusted: actual data has flow type at 38
        natural_inflow = parse(Float64, strip(extract_field(line, 40, 48)))  # Adjusted: actual data has inflow at 40-48
        
        withdrawal_type_str = strip(extract_field(line, 50, 50))  # Adjusted: actual data has withdrawal type at 50
        withdrawal_type = isempty(withdrawal_type_str) ? nothing : parse(Int, withdrawal_type_str)
        
        withdrawal_flow_str = strip(extract_field(line, 57, 60))  # Adjusted: actual data has withdrawal flow at 57-60
        withdrawal_flow = isempty(withdrawal_flow_str) ? 0.0 : parse(Float64, withdrawal_flow_str)
        
        generation_target_str = strip(extract_field(line, 66, 70))  # Adjusted: actual data has target at 66-70
        generation_target = isempty(generation_target_str) ? nothing : parse(Float64, generation_target_str)
        
        return OperRecord(
            plant_number=plant_number,
            plant_type=plant_type,
            plant_name=plant_name,
            initial_day=initial_day,
            initial_hour=initial_hour,
            initial_half_hour=initial_half_hour,
            final_day=final_day,
            final_hour=final_hour,
            final_half_hour=final_half_hour,
            flow_type=flow_type,
            natural_inflow=natural_inflow,
            withdrawal_type=withdrawal_type,
            withdrawal_flow=withdrawal_flow,
            generation_target=generation_target
        )
    catch e
        error("Error parsing OPER record at $filename:$line_num: $e\nLine: '$line'")
    end
end

"""
    parse_simul(io::IO, filename::AbstractString) -> SimulData

Parse complete SIMUL.XXX file with header and three blocks (DISC, VOLI, OPER).

# File Structure
1. Records 1-2: User-defined headers (skipped)
2. Record 3: Simulation start header
3. DISC block: Time discretization (terminated by "FIM")
4. VOLI block: Initial volumes (terminated by "FIM")
5. OPER block: Operation data (terminated by "FIM")

# IDESEM Reference
No dedicated simul.py parser exists in IDESSEM.
Only RegistroSimul in dessemarq.py points to the filename.
"""
function parse_simul(io::IO, filename::AbstractString)
    header = nothing
    disc_records = DiscRecord[]
    voli_records = VoliRecord[]
    oper_records = OperRecord[]
    
    current_block = :none
    header_line_count = 0
    
    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue
        
        # Skip first two header lines
        if header_line_count < 2
            header_line_count += 1
            continue
        end
        
        # Parse simulation header (Record 3)
        if header === nothing && header_line_count == 2
            header = parse_simul_header(line, filename, line_num)
            continue
        end
        
        # Detect block identifiers
        line_upper = uppercase(strip(line))
        
        # Check for block start
        if startswith(line_upper, "DISC")
            current_block = :disc
            continue
        elseif startswith(line_upper, "VOLI")
            current_block = :voli
            continue
        elseif startswith(line_upper, "OPER")
            current_block = :oper
            continue
        end
        
        # Check for block terminator
        if startswith(line_upper, "FIM")
            current_block = :none
            continue
        end
        
        # Parse records based on current block
        if current_block == :disc
            record = parse_disc_record(line, filename, line_num)
            push!(disc_records, record)
        elseif current_block == :voli
            record = parse_voli_record(line, filename, line_num)
            push!(voli_records, record)
        elseif current_block == :oper
            record = parse_oper_record(line, filename, line_num)
            push!(oper_records, record)
        end
    end
    
    if header === nothing
        error("SIMUL file $filename does not contain a valid header (Record 3)")
    end
    
    return SimulData(
        header=header,
        disc_records=disc_records,
        voli_records=voli_records,
        oper_records=oper_records
    )
end

# Convenience method for parsing from filename
parse_simul(filename::AbstractString) = open(io -> parse_simul(io, filename), filename)

export parse_simul, parse_simul_header, parse_disc_record, parse_voli_record, parse_oper_record

end  # module
