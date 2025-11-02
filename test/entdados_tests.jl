# NOTE: LF line endings enforced via .gitattributes for consistent CI formatting
using Test
using DESSEM2Julia

@testset "ENTDADOS Parser Tests" begin

    # ========================================================================
    # TM Record Tests
    # ========================================================================

    @testset "TM Record Parsing" begin
        @testset "Basic TM Record" begin
            line = "TM  28    0   0      0.5     0     LEVE"
            data = parse_entdados(IOBuffer(line))
            @test length(data.time_periods) == 1
            tm = data.time_periods[1]
            @test tm.day == 28
            @test tm.hour == 0
            @test tm.half_hour == 0
            @test tm.duration ≈ 0.5
            @test tm.network_flag == 0
            @test tm.load_level == "LEVE"
        end

        @testset "TM with Different Load Levels" begin
            lines = """
            TM  28   17   1      0.5     0    MEDIA
            TM  29   15   0        7     0   PESADA
            """
            data = parse_entdados(IOBuffer(lines))
            @test length(data.time_periods) == 2
            @test data.time_periods[1].load_level == "MEDIA"
            @test data.time_periods[2].load_level == "PESADA"
            @test data.time_periods[2].duration ≈ 7.0
        end

        @testset "TM with Network Flags" begin
            lines = """
            TM  28    0   0      1.0     0
            TM  28    1   0      1.0     1
            TM  28    2   0      1.0     2
            """
            data = parse_entdados(IOBuffer(lines))
            @test data.time_periods[1].network_flag == 0
            @test data.time_periods[2].network_flag == 1
            @test data.time_periods[3].network_flag == 2
        end

        @testset "TM Validation - Invalid Hour" begin
            line = "TM  28   24   0      0.5     0"
            @test_throws Exception parse_entdados(IOBuffer(line))
        end

        @testset "TM Validation - Invalid Half Hour" begin
            line = "TM  28    0   2      0.5     0"
            @test_throws Exception parse_entdados(IOBuffer(line))
        end

        @testset "TM Validation - Invalid Network Flag" begin
            line = "TM  28    0   0      0.5     3"
            @test_throws Exception parse_entdados(IOBuffer(line))
        end
    end

    # ========================================================================
    # SIST Record Tests
    # ========================================================================

    @testset "SIST Record Parsing" begin
        @testset "Basic SIST Record" begin
            line = "SIST    1 SE  0 SUDESTE"
            data = parse_entdados(IOBuffer(line))
            @test length(data.subsystems) == 1
            sist = data.subsystems[1]
            @test sist.subsystem_num == 1
            @test sist.subsystem_code == "SE"
            @test sist.status == 0
            @test sist.subsystem_name == "SUDESTE"
        end

        @testset "Multiple SIST Records" begin
            lines = """
            SIST    1 SE  0 SUDESTE   
            SIST    2 S   0 SUL
            SIST    3 NE  0 NORDESTE
            SIST    4 N   0 NORTE
            """
            data = parse_entdados(IOBuffer(lines))
            @test length(data.subsystems) == 4
            @test data.subsystems[1].subsystem_code == "SE"
            @test data.subsystems[2].subsystem_code == "S"
            @test data.subsystems[3].subsystem_code == "NE"
            @test data.subsystems[4].subsystem_code == "N"
        end

        @testset "SIST Validation - Invalid Subsystem Number" begin
            line = "SIST  100 XX  0 INVALID"
            @test_throws Exception parse_entdados(IOBuffer(line))
        end
    end

    # ========================================================================
    # UH Record Tests
    # ========================================================================

    @testset "UH Record Parsing" begin
        @testset "Basic UH Record" begin
            line = "UH    1  CAMARGOS       10    82.82    1 I"
            data = parse_entdados(IOBuffer(line))
            @test length(data.hydro_plants) == 1
            uh = data.hydro_plants[1]
            @test uh.plant_num == 1
            @test uh.plant_name == "CAMARGOS"
            @test uh.status == 1
            @test uh.subsystem == 10  # This is actually the REE code (codigo_ree) per idessem spec
            @test uh.initial_volume_pct ≈ 82.82
            @test uh.volume_unit == 1
        end

        @testset "UH with Status and Subsystem" begin
            line = "UH    6  FURNAS         10    42.89    1 I"
            data = parse_entdados(IOBuffer(line))
            uh = data.hydro_plants[1]
            @test uh.plant_name == "FURNAS"
            @test uh.initial_volume_pct ≈ 42.89
        end

        @testset "Multiple UH Records" begin
            lines = """
            UH    1  CAMARGOS       10    82.82    1 I
            UH    2  ITUTINGA       10    94.95    1 I
            UH    4  FUNIL-GRAND    10    64.92    1 I
            """
            data = parse_entdados(IOBuffer(lines))
            @test length(data.hydro_plants) == 3
            @test data.hydro_plants[2].plant_name == "ITUTINGA"
            @test data.hydro_plants[3].initial_volume_pct ≈ 64.92
        end

        @testset "UH Validation - Invalid Plant Number" begin
            line = "UH  321  INVALID        10    50.0    1 I"
            @test_throws Exception parse_entdados(IOBuffer(line))
        end

        @testset "UH Validation - Invalid Volume Percent" begin
            line = "UH    1  CAMARGOS       10   150.0    1 I"
            @test_throws Exception parse_entdados(IOBuffer(line))
        end

        @testset "UH Validation - Invalid Volume Unit" begin
            line = "UH    1  CAMARGOS       10    82.82    3 I"
            @test_throws Exception parse_entdados(IOBuffer(line))
        end
    end

    # ========================================================================
    # UT Record Tests
    # ========================================================================

    @testset "UT Record Parsing" begin
        @testset "Basic UT Record" begin
            line = "UT    1  ANGRA 1       1 2 28  0 0  F               640.0     640.0"
            data = parse_entdados(IOBuffer(line))
            @test length(data.thermal_plants) == 1
            ut = data.thermal_plants[1]
            @test ut.plant_num == 1
            @test ut.plant_name == "ANGRA 1"
            @test ut.status == 1
            @test ut.subsystem == 2
            @test ut.start_day == 28
            @test ut.start_hour == 0
            @test ut.start_half == 0
            @test ut.end_marker == "F"
            @test ut.min_generation ≈ 640.0
            @test ut.max_generation ≈ 640.0
        end

        @testset "UT with Zero Minimum" begin
            line = "UT   12  CUIABA        1 2 28  0 0  F                 0.0     490.0"
            data = parse_entdados(IOBuffer(line))
            ut = data.thermal_plants[1]
            @test ut.plant_name == "CUIABA"
            @test ut.min_generation ≈ 0.0
            @test ut.max_generation ≈ 490.0
        end

        @testset "Multiple UT Records" begin
            lines = """
            UT    1  ANGRA 1       1 2 28  0 0  F               640.0     640.0
            UT   13  ANGRA 2       1 2 28  0 0  F              1350.0    1350.0
            UT   24  J.LACERDA-C   2 2 28  0 0  F               300.0     330.0
            """
            data = parse_entdados(IOBuffer(lines))
            @test length(data.thermal_plants) == 3
            @test data.thermal_plants[2].plant_name == "ANGRA 2"
            @test data.thermal_plants[3].subsystem == 2
        end

        @testset "UT Validation - Invalid Plant Number" begin
            # Plant number 1000 is out of valid range (1-999)
            # But since the field is only 3 characters (cols 5-7), we test with explicit overflow
            line = "UT  999  VALID         1 2 28  0 0  F               100.0     100.0"  # This should pass
            data = parse_entdados(IOBuffer(line))
            @test data.thermal_plants[1].plant_num == 999

            # Test actual invalid case: plant_num = 0
            line_invalid = "UT    0  INVALID       1 2 28  0 0  F               100.0     100.0"
            @test_throws Exception parse_entdados(IOBuffer(line_invalid))
        end

        @testset "UT Validation - Invalid Hour" begin
            line = "UT    1  ANGRA 1       1 2 28 24 0  F               640.0     640.0"
            @test_throws Exception parse_entdados(IOBuffer(line))
        end

        @testset "UT Validation - Negative Generation" begin
            line = "UT    1  ANGRA 1       1 2 28  0 0  F              -100.0     640.0"
            @test_throws Exception parse_entdados(IOBuffer(line))
        end

        @testset "UT with Zero Max Generation" begin
            # Real data can have zero max_generation for offline/unavailable units
            line = "UT    1  ANGRA 1       1 2 28  0 0  F                 0.0       0.0"
            data = parse_entdados(IOBuffer(line))
            @test length(data.thermal_plants) == 1
            ut = data.thermal_plants[1]
            @test ut.min_generation ≈ 0.0
            @test ut.max_generation ≈ 0.0
        end
    end

    # ========================================================================
    # DP Record Tests
    # ========================================================================

    @testset "DP Record Parsing" begin
        @testset "Basic DP Record" begin
            line = "DP   1  28  0 0  F        37143.53"
            data = parse_entdados(IOBuffer(line))
            @test length(data.demands) == 1
            dp = data.demands[1]
            @test dp.subsystem == 1
            @test dp.start_day == 28
            @test dp.start_hour == 0
            @test dp.start_half == 0
            @test dp.end_day == "F"
            @test dp.demand ≈ 37143.53
        end

        @testset "DP with Half Hour" begin
            line = "DP   1  28  0 1  F        36145.07"
            data = parse_entdados(IOBuffer(line))
            dp = data.demands[1]
            @test dp.start_half == 1
            @test dp.demand ≈ 36145.07
        end

        @testset "DP with Time Range" begin
            line = "DP   2  28  1 0  29 15 1   12345.67"
            data = parse_entdados(IOBuffer(line))
            dp = data.demands[1]
            @test dp.subsystem == 2
            @test dp.start_day == 28
            @test dp.start_hour == 1
            @test dp.end_day == 29
            @test dp.end_hour == 15
            @test dp.end_half == 1
        end

        @testset "Multiple DP Records" begin
            lines = """
            DP   1  28  0 0  F        37143.53
            DP   1  28  0 1  F        36145.07
            DP   1  28  1 0  F        35161.33
            DP   2  28  0 0  F        15234.21
            """
            data = parse_entdados(IOBuffer(lines))
            @test length(data.demands) == 4
            @test data.demands[1].subsystem == 1
            @test data.demands[4].subsystem == 2
        end

        @testset "DP Validation - Invalid Hour" begin
            line = "DP   1  28 24 0  F        37143.53"
            @test_throws Exception parse_entdados(IOBuffer(line))
        end

        @testset "DP Validation - Negative Demand" begin
            line = "DP   1  28  0 0  F          -100.0"
            @test_throws Exception parse_entdados(IOBuffer(line))
        end
    end

    # ========================================================================
    # DA Record Tests
    # ========================================================================

    @testset "DA Record Parsing" begin
        line = "DA    1 27      F              0.2"
        data = parse_entdados(IOBuffer(line))
        @test length(data.diversions) == 1
        da = data.diversions[1]
        @test da.plant_num == 1
        @test da.start_day == 27
        @test da.start_hour == 0
        @test da.start_half == 0
        @test da.end_day == "F"
        @test da.withdrawal_rate ≈ 0.2
    end

    # ========================================================================
    # MH Record Tests
    # ========================================================================

    @testset "MH Record Parsing" begin
        line = "MH   43  1  03 3 10 0  3 13 0 0"
        data = parse_entdados(IOBuffer(line))
        @test length(data.hydro_maintenance) == 1
        mh = data.hydro_maintenance[1]
        @test mh.plant_num == 43
        @test mh.group_code == 1
        @test mh.unit_code == 3
        @test mh.start_day == 3
        @test mh.start_hour == 10
        @test mh.end_day == 3
        @test mh.end_hour == 13
        @test mh.available_flag == 0
    end

    # ========================================================================
    # MT Record Tests
    # ========================================================================

    @testset "MT Record Parsing" begin
        line = "MT  052 001  28 00 0 29 00 0 0"
        data = parse_entdados(IOBuffer(line))
        @test length(data.thermal_maintenance) == 1
        mt = data.thermal_maintenance[1]
        @test mt.plant_num == 52
        @test mt.unit_code == 1
        @test mt.start_day == 28
        @test mt.start_hour == 0
        @test mt.end_day == 29
        @test mt.end_hour == 0
        @test mt.available_flag == 0
    end

    # ========================================================================
    # Integration Tests
    # ========================================================================

    @testset "Full File Parsing" begin
        @testset "Mixed Record Types" begin
            lines = """
            &
            & Comment line
            &
            TM  28    0   0      0.5     0     LEVE
            TM  28    1   0      0.5     0     LEVE
            &
            SIST    1 SE  0 SUDESTE   
            SIST    2 S   0 SUL
            &
            UH    1  CAMARGOS       10    82.82    1 I
            UH    2  ITUTINGA       10    94.95    1 I
            &
            UT    1  ANGRA 1       1 2 28  0 0  F               640.0     640.0
            UT   12  CUIABA        1 2 28  0 0  F                 0.0     490.0
            &
            DP   1  28  0 0  F        37143.53
            DP   1  28  0 1  F        36145.07
            """
            data = parse_entdados(IOBuffer(lines))
            @test length(data.time_periods) == 2
            @test length(data.subsystems) == 2
            @test length(data.hydro_plants) == 2
            @test length(data.thermal_plants) == 2
            @test length(data.demands) == 2
        end

        @testset "Empty File" begin
            data = parse_entdados(IOBuffer(""))
            @test length(data.time_periods) == 0
            @test length(data.subsystems) == 0
            @test length(data.hydro_plants) == 0
            @test length(data.thermal_plants) == 0
            @test length(data.demands) == 0
        end

        @testset "Only Comments" begin
            lines = """
            &
            & This is a comment
            &
            """
            data = parse_entdados(IOBuffer(lines))
            @test length(data.time_periods) == 0
        end

        @testset "Unknown Record Types Skipped" begin
            lines = """
            TM  28    0   0      0.5     0     LEVE
            RD  1    800  0 1
            RIVAR  999     4
            REE    1  1 SUDESTE
            SIST    1 SE  0 SUDESTE
            """
            # Should not throw, just warn and skip unknown types
            data = parse_entdados(IOBuffer(lines))
            @test length(data.time_periods) == 1
            @test length(data.subsystems) == 1
        end
    end

    # ========================================================================
    # Edge Cases
    # ========================================================================

    @testset "Edge Cases" begin
        @testset "Blank Lines Between Records" begin
            lines = """
            TM  28    0   0      0.5     0     LEVE
            
            
            TM  28    1   0      0.5     0     LEVE
            """
            data = parse_entdados(IOBuffer(lines))
            @test length(data.time_periods) == 2
        end

        @testset "Trailing Whitespace" begin
            line = "TM  28    0   0      0.5     0     LEVE   \n"
            data = parse_entdados(IOBuffer(line))
            @test data.time_periods[1].load_level == "LEVE"
        end

        @testset "Short Plant Names" begin
            line = "UH    1  CAM            10    82.82    1 I"
            data = parse_entdados(IOBuffer(line))
            @test data.hydro_plants[1].plant_name == "CAM"
        end

        @testset "Empty Load Level" begin
            line = "TM  28    0   0      0.5     0"
            data = parse_entdados(IOBuffer(line))
            @test data.time_periods[1].load_level == ""
        end
    end

    # ========================================================================
    # Real Sample Data Validation
    # ========================================================================

    @testset "Real Sample File Parsing" begin
        sample_path = "c:\\Users\\pedro\\programming\\DSc\\DESSEM2Julia\\docs\\Sample\\DS_CCEE_102025_SEMREDE_RV0D28\\entdados.dat"

        if isfile(sample_path)
            @testset "Parse Real ENTDADOS File" begin
                data = parse_entdados(sample_path)

                @testset "Real File Contains Expected Records" begin
                    @test length(data.time_periods) > 0
                    @test length(data.subsystems) > 0
                    @test length(data.hydro_plants) > 0
                    @test length(data.thermal_plants) > 0
                    @test length(data.demands) > 0
                    @test length(data.diversions) > 0
                    @test length(data.hydro_maintenance) > 0
                    @test length(data.thermal_maintenance) > 0
                end

                @testset "Real File TM Records Valid" begin
                    for tm in data.time_periods
                        @test 1 ≤ tm.day ≤ 31
                        @test 0 ≤ tm.hour ≤ 23
                        @test tm.half_hour ∈ [0, 1]
                        @test tm.duration > 0
                        @test tm.network_flag ∈ [0, 1, 2]
                    end
                end

                @testset "Real File SIST Records Valid" begin
                    @test length(data.subsystems) >= 4  # SE, S, NE, N at minimum
                    for sist in data.subsystems
                        @test 1 ≤ sist.subsystem_num ≤ 99
                        @test length(sist.subsystem_code) > 0
                    end
                end

                @testset "Real File UH Records Valid" begin
                    @test length(data.hydro_plants) > 50  # Brazil has many hydro plants
                    for uh in data.hydro_plants
                        @test 1 ≤ uh.plant_num ≤ 320
                        @test 0.0 ≤ uh.initial_volume_pct ≤ 100.0
                        @test length(uh.plant_name) > 0
                    end
                end

                @testset "Real File UT Records Valid" begin
                    @test length(data.thermal_plants) > 10
                    for ut in data.thermal_plants
                        @test 1 ≤ ut.plant_num ≤ 999
                        @test ut.min_generation >= 0.0
                        @test ut.max_generation >= ut.min_generation
                        @test length(ut.plant_name) > 0
                    end
                end

                @testset "Real File DP Records Valid" begin
                    @test length(data.demands) > 50  # Multiple subsystems, multiple periods
                    for dp in data.demands
                        @test dp.demand >= 0.0
                        @test 0 ≤ dp.start_hour ≤ 23
                        @test dp.start_half ∈ [0, 1]
                    end
                end

                println("\n✅ Real ENTDADOS file statistics:")
                println("   - Time periods: $(length(data.time_periods))")
                println("   - Subsystems: $(length(data.subsystems))")
                println("   - Hydro plants: $(length(data.hydro_plants))")
                println("   - Thermal plants: $(length(data.thermal_plants))")
                println("   - Demand records: $(length(data.demands))")
            end
        else
            @test_skip "Real sample file not found at $sample_path"
        end
    end
end

println("\n✅ All ENTDADOS parser tests completed!")
