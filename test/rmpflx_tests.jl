using Test
using DESSEM2Julia
using DESSEM2Julia.CoreTypes
using DESSEM2Julia.RmpflxParser

@testset "RMPFLX Parser Tests" begin
    @testset "REST Record Parsing" begin
        # RMPFLX REST DREF Valor [Status]
        # 1-6: Mnem, 8-11: Type, 13-16: DREF, 18-27: Value, 29: Status
        line = "RMPFLX REST 9003        600"
        io = IOBuffer(line)
        data = parse_rmpflx(io, "test.dat")

        @test length(data.rest_records) == 1
        record = data.rest_records[1]
        @test record.constraint_id == 9003
        @test record.initial_value == 600.0
        @test record.status === nothing

        # With status
        line = "RMPFLX REST  958        494 1"
        io = IOBuffer(line)
        data = parse_rmpflx(io, "test.dat")

        @test length(data.rest_records) == 1
        record = data.rest_records[1]
        @test record.constraint_id == 958
        @test record.initial_value == 494.0
        @test record.status == 1
    end

    @testset "LIMI Record Parsing" begin
        # RMPFLX LIMI DI HI MI DF HF MF DREF Desc Sub [Status]
        # 1-6: Mnem, 8-11: Type, 13-14: DI, 16-17: HI, 19: MI, 21-22: DF, 24-25: HF, 27: MF, 29-32: DREF, 34-43: Desc, 45-54: Sub, 56: Status
        line = "RMPFLX LIMI  I       F      9003        100        100"
        io = IOBuffer(line)
        data = parse_rmpflx(io, "test.dat")

        @test length(data.limi_records) == 1
        record = data.limi_records[1]
        @test record.constraint_id == 9003
        @test record.start_day == "I"
        @test record.end_day == "F"
        @test record.ramp_down == 100.0
        @test record.ramp_up == 100.0
        @test record.status === nothing

        # With numeric dates and status
        line = "RMPFLX LIMI 28 00 0 29 00 0  958       2400       2400 1"
        io = IOBuffer(line)
        data = parse_rmpflx(io, "test.dat")

        @test length(data.limi_records) == 1
        record = data.limi_records[1]
        @test record.constraint_id == 958
        @test record.start_day == 28
        @test record.start_hour == 0
        @test record.start_half == 0
        @test record.end_day == 29
        @test record.end_hour == 0
        @test record.end_half == 0
        @test record.ramp_down == 2400.0
        @test record.ramp_up == 2400.0
        @test record.status == 1
    end

    @testset "Real File Integration" begin
        filepath = joinpath(
            @__DIR__,
            "..",
            "docs",
            "Sample",
            "DS_CCEE_102025_SEMREDE_RV0D28",
            "rmpflx.dat",
        )
        if isfile(filepath)
            data = parse_rmpflx(filepath)
            @test length(data.rest_records) > 0
            @test length(data.limi_records) > 0
        end
    end
end
