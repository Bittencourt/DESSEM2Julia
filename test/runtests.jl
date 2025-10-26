using Test
using DESSEM2Julia

@testset "DESSEM2Julia.greet" begin
    @test greet() == "Hello, world! 👋"
    @test greet("Julia") == "Hello, Julia! 👋"
end

include("convert_tests.jl")
include("parser/common_tests.jl")
include("termdat_tests.jl")
include("entdados_tests.jl")
include("dessemarq_tests.jl")
include("operut_tests.jl")
include("dadvaz_tests.jl")
include("deflant_tests.jl")
include("desselet_tests.jl")
include("renovaveis_tests.jl")
include("simul_tests.jl")
include("dessopc_tests.jl")
include("areacont_tests.jl")
include("cotasr11_tests.jl")
include("curvtviag_tests.jl")
include("network_topology_tests.jl")

# Integration tests with real ONS sample data
include("ons_integration_tests.jl")
