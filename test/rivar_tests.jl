using Test
using DESSEM2Julia
using DESSEM2Julia.RivarParser

@testset "RIVAR.DAT Parser Tests" begin
    @testset "Single Record Parsing" begin
        # Test case based on typical format
        # Type 1, Index 5, Cost 1000.00, Lower 0.00, Upper 5000.00
        line = "  1   5    1000.00      0.00   5000.00"
        record = parse_rivar_record(line, "test.dat", 1)

        @test record.variable_type == 1
        @test record.variable_index == 5
        @test record.penalty_cost == 1000.00
        @test record.limit_lower == 0.00
        @test record.limit_upper == 5000.00
    end

    @testset "Optional Limits" begin
        # Test with missing limits
        line = "  2  10     500.50                  "
        record = parse_rivar_record(line, "test.dat", 1)

        @test record.variable_type == 2
        @test record.variable_index == 10
        @test record.penalty_cost == 500.50
        @test record.limit_lower === nothing
        @test record.limit_upper === nothing

        # Test with only lower limit
        line = "  3  15     100.00     10.00          "
        record = parse_rivar_record(line, "test.dat", 1)

        @test record.variable_type == 3
        @test record.variable_index == 15
        @test record.penalty_cost == 100.00
        @test record.limit_lower == 10.00
        @test record.limit_upper === nothing
    end

    @testset "File Parsing" begin
        # Create a temporary file
        content = """
        RIVAR - ARQUIVO DE PENALIDADES
        # Comentario
          1   5    1000.00      0.00   5000.00
          2  10     500.50
        FIM
        """

        path = "temp_rivar.dat"
        open(path, "w") do io
            write(io, content)
        end

        try
            data = parse_rivar(path)

            @test length(data.records) == 2

            r1 = data.records[1]
            @test r1.variable_type == 1
            @test r1.variable_index == 5
            @test r1.penalty_cost == 1000.00

            r2 = data.records[2]
            @test r2.variable_type == 2
            @test r2.variable_index == 10
            @test r2.penalty_cost == 500.50
            @test r2.limit_lower === nothing

        finally
            rm(path, force = true)
        end
    end

    @testset "Error Handling" begin
        # Empty fields
        line = "      5    1000.00"
        @test_throws ErrorException parse_rivar_record(line, "test.dat", 1)

        line = "  1        1000.00"
        @test_throws ErrorException parse_rivar_record(line, "test.dat", 1)

        line = "  1   5           "
        @test_throws ErrorException parse_rivar_record(line, "test.dat", 1)
    end
end
