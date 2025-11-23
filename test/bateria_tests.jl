using Test
using DESSEM2Julia

@testset "BATERIA Parser Tests" begin
    @testset "Single Record Parsing - All Fields" begin
        # Test with all optional fields populated
        # Format: 1-3=num, 5-16=name, 20-21=subsystem, 25-34=charge, 40-49=discharge, 55-64=energy, 70-79=init, 85-94=chg_eff, 100-109=dsch_eff
        line = "  1 BATERIA-1       1      100.000        100.000        500.000          0.000           0.90           0.90"
        record = DESSEM2Julia.BateriaParser.parse_bateria_record(line, "test.dat", 1)
        
        @test record.battery_num == 1
        @test record.battery_name == "BATERIA-1"
        @test record.subsystem_num == 1
        @test record.charging_capacity == 100.0
        @test record.discharging_capacity == 100.0
        @test record.energy_capacity == 500.0
        @test record.initial_energy == 0.0
        @test record.charging_efficiency == 0.90
        @test record.discharging_efficiency == 0.90
    end
    
    @testset "Single Record Parsing - Required Fields Only" begin
        # Test with only required fields (optional fields empty)
        line = "  2 BATERIA-2       2      150.000        150.000        750.000"
        record = DESSEM2Julia.BateriaParser.parse_bateria_record(line, "test.dat", 2)
        
        @test record.battery_num == 2
        @test record.battery_name == "BATERIA-2"
        @test record.subsystem_num == 2
        @test record.charging_capacity == 150.0
        @test record.discharging_capacity == 150.0
        @test record.energy_capacity == 750.0
        @test record.initial_energy === nothing
        @test record.charging_efficiency === nothing
        @test record.discharging_efficiency === nothing
    end
    
    @testset "Single Record Parsing - Partial Optional Fields" begin
        # Test with some optional fields
        line = "  3 BATERIA-3       1       50.000         60.000        300.000        100.000           0.95"
        record = DESSEM2Julia.BateriaParser.parse_bateria_record(line, "test.dat", 3)
        
        @test record.battery_num == 3
        @test record.battery_name == "BATERIA-3"
        @test record.subsystem_num == 1
        @test record.charging_capacity == 50.0
        @test record.discharging_capacity == 60.0
        @test record.energy_capacity == 300.0
        @test record.initial_energy == 100.0
        @test record.charging_efficiency == 0.95
        @test record.discharging_efficiency === nothing
    end
    
    @testset "Different Battery Names" begin
        # Test various name formats
        line1 = " 10 BAT-ALPHA      3        200.0          200.0         1000.0"
        record1 = DESSEM2Julia.BateriaParser.parse_bateria_record(line1, "test.dat", 1)
        @test record1.battery_name == "BAT-ALPHA"
        
        line2 = " 25 ESS 01         1         80.0           80.0          400.0"
        record2 = DESSEM2Julia.BateriaParser.parse_bateria_record(line2, "test.dat", 2)
        @test record2.battery_name == "ESS 01"
        
        line3 = "100 BESS-SITE-A    2        120.0          120.0          600.0"
        record3 = DESSEM2Julia.BateriaParser.parse_bateria_record(line3, "test.dat", 3)
        @test record3.battery_name == "BESS-SITE-A"
    end
    
    @testset "Asymmetric Charging/Discharging" begin
        # Test battery with different charge/discharge rates
        line = " 15 ASYM-BATT      1      100.000        150.000        500.000        250.000           0.92           0.88"
        record = DESSEM2Julia.BateriaParser.parse_bateria_record(line, "test.dat", 1)
        
        @test record.charging_capacity == 100.0
        @test record.discharging_capacity == 150.0
        @test record.charging_efficiency == 0.92
        @test record.discharging_efficiency == 0.88
    end
    
    @testset "Full File Parsing" begin
        # Test parsing a complete file with multiple records
        content = """
BATERIA
&& Battery Storage Systems
&Num Nome          Sub  ChargeMW  DischMW   EnergyMWh  InitMWh   ChgEff    DschEff
  1 BATERIA-1       1        100.0          100.0          500.0            0.0            0.9            0.9
  2 BATERIA-2       2        150.0          150.0          750.0          375.0           0.92           0.88
  3 BAT-SITE-A      1         50.0           60.0          300.0
 10 ESS-01          3        200.0          200.0         1000.0          500.0           0.95           0.95
FIM
"""
        path = tempname() * "_bateria.dat"
        open(path, "w") do io
            write(io, content)
        end
        
        try
            data = parse_bateria(path)
            
            @test length(data.records) == 4
            
            # Check first record
            @test data.records[1].battery_num == 1
            @test data.records[1].battery_name == "BATERIA-1"
            @test data.records[1].initial_energy == 0.0
            
            # Check second record
            @test data.records[2].battery_num == 2
            @test data.records[2].initial_energy == 375.0
            @test data.records[2].charging_efficiency == 0.92
            @test data.records[2].discharging_efficiency == 0.88
            
            # Check third record (no optional fields)
            @test data.records[3].battery_num == 3
            @test data.records[3].battery_name == "BAT-SITE-A"
            @test data.records[3].initial_energy === nothing
            @test data.records[3].charging_efficiency === nothing
            
            # Check fourth record
            @test data.records[4].battery_num == 10
            @test data.records[4].subsystem_num == 3
            @test data.records[4].energy_capacity == 1000.0
        finally
            rm(path, force=true)
        end
    end
    
    @testset "File with Comments and Blank Lines" begin
        content = """
& BATERIA.XXX - Battery Storage Data
&& Comments and blank lines should be skipped

  1 BATERIA-1       1        100.0          100.0          500.0            0.0            0.9            0.9

& Another comment
  2 BATERIA-2       2        150.0          150.0          750.0          375.0           0.92           0.88

FIM
"""
        path = tempname() * "_bateria_comments.dat"
        open(path, "w") do io
            write(io, content)
        end
        
        try
            data = parse_bateria(path)
            @test length(data.records) == 2
        finally
            rm(path, force=true)
        end
    end
    
    @testset "Empty File" begin
        content = """
& Empty battery file
FIM
"""
        path = tempname() * "_bateria_empty.dat"
        open(path, "w") do io
            write(io, content)
        end
        
        try
            data = parse_bateria(path)
            @test length(data.records) == 0
        finally
            rm(path, force=true)
        end
    end
    
    @testset "High Battery Numbers" begin
        # Test with high battery numbers (up to 999)
        line = "999 HIGH-NUM        1        100.0          100.0          500.0"
        record = DESSEM2Julia.BateriaParser.parse_bateria_record(line, "test.dat", 1)
        @test record.battery_num == 999
    end
    
    @testset "Efficiency Values" begin
        # Test various efficiency values (0-1 range)
        line1 = "  1 BAT-LOW-EFF    1      100.000        100.000        500.000          0.000           0.70           0.65"
        record1 = DESSEM2Julia.BateriaParser.parse_bateria_record(line1, "test.dat", 1)
        @test record1.charging_efficiency == 0.70
        @test record1.discharging_efficiency == 0.65
        
        line2 = "  2 BAT-HIGH-EFF   1      100.000        100.000        500.000          0.000           0.98           0.97"
        record2 = DESSEM2Julia.BateriaParser.parse_bateria_record(line2, "test.dat", 2)
        @test record2.charging_efficiency == 0.98
        @test record2.discharging_efficiency == 0.97
    end
    
    @testset "Large Capacity Values" begin
        # Test with large MW and MWh values
        line = " 50 MEGA-BATT       1       5000.0         5000.0        25000.0        12500.0            0.9            0.9"
        record = DESSEM2Julia.BateriaParser.parse_bateria_record(line, "test.dat", 1)
        @test record.charging_capacity == 5000.0
        @test record.discharging_capacity == 5000.0
        @test record.energy_capacity == 25000.0
        @test record.initial_energy == 12500.0
    end
    
    @testset "9999 End Marker" begin
        # Test file ending with 9999 instead of FIM
        content = """
  1 BATERIA-1       1        100.0          100.0          500.0
9999
"""
        path = tempname() * "_bateria_9999.dat"
        open(path, "w") do io
            write(io, content)
        end
        
        try
            data = parse_bateria(path)
            @test length(data.records) == 1
        finally
            rm(path, force=true)
        end
    end
end
