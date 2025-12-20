using Test
using DESSEM2Julia
using DESSEM2Julia: parse_mlt, MltData

@testset "MLT Parser Tests" begin
    @testset "Basic Binary Parsing" begin
        mktempdir() do dir
            mlt_path = joinpath(dir, "MLT.DAT")
            # Write some binary test data
            test_bytes = UInt8[0x01, 0x02, 0x03, 0x04, 0x00, 0x00, 0x00, 0x00]
            write(mlt_path, test_bytes)

            data = parse_mlt(mlt_path)
            @test data isa MltData
            @test data.size == 8
            @test length(data.raw_bytes) == 8
            @test data.raw_bytes == test_bytes
        end
    end

    @testset "Empty File" begin
        mktempdir() do dir
            mlt_path = joinpath(dir, "MLT.DAT")
            write(mlt_path, UInt8[])

            data = parse_mlt(mlt_path)
            @test data isa MltData
            @test data.size == 0
            @test isempty(data.raw_bytes)
        end
    end

    @testset "Real CCEE Data" begin
        mlt_path = joinpath(
            @__DIR__,
            "..",
            "docs",
            "Sample",
            "DS_CCEE_102025_SEMREDE_RV0D28",
            "mlt.dat",
        )
        if isfile(mlt_path)
            data = parse_mlt(mlt_path)
            @test data isa MltData
            @test data.size == 15360  # Known size from sample
            @test length(data.raw_bytes) == data.size
            # Verify first few bytes match expected binary pattern
            @test data.raw_bytes[1:4] == UInt8[0xf3, 0x00, 0x00, 0x00]  # 243, 0, 0, 0
        end
    end
end
