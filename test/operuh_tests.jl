"""
Test OPERUH.DAT parser
"""

using Test
using DESSEM2Julia

@testset "OPERUH Parser Tests" verbose=true begin
    
    # Sample directory with real DESSEM data
    sample_dir = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")
    operuh_file = joinpath(sample_dir, "operuh.dat")
    
    @testset "File Parsing" begin
        @test isfile(operuh_file)
        
        # Parse the file
        data = parse_operuh(operuh_file)
        
        @test data isa OperuhData
        @test !isempty(data.rest_records)
        @test !isempty(data.elem_records)
        @test !isempty(data.lim_records)
        
        println("\n📊 OPERUH Data Summary:")
        println("  REST records (constraints): $(length(data.rest_records))")
        println("  ELEM records (elements):    $(length(data.elem_records))")
        println("  LIM records (limits):       $(length(data.lim_records))")
        println("  VAR records (variations):   $(length(data.var_records))")
    end
    
    @testset "REST Records" begin
        data = parse_operuh(operuh_file)
        
        # Check we have REST records
        @test length(data.rest_records) > 0
        
        # Check first REST record structure
        first_rest = data.rest_records[1]
        @test first_rest isa HydroConstraintREST
        @test first_rest.constraint_id > 0
        @test first_rest.type_flag in ["L", "V"]  # Limit or Variation
        @test !isempty(first_rest.variable_code)
        
        println("\n  Sample REST record:")
        println("    Constraint ID: $(first_rest.constraint_id)")
        println("    Type: $(first_rest.type_flag)")
        println("    Variable: $(first_rest.variable_code)")
    end
    
    @testset "ELEM Records" begin
        data = parse_operuh(operuh_file)
        
        # Check we have ELEM records
        @test length(data.elem_records) > 0
        
        # Check first ELEM record structure
        first_elem = data.elem_records[1]
        @test first_elem isa HydroConstraintELEM
        @test first_elem.constraint_id > 0
        @test first_elem.plant_num > 0
        @test !isempty(first_elem.plant_name)
        @test first_elem.variable_code > 0
        @test first_elem.participation_factor != 0.0
        
        println("\n  Sample ELEM record:")
        println("    Constraint ID: $(first_elem.constraint_id)")
        println("    Plant: $(first_elem.plant_num) - $(first_elem.plant_name)")
        println("    Participation: $(first_elem.participation_factor)")
    end
    
    @testset "LIM Records" begin
        data = parse_operuh(operuh_file)
        
        # Check we have LIM records
        @test length(data.lim_records) > 0
        
        # Check first LIM record structure  
        first_lim = data.lim_records[1]
        @test first_lim isa HydroConstraintLIM
        @test first_lim.constraint_id > 0
        @test !isempty(first_lim.start_day)
        @test !isempty(first_lim.end_day)
        
        println("\n  Sample LIM record:")
        println("    Constraint ID: $(first_lim.constraint_id)")
        println("    Period: $(first_lim.start_day) to $(first_lim.end_day)")
        if !isnothing(first_lim.lower_limit)
            println("    Lower limit: $(first_lim.lower_limit)")
        end
        if !isnothing(first_lim.upper_limit)
            println("    Upper limit: $(first_lim.upper_limit)")
        end
    end
    
    @testset "Constraint Linking" begin
        data = parse_operuh(operuh_file)
        
        # Check that ELEM and LIM records link to REST records
        rest_ids = Set(r.constraint_id for r in data.rest_records)
        elem_ids = Set(r.constraint_id for r in data.elem_records)
        lim_ids = Set(r.constraint_id for r in data.lim_records)
        
        # All ELEM constraints should have corresponding REST
        for elem_id in elem_ids
            @test elem_id in rest_ids
        end
        
        # All LIM constraints should have corresponding REST
        for lim_id in lim_ids
            @test lim_id in rest_ids
        end
        
        println("\n  Constraint linking verified:")
        println("    Unique REST IDs: $(length(rest_ids))")
        println("    Unique ELEM IDs: $(length(elem_ids))")
        println("    Unique LIM IDs:  $(length(lim_ids))")
    end
    
end
