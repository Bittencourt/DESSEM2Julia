using Test
using DESSEM2Julia
using Printf

@testset "MLT Parser Tests" begin
    @testset "Single Record Parsing" begin
        # Create a sample line with exact formatting
        # 1-3: Plant 1
        # 5-16: "USINA 1"
        # 20-29: 100.0
        # ...

        # Construct line manually to ensure exact positions
        # 1234567890123456789012345678901234567890
        #   1 USINA 1         100.00    110.00

        # Using @sprintf for precision
        # %3d (1-3)
        # space (4)
        # %-12s (5-16)
        # spaces (17-19)
        # %10.2f (20-29)
        # space (30)
        # %10.2f (31-40)

        vals = [
            100.0,
            110.0,
            120.0,
            130.0,
            140.0,
            150.0,
            160.0,
            170.0,
            180.0,
            190.0,
            200.0,
            210.0,
        ]

        line = @sprintf("%3d %-12s   ", 1, "USINA 1")
        for val in vals
            line *= @sprintf("%10.2f ", val)
        end
        # Remove trailing space to match exact length if needed, but parser ignores trailing

        tempfile = tempname()
        write(tempfile, line)

        try
            data = parse_mlt(tempfile)
            @test length(data.records) == 1
            record = data.records[1]
            @test record.plant_num == 1
            @test record.plant_name == "USINA 1"
            @test length(record.monthly_flows) == 12
            @test record.monthly_flows[1] == 100.0
            @test record.monthly_flows[12] == 210.0
        finally
            rm(tempfile, force = true)
        end
    end

    @testset "Multiple Records" begin
        vals1 = fill(100.0, 12)
        vals2 = fill(200.0, 12)

        line1 = @sprintf("%3d %-12s   ", 1, "USINA 1")
        for val in vals1
            line1 *= @sprintf("%10.2f ", val)
        end

        line2 = @sprintf("%3d %-12s   ", 2, "USINA 2")
        for val in vals2
            line2 *= @sprintf("%10.2f ", val)
        end

        content = line1 * "\n" * line2

        tempfile = tempname()
        write(tempfile, content)

        try
            data = parse_mlt(tempfile)
            @test length(data.records) == 2
            @test data.records[1].plant_num == 1
            @test data.records[2].plant_num == 2
            @test data.records[2].monthly_flows[1] == 200.0
        finally
            rm(tempfile, force = true)
        end
    end

    @testset "Comments and Blank Lines" begin
        vals = fill(100.0, 12)
        line = @sprintf("%3d %-12s   ", 1, "USINA 1")
        for val in vals
            line *= @sprintf("%10.2f ", val)
        end

        content = """
& This is a comment
$line

& Another comment
"""
        tempfile = tempname()
        write(tempfile, content)

        try
            data = parse_mlt(tempfile)
            @test length(data.records) == 1
        finally
            rm(tempfile, force = true)
        end
    end
end
