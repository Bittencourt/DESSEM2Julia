using Test
using DESSEM2Julia

@testset "AREACONT Parser Tests" begin
    @testset "Single Area Record Parsing" begin
        line = "  1      FOLGA FPM - RESERVA DE POTENCIA DO SIN"
        record = DESSEM2Julia.AreaContParser.parse_area_record(line)

        @test record.codigo_area == 1
        @test record.nome_area == "FOLGA FPM - RESERVA DE POTENCIA DO SIN"
    end

    @testset "Single Usina Record Parsing - Hydro" begin
        line = "  1    H 261  LAJEADO"
        record = DESSEM2Julia.AreaContParser.parse_usina_record(line)

        @test record.codigo_area == 1
        @test record.tipo_componente == "H"
        @test record.codigo_componente == 261
        @test record.nome_componente == "LAJEADO"
    end

    @testset "Single Usina Record Parsing - Thermal" begin
        line = "  1    T  45  ANGRA 1"
        record = DESSEM2Julia.AreaContParser.parse_usina_record(line)

        @test record.codigo_area == 1
        @test record.tipo_componente == "T"
        @test record.codigo_componente == 45
        @test record.nome_componente == "ANGRA 1"
    end

    @testset "Names with Spaces" begin
        # Test that fixed-width parsing handles spaces correctly
        line = "  1    H 123  NOVA VENECIA 2"
        record = DESSEM2Julia.AreaContParser.parse_usina_record(line)

        @test record.nome_componente == "NOVA VENECIA 2"
    end

    @testset "Real CCEE Data - Full File Parsing" begin
        filepath = "docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/areacont.dat"
        if isfile(filepath)
            result = parse_areacont(filepath)

            # Check areas
            @test length(result.areas) >= 1
            @test result.areas[1].codigo_area == 1
            @test occursin("FOLGA", result.areas[1].nome_area)

            # Check usinas
            @test length(result.usinas) == 24  # Sample has 24 plants

            # Verify all area codes match
            for usina in result.usinas
                @test usina.codigo_area == 1
            end

            # Verify tipos are H or T
            for usina in result.usinas
                @test usina.tipo_componente in ["H", "T"]
            end

            # Check specific plants exist
            lajeado = findfirst(u -> u.codigo_componente == 261, result.usinas)
            @test lajeado !== nothing
            if lajeado !== nothing
                @test result.usinas[lajeado].nome_componente == "LAJEADO"
            end
        else
            @test_skip "CCEE sample file not found"
        end
    end

    @testset "Real ONS Data" begin
        filepath = "docs/Sample/DS_ONS_102025_RV2D11/areacont.dat"
        if isfile(filepath)
            result = parse_areacont(filepath)
            @test length(result.areas) >= 0
            @test length(result.usinas) >= 0
        else
            @test_skip "ONS sample file not found"
        end
    end

    @testset "Block Structure" begin
        # Test proper handling of block markers
        test_content = """
        AREA
          1      TEST AREA
        FIM
        &
        USINA
          1    H 100  TEST PLANT 1
          1    T 200  TEST PLANT 2
        FIM
        9999
        """

        result = parse_areacont(IOBuffer(test_content), "test.dat")

        @test length(result.areas) == 1
        @test result.areas[1].codigo_area == 1
        @test result.areas[1].nome_area == "TEST AREA"

        @test length(result.usinas) == 2
        @test result.usinas[1].tipo_componente == "H"
        @test result.usinas[2].tipo_componente == "T"
    end

    @testset "Comment Handling" begin
        test_content = """
        & This is a comment
        AREA
        & Another comment
          1      TEST AREA
        FIM
        & Comment between blocks
        USINA
          1    H 100  TEST PLANT
        FIM
        9999
        """

        result = parse_areacont(IOBuffer(test_content), "test.dat")

        @test length(result.areas) == 1
        @test length(result.usinas) == 1
    end

    @testset "Empty Blocks" begin
        test_content = """
        AREA
        FIM
        USINA
        FIM
        9999
        """

        result = parse_areacont(IOBuffer(test_content), "test.dat")

        @test length(result.areas) == 0
        @test length(result.usinas) == 0
    end
end
