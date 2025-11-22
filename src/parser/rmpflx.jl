module RmpflxParser

using ..CoreTypes
using ..ParserCommon

export parse_rmpflx

"""
    parse_rmpflx(io::IO, filename::String) -> RmpflxData

Parse RMPFLX.DAT file (Flow Ramp Constraints).

# Arguments
- `io::IO`: Input stream
- `filename::String`: Source filename for error reporting

# Returns
- `RmpflxData`: Parsed data structure
"""
function parse_rmpflx(io::IO, filename::String)
    rest_records = RmpflxRest[]
    limi_records = RmpflxLimi[]

    for (line_num, line) in enumerate(eachline(io))
        # Skip comments and blank lines
        if is_comment_line(line) || is_blank(line)
            continue
        end

        # Check mnemonic
        mnemonic = extract_field(line, 1, 6)
        if mnemonic != "RMPFLX"
            continue
        end

        record_type = extract_field(line, 8, 11)

        if record_type == "REST"
            # RMPFLX REST DREF Valor [Status]
            # 1-6: Mnem
            # 8-11: Type
            # 13-16: DREF (ID)
            # 18-27: Value
            # 29: Status (Optional)

            dref_str = extract_field(line, 13, 16)
            val_str = extract_field(line, 18, 27)
            status_str = extract_field(line, 29, 29)

            if isempty(dref_str) || isempty(val_str)
                continue
            end

            dref = parse_int(dref_str)
            val = parse_float(val_str)
            status = isempty(status_str) ? nothing : parse_int(status_str)

            push!(
                rest_records,
                RmpflxRest(constraint_id = dref, initial_value = val, status = status),
            )

        elseif record_type == "LIMI"
            # RMPFLX LIMI DI HI MI DF HF MF DREF Desc Sub [Status]
            # 1-6: Mnem
            # 8-11: Type
            # 13-14: DI
            # 16-17: HI
            # 19: MI
            # 21-22: DF
            # 24-25: HF
            # 27: MF
            # 29-32: DREF
            # 34-43: Desc
            # 45-54: Sub
            # 56: Status (Optional)

            # Parse start date
            (start_day, start_hour, start_half) = parse_stage_date(
                line,
                13;
                special_char = "I",
                file = filename,
                line_num = line_num,
            )

            # Parse end date
            (end_day, end_hour, end_half) = parse_stage_date(
                line,
                21;
                special_char = "F",
                file = filename,
                line_num = line_num,
            )

            dref_str = extract_field(line, 29, 32)
            desc_str = extract_field(line, 34, 43)
            sub_str = extract_field(line, 45, 54)
            status_str = extract_field(line, 56, 56)

            if isempty(dref_str)
                continue
            end

            dref = parse_int(dref_str)
            desc = parse_float(desc_str)
            sub = parse_float(sub_str)
            status = isempty(status_str) ? nothing : parse_int(status_str)

            push!(
                limi_records,
                RmpflxLimi(
                    constraint_id = dref,
                    start_day = start_day,
                    start_hour = start_hour,
                    start_half = start_half,
                    end_day = end_day,
                    end_hour = end_hour,
                    end_half = end_half,
                    ramp_down = desc,
                    ramp_up = sub,
                    status = status,
                ),
            )
        end
    end

    return RmpflxData(rest_records = rest_records, limi_records = limi_records)
end

"""
    parse_rmpflx(filename::String) -> RmpflxData

Parse RMPFLX.DAT file from file path.
"""
parse_rmpflx(filename::String) = open(io -> parse_rmpflx(io, filename), filename)

end # module
