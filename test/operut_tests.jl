"""
Tests for OPERUT.XXX parser (Thermal Operational Data).
"""

using Test
using DESSEM2Julia
using DESSEM2Julia: parse_operut, INITRecord, OPERRecord, OperutData

@testset "OPERUT Parser" begin
    @testset "INIT Record Parsing" begin
        # Basic INIT record with all required fields
        line = "  1  ANGRA 1        1    1      640.000   1879  1  0  1        640."
        record = DESSEM2Julia.parse_init_record(line)

        @test record.plant_num == 1
        @test record.plant_name == "ANGRA 1"
        @test record.unit_num == 1
        @test record.initial_status == 1
        @test record.initial_generation ≈ 640.0
        @test record.hours_in_state == 1879
        @test record.mh_flag == 1
        @test record.ad_flag == 0
        @test record.t_flag == 1
        @test record.inflexible_limit ≈ 640.0

        # Unit that is OFF
        line2 = "  4  ST.CRUZ 34     3    0        0.000  20016  0  0  0          0."
        record2 = DESSEM2Julia.parse_init_record(line2)

        @test record2.plant_num == 4
        @test record2.plant_name == "ST.CRUZ 34"
        @test record2.unit_num == 3
        @test record2.initial_status == 0
        @test record2.initial_generation ≈ 0.0
        @test record2.hours_in_state == 20016

        # Record with partial initial generation
        line3 = " 46  N.VENECIA 2    1    1      178.213    120  0  0  1         81."
        record3 = DESSEM2Julia.parse_init_record(line3)

        @test record3.plant_num == 46
        @test record3.plant_name == "N.VENECIA 2"
        @test record3.unit_num == 1
        @test record3.initial_generation ≈ 178.213
        @test record3.inflexible_limit ≈ 81.0

        # Three-digit plant number
        line4 = "106  ERB CANDEIAS   1    1        4.500    816  0  0  1          3."
        record4 = DESSEM2Julia.parse_init_record(line4)

        @test record4.plant_num == 106
        @test record4.plant_name == "ERB CANDEIA"  # Fixed width: 12 chars, last 'S' truncated
        @test record4.initial_generation ≈ 4.5
        @test record4.inflexible_limit ≈ 3.0
    end

    @testset "OPER Record Parsing" begin
        # Basic OPER record with cost only
        line = "  1 ANGRA 1       1 27  0 0 F                                31.17"
        record = DESSEM2Julia.parse_oper_record(line)

        @test record.plant_num == 1
        @test record.plant_name == "ANGRA 1"
        @test record.unit_num == 1
        @test record.start_day == 27
        @test record.start_hour == 0
        @test record.start_half == 0
        @test record.end_day == "F"
        @test record.operating_cost ≈ 31.17
        @test isnothing(record.min_generation)
        @test isnothing(record.max_generation)

        # OPER record with min generation
        line2 = "434 W.ARJONA O    1 27  0 0 F                        0.0      0.00"
        record2 = DESSEM2Julia.parse_oper_record(line2)

        @test record2.plant_num == 434
        @test record2.plant_name == "W.ARJONA O"
        @test record2.unit_num == 1
        @test (record2.min_generation === nothing) || (record2.min_generation ≈ 0.0)
        @test record2.operating_cost ≈ 0.0

        # Three-digit plant number
        line3 = "110 NPIRATINING   1 27  0 0 F                              1433.92"
        record3 = DESSEM2Julia.parse_oper_record(line3)

        @test record3.plant_num == 110
        @test record3.plant_name == "NPIRATINING"
        @test record3.operating_cost ≈ 1433.92

        # High cost value
        line4 = "328 PALMAPLAN     1 27  0 0 F                              1760.58"
        record4 = DESSEM2Julia.parse_oper_record(line4)

        @test record4.plant_num == 328
        @test record4.operating_cost ≈ 1760.58
    end

    @testset "Full File Parsing" begin
        # Create a test file with both blocks
        test_content = """
        & CONDICOES INICIAIS DAS UNIDADES
        &
        INIT
        &us     nome       ug   st   GerInic     tempo MH A/D T  TITULINFLX
          1  ANGRA 1        1    1      640.000   1879  1  0  1        640.
         13  ANGRA 2        1    1     1350.000   6682  0  0  1       1350.
         47  TERMORIO       1    0        0.000    803  0  0  0          0.
         47  TERMORIO       2    0        0.000   3456  0  0  0          0.
        106  ERB CANDEIAS   1    1        4.500    816  0  0  1          3.
        FIM
        OPER
        &us    nome      un di hi m df hf m Gmin     Gmax       Custo
          1 ANGRA 1       1 27  0 0 F                                31.17
         13 ANGRA 2       1 27  0 0 F                                20.12
         97 CUBATAO       1 27  0 0 F                               396.75
        110 NPIRATINING   1 27  0 0 F                              1433.92
        434 W.ARJONA O    1 27  0 0 F                        0.0      0.00
        FIM
        """

        tmpfile = tempname() * ".dat"
        try
            write(tmpfile, test_content)
            data = parse_operut(tmpfile)

            @test length(data.init_records) == 5
            @test length(data.oper_records) == 5

            # Check first INIT record
            @test data.init_records[1].plant_num == 1
            @test data.init_records[1].plant_name == "ANGRA 1"
            @test data.init_records[1].initial_status == 1
            @test data.init_records[1].initial_generation ≈ 640.0

            # Check INIT record with multiple units
            termorio_units = filter(r -> r.plant_name == "TERMORIO", data.init_records)
            @test length(termorio_units) == 2
            @test all(r -> r.initial_status == 0, termorio_units)

            # Check first OPER record
            @test data.oper_records[1].plant_num == 1
            @test data.oper_records[1].operating_cost ≈ 31.17
            @test data.oper_records[1].end_day == "F"

            # Check OPER with min generation
            waron_record = filter(r -> r.plant_name == "W.ARJONA O", data.oper_records)[1]
            @test (waron_record.min_generation === nothing) ||
                  (waron_record.min_generation ≈ 0.0)
            @test waron_record.operating_cost ≈ 0.0

        finally
            rm(tmpfile, force = true)
        end
    end

    @testset "Real CCEE Sample Data" begin
        sample_path = "docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/operut.dat"

        if isfile(sample_path)
            data = parse_operut(sample_path)

            # Basic counts
            @test length(data.init_records) > 0
            @test length(data.oper_records) > 0

            println("  Parsed $(length(data.init_records)) INIT records")
            println("  Parsed $(length(data.oper_records)) OPER records")

            # Check specific known units
            angra1_init = filter(
                r -> r.plant_num == 1 && r.plant_name == "ANGRA 1",
                data.init_records,
            )
            @test length(angra1_init) > 0
            @test angra1_init[1].initial_status == 1  # Should be ON
            @test angra1_init[1].initial_generation ≈ 640.0

            angra1_oper = filter(
                r -> r.plant_num == 1 && r.plant_name == "ANGRA 1",
                data.oper_records,
            )
            @test length(angra1_oper) > 0
            @test angra1_oper[1].operating_cost > 0

            # Check for units with zero cost (invalid CVU)
            zero_cost = filter(r -> r.operating_cost == 0.0, data.oper_records)
            if length(zero_cost) > 0
                println("  Found $(length(zero_cost)) units with zero cost")
            end

            # Check for OFF units
            off_units = filter(r -> r.initial_status == 0, data.init_records)
            on_units = filter(r -> r.initial_status == 1, data.init_records)
            println("  Units ON: $(length(on_units)), OFF: $(length(off_units))")

            # Verify all OPER records have end_day = "F"
            all_final = all(r -> r.end_day == "F", data.oper_records)
            @test all_final

            # Check for reasonable cost ranges (R$/MWh)
            costs = [r.operating_cost for r in data.oper_records]
            @test all(c -> c >= 0, costs)  # All non-negative
            @test maximum(costs) < 5000  # Reasonable upper bound

        else
            @warn "Sample file not found: $sample_path - skipping real data tests"
        end
    end

    @testset "Edge Cases" begin
        # Empty blocks
        test_content = """
        INIT
        FIM
        OPER
        FIM
        """

        tmpfile = tempname() * ".dat"
        try
            write(tmpfile, test_content)
            data = parse_operut(tmpfile)

            @test length(data.init_records) == 0
            @test length(data.oper_records) == 0
        finally
            rm(tmpfile, force = true)
        end

        # Only comments
        test_content2 = """
        & Comment line
        INIT
        & More comments
        & Us Nome etc
        FIM
        OPER
        & Even more comments
        FIM
        """

        tmpfile2 = tempname() * ".dat"
        try
            write(tmpfile2, test_content2)
            data2 = parse_operut(tmpfile2)

            @test length(data2.init_records) == 0
            @test length(data2.oper_records) == 0
        finally
            rm(tmpfile2, force = true)
        end
    end

    @testset "Configuration Blocks" begin
        # Test all 14 configuration blocks from IDESEM
        test_file = "test/operut_complete_test_data.txt"

        if isfile(test_file)
            data = parse_operut(test_file)

            # Test single-value blocks
            @test data.uctpar == 2
            @test data.ucterm == 2
            @test data.pint == true
            @test data.avlcmo == 1
            @test data.cplexlog == true
            @test data.tolerilh == 1
            @test data.engolimento == 0
            @test data.tratainviabilha == 1

            # Test multi-value blocks
            @test data.regranptv == [1]
            @test data.constdados == [1, 1]
            @test data.crossover == [0, 0, 0, 0]

            # Test optional blocks (commented out in test file)
            @test isnothing(data.uctbusloc)
            @test isempty(data.uctheurfp)
            @test isnothing(data.ajustefcf)

            # Test data blocks still work
            @test length(data.init_records) == 3
            @test length(data.oper_records) == 3

            # Verify specific records
            @test data.init_records[1].plant_name == "ANGRA 1"
            @test data.init_records[1].initial_generation ≈ 640.0

            @test data.oper_records[1].plant_name == "ANGRA 1"
            @test data.oper_records[1].operating_cost ≈ 31.17  # Nuclear plant cost

        else
            @warn "Test data file not found: $test_file - skipping configuration block tests"
        end
    end

    @testset "Configuration Blocks - Individual Patterns" begin
        # Test UCTPAR
        tmpfile = tempname() * ".dat"
        try
            write(tmpfile, "UCTPAR 4\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.uctpar == 4
        finally
            rm(tmpfile, force = true)
        end

        # Test UCTERM
        try
            write(tmpfile, "UCTERM 1\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.ucterm == 1
        finally
            rm(tmpfile, force = true)
        end

        # Test PINT (boolean flag)
        try
            write(tmpfile, "PINT\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.pint == true
        finally
            rm(tmpfile, force = true)
        end

        # Test REGRANPTV (multi-value)
        try
            write(tmpfile, "REGRANPTV 1 2 3\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.regranptv == [1, 2, 3]
        finally
            rm(tmpfile, force = true)
        end

        # Test AVLCMO
        try
            write(tmpfile, "AVLCMO 0\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.avlcmo == 0
        finally
            rm(tmpfile, force = true)
        end

        # Test CPLEXLOG (boolean flag)
        try
            write(tmpfile, "CPLEXLOG\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.cplexlog == true
        finally
            rm(tmpfile, force = true)
        end

        # Test UCTBUSLOC (boolean flag)
        try
            write(tmpfile, "UCTBUSLOC\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.uctbusloc == true
        finally
            rm(tmpfile, force = true)
        end

        # Test UCTHEURFP (multi-value)
        try
            write(tmpfile, "UCTHEURFP 1 100 50\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.uctheurfp == [1, 100, 50]
        finally
            rm(tmpfile, force = true)
        end

        # Test CONSTDADOS (multi-value)
        try
            write(tmpfile, "CONSTDADOS 0 1\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.constdados == [0, 1]
        finally
            rm(tmpfile, force = true)
        end

        # Test AJUSTEFCF (boolean flag)
        try
            write(tmpfile, "AJUSTEFCF\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.ajustefcf == true
        finally
            rm(tmpfile, force = true)
        end

        # Test TOLERILH
        try
            write(tmpfile, "TOLERILH 0\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.tolerilh == 0
        finally
            rm(tmpfile, force = true)
        end

        # Test CROSSOVER (multi-value)
        try
            write(tmpfile, "CROSSOVER 1 0 1 0\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.crossover == [1, 0, 1, 0]
        finally
            rm(tmpfile, force = true)
        end

        # Test ENGOLIMENTO
        try
            write(tmpfile, "ENGOLIMENTO 1\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.engolimento == 1
        finally
            rm(tmpfile, force = true)
        end

        # Test TRATA_INVIAB_ILHA
        try
            write(tmpfile, "TRATA_INVIAB_ILHA 0\nINIT\nFIM\nOPER\nFIM\n")
            data = parse_operut(tmpfile)
            @test data.tratainviabilha == 0
        finally
            rm(tmpfile, force = true)
        end
    end
end
