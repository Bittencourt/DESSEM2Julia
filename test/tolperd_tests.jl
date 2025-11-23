using Test
using DESSEM2Julia

@testset "TOLPERD Parser Tests" begin
    @testset "Placeholder Parsing" begin
        io = IOBuffer("""
        * Comment
        DATA LINE 1
        DATA LINE 2
        """)

        data = parse_tolperd(io, "test.dat")

        @test length(data.lines) == 2
        @test data.lines[1] == "DATA LINE 1"
        @test data.lines[2] == "DATA LINE 2"
    end
end
