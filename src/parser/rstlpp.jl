module RstlppParser

using ..CoreTypes
using ..ParserCommon

export parse_rstlpp

"""
    parse_rstlpp(io::IO, filename::AbstractString) -> Vector{LPPConstraint}

Parse RSTLPP.DAT file (Linear Piecewise Constraints).

# Format
Based on reverse-engineering of sample file `docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/rstlpp.dat`.

Structure:
1. RSTSEG: Defines the constraint and main controller.
2. ADICRS: Defines additional controllers.
3. RESLPP: Defines the linear segments (coefficients).

The equation for each segment is:
Flow <= LinearCoeff + AngCoeff * MainController + Coeff2 * Controller2 + ...

Rearranged for standard form (LHS <= RHS):
Flow - AngCoeff * MainController - Coeff2 * Controller2 ... <= LinearCoeff
"""
function parse_rstlpp(io::IO, filename::AbstractString)
    constraints = LPPConstraint[]

    # Map constraint_id -> List of (type, code)
    # The first element is the main controller from RSTSEG
    # Subsequent elements are from ADICRS
    controllers = Dict{Int,Vector{Tuple{String,Int}}}()

    # Map constraint_id -> Name
    names = Dict{Int,String}()

    line_num = 0
    for line in eachline(io)
        line_num += 1

        # Skip comments and blank lines
        if is_comment_line(line) || is_blank(line)
            continue
        end

        record_type = strip(extract_field(line, 1, 6))

        if record_type == "RSTSEG"
            # Parse RSTSEG
            # RSTSEG FNS        1 9007 DREF   9042
            # MNEM: 1-6
            # CHA1 (Name): 8-14
            # NUM (ID): 16-19
            # DREF: 21-24
            # CHAVE (Type): 26-30
            # IDENT (Code): 32-36

            name = strip(extract_field(line, 8, 14))
            id_str = strip(extract_field(line, 16, 19))
            id = parse(Int, id_str)

            # dref_id = parse(Int, strip(extract_field(line, 21, 24))) # Not used directly

            type = strip(extract_field(line, 26, 30))
            code_str = strip(extract_field(line, 32, 36))
            code = parse(Int, code_str)

            names[id] = name
            controllers[id] = [(type, code)]

        elseif record_type == "ADICRS"
            # Parse ADICRS
            # ADICRS FNS        1 9007 DREF   9036
            # Same columns as RSTSEG for ID, Type, Code

            id_str = strip(extract_field(line, 16, 19))
            id = parse(Int, id_str)

            type = strip(extract_field(line, 26, 30))
            code_str = strip(extract_field(line, 32, 36))
            code = parse(Int, code_str)

            if haskey(controllers, id)
                push!(controllers[id], (type, code))
            else
                @warn "ADICRS found for unknown constraint ID $id at line $line_num"
            end

        elseif record_type == "RESLPP"
            # Parse RESLPP
            # RESLPP    1 1 1      0.000       5000      0.000
            id_str = strip(extract_field(line, 8, 11))
            id = parse(Int, id_str)

            period_str = strip(extract_field(line, 13, 13))
            period = parse(Int, period_str)

            segment_str = strip(extract_field(line, 15, 15))
            segment = parse(Int, segment_str)

            # Coefficients start at 17
            # Ang Coeff (Main): 17-26
            # Linear Coeff (RHS): 28-37
            # Coeff 2: 39-48
            # Coeff 3: 50-59
            # ...

            ang_coeff_str = strip(extract_field(line, 17, 26))
            ang_coeff = isempty(ang_coeff_str) ? 0.0 : parse(Float64, ang_coeff_str)

            rhs_str = strip(extract_field(line, 28, 37))
            rhs = isempty(rhs_str) ? 0.0 : parse(Float64, rhs_str)

            coeffs = Dict{Tuple{String,Int},Float64}()

            # Add main controller coefficient
            if haskey(controllers, id) && length(controllers[id]) >= 1
                main_type, main_code = controllers[id][1]
                # The equation is: Flow <= RHS + AngCoeff * Main + Coeff2 * Adicrs1 ...
                # Rearranged: Flow - AngCoeff * Main - Coeff2 * Adicrs1 ... <= RHS
                # So we store -AngCoeff
                coeffs[(main_type, main_code)] = -ang_coeff
            end

            # Parse additional coefficients
            current_pos = 39
            ctrl_idx = 2

            while current_pos + 9 <= length(line)
                val_str = strip(extract_field(line, current_pos, current_pos + 9))
                if isempty(val_str)
                    break
                end

                val = parse(Float64, val_str)

                if haskey(controllers, id) && ctrl_idx <= length(controllers[id])
                    type, code = controllers[id][ctrl_idx]
                    coeffs[(type, code)] = -val
                end

                current_pos += 11 # 10 chars + 1 space
                ctrl_idx += 1
            end

            push!(
                constraints,
                LPPConstraint(
                    constraint_id = id,
                    constraint_name = get(names, id, ""),
                    period = period,
                    segment = segment,
                    sense = "<=",
                    rhs = rhs,
                    coefficients = coeffs,
                ),
            )
        end
    end

    return constraints
end

parse_rstlpp(filename::AbstractString) = open(io -> parse_rstlpp(io, filename), filename)

end
