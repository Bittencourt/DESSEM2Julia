using Test
using DESSEM2Julia

@testset "RIVAR.DAT Parser Tests" begin
    @testset "Single Record Parsing" begin
        # Test basic record with all fields
        # Columns: 1-3 (var type), 5-7 (var index), 10-19 (penalty), 21-30 (lower), 32-41 (upper)
        line = "  1   5    1000.00      0.00   5000.00"
        record = DESSEM2Julia.RivarParser.parse_rivar_record(line, "test.dat", 1)

        @test record.variable_type == 1
        @test record.variable_index == 5
        @test record.penalty_cost == 1000.0
        @test record.limit_lower == 0.0
        @test record.limit_upper == 5000.0
    end

    @testset "Record Without Optional Limits" begin
        # Test record with only required fields
        line = "  2  10    2500.00"
        record = DESSEM2Julia.RivarParser.parse_rivar_record(line, "test.dat", 2)

        @test record.variable_type == 2
        @test record.variable_index == 10
        @test record.penalty_cost == 2500.0
        @test record.limit_lower === nothing
        @test record.limit_upper === nothing
    end

    @testset "Record With Lower Limit Only" begin
        # Test record with lower limit but no upper limit
        line = "  3  15     500.00    100.00"
        record = DESSEM2Julia.RivarParser.parse_rivar_record(line, "test.dat", 3)

        @test record.variable_type == 3
        @test record.variable_index == 15
        @test record.penalty_cost == 500.0
        @test record.limit_lower == 100.0
        @test record.limit_upper === nothing
    end

    @testset "Real File Parsing" begin
        # Create a temporary file with sample content
        content = """
* RIVAR.DAT - Soft variation constraints
* Variable Type, Index, Penalty Cost, Lower Limit, Upper Limit
  1   5    1000.00      0.00   5000.00
  2  10    2500.00
  3  15     500.00    100.00
  4  20    1500.00   -100.00    100.00
FIM
"""
        path = "temp_rivar.dat"
        open(path, "w") do io
            write(io, content)
        end

        try
            data = parse_rivar(path)
            @test length(data.records) == 4

            # Check first record
            @test data.records[1].variable_type == 1
            @test data.records[1].variable_index == 5
            @test data.records[1].penalty_cost == 1000.0
            @test data.records[1].limit_lower == 0.0
            @test data.records[1].limit_upper == 5000.0

            # Check second record (no limits)
            @test data.records[2].variable_type == 2
            @test data.records[2].penalty_cost == 2500.0
            @test data.records[2].limit_lower === nothing
            @test data.records[2].limit_upper === nothing

            # Check third record (lower limit only)
            @test data.records[3].variable_type == 3
            @test data.records[3].limit_lower == 100.0
            @test data.records[3].limit_upper === nothing

            # Check fourth record (both limits)
            @test data.records[4].variable_type == 4
            @test data.records[4].limit_lower == -100.0
            @test data.records[4].limit_upper == 100.0
        finally
            rm(path, force = true)
        end
    end

    @testset "Comment and Blank Line Handling" begin
        # Test that comments and blank lines are properly skipped
        content = """
* Header comment
* More info

  1   5    1000.00      0.00   5000.00

* Middle comment
  2  10    2500.00

"""
        path = "temp_rivar_comments.dat"
        open(path, "w") do io
            write(io, content)
        end

        try
            data = parse_rivar(path)
            @test length(data.records) == 2
            @test data.records[1].variable_type == 1
            @test data.records[2].variable_type == 2
        finally
            rm(path, force = true)
        end
    end

    @testset "Real CCEE Sample File" begin
        # Check if the sample file exists in the workspace
        sample_path = joinpath(
            dirname(@__DIR__),
            "docs",
            "Sample",
            "DS_CCEE_102025_SEMREDE_RV0D28",
            "rivar.dat",
        )
        if isfile(sample_path)
            data = parse_rivar(sample_path)
            @test length(data.records) >= 0
            println("Parsed $(length(data.records)) records from real CCEE sample file.")
            
            # If there are records, verify structure
            if length(data.records) > 0
                @test data.records[1].variable_type isa Int
                @test data.records[1].variable_index isa Int
                @test data.records[1].penalty_cost isa Float64
            end
        else
            println("CCEE sample file not found at $sample_path, skipping real file test.")
        end
    end

    @testset "Real ONS Sample File" begin
        # Check if ONS sample file exists
        sample_path = joinpath(
            dirname(@__DIR__),
            "docs",
            "Sample",
            "DS_ONS_102025_RV2D11",
            "rivar.dat",
        )
        if isfile(sample_path)
            data = parse_rivar(sample_path)
            @test length(data.records) >= 0
            println("Parsed $(length(data.records)) records from real ONS sample file.")
            
            # If there are records, verify structure
            if length(data.records) > 0
                @test data.records[1].variable_type isa Int
                @test data.records[1].variable_index isa Int
                @test data.records[1].penalty_cost isa Float64
            end
        else
            println("ONS sample file not found at $sample_path, skipping real file test.")
        end
    end
end
