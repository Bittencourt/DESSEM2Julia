using Test
using DESSEM2Julia

@testset "DESSEM2Julia.greet" begin
    @test greet() == "Hello, world! 👋"
    @test greet("Julia") == "Hello, Julia! 👋"
end

include("convert_tests.jl")
include("parser/common_tests.jl")
include("termdat_tests.jl")
