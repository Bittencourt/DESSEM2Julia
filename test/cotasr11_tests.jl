using Test
using DESSEM2Julia

@testset "COTASR11 Parser Tests" begin
    @testset "Single Record Parsing" begin
        line = "27  0 0              96.35"
        record = DESSEM2Julia.CotasR11Parser.parse_cotasr11_record(line)

        @test record.dia == 27
        @test record.hora == 0
        @test record.meia_hora == 0
        @test record.cota ≈ 96.35
    end

    @testset "Different Hours" begin
        line = "27 23 1              93.58"
        record = DESSEM2Julia.CotasR11Parser.parse_cotasr11_record(line)

        @test record.dia == 27
        @test record.hora == 23
        @test record.meia_hora == 1
        @test record.cota ≈ 93.58
    end

    @testset "Hour Boundaries" begin
        # Test midnight
        line = "27  0 0              96.35"
        record = DESSEM2Julia.CotasR11Parser.parse_cotasr11_record(line)
        @test record.hora == 0

        # Test noon
        line = "27 12 0              95.00"
        record = DESSEM2Julia.CotasR11Parser.parse_cotasr11_record(line)
        @test record.hora == 12

        # Test end of day
        line = "27 23 1              93.58"
        record = DESSEM2Julia.CotasR11Parser.parse_cotasr11_record(line)
        @test record.hora == 23
    end

    @testset "Half-Hour Values" begin
        # First half-hour (0)
        line = "27 10 0              95.50"
        record = DESSEM2Julia.CotasR11Parser.parse_cotasr11_record(line)
        @test record.meia_hora == 0

        # Second half-hour (1)
        line = "27 10 1              95.45"
        record = DESSEM2Julia.CotasR11Parser.parse_cotasr11_record(line)
        @test record.meia_hora == 1
    end

    @testset "Real CCEE Data - Full File Parsing" begin
        filepath = "docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/cotasr11.dat"
        if isfile(filepath)
            result = parse_cotasr11(filepath)

            # Should have 48 records (24 hours × 2 half-hours)
            @test length(result.records) == 48

            # Check first record
            @test result.records[1].dia == 27
            @test result.records[1].hora == 0
            @test result.records[1].meia_hora == 0
            @test result.records[1].cota ≈ 96.35

            # Check last record
            @test result.records[end].dia == 27
            @test result.records[end].hora == 23
            @test result.records[end].meia_hora == 1
            @test result.records[end].cota ≈ 93.58

            # Verify all records are for day 27
            @test all(r -> r.dia == 27, result.records)

            # Verify hours range 0-23
            hours = [r.hora for r in result.records]
            @test minimum(hours) == 0
            @test maximum(hours) == 23

            # Verify meia_hora is 0 or 1
            @test all(r -> r.meia_hora in [0, 1], result.records)

            # Verify cotas are reasonable (90-100 meters typical for Itaipu)
            cotas = [r.cota for r in result.records]
            @test all(c -> 90.0 <= c <= 100.0, cotas)

            # Verify sequential ordering (hour 0-23, each with half-hours 0 and 1)
            for h in 0:23
                records_h = filter(r -> r.hora == h, result.records)
                @test length(records_h) == 2
                @test any(r -> r.meia_hora == 0, records_h)
                @test any(r -> r.meia_hora == 1, records_h)
            end
        else
            @test_skip "CCEE sample file not found"
        end
    end

    @testset "Real ONS Data" begin
        filepath = "docs/Sample/DS_ONS_102025_RV2D11/cotasr11.dat"
        if isfile(filepath)
            result = parse_cotasr11(filepath)
            @test length(result.records) > 0

            # Verify basic constraints
            @test all(r -> 0 <= r.hora <= 23, result.records)
            @test all(r -> r.meia_hora in [0, 1], result.records)
        else
            @test_skip "ONS sample file not found"
        end
    end

    @testset "Comment Handling" begin
        test_content = """
        & Historical R11 gauge levels
        27  0 0              96.35
        & Midnight readings
        27  0 1              96.33
        27  1 0              96.30
        """

        result = parse_cotasr11(IOBuffer(test_content), "test.dat")

        @test length(result.records) == 3
        @test result.records[1].cota ≈ 96.35
        @test result.records[2].cota ≈ 96.33
        @test result.records[3].cota ≈ 96.30
    end

    @testset "Blank Lines" begin
        test_content = """
        27  0 0              96.35

        27  0 1              96.33

        27  1 0              96.30
        """

        result = parse_cotasr11(IOBuffer(test_content), "test.dat")

        @test length(result.records) == 3
    end
end
