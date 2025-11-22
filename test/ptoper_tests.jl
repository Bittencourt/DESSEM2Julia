using Test
using DESSEM2Julia
using DESSEM2Julia.PtoperParser

@testset "PTOPER Parser Tests" begin
    @testset "Single Record Parsing" begin
        line = "PTOPER USIT    86 GERA   27  0 0 F             175."
        record = parse_ptoper_record(line, "test.dat", 1)

        @test record.mnemonic == "PTOPER"
        @test record.element_type == "USIT"
        @test record.element_id == 86
        @test record.variable == "GERA"
        @test record.start_day == 27
        @test record.start_hour == 0
        @test record.start_half == 0
        @test record.end_day == "F"
        @test record.end_hour == 0
        @test record.end_half == 0
        @test record.value == 175.0
    end

    @testset "Record with End Time" begin
        # Construct a line with explicit end time
        # PTOPER USIT    86 GERA   27  0 0 27 10 0             175.
        # DI(26-27) HI(29-30) M(32) DF(34-35) HF(37-38) M(40)
        line = "PTOPER USIT    86 GERA   27  0 0 27 10 0             175."
        record = parse_ptoper_record(line, "test.dat", 1)

        @test record.end_day == 27
        @test record.end_hour == 10
        @test record.end_half == 0
    end

    @testset "Real CCEE Data" begin
        filepath = joinpath(
            @__DIR__,
            "..",
            "docs",
            "Sample",
            "DS_CCEE_102025_SEMREDE_RV0D28",
            "ptoper.dat",
        )
        if isfile(filepath)
            data = parse_ptoper(filepath)
            @test length(data.records) > 0
            @test data.records[1].element_type == "USIT"
            println("Parsed $(length(data.records)) records from CCEE sample")
        else
            @warn "CCEE sample file not found: $filepath"
        end
    end

    @testset "Real ONS Data" begin
        filepath =
            joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11", "ptoper.dat")
        if isfile(filepath)
            data = parse_ptoper(filepath)
            @test length(data.records) > 0
            println("Parsed $(length(data.records)) records from ONS sample")
        else
            @warn "ONS sample file not found: $filepath"
        end
    end
end
