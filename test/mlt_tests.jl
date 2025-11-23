using Test
using DESSEM2Julia
using DESSEM2Julia: parse_mlt, MltData

@testset "MLT Parser Tests" begin
    mktempdir() do dir
        mlt_path = joinpath(dir, "MLT.DAT")
        open(mlt_path, "w") do io
            println(io, "SAMPLE MLT LINE 1")
            println(io, "SAMPLE MLT LINE 2")
        end

        data = parse_mlt(mlt_path)
        @test data isa MltData
        @test length(data.records) == 2
        @test strip(data.records[1].raw_line) == "SAMPLE MLT LINE 1"
    end
end
