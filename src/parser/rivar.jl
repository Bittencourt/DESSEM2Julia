"""
RIVAR.DAT Parser

Parses soft variation constraint file with penalty costs.

# IDESEM Reference
idessem/dessem/modelos/rivar.py

# Format
Fixed-width columns containing:
- Variable type identifier
- Variable index (entity code)
- Penalty cost for violations
- Optional: Lower and upper limits

# File Structure
The file contains records defining flexible constraints with penalty costs.
These constraints allow violations but penalize them in the objective function.
"""
module RivarParser

using ..CoreTypes: RivarRecord, RivarData
using ..ParserCommon: extract_field, is_comment_line, is_blank, parse_int, parse_float

export parse_rivar, parse_rivar_record

"""
    parse_rivar_record(line::AbstractString, filename::AbstractString, line_num::Int) -> RivarRecord

Parse a single RIVAR record from a line.

# IDESEM Reference
Based on idessem/dessem/modelos/rivar.py field positions (converting Python 0-indexed to Julia 1-indexed):
- Variable type: Identifies the type of variable being constrained
- Variable index: Entity identifier (plant, unit, interchange, etc.)
- Penalty cost: Cost for violating the constraint (currency/unit)
- Optional limits: Lower and/or upper bounds

# Column Positions
These are typical fixed-width positions (to be verified with actual RIVAR.DAT samples):
- Columns 1-3: Variable type (I3)
- Columns 5-7: Variable index (I3)
- Columns 10-19: Penalty cost (F10.2)
- Columns 21-30: Lower limit (F10.2, optional)
- Columns 32-41: Upper limit (F10.2, optional)

# Arguments
- `line::AbstractString`: Input line to parse
- `filename::AbstractString`: Source filename (for error messages)
- `line_num::Int`: Line number (for error messages)

# Returns
- `RivarRecord`: Parsed record

# Example
```julia
line = "  1   5    1000.00      0.00   5000.00"
record = parse_rivar_record(line, "rivar.dat", 1)
```
"""
function parse_rivar_record(line::AbstractString, filename::AbstractString, line_num::Int)
    # Extract fields using fixed-width positions
    # Note: These positions may need adjustment based on actual RIVAR.DAT samples

    variable_type_str = extract_field(line, 1, 3)
    if isempty(strip(variable_type_str))
        throw(
            ErrorException(
                "Variable type field is empty at line $line_num in $filename: '$line'",
            ),
        )
    end
    variable_type = parse_int(variable_type_str)

    variable_index_str = extract_field(line, 5, 7)
    if isempty(strip(variable_index_str))
        throw(
            ErrorException(
                "Variable index field is empty at line $line_num in $filename: '$line'",
            ),
        )
    end
    variable_index = parse_int(variable_index_str)

    penalty_cost_str = extract_field(line, 10, 19)
    if isempty(strip(penalty_cost_str))
        throw(
            ErrorException(
                "Penalty cost field is empty at line $line_num in $filename: '$line'",
            ),
        )
    end
    penalty_cost = parse_float(penalty_cost_str)

    # Optional fields: lower and upper limits
    limit_lower = nothing
    limit_lower_str = extract_field(line, 21, 30)
    if !isempty(strip(limit_lower_str))
        limit_lower = parse_float(limit_lower_str)
    end

    limit_upper = nothing
    limit_upper_str = extract_field(line, 32, 41)
    if !isempty(strip(limit_upper_str))
        limit_upper = parse_float(limit_upper_str)
    end

    return RivarRecord(
        variable_type = variable_type,
        variable_index = variable_index,
        penalty_cost = penalty_cost,
        limit_lower = limit_lower,
        limit_upper = limit_upper,
    )
end

"""
    parse_rivar(io::IO, filename::AbstractString) -> RivarData

Parse complete RIVAR.DAT file.

# Arguments
- `io::IO`: Input stream
- `filename::AbstractString`: Source filename (for error messages)

# Returns
- `RivarData`: Container with all parsed records

# Example
```julia
# Parse from file
data = parse_rivar("rivar.dat")

# Parse from IO stream
open("rivar.dat") do io
    data = parse_rivar(io, "rivar.dat")
end
```
"""
function parse_rivar(io::IO, filename::AbstractString)
    records = RivarRecord[]

    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        is_comment_line(line) && continue
        is_blank(line) && continue

        # Check for end of file marker
        stripped = strip(line)
        if startswith(stripped, "FIM") || startswith(stripped, "99999")
            break
        end

        # Parse record
        try
            record = parse_rivar_record(line, filename, line_num)
            push!(records, record)
        catch e
            @warn "Error parsing line $line_num in $filename" exception =
                (e, catch_backtrace())
            @warn "Line content: '$line'"
            # Continue parsing to be robust, but log the error
        end
    end

    return RivarData(records = records)
end

"""
    parse_rivar(filename::AbstractString) -> RivarData

Parse RIVAR.DAT file from filesystem.

# Arguments
- `filename::AbstractString`: Path to RIVAR.DAT file

# Returns
- `RivarData`: Container with all parsed records

# Example
```julia
data = parse_rivar("rivar.dat")
println("Parsed \$(length(data.records)) soft constraint records")
```
"""
parse_rivar(filename::AbstractString) = open(io -> parse_rivar(io, filename), filename)

end # module
