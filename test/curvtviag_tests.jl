using Test
using DESSEM2Julia

@testset "CURVTVIAG Parser Tests" begin
    @testset "Single Record Parsing" begin
        line = "CURVTV    66    1  S             1        10"
        record = DESSEM2Julia.CurvTviagParser.parse_curvtviag_record(line)

        @test record.codigo_usina_montante == 66
        @test record.codigo_elemento_jusante == 1
        @test record.tipo_elemento_jusante == "S"
        @test record.hora == 1
        @test record.percentual_acumulado == 10
    end

    @testset "Different Element Types" begin
        # Section (S)
        line1 = "CURVTV    66    1  S             1        10"
        record1 = DESSEM2Julia.CurvTviagParser.parse_curvtviag_record(line1)
        @test record1.tipo_elemento_jusante == "S"

        # Hydro plant (H)
        line2 = "CURVTV    83    2  H            12        75"
        record2 = DESSEM2Julia.CurvTviagParser.parse_curvtviag_record(line2)
        @test record2.tipo_elemento_jusante == "H"
    end

    @testset "Hour Range" begin
        # Start of curve
        line1 = "CURVTV    66    1  S             1        10"
        record1 = DESSEM2Julia.CurvTviagParser.parse_curvtviag_record(line1)
        @test record1.hora == 1

        # Middle
        line2 = "CURVTV    66    1  S            12        55"
        record2 = DESSEM2Julia.CurvTviagParser.parse_curvtviag_record(line2)
        @test record2.hora == 12

        # End of curve
        line3 = "CURVTV    66    1  S            24       100"
        record3 = DESSEM2Julia.CurvTviagParser.parse_curvtviag_record(line3)
        @test record3.hora == 24
    end

    @testset "Percentage Range" begin
        # Start
        line1 = "CURVTV    66    1  S             1         0"
        record1 = DESSEM2Julia.CurvTviagParser.parse_curvtviag_record(line1)
        @test record1.percentual_acumulado == 0

        # Middle
        line2 = "CURVTV    66    1  S            12        50"
        record2 = DESSEM2Julia.CurvTviagParser.parse_curvtviag_record(line2)
        @test record2.percentual_acumulado == 50

        # Complete
        line3 = "CURVTV    66    1  S            24       100"
        record3 = DESSEM2Julia.CurvTviagParser.parse_curvtviag_record(line3)
        @test record3.percentual_acumulado == 100
    end

    @testset "Real CCEE Data - Full File Parsing" begin
        filepath = "docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/curvtviag.dat"
        if isfile(filepath)
            result = parse_curvtviag(filepath)

            # Should have 39 records (24 for plant 66→1 + 15 for plant 83→1)
            @test length(result.records) == 39

            # Check plant 66 → section 1 curve
            curve_66_1 = filter(
                r -> r.codigo_usina_montante == 66 && r.codigo_elemento_jusante == 1,
                result.records,
            )
            @test length(curve_66_1) == 24
            @test all(r -> r.tipo_elemento_jusante == "S", curve_66_1)

            # Verify hours 1-24
            hours_66 = sort([r.hora for r in curve_66_1])
            @test hours_66 == collect(1:24)

            # Verify percentages increase monotonically
            percs_66 = [r.percentual_acumulado for r in sort(curve_66_1, by = r -> r.hora)]
            @test issorted(percs_66)
            @test percs_66[1] == 10  # Starts at 10%
            @test percs_66[end] == 100  # Ends at 100%

            # Check plant 83 → section 1 curve
            curve_83_1 = filter(
                r -> r.codigo_usina_montante == 83 && r.codigo_elemento_jusante == 1,
                result.records,
            )
            @test length(curve_83_1) == 15
            @test all(r -> r.tipo_elemento_jusante == "S", curve_83_1)

            # Verify hours 1-15
            hours_83 = sort([r.hora for r in curve_83_1])
            @test hours_83 == collect(1:15)

            # Verify percentages increase monotonically
            percs_83 = [r.percentual_acumulado for r in sort(curve_83_1, by = r -> r.hora)]
            @test issorted(percs_83)
            @test percs_83[end] == 100  # Ends at 100%
        else
            @test_skip "CCEE sample file not found"
        end
    end

    @testset "Real ONS Data" begin
        filepath = "docs/Sample/DS_ONS_102025_RV2D11/curvtviag.dat"
        if isfile(filepath)
            result = parse_curvtviag(filepath)
            @test length(result.records) > 0

            # Verify basic constraints
            @test all(r -> r.hora >= 0, result.records)
            @test all(r -> 0 <= r.percentual_acumulado <= 100, result.records)
            @test all(r -> r.tipo_elemento_jusante in ["S", "H"], result.records)
        else
            @test_skip "ONS sample file not found"
        end
    end

    @testset "Comment and Section Separator Handling" begin
        test_content = """
        & Travel time curves
        CURVTV    66    1  S             1        10
        CURVTV    66    1  S             2        20
        &
        CURVTV    83    1  S             1        15
        CURVTV    83    1  S             2        30
        """

        result = parse_curvtviag(IOBuffer(test_content), "test.dat")

        @test length(result.records) == 4

        # Verify two curves
        curve_66 = filter(r -> r.codigo_usina_montante == 66, result.records)
        curve_83 = filter(r -> r.codigo_usina_montante == 83, result.records)
        @test length(curve_66) == 2
        @test length(curve_83) == 2
    end

    @testset "Multiple Propagation Curves" begin
        test_content = """
        CURVTV   100   10  S             1         5
        CURVTV   100   10  S             2        15
        CURVTV   100   10  S             3       100
        &
        CURVTV   200   20  H             1        20
        CURVTV   200   20  H             2        50
        CURVTV   200   20  H             3       100
        """

        result = parse_curvtviag(IOBuffer(test_content), "test.dat")

        @test length(result.records) == 6

        # Check first curve (plant 100 → section 10)
        curve1 = filter(
            r -> r.codigo_usina_montante == 100 && r.codigo_elemento_jusante == 10,
            result.records,
        )
        @test length(curve1) == 3
        @test all(r -> r.tipo_elemento_jusante == "S", curve1)

        # Check second curve (plant 200 → plant 20)
        curve2 = filter(
            r -> r.codigo_usina_montante == 200 && r.codigo_elemento_jusante == 20,
            result.records,
        )
        @test length(curve2) == 3
        @test all(r -> r.tipo_elemento_jusante == "H", curve2)
    end

    @testset "Non-CURVTV Lines Ignored" begin
        test_content = """
        & This is a comment
        RANDOM TEXT LINE
        CURVTV    66    1  S             1        10
        NOT A CURVTV LINE
        CURVTV    66    1  S             2        20
        """

        result = parse_curvtviag(IOBuffer(test_content), "test.dat")

        # Should only parse CURVTV lines
        @test length(result.records) == 2
    end

    @testset "Monotonic Accumulation Validation" begin
        # Test helper to check monotonicity per curve
        test_content = """
        CURVTV    66    1  S             1        10
        CURVTV    66    1  S             2        21
        CURVTV    66    1  S             3        35
        CURVTV    66    1  S             4        50
        CURVTV    66    1  S             5       100
        """

        result = parse_curvtviag(IOBuffer(test_content), "test.dat")

        # Get percentages in hour order
        sorted_records = sort(result.records, by = r -> r.hora)
        percentages = [r.percentual_acumulado for r in sorted_records]

        # Should be monotonically increasing
        @test issorted(percentages)
    end
end
