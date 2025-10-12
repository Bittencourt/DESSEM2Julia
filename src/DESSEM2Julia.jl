module DESSEM2Julia

export greet
export DessemData, convert_inputs
export ThermalRegistry, CADUSIT, CADUNIDT, CURVACOMB
export parse_termdat

include("types.jl"); using .Types: DessemData, ThermalRegistry, CADUSIT, CADUNIDT, CURVACOMB
include("io.jl"); using .IO
include("parser/common.jl"); using .ParserCommon
include("parser/termdat.jl"); using .TermdatParser: parse_termdat, parse_cadusit, parse_cadunidt, parse_curvacomb
include("parser/registry.jl"); using .ParserRegistry
include("api.jl"); using .API: convert_inputs

"""
    greet(name::AbstractString = "world") -> String

Return a friendly greeting. Used for initial package smoke test.
"""
greet(name::AbstractString = "world")::String = "Hello, $(name)! 👋"

end # module
