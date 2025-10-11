module Types

"""
DessemData holds parsed DESSEM inputs aggregated by filename.

Fields
- files: Dict mapping filename (uppercase) -> parsed object (Any for now)
- metadata: Dict for auxiliary info (e.g., input_dir, timestamp, version)
"""
Base.@kwdef struct DessemData
    files::Dict{String, Any} = Dict{String, Any}()
    metadata::Dict{String, Any} = Dict{String, Any}()
end

end # module
