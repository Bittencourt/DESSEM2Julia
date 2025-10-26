using Test
using DESSEM2Julia

@testset "Renovaveis Parser Tests" begin
    
    @testset "Single Record Parsing" begin
        # Test basic EOLICA record parsing
        line = "EOLICA ;    1 ;5G260  _MMGD_F_260_00260_MGD             ;      9999 ;1.0 ;0; "
        record = parse_renovaveis_record(line, "test.dat", 1)
        
        @test record.plant_code == 1
        @test record.plant_name == "5G260  _MMGD_F_260_00260_MGD"
        @test record.pmax == 9999.0
        @test record.fcap == 1.0
        @test record.cadastro == 0
    end
    
    @testset "Different Plant Types" begin
        # Wind farm (UEE)
        line1 = "EOLICA ;  123 ;3RUECI _CIDREIRA_01347_UEE               ;      9999 ;1.0 ;0;"
        record1 = parse_renovaveis_record(line1, "test.dat", 1)
        @test record1.plant_code == 123
        @test occursin("UEE", record1.plant_name)
        @test record1.pmax == 9999.0
        
        # Solar farm (UFV)
        line2 = "EOLICA ;  456 ;GTCUFG _CJGUAIMBE_00409_UFV              ;      9999 ;1.0 ;1;"
        record2 = parse_renovaveis_record(line2, "test.dat", 2)
        @test record2.plant_code == 456
        @test occursin("UFV", record2.plant_name)
        @test record2.cadastro == 1
        
        # Biomass (UTE)
        line3 = "EOLICA ;  789 ;A6UDM  _CJ Da Mata_00498_UTE             ;      9999 ;1.0 ;0;"
        record3 = parse_renovaveis_record(line3, "test.dat", 3)
        @test record3.plant_code == 789
        @test occursin("UTE", record3.plant_name)
        
        # Small hydro (PCH)
        line4 = "EOLICA ;  101 ;A2BPC  _Barra da Paciencia_00348_PCH     ;      9999 ;1.0 ;0;"
        record4 = parse_renovaveis_record(line4, "test.dat", 4)
        @test record4.plant_code == 101
        @test occursin("PCH", record4.plant_name)
    end
    
    @testset "Capacity Factor Variations" begin
        # FCAP = 0.5
        line1 = "EOLICA ;  200 ;TEST1  _Plant1_00100_UEE                ;      500  ;0.5 ;0;"
        record1 = parse_renovaveis_record(line1, "test.dat", 1)
        @test record1.fcap == 0.5
        @test record1.pmax == 500.0
        
        # FCAP = 0.0
        line2 = "EOLICA ;  201 ;TEST2  _Plant2_00101_UFV                ;      100  ;0.0 ;1;"
        record2 = parse_renovaveis_record(line2, "test.dat", 2)
        @test record2.fcap == 0.0
        @test record2.pmax == 100.0
        @test record2.cadastro == 1
    end
    
    @testset "Edge Cases" begin
        # Minimal plant name
        line1 = "EOLICA ;    1 ;A                                        ;        10 ;1.0 ;0;"
        record1 = parse_renovaveis_record(line1, "test.dat", 1)
        @test record1.plant_name == "A"
        @test record1.pmax == 10.0
        
        # Large plant code
        line2 = "EOLICA ; 9999 ;MAXCODE_Plant_99999_UEE                 ;     99999 ;0.99;1;"
        record2 = parse_renovaveis_record(line2, "test.dat", 2)
        @test record2.plant_code == 9999
        @test record2.pmax == 99999.0
        @test record2.fcap == 0.99
    end
    
    @testset "Full File Parsing - Synthetic" begin
        # Create temporary file with multiple records
        temp_file = tempname() * ".dat"
        try
            open(temp_file, "w") do io
                # Comment header
                println(io, "&XXXXXX;XXXXX ;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ;XXXXXXXXXX ;XXX ;X;")
                println(io, "&      ;CODIGO;NOME: Usina, Barra e Tipo de Usina       ;PMAX       ;FCAP;C;")
                println(io, "&XXXXXX;XXXXX ;XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX ;XXXXXXXXXX ;XXX ;X;")
                
                # Data records
                println(io, "EOLICA ;    1 ;5G260  _MMGD_F_260_00260_MGD             ;      9999 ;1.0 ;0;")
                println(io, "EOLICA ;    2 ;5G262  _MMGD_F_262_00262_MGD             ;      9999 ;1.0 ;0;")
                println(io, "EOLICA ;    3 ;5G263  _MMGD_F_263_00263_MGD             ;      9999 ;1.0 ;0;")
                println(io, "EOLICA ;   43 ;GTCUFG _CJGUAIMBE_00409_UFV              ;      9999 ;1.0 ;1;")
                println(io, "EOLICA ;  199 ;3RUECI _CIDREIRA_01347_UEE               ;      9999 ;1.0 ;0;")
                
                # Blank line
                println(io, "")
                
                # More records
                println(io, "EOLICA ; 1000 ;TEST_PLANT_12345_PCH                    ;       250 ;0.8 ;1;")
            end
            
            # Parse the file
            data = parse_renovaveis(temp_file)
            
            # Validate results
            @test length(data.plants) == 6
            @test data.plants[1].plant_code == 1
            @test data.plants[4].plant_code == 43
            @test data.plants[4].cadastro == 1  # Registered
            @test data.plants[6].pmax == 250.0
            @test data.plants[6].fcap == 0.8
            
            # Check specific plant
            solar_plant = data.plants[4]
            @test occursin("UFV", solar_plant.plant_name)
            @test solar_plant.cadastro == 1
            
        finally
            # Cleanup
            isfile(temp_file) && rm(temp_file)
        end
    end
    
    @testset "Comment and Blank Line Handling" begin
        temp_file = tempname() * ".dat"
        try
            open(temp_file, "w") do io
                println(io, "& This is a comment")
                println(io, "")
                println(io, "&      Another comment")
                println(io, "EOLICA ;    1 ;Plant1                                  ;      100  ;1.0 ;0;")
                println(io, "")
                println(io, "& Comment between records")
                println(io, "EOLICA ;    2 ;Plant2                                  ;      200  ;0.5 ;1;")
                println(io, "")
            end
            
            data = parse_renovaveis(temp_file)
            @test length(data.plants) == 2
            @test data.plants[1].plant_code == 1
            @test data.plants[2].plant_code == 2
            
        finally
            isfile(temp_file) && rm(temp_file)
        end
    end
    
    @testset "Real CCEE Sample Data" begin
        # Test with actual CCEE sample file
        filepath = "docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/renovaveis.dat"
        
        if isfile(filepath)
            @testset "CCEE File Parsing" begin
                data = parse_renovaveis(filepath)
                
                # Basic validation - plants
                @test length(data.plants) > 0
                @test all(p -> p.plant_code > 0, data.plants)
                @test all(p -> !isempty(p.plant_name), data.plants)
                @test all(p -> p.pmax >= 0, data.plants)
                @test all(p -> 0.0 <= p.fcap <= 1.0, data.plants)
                @test all(p -> p.cadastro in (0, 1), data.plants)
                
                # Validate relationship data
                @test length(data.subsystem_mappings) > 0
                @test length(data.bus_mappings) > 0
                @test length(data.generation_forecasts) > 0
                
                # Subsystem mappings validation
                @test all(s -> s.plant_code > 0, data.subsystem_mappings)
                @test all(s -> s.subsystem in ["N", "NE", "S", "SE"], data.subsystem_mappings)
                
                # Bus mappings validation
                @test all(b -> b.plant_code > 0, data.bus_mappings)
                @test all(b -> b.bus_code > 0, data.bus_mappings)
                
                # Generation forecasts validation
                @test all(g -> g.plant_code > 0, data.generation_forecasts)
                @test all(g -> g.generation >= 0, data.generation_forecasts)
                @test all(g -> 0 <= g.start_hour <= 23, data.generation_forecasts)
                @test all(g -> g.start_half_hour in (0, 1), data.generation_forecasts)
                
                # Every plant should have subsystem and bus mapping
                @test length(data.subsystem_mappings) == length(data.plants)
                @test length(data.bus_mappings) == length(data.plants)
                
                # Print statistics
                println("\nCCEE Sample Statistics:")
                println("  Total plants: $(length(data.plants))")
                println("  Subsystem mappings: $(length(data.subsystem_mappings))")
                println("  Bus mappings: $(length(data.bus_mappings))")
                println("  Generation forecasts: $(length(data.generation_forecasts))")
                
                # Count by registration status
                registered = count(p -> p.cadastro == 1, data.plants)
                println("  Registered: $registered")
                println("  Not registered: $(length(data.plants) - registered)")
                
                # Subsystem distribution
                subsystem_counts = Dict{String, Int}()
                for s in data.subsystem_mappings
                    subsystem_counts[s.subsystem] = get(subsystem_counts, s.subsystem, 0) + 1
                end
                println("  Subsystem distribution:")
                for (subsystem, count) in sort(collect(subsystem_counts))
                    println("    $subsystem: $count plants")
                end
                
                # Count by type (based on name patterns)
                wind = count(p -> occursin("UEE", p.plant_name), data.plants)
                solar = count(p -> occursin("UFV", p.plant_name), data.plants)
                biomass = count(p -> occursin("UTE", p.plant_name), data.plants)
                small_hydro = count(p -> occursin(r"PCH|CGH", p.plant_name), data.plants)
                
                println("  Wind (UEE): $wind")
                println("  Solar (UFV): $solar")
                println("  Biomass (UTE): $biomass")
                println("  Small Hydro (PCH/CGH): $small_hydro")
                
                # Capacity factor statistics
                avg_fcap = sum(p -> p.fcap, data.plants) / length(data.plants)
                println("  Average FCAP: $(round(avg_fcap, digits=3))")
                
                # PMAX statistics (excluding 9999 placeholders)
                real_pmax = filter(p -> p.pmax < 9000, data.plants)
                if !isempty(real_pmax)
                    avg_pmax = sum(p -> p.pmax, real_pmax) / length(real_pmax)
                    max_pmax = maximum(p -> p.pmax, real_pmax)
                    println("  Average PMAX (real): $(round(avg_pmax, digits=1)) MW")
                    println("  Max PMAX: $(round(max_pmax, digits=1)) MW")
                end
            end
            
            @testset "CCEE Specific Plants" begin
                data = parse_renovaveis(filepath)
                
                # Find first plant
                first_plant = data.plants[1]
                @test first_plant.plant_code == 1
                @test !isempty(first_plant.plant_name)
                
                # Look for registered plant if exists
                registered_plants = filter(p -> p.cadastro == 1, data.plants)
                if !isempty(registered_plants)
                    @test all(p -> p.cadastro == 1, registered_plants)
                end
            end
        else
            @warn "CCEE sample file not found: $filepath"
        end
    end
    
    @testset "Real ONS Sample Data" begin
        # Test with actual ONS sample file (LARGE!)
        filepath = "docs/Sample/DS_ONS_102025_RV2D11/renovaveis.dat"
        
        if isfile(filepath)
            @testset "ONS File Parsing" begin
                # This file is HUGE (333k+ lines), so parsing might take a moment
                println("\nParsing large ONS file (this may take a moment)...")
                
                data = parse_renovaveis(filepath)
                
                # Basic validation - plants
                @test length(data.plants) > 0
                @test all(p -> p.plant_code > 0, data.plants)
                @test all(p -> !isempty(p.plant_name), data.plants)
                
                # Validate relationship data
                @test length(data.subsystem_mappings) > 0
                @test length(data.bus_mappings) > 0
                @test length(data.generation_forecasts) > 0
                
                # Generation forecasts should be much larger than plants (time series)
                @test length(data.generation_forecasts) > length(data.plants)
                
                # Every plant should have subsystem and bus mapping
                @test length(data.subsystem_mappings) == length(data.plants)
                @test length(data.bus_mappings) == length(data.plants)
                @test all(p -> p.pmax >= 0, data.plants)
                @test all(p -> 0.0 <= p.fcap <= 1.0, data.plants)
                @test all(p -> p.cadastro in (0, 1), data.plants)
                
                # Print statistics
                println("\nONS Sample Statistics:")
                println("  Total plants: $(length(data.plants))")
                
                # Count by registration status
                registered = count(p -> p.cadastro == 1, data.plants)
                println("  Registered: $registered")
                
                # Count by type
                wind = count(p -> occursin("UEE", p.plant_name), data.plants)
                solar = count(p -> occursin("UFV", p.plant_name), data.plants)
                biomass = count(p -> occursin("UTE", p.plant_name), data.plants)
                
                println("  Wind (UEE): $wind")
                println("  Solar (UFV): $solar")
                println("  Biomass (UTE): $biomass")
            end
        else
            @warn "ONS sample file not found: $filepath"
        end
    end
    
    @testset "Error Handling" begin
        # Test with malformed record (missing fields)
        @test_throws Exception parse_renovaveis_record("EOLICA ;    1 ;PlantName", "test.dat", 1)
        
        # Test with wrong record type
        @test_throws Exception parse_renovaveis_record("WRONG ;    1 ;PlantName;100;1.0;0;", "test.dat", 1)
    end
    
    @testset "Type Constructor" begin
        # Test direct construction
        record = RenovaveisRecord(
            plant_code=123,
            plant_name="TestPlant_UEE",
            pmax=500.0,
            fcap=0.75,
            cadastro=1
        )
        
        @test record.plant_code == 123
        @test record.plant_name == "TestPlant_UEE"
        @test record.pmax == 500.0
        @test record.fcap == 0.75
        @test record.cadastro == 1
        
        # Test data container
        data = RenovaveisData(plants=[record])
        @test length(data.plants) == 1
        @test data.plants[1].plant_code == 123
    end
end
