# NOTE: LF line endings enforced via .gitattributes for consistent CI formatting
using Test
using DESSEM2Julia

@testset "RESPOTELE Parser Tests" begin
    @testset "RP Record Parsing" begin
        # Test basic RP record similar to RESPOT format through file parsing
        test_data = """
        &
        RP    1  11  0 0  F           ELECTRICAL RESERVE AREA 1
        &
        """

        tempfile = tempname()
        write(tempfile, test_data)

        try
            result = parse_respotele(tempfile)
            @test length(result.rp_records) == 1
            record = result.rp_records[1]

            @test record.codigo_area == 1
            @test record.dia_inicial == 11
            @test record.hora_inicial == 0
            @test record.meia_hora_inicial == 0
            @test record.dia_final == "F"
            @test record.hora_final === nothing
            @test record.meia_hora_final === nothing
            @test record.descricao == "ELECTRICAL RESERVE AREA 1"
        finally
            rm(tempfile, force = true)
        end
    end

    @testset "RP Record with Numeric Final Day" begin
        # Use exact spacing from RESPOT format
        test_data = """
        &
        RP    2  10 15 1 11 23 1       AREA 2 ELECTRICAL RESERVE
        &
        """

        tempfile = tempname()
        write(tempfile, test_data)

        try
            result = parse_respotele(tempfile)
            @test length(result.rp_records) == 1
            record = result.rp_records[1]
            @test record.codigo_area == 2
            @test record.dia_inicial == 10
            @test record.hora_inicial == 15
            @test record.meia_hora_inicial == 1
            @test record.dia_final == 11
            @test record.hora_final == 23
            @test record.meia_hora_final == 1
            @test occursin("AREA 2", record.descricao)
        finally
            rm(tempfile, force = true)
        end
    end

    @testset "RP Record with Initial Marker 'I'" begin
        # Use exact spacing
        test_data = """
        &
        RP    3  I   0 0 12  0 0       AREA 3 FROM START
        &
        """

        tempfile = tempname()
        write(tempfile, test_data)

        try
            result = parse_respotele(tempfile)
            @test length(result.rp_records) == 1
            record = result.rp_records[1]
            @test record.codigo_area == 3
            @test record.dia_inicial == "I"
            @test record.hora_inicial == 0
            @test record.meia_hora_inicial == 0
            @test record.dia_final == 12
            @test record.hora_final == 0
            @test record.meia_hora_final == 0
        finally
            rm(tempfile, force = true)
        end
    end

    @testset "LM Record Parsing" begin
        # Test basic LM record similar to RESPOT format
        test_data = """
        &
        LM    1  11  0 0  F            3285
        &
        """

        tempfile = tempname()
        write(tempfile, test_data)

        try
            result = parse_respotele(tempfile)
            @test length(result.lm_records) == 1
            record = result.lm_records[1]
            @test record.codigo_area == 1
            @test record.dia_inicial == 11
            @test record.hora_inicial == 0
            @test record.meia_hora_inicial == 0
            @test record.dia_final == "F"
            @test record.hora_final === nothing
            @test record.meia_hora_final === nothing
            @test record.limite_inferior ≈ 3285.0
        finally
            rm(tempfile, force = true)
        end
    end

    @testset "LM Record Half-Hourly Sequence" begin
        # Test half-hour progression (0 -> 1)
        test_data = """
        &
        LM    1  11  0 0  F            2732
        LM    1  11  0 1  F            2632
        &
        """

        tempfile = tempname()
        write(tempfile, test_data)

        try
            result = parse_respotele(tempfile)
            @test length(result.lm_records) == 2

            rec1 = result.lm_records[1]
            rec2 = result.lm_records[2]
            @test rec1.hora_inicial == 0
            @test rec1.meia_hora_inicial == 0
            @test rec1.limite_inferior ≈ 2732.0

            @test rec2.hora_inicial == 0
            @test rec2.meia_hora_inicial == 1
            @test rec2.limite_inferior ≈ 2632.0
        finally
            rm(tempfile, force = true)
        end
    end

    @testset "LM Record Hourly Progression" begin
        # Test hour change with integer limits
        test_data = """
        &
        LM    1  11  1 0  F            3113
        LM    1  11  1 1  F            3053
        &
        """

        tempfile = tempname()
        write(tempfile, test_data)

        try
            result = parse_respotele(tempfile)
            @test length(result.lm_records) == 2

            rec1 = result.lm_records[1]
            rec2 = result.lm_records[2]
            @test rec1.hora_inicial == 1
            @test rec1.meia_hora_inicial == 0
            @test rec1.limite_inferior ≈ 3113.0

            @test rec2.hora_inicial == 1
            @test rec2.meia_hora_inicial == 1
            @test rec2.limite_inferior ≈ 3053.0
        finally
            rm(tempfile, force = true)
        end
    end

    @testset "LM Record with Numeric Final Day" begin
        # Verify numeric final day handling
        test_data = """
        &
        LM    2  10  5 0 11  6 0       1500
        &
        """

        tempfile = tempname()
        write(tempfile, test_data)

        try
            result = parse_respotele(tempfile)
            @test length(result.lm_records) == 1
            record = result.lm_records[1]
            @test record.codigo_area == 2
            @test record.dia_inicial == 10
            @test record.hora_inicial == 5
            @test record.meia_hora_inicial == 0
            @test record.dia_final == 11
            @test record.hora_final == 6
            @test record.meia_hora_final == 0
            @test record.limite_inferior ≈ 1500.0
        finally
            rm(tempfile, force = true)
        end
    end

    @testset "Complete File Parsing" begin
        # Create temporary test file
        test_data = """
        &
        RP    1  11  0 0  F           ELECTRICAL RESERVE POOL 1
        &
        LM    1  11  0 0  F            2732
        LM    1  11  0 1  F            2632
        LM    1  11  1 0  F            2566
        LM    1  11  1 1  F            2505
        &
        RP    2  11  0 0  F           AREA 2 ELECTRICAL RESERVES
        &
        LM    2  11  0 0  F            1500
        LM    2  11  0 1  F            1450
        """

        tempfile = tempname()
        write(tempfile, test_data)

        try
            result = parse_respotele(tempfile)

            @test length(result.rp_records) == 2
            @test length(result.lm_records) == 6

            # Check first RP
            @test result.rp_records[1].codigo_area == 1
            @test result.rp_records[1].descricao == "ELECTRICAL RESERVE POOL 1"

            # Check second RP
            @test result.rp_records[2].codigo_area == 2
            @test result.rp_records[2].descricao == "AREA 2 ELECTRICAL RESERVES"

            # Check LM records for area 1
            area1_lm = filter(r -> r.codigo_area == 1, result.lm_records)
            @test length(area1_lm) == 4
            @test area1_lm[1].limite_inferior ≈ 2732.0
            @test area1_lm[4].limite_inferior ≈ 2505.0

            # Check LM records for area 2
            area2_lm = filter(r -> r.codigo_area == 2, result.lm_records)
            @test length(area2_lm) == 2
            @test area2_lm[1].limite_inferior ≈ 1500.0

        finally
            rm(tempfile, force = true)
        end
    end

    @testset "Comment and Blank Line Handling" begin
        test_data = """
        &
        & This is a comment
        RP    1  11  0 0  F           TEST ELECTRICAL RESERVE POOL

        & Another comment
        &
        LM    1  11  0 0  F            2500

        LM    1  11  0 1  F            2400
        &
        """

        tempfile = tempname()
        write(tempfile, test_data)

        try
            result = parse_respotele(tempfile)

            @test length(result.rp_records) == 1
            @test length(result.lm_records) == 2

        finally
            rm(tempfile, force = true)
        end
    end

    @testset "Half-Hourly Time Series Validation" begin
        # Test with full day format
        test_data = """
        &
        RP    1  11  0 0  F           TEST FULL DAY ELECTRICAL
        &
        LM    1  11  0 0  F            2732
        LM    1  11  0 1  F            2632
        LM    1  11  1 0  F            2566
        LM    1  11  1 1  F            2505
        LM    1  11  2 0  F            2453
        LM    1  11  2 1  F            2417
        """

        tempfile = tempname()
        write(tempfile, test_data)

        try
            result = parse_respotele(tempfile)

            @test length(result.rp_records) == 1
            @test length(result.lm_records) == 6

            # Validate time progression for first few records
            @test result.lm_records[1].hora_inicial == 0
            @test result.lm_records[1].meia_hora_inicial == 0
            @test result.lm_records[1].limite_inferior ≈ 2732.0

            @test result.lm_records[2].hora_inicial == 0
            @test result.lm_records[2].meia_hora_inicial == 1
            @test result.lm_records[2].limite_inferior ≈ 2632.0

            @test result.lm_records[3].hora_inicial == 1
            @test result.lm_records[3].meia_hora_inicial == 0

            @test result.lm_records[5].hora_inicial == 2
            @test result.lm_records[5].meia_hora_inicial == 0

        finally
            rm(tempfile, force = true)
        end
    end

    @testset "Type System Constraints" begin
        # Test that optional fields are truly optional
        rp = RespoteleRP(
            codigo_area = 1,
            dia_inicial = 11,
            dia_final = "F",
            descricao = "TEST",
        )
        @test rp.hora_inicial === nothing
        @test rp.meia_hora_inicial === nothing

        # Test that required fields must be provided
        @test_throws UndefKeywordError RespoteleRP(dia_inicial = 11, dia_final = "F")  # Missing codigo_area

        # Test LM with all fields
        lm = RespoteLM(
            codigo_area = 1,
            dia_inicial = 11,
            hora_inicial = 5,
            meia_hora_inicial = 1,
            dia_final = "F",
            limite_inferior = 2500.0,
        )
        @test lm.limite_inferior ≈ 2500.0
    end

    @testset "Empty File Handling" begin
        # Test with file containing only comments
        test_data = """
        &
        & Comment only file
        &
        """

        tempfile = tempname()
        write(tempfile, test_data)

        try
            result = parse_respotele(tempfile)

            @test length(result.rp_records) == 0
            @test length(result.lm_records) == 0

        finally
            rm(tempfile, force = true)
        end
    end
end

println("\n✅ All RESPOTELE parser tests completed!")
