module DESSEM2Julia

export greet
export DessemData, convert_inputs

include("types.jl"); using .Types: DessemData
include("io.jl"); using .IO
include("parser/common.jl"); using .ParserCommon
include("parser/registry.jl"); using .ParserRegistry
include("api.jl"); using .API: convert_inputs

"""
    greet(name::AbstractString = "world") -> String

Return a friendly greeting. Used for initial package smoke test.
"""
greet(name::AbstractString = "world")::String = "Hello, $(name)! 👋"

end # module
