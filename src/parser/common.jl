module ParserCommon

using Dates

export normalize_name, strip_comments, is_blank
export extract_field, parse_int, parse_float, parse_string
export parse_date, parse_time, parse_datetime, parse_time_period
export ParserError, FieldSpec, extract_fields
export is_comment_line, read_nonblank_lines
export validate_range, validate_positive, validate_nonnegative

# ============================================================================
# Error Types
# ============================================================================

"""
    ParserError

Exception type for parsing errors with file/line context.

# Fields
- `msg::String` - Error message
- `file::String` - Source file path
- `line::Int` - Line number where error occurred
- `content::String` - The problematic line content
"""
struct ParserError <: Exception
    msg::String
    file::String
    line::Int
    content::String
end

function Base.showerror(io::IO, e::ParserError)
    print(io, "ParserError in $(e.file):$(e.line)\n")
    print(io, "  $(e.msg)\n")
    print(io, "  Line content: $(e.content)")
end

# ============================================================================
# Field Specification
# ============================================================================

"""
    FieldSpec

Specification for a fixed-column field in DESSEM files.

# Fields
- `name::Symbol` - Field name
- `start_col::Int` - Starting column (1-indexed)
- `end_col::Int` - Ending column (inclusive)
- `type::Type` - Target type (Int, Float64, String, etc.)
- `required::Bool` - Whether field must be non-empty
- `default::Any` - Default value if field is blank
"""
struct FieldSpec
    name::Symbol
    start_col::Int
    end_col::Int
    type::Type
    required::Bool
    default::Any
    
    function FieldSpec(name::Symbol, start_col::Int, end_col::Int, type::Type; 
                       required::Bool=false, default=nothing)
        @assert start_col >= 1 "Column indices must be >= 1"
        @assert end_col >= start_col "End column must be >= start column"
        new(name, start_col, end_col, type, required, default)
    end
end

# ============================================================================
# Basic Utilities
# ============================================================================

"""
    normalize_name(fname) -> String

Convert filename to uppercase base filename without path.

# Example
```julia
normalize_name("/path/to/hidr.dat") # => "HIDR.DAT"
```
"""
normalize_name(fname::AbstractString) = uppercase(Base.basename(String(fname)))

"""
    strip_comments(s; comment_chars=["*", "#", ";"]) -> String

Remove trailing comments and trim whitespace. DESSEM files use `*` for comments,
electrical network files use `C`.

# Arguments
- `s::AbstractString` - Input line
- `comment_chars` - Characters that start comments

# Example
```julia
strip_comments("DATA 123  * this is a comment") # => "DATA 123"
```
"""
function strip_comments(s::AbstractString; comment_chars=["*", "#", ";"])
    str = String(s)
    for ch in comment_chars
        idx = findfirst(ch, str)
        if idx !== nothing
            # findfirst returns a range for strings, get the first index
            pos = first(idx)
            str = str[1:pos-1]
        end
    end
    return strip(str)
end

"""
    is_blank(s) -> Bool

Check if line is empty or contains only whitespace/comments.

# Example
```julia
is_blank("   * comment only")  # => true
is_blank("  ")                  # => true
is_blank("DATA 123")            # => false
```
"""
is_blank(s::AbstractString) = isempty(strip_comments(s))

"""
    is_comment_line(s; comment_chars=["*", "C", "&"]) -> Bool

Check if line is a comment (comment character followed by space/tab or alone).

# Example
```julia
is_comment_line("* This is a comment")  # => true
is_comment_line("C This is a comment")  # => true
is_comment_line("& DESSEM comment")     # => true
is_comment_line("  * Comment")          # => true
is_comment_line("DATA 123")             # => false
is_comment_line("CADUSIT ...")          # => false (not a comment)
```
"""
function is_comment_line(s::AbstractString; comment_chars=["*", "C", "&"])
    stripped = lstrip(s)
    isempty(stripped) && return false
    
    # Check if line starts with comment char followed by space/tab or is just the char
    for ch in comment_chars
        if stripped == ch || startswith(stripped, ch * " ") || startswith(stripped, ch * "\t")
            return true
        end
    end
    return false
end

"""
    read_nonblank_lines(io; skip_comments=true) -> Vector{String}

Read all non-blank lines from an IO stream, optionally skipping comment lines.

# Arguments
- `io` - IO stream or file path
- `skip_comments::Bool` - Skip lines starting with comment characters

# Returns
Vector of non-blank lines with comments stripped
"""
function read_nonblank_lines(io; skip_comments::Bool=true)
    lines = String[]
    for line in eachline(io)
        skip_comments && is_comment_line(line) && continue
        is_blank(line) && continue
        push!(lines, strip_comments(line))
    end
    return lines
end

read_nonblank_lines(path::AbstractString; kwargs...) = 
    open(io -> read_nonblank_lines(io; kwargs...), path)

# ============================================================================
# Field Extraction
# ============================================================================

"""
    extract_field(line, start_col, end_col) -> String

Extract substring from fixed columns. Returns empty string if line is too short.
Column indices are 1-based and inclusive.

# Arguments
- `line::AbstractString` - Source line
- `start_col::Int` - Starting column (1-indexed)
- `end_col::Int` - Ending column (inclusive, 1-indexed)

# Example
```julia
extract_field("ABCDEFGHIJ", 3, 5)  # => "CDE"
extract_field("SHORT", 10, 15)     # => ""
```
"""
function extract_field(line::AbstractString, start_col::Int, end_col::Int)::String
    line_str = String(line)
    len = length(line_str)
    
    # If line is too short, return empty string
    start_col > len && return ""
    
    # Adjust end_col if it exceeds line length
    actual_end = min(end_col, len)
    
    # Extract and strip
    return strip(line_str[start_col:actual_end])
end

"""
    extract_fields(line, specs::Vector{FieldSpec}; file="", line_num=0) -> NamedTuple

Extract multiple fields from a line according to field specifications.

# Arguments
- `line::AbstractString` - Source line
- `specs::Vector{FieldSpec}` - Field specifications
- `file::String` - Source file (for error reporting)
- `line_num::Int` - Line number (for error reporting)

# Returns
NamedTuple with parsed field values

# Throws
- `ParserError` if required field is missing or type conversion fails

# Example
```julia
specs = [
    FieldSpec(:num, 1, 3, Int; required=true),
    FieldSpec(:name, 5, 16, String; default=""),
    FieldSpec(:value, 20, 29, Float64; default=0.0)
]
extract_fields("001 PLANT_A    123.45", specs)
# => (num=1, name="PLANT_A", value=123.45)
```
"""
function extract_fields(line::AbstractString, specs::Vector{FieldSpec}; 
                       file::String="", line_num::Int=0)
    values = []
    names = Symbol[]
    
    for spec in specs
        push!(names, spec.name)
        
        # Extract raw field
        raw = extract_field(line, spec.start_col, spec.end_col)
        
        # Check if required field is missing
        if spec.required && isempty(raw)
            throw(ParserError(
                "Required field '$(spec.name)' is missing or blank (columns $(spec.start_col)-$(spec.end_col))",
                file, line_num, line
            ))
        end
        
        # Use default if blank
        if isempty(raw)
            push!(values, spec.default)
            continue
        end
        
        # Parse according to type
        try
            if spec.type == Int
                push!(values, parse_int(raw))
            elseif spec.type == Float64
                push!(values, parse_float(raw))
            elseif spec.type == String
                push!(values, raw)
            elseif spec.type == Bool
                push!(values, parse_int(raw) != 0)
            else
                # Try generic parsing
                push!(values, parse(spec.type, raw))
            end
        catch e
            throw(ParserError(
                "Failed to parse field '$(spec.name)' as $(spec.type): $e",
                file, line_num, line
            ))
        end
    end
    
    return NamedTuple{Tuple(names)}(Tuple(values))
end

# ============================================================================
# Type Conversion
# ============================================================================

"""
    parse_int(s; allow_blank=false) -> Union{Int, Nothing}

Parse integer from string, handling DESSEM-specific formats.

# Arguments
- `s::AbstractString` - String to parse
- `allow_blank::Bool` - Return nothing for blank strings

# Returns
Parsed integer or nothing if blank and allowed

# Example
```julia
parse_int("  123  ")  # => 123
parse_int("001")      # => 1
parse_int("", allow_blank=true)  # => nothing
```
"""
function parse_int(s::AbstractString; allow_blank::Bool=false)::Union{Int, Nothing}
    stripped = strip(s)
    if isempty(stripped)
        allow_blank && return nothing
        throw(ArgumentError("Cannot parse empty string as Int"))
    end
    return parse(Int, stripped)
end

"""
    parse_float(s; allow_blank=false, decimal_char='.') -> Union{Float64, Nothing}

Parse float from string, handling DESSEM-specific formats including locale variations.

# Arguments
- `s::AbstractString` - String to parse
- `allow_blank::Bool` - Return nothing for blank strings
- `decimal_char::Char` - Decimal separator ('.' or ',')

# Returns
Parsed float or nothing if blank and allowed

# Example
```julia
parse_float("  123.45  ")          # => 123.45
parse_float("1.5E+02")              # => 150.0
parse_float("123,45", decimal_char=',')  # => 123.45
parse_float("", allow_blank=true)   # => nothing
```
"""
function parse_float(s::AbstractString; allow_blank::Bool=false, 
                    decimal_char::Char='.')::Union{Float64, Nothing}
    stripped = strip(s)
    if isempty(stripped)
        allow_blank && return nothing
        throw(ArgumentError("Cannot parse empty string as Float64"))
    end
    
    # Handle locale-specific decimal separator
    if decimal_char == ','
        stripped = replace(stripped, ',' => '.')
    end
    
    return parse(Float64, stripped)
end

"""
    parse_string(s; allow_blank=true) -> Union{String, Nothing}

Parse string field, optionally allowing blank values.

# Arguments
- `s::AbstractString` - String to parse
- `allow_blank::Bool` - Return nothing for blank strings

# Returns
Stripped string or nothing if blank and allowed

# Example
```julia
parse_string("  PLANT  ")  # => "PLANT"
parse_string("", allow_blank=true)  # => nothing
```
"""
function parse_string(s::AbstractString; allow_blank::Bool=true)::Union{String, Nothing}
    stripped = strip(s)
    if isempty(stripped)
        allow_blank && return nothing
        return ""
    end
    return stripped
end

# ============================================================================
# Date/Time Parsing
# ============================================================================

"""
    parse_date(day, month, year) -> Date

Parse date from DESSEM day/month/year fields.

# Example
```julia
parse_date(15, 3, 2024)  # => Date(2024, 3, 15)
```
"""
function parse_date(day::Int, month::Int, year::Int)::Date
    return Date(year, month, day)
end

"""
    parse_time(hour, half_hour=0) -> Time

Parse time from DESSEM hour and half-hour flag.

# Arguments
- `hour::Int` - Hour (0-23)
- `half_hour::Int` - Half-hour flag (0=first half, 1=second half)

# Returns
Time object representing the time

# Example
```julia
parse_time(14, 0)  # => Time(14, 0)   (14:00)
parse_time(14, 1)  # => Time(14, 30)  (14:30)
```
"""
function parse_time(hour::Int, half_hour::Int=0)::Time
    @assert 0 <= hour <= 23 "Hour must be in range 0-23"
    @assert half_hour in [0, 1] "Half-hour flag must be 0 or 1"
    
    minute = half_hour * 30
    return Time(hour, minute)
end

"""
    parse_datetime(day, month, year, hour=0, half_hour=0) -> DateTime

Parse datetime from DESSEM date and time fields.

# Example
```julia
parse_datetime(15, 3, 2024, 14, 1)  # => DateTime(2024, 3, 15, 14, 30)
```
"""
function parse_datetime(day::Int, month::Int, year::Int, 
                       hour::Int=0, half_hour::Int=0)::DateTime
    @assert 0 <= hour <= 23 "Hour must be in range 0-23"
    @assert half_hour in [0, 1] "Half-hour flag must be 0 or 1"
    
    minute = half_hour * 30
    return DateTime(year, month, day, hour, minute)
end

"""
    parse_time_period(day_i, hour_i, hh_i, day_f, hour_f, hh_f) -> (DateTime, DateTime)

Parse time period from DESSEM initial/final date-time fields.
Returns tuple of (start_time, end_time).

# Arguments
- Initial: day_i, hour_i, hh_i (half-hour flag)
- Final: day_f, hour_f, hh_f (half-hour flag)

Note: This assumes all times are in the same month/year context.
For full date parsing, use parse_datetime with explicit month/year.

# Example
```julia
# Requires context of current month/year - simplified for within-day periods
parse_time_period(1, 0, 0, 1, 23, 1)  # => Day 1, 00:00 to 23:30
```
"""
function parse_time_period(day_i::Int, hour_i::Int, hh_i::Int,
                          day_f::Int, hour_f::Int, hh_f::Int)
    # Note: This is a simplified version. Full implementation would need
    # month/year context from the file header
    time_i = parse_time(hour_i, hh_i)
    time_f = parse_time(hour_f, hh_f)
    
    return (day_i, time_i), (day_f, time_f)
end

# ============================================================================
# Validation Helpers
# ============================================================================

"""
    validate_range(value, min_val, max_val, field_name; file="", line_num=0)

Validate that a value is within a specified range.

# Throws
ParserError if value is out of range
"""
function validate_range(value, min_val, max_val, field_name::String; 
                       file::String="", line_num::Int=0, line::String="")
    if value < min_val || value > max_val
        throw(ParserError(
            "Field '$field_name' value $value out of range [$min_val, $max_val]",
            file, line_num, line
        ))
    end
    return value
end

"""
    validate_positive(value, field_name; file="", line_num=0)

Validate that a value is positive (> 0).

# Throws
ParserError if value is not positive
"""
function validate_positive(value, field_name::String; 
                          file::String="", line_num::Int=0, line::String="")
    if value <= 0
        throw(ParserError(
            "Field '$field_name' must be positive, got $value",
            file, line_num, line
        ))
    end
    return value
end

"""
    validate_nonnegative(value, field_name; file="", line_num=0)

Validate that a value is non-negative (>= 0).

# Throws
ParserError if value is negative
"""
function validate_nonnegative(value, field_name::String; 
                             file::String="", line_num::Int=0, line::String="")
    if value < 0
        throw(ParserError(
            "Field '$field_name' must be non-negative, got $value",
            file, line_num, line
        ))
    end
    return value
end

end # module
