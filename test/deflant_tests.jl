using Test
using DESSEM2Julia

@testset "DEFLANT Parser Tests" begin
    
    @testset "Single Record Parsing" begin
        @testset "Standard Record with F for Final Day" begin
            line = "DEFANT     2    4  H    10 00 0  F                 113"
            record = DESSEM2Julia.DeflantParser.parse_deflant_record(line, "test.dat", 1)
            
            @test record.upstream_plant == 2
            @test record.downstream_element == 4
            @test record.element_type == "H"
            @test record.initial_day == 10
            @test record.initial_hour == 0
            @test record.initial_half == 0
            @test record.final_day == "F"
            @test record.final_hour === nothing
            @test record.final_half === nothing
            @test record.flow == 113.0
        end
        
        @testset "Record with I for Initial Day" begin
            line = "DEFANT    25   26  H     I 00 0 05 00 0            445"
            record = DESSEM2Julia.DeflantParser.parse_deflant_record(line, "test.dat", 1)
            
            @test record.upstream_plant == 25
            @test record.downstream_element == 26
            @test record.element_type == "H"
            @test record.initial_day == "I"
            @test record.initial_hour == 0
            @test record.initial_half == 0
            @test record.final_day == 5
            @test record.final_hour == 0
            @test record.final_half == 0
            @test record.flow == 445.0
        end
        
        @testset "Record with Large Plant Numbers" begin
            line = "DEFANT   203  249  H    10 00 0  F                 109"
            record = DESSEM2Julia.DeflantParser.parse_deflant_record(line, "test.dat", 1)
            
            @test record.upstream_plant == 203
            @test record.downstream_element == 249
            @test record.element_type == "H"
            @test record.flow == 109.0
        end
        
        @testset "Record with River Section Type" begin
            line = "DEFANT    12   34  S    08 00 0  F                  50"
            record = DESSEM2Julia.DeflantParser.parse_deflant_record(line, "test.dat", 1)
            
            @test record.element_type == "S"
            @test record.upstream_plant == 12
            @test record.downstream_element == 34
        end
        
        @testset "Record with Large Flow Value" begin
            line = "DEFANT    46   66  H    10 00 0  F                4321"
            record = DESSEM2Julia.DeflantParser.parse_deflant_record(line, "test.dat", 1)
            
            @test record.upstream_plant == 46
            @test record.downstream_element == 66
            @test record.flow == 4321.0
        end
        
        @testset "Record with Different Initial Times" begin
            line = "DEFANT    16   17  H    08 00 0  F                  47"
            record = DESSEM2Julia.DeflantParser.parse_deflant_record(line, "test.dat", 1)
            
            @test record.initial_day == 8
            @test record.initial_hour == 0
            @test record.initial_half == 0
            @test record.flow == 47.0
        end
        
        @testset "Record with Half-Hour = 1" begin
            line = "DEFANT    30   31  H    10 12 1  F                 142"
            record = DESSEM2Julia.DeflantParser.parse_deflant_record(line, "test.dat", 1)
            
            @test record.initial_hour == 12
            @test record.initial_half == 1
        end
    end
    
    @testset "File Parsing" begin
        @testset "Comment and Blank Line Handling" begin
            io = IOBuffer("""
            &   DEFLUENCIAS ANTERIORES AO INICIO DO ESTUDO
            &
            &        Mont Jus TpJ   di hi m df hf m     defluencia
            DEFANT     2    4  H    10 00 0  F                 113
            
            DEFANT     4    6  H    10 00 0  F                 170
            """)
            
            result = DESSEM2Julia.DeflantParser.parse_deflant(io, "test.dat")
            
            @test length(result.records) == 2
            @test result.records[1].upstream_plant == 2
            @test result.records[1].flow == 113.0
            @test result.records[2].upstream_plant == 4
            @test result.records[2].flow == 170.0
        end
        
        @testset "Multiple Records Parsing" begin
            io = IOBuffer("""
            DEFANT     2    4  H    10 00 0  F                 113
            DEFANT     4    6  H    10 00 0  F                 170
            DEFANT     6    7  H    10 00 0  F                 972
            DEFANT     7    8  H    10 00 0  F                 970
            DEFANT     8    9  H    10 00 0  F                1053
            """)
            
            result = DESSEM2Julia.DeflantParser.parse_deflant(io, "test.dat")
            
            @test length(result.records) == 5
            @test result.records[1].flow == 113.0
            @test result.records[2].flow == 170.0
            @test result.records[3].flow == 972.0
            @test result.records[4].flow == 970.0
            @test result.records[5].flow == 1053.0
        end
        
        @testset "Empty File" begin
            io = IOBuffer("")
            result = DESSEM2Julia.DeflantParser.parse_deflant(io, "test.dat")
            
            @test length(result.records) == 0
        end
        
        @testset "Only Comments File" begin
            io = IOBuffer("""
            &   DEFLUENCIAS ANTERIORES AO INICIO DO ESTUDO
            & Comment line
            """)
            
            result = DESSEM2Julia.DeflantParser.parse_deflant(io, "test.dat")
            
            @test length(result.records) == 0
        end
    end
    
    @testset "Real ONS Data" begin
        filepath = "docs/Sample/DS_ONS_102025_RV2D11/deflant.dat"
        if isfile(filepath)
            @testset "ONS File Parsing" begin
                result = DESSEM2Julia.DeflantParser.parse_deflant(filepath)
                
                @test length(result.records) > 0
                @test all(r -> r.upstream_plant > 0, result.records)
                @test all(r -> r.downstream_element > 0, result.records)
                @test all(r -> r.element_type in ["H", "S"], result.records)
                @test all(r -> r.flow >= 0, result.records)
            end
            
            @testset "ONS Specific Records Validation" begin
                result = DESSEM2Julia.DeflantParser.parse_deflant(filepath)
                
                # Check for specific known records from sample
                record_2_4 = findfirst(r -> r.upstream_plant == 2 && r.downstream_element == 4, result.records)
                @test !isnothing(record_2_4)
                if !isnothing(record_2_4)
                    rec = result.records[record_2_4]
                    @test rec.element_type == "H"
                    @test rec.initial_day == 10
                    @test rec.final_day == "F"
                    @test rec.flow == 113.0
                end
                
                # Check for record with different initial day
                record_16_17 = findfirst(r -> r.upstream_plant == 16 && r.downstream_element == 17 && r.initial_day == 8, result.records)
                @test !isnothing(record_16_17)
                if !isnothing(record_16_17)
                    rec = result.records[record_16_17]
                    @test rec.flow == 47.0
                end
                
                # Check for large flow value
                record_46_66 = findfirst(r -> r.upstream_plant == 46 && r.downstream_element == 66 && r.flow > 4000, result.records)
                @test !isnothing(record_46_66)
                if !isnothing(record_46_66)
                    rec = result.records[record_46_66]
                    @test rec.flow == 4321.0
                end
            end
            
            @testset "ONS Data Integrity" begin
                result = DESSEM2Julia.DeflantParser.parse_deflant(filepath)
                
                # All records should have valid day values
                for record in result.records
                    if record.initial_day isa Int
                        @test 1 <= record.initial_day <= 31
                    else
                        @test record.initial_day in ["I", "F", ""]
                    end
                    
                    if record.final_day isa Int
                        @test 1 <= record.final_day <= 31
                    else
                        @test record.final_day in ["I", "F", ""]
                    end
                end
                
                # All records with hour values should be valid
                for record in result.records
                    if !isnothing(record.initial_hour)
                        @test 0 <= record.initial_hour <= 23
                    end
                    if !isnothing(record.final_hour)
                        @test 0 <= record.final_hour <= 23
                    end
                end
                
                # All records with half-hour values should be 0 or 1
                for record in result.records
                    if !isnothing(record.initial_half)
                        @test record.initial_half in [0, 1]
                    end
                    if !isnothing(record.final_half)
                        @test record.final_half in [0, 1]
                    end
                end
            end
        else
            @warn "ONS sample file not found: $filepath"
        end
    end
    
    @testset "Real CCEE Data" begin
        # CCEE samples may not have DEFLANT.DAT
        ccee_paths = [
            "docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/deflant.dat",
            "docs/Sample/DS_CCEE_102025_SEMREDE_RV1D04/deflant.dat"
        ]
        
        for filepath in ccee_paths
            if isfile(filepath)
                @testset "CCEE $(basename(dirname(filepath)))" begin
                    result = DESSEM2Julia.DeflantParser.parse_deflant(filepath)
                    
                    @test length(result.records) >= 0  # May be empty
                    if length(result.records) > 0
                        @test all(r -> r.upstream_plant > 0, result.records)
                        @test all(r -> r.downstream_element > 0, result.records)
                        @test all(r -> r.element_type in ["H", "S"], result.records)
                        @test all(r -> r.flow >= 0, result.records)
                    end
                end
            end
        end
    end
    
    @testset "Edge Cases" begin
        @testset "Minimum Flow Value" begin
            line = "DEFANT     1    2  H    01 00 0  F                   0"
            record = DESSEM2Julia.DeflantParser.parse_deflant_record(line, "test.dat", 1)
            
            @test record.flow == 0.0
        end
        
        @testset "Both Days as Numbers" begin
            line = "DEFANT    10   11  H    05 12 0 10 18 1            100"
            record = DESSEM2Julia.DeflantParser.parse_deflant_record(line, "test.dat", 1)
            
            @test record.initial_day == 5
            @test record.initial_hour == 12
            @test record.initial_half == 0
            @test record.final_day == 10
            @test record.final_hour == 18
            @test record.final_half == 1
        end
    end
    
end
