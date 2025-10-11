module ParserRegistry

using ..ParserCommon: normalize_name

export register_parser!, get_parser, known_parsers

const _REGISTRY = Dict{String, Function}()

"""register_parser!(fname::AbstractString, f::Function)
Register a parser function for a filename (case-insensitive, normalized).
"""
function register_parser!(fname::AbstractString, f::Function)
    _REGISTRY[normalize_name(fname)] = f
    return nothing
end

"""get_parser(fname::AbstractString) -> Union{Function,Nothing}
Return parser function for normalized filename or nothing if not present.
"""
get_parser(fname::AbstractString) = get(_REGISTRY, normalize_name(fname), nothing)

"""known_parsers() -> Vector{String}
List filenames with registered parsers.
"""
known_parsers() = collect(keys(_REGISTRY))

end # module
