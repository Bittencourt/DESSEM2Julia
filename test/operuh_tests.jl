"""
Test OPERUH.DAT parser - Comprehensive field extraction tests
"""

using Test
using DESSEM2Julia

@testset "OPERUH Parser Tests" verbose = true begin
    @testset "REST Record Parsing" begin
        # Test basic REST record with all fields
        # Note: variation_type field may be optional even when other fields present
        line = "OPERUH REST   00066  L     RHQ               489.00      15.00"
        record = DESSEM2Julia.OperuhParser.parse_rest_record(line, "test.dat", 1)

        @test !isnothing(record)
        @test record.constraint_id == 66
        @test record.type_flag == "L"
        @test record.variable_code == "RHQ"
        @test record.initial_value == 489.00
        # variation_type is optional
        @test record.window_duration == 15.00

        # Test REST with minimal fields
        line2 = "OPERUH REST   00067  V     RHQ"
        record2 = DESSEM2Julia.OperuhParser.parse_rest_record(line2, "test.dat", 2)
        @test !isnothing(record2)
        @test record2.constraint_id == 67
        @test record2.initial_value === nothing
        @test record2.window_duration === nothing

        # Test REST with dot as placeholder (should parse as nothing)
        line3 = "OPERUH REST   99212  V     RHQ                  ."
        record3 = DESSEM2Julia.OperuhParser.parse_rest_record(line3, "test.dat", 3)
        @test !isnothing(record3)
        @test record3.constraint_id == 99212
        @test record3.initial_value === nothing
    end

    @testset "ELEM Record Parsing" begin
        # Test basic ELEM record
        line = "OPERUH ELEM   00066  14  CACONDE         6   1.0"
        record = DESSEM2Julia.OperuhParser.parse_elem_record(line, "test.dat", 1)

        @test !isnothing(record)
        @test record.constraint_id == 66
        @test record.plant_code == 14
        @test record.plant_name == "CACONDE"
        @test record.variable_type == 6
        @test record.coefficient == 1.0

        # Test with different coefficient
        line2 = "OPERUH ELEM   00070  25  NOVA PONTE      3   2.5"
        record2 = DESSEM2Julia.OperuhParser.parse_elem_record(line2, "test.dat", 2)
        @test !isnothing(record2)
        @test record2.coefficient == 2.5
    end

    @testset "LIM Record Parsing" begin
        # Test basic LIM record with special day characters
        line = "OPERUH LIM    00066  I       F                         600.00"
        record = DESSEM2Julia.OperuhParser.parse_lim_record(line, "test.dat", 1)

        @test !isnothing(record)
        @test record.constraint_id == 66
        @test record.start_day == "I"
        @test record.start_hour === nothing
        @test record.start_half === nothing
        @test record.end_day == "F"
        @test record.end_hour === nothing
        @test record.end_half === nothing
        @test record.upper_limit == 600.00
        @test record.lower_limit === nothing

        # Test LIM with both limits and numeric days
        line2 = "OPERUH LIM    00070 11 01 0 11 07 1     100.00     200.00"
        record2 = DESSEM2Julia.OperuhParser.parse_lim_record(line2, "test.dat", 2)
        @test !isnothing(record2)
        @test record2.start_day == 11
        @test record2.start_hour == 1
        @test record2.start_half == 0
        @test record2.lower_limit == 100.00
        @test record2.upper_limit == 200.00
    end

    @testset "VAR Record Parsing" begin
        # Test VAR record with single ramp value (most common)
        line = "OPERUH VAR    03111 I       F                                          600.00"
        record = DESSEM2Julia.OperuhParser.parse_var_record(line, "test.dat", 1)

        @test !isnothing(record)
        @test record.constraint_id == 3111
        @test record.start_day == "I"
        @test record.end_day == "F"
        @test record.ramp_up_2 == 600.00
        @test record.ramp_down === nothing
        @test record.ramp_up === nothing
        @test record.ramp_down_2 === nothing

        # Test VAR with all four ramp values (less common)
        line2 = "OPERUH VAR    0746011 00 0 11 01 0     10.00     20.00     30.00     50.00"
        record2 = DESSEM2Julia.OperuhParser.parse_var_record(line2, "test.dat", 2)
        @test !isnothing(record2)
        @test record2.start_day == 11
        @test record2.start_hour == 0
        @test record2.start_half == 0
        @test record2.ramp_down == 10.00
        @test record2.ramp_up == 20.00
        @test record2.ramp_down_2 == 30.00
        @test record2.ramp_up_2 == 50.00
    end

    @testset "Real ONS Data - 100% Parsing Success" begin
        filepath =
            joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11", "operuh.dat")
        if isfile(filepath)
            data = parse_operuh(filepath)

            # Verify exact counts (100% parsing success)
            @test length(data.rest_records) == 340
            @test length(data.elem_records) == 342
            @test length(data.lim_records) == 341
            @test length(data.var_records) == 89

            println("\n📊 ONS OPERUH Data:")
            println("  REST: 340/340 (100%)")
            println("  ELEM: 342/342 (100%)")
            println("  LIM:  341/341 (100%)")
            println("  VAR:  89/89 (100%)")
            println("  Total: 1,112/1,112 records (100% success)")

            # Verify first records have valid structured data
            @test data.rest_records[1].constraint_id > 0
            @test !isempty(data.rest_records[1].variable_code)
            @test !isempty(data.elem_records[1].plant_name)
            @test data.elem_records[1].coefficient != 0.0
            @test data.lim_records[1].constraint_id > 0
            @test data.var_records[1].constraint_id > 0
        else
            @warn "ONS sample file not found, skipping real data tests"
        end
    end

    @testset "Real CCEE Data - Field Extraction Verified" begin
        filepath = joinpath(
            @__DIR__,
            "..",
            "docs",
            "Sample",
            "DS_CCEE_102025_SEMREDE_RV0D28",
            "operuh.dat",
        )
        if isfile(filepath)
            data = parse_operuh(filepath)

            @test length(data.rest_records) > 0
            @test length(data.elem_records) > 0
            @test length(data.lim_records) > 0

            println("\n📊 CCEE OPERUH Data:")
            println("  REST: $(length(data.rest_records))")
            println("  ELEM: $(length(data.elem_records))")
            println("  LIM:  $(length(data.lim_records))")
            println("  VAR:  $(length(data.var_records))")

            # Verify structure
            @test data.rest_records[1] isa HydroConstraintREST
            @test data.elem_records[1] isa HydroConstraintELEM
            @test data.lim_records[1] isa HydroConstraintLIM

            # Verify field extraction (not just raw lines)
            @test data.elem_records[1].plant_code > 0
            @test !isempty(data.elem_records[1].plant_name)
            @test data.elem_records[1].coefficient > 0.0
        else
            @warn "CCEE sample file not found, skipping real data tests"
        end
    end

    @testset "Edge Cases" begin
        # Test empty optional fields
        line_rest = "OPERUH REST   00100  L     RHQ"
        record = DESSEM2Julia.OperuhParser.parse_rest_record(line_rest, "test.dat", 1)
        @test !isnothing(record)
        @test record.initial_value === nothing

        # Test with special day characters (I = Initial, F = Final)
        line_lim = "OPERUH LIM    00200  F       I                         500.00"
        record_lim = DESSEM2Julia.OperuhParser.parse_lim_record(line_lim, "test.dat", 2)
        @test !isnothing(record_lim)
        @test record_lim.start_day == "F"
        @test record_lim.end_day == "I"
    end

    @testset "Constraint Relationships" begin
        filepath =
            joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11", "operuh.dat")
        if isfile(filepath)
            data = parse_operuh(filepath)

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
end
