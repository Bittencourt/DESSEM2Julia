module API

using ..Types: DessemData
using ..ParserCommon: normalize_name
using ..ParserRegistry: get_parser
using ..IO: save_jld2
using Dates

export convert_inputs

"""convert_inputs(input_dir::AbstractString, output_path::AbstractString) -> String
Enumerate files in input_dir, route to registered parsers by filename, aggregate
into DessemData, and save to JLD2 at output_path. Returns output_path.
Unknown files are currently stored as raw text content for traceability.
"""
function convert_inputs(input_dir::AbstractString, output_path::AbstractString)
    files_map = Dict{String,Any}()

    for (root, _, files) in walkdir(String(input_dir))
        for f in files
            norm = normalize_name(f)
            parser = get_parser(norm)
            full = joinpath(root, f)
            if parser === nothing
                # Fallback: store raw content for now
                files_map[norm] = read(full, String)
            else
                files_map[norm] = parser(full)
            end
        end
        # Only parse top-level directory by default
        break
    end

    data = DessemData(
        files_map,
        Dict("input_dir" => String(input_dir), "generated_at" => Dates.now()),
    )
    return save_jld2(String(output_path), data)
end

end # module
