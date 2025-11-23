using Test
using DESSEM2Julia

@testset "MODIF Parser Tests" begin
    @testset "Basic Parsing" begin
        # Mock data
        data = """
        & This is a comment
        MODIF RECORD 1
        MODIF RECORD 2
        """

        io = IOBuffer(data)
        result = parse_modif(io)

        @test length(result.records) == 2
        @test strip(result.records[1].line) == "MODIF RECORD 1"
        @test strip(result.records[2].line) == "MODIF RECORD 2"
    end

    @testset "Empty File" begin
        io = IOBuffer("")
        result = parse_modif(io)
        @test isempty(result.records)
    end
end
