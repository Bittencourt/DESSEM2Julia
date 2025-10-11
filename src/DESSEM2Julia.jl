module DESSEM2Julia

export greet

"""
    greet(name::AbstractString = "world") -> String

Return a friendly greeting. Used for initial package smoke test.
"""
greet(name::AbstractString = "world")::String = "Hello, $(name)! 👋"

end # module
