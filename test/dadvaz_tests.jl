"""
Tests for DADVAZ.DAT parser (natural inflows).
"""

using Test
using Dates
using DESSEM2Julia
using DESSEM2Julia: parse_dadvaz, DadvazData

@testset "DADVAZ Parser" begin
    @testset "Synthetic File" begin
        sample = """
        NUMERO DE USINAS
        XXX
        2
        NUMERO DAS USINAS NO CADASTRO
        1   2
        Hr  Dd  Mm  Ano
        XX  XX  XX  XXXX
        00  28  09  2025
        Dia inic(1-SAB...7-SEX); sem da FCF; n. semanas; pre-interesse
        X X X X
        2 1 1 0
        VAZOES DIARIAS PARA CADA USINA (m3/s)
        NUM     NOME      itp   DI HI M DF HF M      VAZAO
          1 CAMARGOS       1    28      F                  37
          2 ITUTINGA       1    28      F                   0
        """

        tmp = tempname() * ".dat"
        try
            write(tmp, sample)
            data = parse_dadvaz(tmp)

            @test data isa DadvazData
            @test data.header.plant_count == 2
            @test data.header.plant_numbers == [1, 2]
            @test data.header.study_start == DateTime(2025, 9, 28, 0)
            @test data.header.initial_day_code == 2
            @test data.header.fcf_week_index == 1
            @test data.header.study_weeks == 1
            @test data.header.simulation_flag == 0

            @test length(data.records) == 2
            first_record = data.records[1]
            @test first_record.plant_num == 1
            @test first_record.plant_name == "CAMARGOS"
            @test first_record.end_day == "F"
            @test first_record.flow_m3s ≈ 37.0
        finally
            rm(tmp, force=true)
        end
    end

    @testset "Real Sample" begin
        sample_path = "docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/dadvaz.dat"
        if isfile(sample_path)
            data = parse_dadvaz(sample_path)
            @test data.header.plant_count > 0
            @test !isempty(data.records)

            camargos = filter(r -> r.plant_name == "CAMARGOS", data.records)
            @test !isempty(camargos)
            @test all(r -> r.inflow_type in (1, 2, 3), camargos)
        else
            @warn "Sample file not found: $sample_path - skipping real data tests"
        end
    end
end
