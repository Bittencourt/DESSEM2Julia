using Test
using DESSEM2Julia

@testset "SIMUL Parser Tests" begin
    @testset "SimulHeader Parsing" begin
        # Test basic header parsing
        # Format: Fixed-width per specification
        # Col 5-6 (day), 8-9 (hour), 11 (half), 14-15 (month), 17-20 (year), 22 (flag)
        line = "    15  8 0  10 2024 1"
        header = DESSEM2Julia.SimulParser.parse_simul_header(line, "test.dat", 3)
        
        @test header.start_day == 15
        @test header.start_hour == 8
        @test header.start_half_hour == 0
        @test header.start_month == 10
        @test header.start_year == 2024
        @test header.operuh_flag == 1
        
        # Test header with defaults (no hour, no half-hour, no flag)
        # Properly formatted fixed-width with spaces in empty fields
        line = "    20      12 2025  "
        header = DESSEM2Julia.SimulParser.parse_simul_header(line, "test.dat", 3)
        
        @test header.start_day == 20
        @test header.start_hour == 0  # default
        @test header.start_half_hour == 0  # default
        @test header.start_month == 12
        @test header.start_year == 2025
        @test header.operuh_flag === nothing  # no flag provided
    end
    
    @testset "DiscRecord Parsing" begin
        # Test complete DISC record
        line = "    15  9 1    2.5 1"
        record = DESSEM2Julia.SimulParser.parse_disc_record(line, "test.dat", 10)
        
        @test record.day == 15
        @test record.hour == 9
        @test record.half_hour == 1
        @test record.duration == 2.5
        @test record.constraints_flag == 1
        
        # Test DISC record with defaults
        line = "    20       0.5  "
        record = DESSEM2Julia.SimulParser.parse_disc_record(line, "test.dat", 11)
        
        @test record.day == 20
        @test record.hour == 0  # default
        @test record.half_hour == 0  # default
        @test record.duration == 0.5
        @test record.constraints_flag === nothing
    end
    
    @testset "VoliRecord Parsing" begin
        # Test complete VOLI record
        line = "     66 FURNAS           85.5"
        record = DESSEM2Julia.SimulParser.parse_voli_record(line, "test.dat", 20)
        
        @test record.plant_number == 66
        @test record.plant_name == "FURNAS"
        @test record.initial_volume_percent == 85.5
        
        # Test with trailing spaces
        line = "    169 ITAIPU                100.0"
        record = DESSEM2Julia.SimulParser.parse_voli_record(line, "test.dat", 21)
        
        @test record.plant_number == 169
        @test record.plant_name == "ITAIPU"
        @test record.initial_volume_percent == 100.0
    end
    
    @testset "OperRecord Parsing" begin
        # Test complete OPER record with all fields
        line = "     66H FURNAS      20  8 0 21  8 0 1   1250.50 1      15.0     500.0"
        record = DESSEM2Julia.SimulParser.parse_oper_record(line, "test.dat", 30)
        
        @test record.plant_number == 66
        @test record.plant_type == "H"
        @test record.plant_name == "FURNAS"
        @test record.initial_day == 20
        @test record.initial_hour == 8
        @test record.initial_half_hour == 0
        @test record.final_day == 21
        @test record.final_hour == 8
        @test record.final_half_hour == 0
        @test record.flow_type == 1
        @test record.natural_inflow == 1250.50
        @test record.withdrawal_type == 1
        @test record.withdrawal_flow == 15.0
        @test record.generation_target == 500.0
        
        # Test with defaults (no plant type, no withdrawal, no target)
        line = "    169  ITAIPU      20     21     2   2500.00       0.0         "
        record = DESSEM2Julia.SimulParser.parse_oper_record(line, "test.dat", 31)
        
        @test record.plant_number == 169
        @test record.plant_type == "H"  # default
        @test record.plant_name == "ITAIPU"
        @test record.initial_day == 20
        @test record.initial_hour == 0  # default
        @test record.initial_half_hour == 0  # default
        @test record.final_day == 21
        @test record.final_hour == 0  # default
        @test record.final_half_hour == 0  # default
        @test record.flow_type == 2
        @test record.natural_inflow == 2500.0
        @test record.withdrawal_type === nothing
        @test record.withdrawal_flow == 0.0  # default
        @test record.generation_target === nothing
    end
    
    @testset "Complete SIMUL File Parsing" begin
        # Create a minimal valid SIMUL file
        simul_content = """
        SIMUL TEST FILE
        USER HEADER LINE
            20  9 0  10 2024 1
        DISC
            20  9 0  0.5 1
            20  9 1  0.5 0
            20 10 0  1.0 1
        FIM
        VOLI
             66 FURNAS           85.5
            169 ITAIPU          100.0
        FIM
        OPER
             66H FURNAS      20  9 0 21  9 0 1   1250.50 1      15.0     500.0
            169  ITAIPU      20  9 0 21  9 0 2   2500.00       0.0         
        FIM
        """
        
        # Write to temporary file
        temp_file = tempname() * ".xxx"
        write(temp_file, simul_content)
        
        try
            # Parse the file
            result = parse_simul(temp_file)
            
            # Check header
            @test result.header.start_day == 20
            @test result.header.start_month == 10
            @test result.header.start_year == 2024
            @test result.header.operuh_flag == 1
            
            # Check DISC records
            @test length(result.disc_records) == 3
            @test result.disc_records[1].day == 20
            @test result.disc_records[1].hour == 9
            @test result.disc_records[1].half_hour == 0
            @test result.disc_records[1].duration == 0.5
            @test result.disc_records[2].half_hour == 1
            @test result.disc_records[3].hour == 10
            
            # Check VOLI records
            @test length(result.voli_records) == 2
            @test result.voli_records[1].plant_number == 66
            @test result.voli_records[1].plant_name == "FURNAS"
            @test result.voli_records[1].initial_volume_percent == 85.5
            @test result.voli_records[2].plant_number == 169
            @test result.voli_records[2].initial_volume_percent == 100.0
            
            # Check OPER records
            @test length(result.oper_records) == 2
            @test result.oper_records[1].plant_number == 66
            @test result.oper_records[1].plant_type == "H"
            @test result.oper_records[1].natural_inflow == 1250.50
            @test result.oper_records[1].withdrawal_flow == 15.0
            @test result.oper_records[1].generation_target == 500.0
            @test result.oper_records[2].plant_number == 169
            @test result.oper_records[2].flow_type == 2
            @test result.oper_records[2].withdrawal_type === nothing
            
        finally
            rm(temp_file, force=true)
        end
    end
    
    @testset "SIMUL File with Comments and Blank Lines" begin
        simul_content = """
        & SIMUL TEST FILE WITH COMMENTS
        USER HEADER LINE
            20  9 0  10 2024 1
        DISC
        & This is a comment
            20  9 0  0.5 1
        
            20  9 1  0.5 0
        & Another comment
        FIM
        VOLI
             66 FURNAS           85.5
        & Volume comment
        FIM
        OPER
        & Operation comment
             66H FURNAS      20  9 0 21  9 0 1   1250.50 1      15.0     500.0
        FIM
        """
        
        temp_file = tempname() * ".xxx"
        write(temp_file, simul_content)
        
        try
            result = parse_simul(temp_file)
            
            # Should skip comments and blank lines
            @test length(result.disc_records) == 2
            @test length(result.voli_records) == 1
            @test length(result.oper_records) == 1
            
        finally
            rm(temp_file, force=true)
        end
    end
    
    @testset "Empty Blocks" begin
        # Test with empty VOLI and OPER blocks
        simul_content = """
        SIMUL TEST
        HEADER
            20  9 0  10 2024 1
        DISC
            20  9 0  1.0 1
        FIM
        VOLI
        FIM
        OPER
        FIM
        """
        
        temp_file = tempname() * ".xxx"
        write(temp_file, simul_content)
        
        try
            result = parse_simul(temp_file)
            
            @test length(result.disc_records) == 1
            @test length(result.voli_records) == 0  # Empty block
            @test length(result.oper_records) == 0  # Empty block
            
        finally
            rm(temp_file, force=true)
        end
    end
    
    @testset "Type System Constraints" begin
        # Test that struct construction validates types
        header = SimulHeader(
            start_day=15,
            start_month=10,
            start_year=2024
        )
        @test header.start_day == 15
        @test header.start_hour == 0  # default
        @test header.operuh_flag === nothing  # default
        
        disc = DiscRecord(
            day=20,
            duration=2.5
        )
        @test disc.day == 20
        @test disc.duration == 2.5
        @test disc.constraints_flag === nothing
        
        voli = VoliRecord(
            plant_number=66,
            plant_name="FURNAS",
            initial_volume_percent=85.5
        )
        @test voli.plant_number == 66
        
        oper = OperRecord(
            plant_number=66,
            plant_name="FURNAS",
            initial_day=20,
            final_day=21,
            flow_type=1,
            natural_inflow=1250.5
        )
        @test oper.plant_number == 66
        @test oper.plant_type == "H"  # default
    end
end
