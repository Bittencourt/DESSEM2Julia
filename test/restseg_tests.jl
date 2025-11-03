using Test
using DESSEM2Julia

@testset "RESTSEG Parser" begin
    @testset "Parse INDICE line" begin
        io = IOBuffer(
            "TABSEG INDICE     7 Fluxo Ji-Paraná - Pimenta Bueno em função do back-to-back\n",
        )
        seekstart(io)
        data = parse_restseg(io, "restseg.dat")
        @test length(data.indices) == 1
        @test data.indices[1].indice == 7
        @test occursin("Fluxo", data.indices[1].descricao)
    end

    @testset "Parse TABELA line" begin
        io = IOBuffer("TABSEG TABELA     7 CONTR  DREF    9004\n")
        seekstart(io)
        data = parse_restseg(io, "restseg.dat")
        @test length(data.tabelas) == 1
        t = data.tabelas[1]
        @test t.indice == 7
        @test t.tipo1 == "CONTR"
        @test t.tipo2 == "DREF"
        @test t.num == 9004
    end

    @testset "Parse LIMITE lines" begin
        io = IOBuffer("TABSEG LIMITE     7          0\nTABSEG LIMITE     7        800\n")
        seekstart(io)
        data = parse_restseg(io, "restseg.dat")
        @test length(data.limites) == 2
        @test data.limites[1].limite == 0
        @test data.limites[2].limite == 800
    end

    @testset "Parse CELULA lines" begin
        io = IOBuffer(
            "TABSEG CELULA     7        300             700         800\nTABSEG CELULA     7        970               0         500\n",
        )
        seekstart(io)
        data = parse_restseg(io, "restseg.dat")
        @test length(data.celulas) == 2
        c1 = data.celulas[1]
        @test c1.indice == 7 && c1.limite == 300
        @test c1.par1_inf == 700 && c1.par1_sup == 800
    end

    @testset "Integration with sample file (if available)" begin
        path = joinpath(
            @__DIR__,
            "..",
            "docs",
            "Sample",
            "DS_CCEE_102025_SEMREDE_RV0D28",
            "restseg.dat",
        )
        if isfile(path)
            data = parse_restseg(path)
            # Expect at least one block present
            @test length(data.indices) > 0
            @test length(data.tabelas) >= length(data.indices)
            @test length(data.celulas) > 0
        end
    end
end
