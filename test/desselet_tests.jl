using Test
using Dates
using DESSEM2Julia
using DESSEM2Julia: parse_desselet, DesseletData

@testset "DESSELET Parser" begin
    @testset "Synthetic File" begin
        sample = """
        (-----------------------------------------------------------------------)
        (Arquivos com Dados Eletricos para o DESSEM                             )
        (-----------------------------------------------------------------------)
        ( Arquivos de caso base
          1    leve          leve        .pwf
          2    pesada        pesado      .pwf
        99999
        (( Alteracoes dos casos base
          01 Estagio01    20250101  0  0  0.5      1 pat01.afp
          02 Estagio02    20250101  0 30  0.5      2 pat02.afp
        99999
        FIM
        """

        tmp = tempname() * ".dat"
        try
            write(tmp, sample)
            data = parse_desselet(tmp)

            @test data isa DesseletData
            @test length(data.base_cases) == 2
            @test data.base_cases[1].filename == "leve.pwf"
            @test data.base_cases[2].label == "pesada"

            @test length(data.patamares) == 2
            first_patamar = data.patamares[1]
            @test first_patamar.date == Date(2025, 1, 1)
            @test first_patamar.duration_hours == 0.5
            @test first_patamar.base_case_id == 1
            @test first_patamar.filename == "pat01.afp"
        finally
            rm(tmp, force = true)
        end
    end

    @testset "ONS Sample" begin
        sample_path = joinpath(
            @__DIR__,
            "..",
            "docs",
            "Sample",
            "DS_ONS_102025_RV2D11",
            "desselet.dat",
        )
        if isfile(sample_path)
            data = parse_desselet(sample_path)
            @test length(data.base_cases) >= 4
            @test length(data.patamares) == 48

            ids = sort(collect(b.base_id for b in data.base_cases))
            @test 1 in ids

            first_stage = data.patamares[1]
            @test first_stage.date == Date(2025, 10, 11)
            @test first_stage.hour == 0
            @test first_stage.minute in (0, 30)
        else
            @warn "ONS sample desselet.dat not found - skipping real data tests"
        end
    end
end
