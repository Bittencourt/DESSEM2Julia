using Test
using DESSEM2Julia

@testset "HIDR.DAT Parser Tests" begin
    
    @testset "Text format parsing with test data" begin
        # Create a temporary test file with text format
        test_file = joinpath(tempdir(), "test_hidr.dat")
        
        # Write test data in text format with exact column positions
        open(test_file, "w") do f
            # CADUSIH record - columns must match spec
            # Format: record(1-7) plant_num(9-11) plant_name(13-24) subsystem(26-27) year(29-32) month(34-35) day(37-38)
            #         downstream(40-41) diversion(43-44) type(46) min_vol(48-57) max_vol(59-68) max_flow(70-79) capacity(81-90) prod(92-101)
            println(f, "CADUSIH   1CAMARGOS     1 2020  1  1  2  0  1    5000.0   10000.0    1000.0     500.0      100.5")
            # USITVIAG record
            println(f, "USITVIAG  1  2   5.0")
            # POLCOT record - columns: record(1-6) plant(8-10) degree(12-13) coef0(15-24) coef1(26-35) coef2(37-46) coef3(48-57) coef4(59-68) coef5(70-79)
            println(f, "POLCOT  1  3     100.0     200.0     300.0     400.0     500.0     600.0")
            # POLARE record
            println(f, "POLARE  1  2      50.0     150.0     250.0     350.0     450.0     550.0")
            # POLJUS record
            println(f, "POLJUS  1  2      10.0     110.0     210.0     310.0     410.0     510.0")
            # COEFEVA record - columns: record(1-7) plant(9-11) jan(13-17) feb(19-23) mar(25-29)... dec(79-83)
            println(f, "COEFEVA   1  0.1  0.2  0.3  0.4  0.5  0.6  0.7  0.8  0.9  1.0  1.1  1.2")
            # CADCONJ record - columns: record(1-7) plant(9-11) set(13-14) num_units(16-17) capacity(19-28) min_gen(30-39) max_flow(41-50)
            println(f, "CADCONJ   1  1  2     100.0      50.0     200.0")
        end
        
        try
            @testset "Parse test file" begin
                # Parse the file
                data = parse_hidr(test_file)
                
                # Basic structure tests
                @test data isa HidrData
                @test data.plants isa Vector{CADUSIH}
                @test data.travel_times isa Vector{USITVIAG}
                @test data.volume_elevation isa Vector{POLCOT}
                @test data.volume_area isa Vector{POLARE}
                @test data.tailrace isa Vector{POLJUS}
                @test data.evaporation isa Vector{COEFEVA}
                @test data.unit_sets isa Vector{CADCONJ}
                
                # Check counts
                @test length(data.plants) == 1
                @test length(data.travel_times) == 1
                @test length(data.volume_elevation) == 1
                @test length(data.volume_area) == 1
                @test length(data.tailrace) == 1
                @test length(data.evaporation) == 1
                @test length(data.unit_sets) == 1
                
                println("  ✅ Text format parser working correctly!")
            end
            
            @testset "CADUSIH validation" begin
                data = parse_hidr(test_file)
                plant = data.plants[1]
                
                @test plant.plant_num == 1
                @test strip(plant.plant_name) == "CAMARGOS"
                @test plant.subsystem == 1
                @test plant.commission_year == 2020
                @test plant.commission_month == 1
                @test plant.commission_day == 1
                @test plant.min_volume == 5000.0
                @test plant.max_volume == 10000.0
                
                println("  Sample plant: $(plant.plant_num) $(plant.plant_name)")
            end
            
            @testset "USITVIAG validation" begin
                data = parse_hidr(test_file)
                tt = data.travel_times[1]
                
                @test tt.plant_num == 1
                @test tt.downstream_plant == 2
                @test tt.travel_time == 5.0
                
                println("  Travel time: Plant $(tt.plant_num) → $(tt.downstream_plant): $(tt.travel_time) hours")
            end
            
            @testset "POLCOT validation" begin
                data = parse_hidr(test_file)
                pol = data.volume_elevation[1]
                
                @test pol.plant_num == 1
                @test pol.degree == 3
                @test pol.coef0 == 100.0
                @test pol.coef1 == 200.0
                
                println("  POLCOT: Plant $(pol.plant_num), degree $(pol.degree)")
            end
            
            @testset "COEFEVA validation" begin
                data = parse_hidr(test_file)
                eva = data.evaporation[1]
                
                @test eva.plant_num == 1
                @test eva.jan == 0.1
                @test eva.dec == 1.2
                
                println("  COEFEVA: Plant $(eva.plant_num), Jan=$(eva.jan), Dec=$(eva.dec)")
            end
            
        finally
            # Clean up test file
            rm(test_file, force=true)
        end
    end
    
    @testset "Binary format detection" begin
        # Test with ONS sample (binary format)
        sample_file = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11", "hidr.dat")
        
        if isfile(sample_file)
            @testset "Parse ONS binary HIDR.DAT" begin
                # Parse the binary file
                data = parse_hidr(sample_file)
                
                # Should detect binary format and parse successfully
                @test data isa HidrData
                @test length(data.plants) > 0
                
                # Binary format only has plant records
                @test length(data.travel_times) == 0
                @test length(data.volume_elevation) == 0
                
                println("  ✅ Binary parser: $(length(data.plants)) plants parsed")
                
                # Check first valid plant
                valid_plants = filter(p -> p.plant_num > 0, data.plants)
                if !isempty(valid_plants)
                    p = valid_plants[1]
                    @test p.plant_num > 0
                    @test !isempty(strip(p.plant_name))
                    @test p.subsystem > 0
                    println("  First plant: $(p.plant_name) (num: $(p.plant_num))")
                end
            end
            
            println("  ℹ Note: Binary format (792 bytes/record) parsed successfully")
            println("  ℹ Text parser also available for text-format HIDR.DAT files")
        else
            @test_skip "ONS sample file not found"
        end
    end
    
    @testset "Error handling" begin
        # Test with non-existent file
        @test_throws Exception parse_hidr("nonexistent_hidr.dat")
    end
    
end

