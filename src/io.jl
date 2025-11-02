module IO

using JLD2
using ..Types: DessemData

export save_jld2, load_jld2

"""save_jld2(path::AbstractString, data::DessemData)
Save DessemData to JLD2 at the given path.
"""
function save_jld2(path::AbstractString, data::DessemData)
    jldsave(path; data = data)
    return path
end

"""load_jld2(path::AbstractString) -> DessemData
Load DessemData from a JLD2 file created by save_jld2.
"""
function load_jld2(path::AbstractString)::DessemData
    jldopen(path, "r") do f
        return read(f, "data")
    end
end

end # module
