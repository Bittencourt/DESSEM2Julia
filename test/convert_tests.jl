using Test
using DESSEM2Julia
using JLD2

@testset "convert API" begin
    mktempdir() do tmp
        # Create a dummy DESSEM-like .DAT file
        input_dir = joinpath(tmp, "inputs")
        mkpath(input_dir)
        sample = joinpath(input_dir, "DADGER.DAT")
        open(sample, "w") do io
            write(io, "# sample\nPARAM 1 2 3\n")
        end

        outpath = joinpath(tmp, "out.jld2")
        p = DESSEM2Julia.convert_inputs(input_dir, outpath)
        @test p == outpath
        @test isfile(outpath)

        data = JLD2.jldopen(outpath, "r") do f
            read(f, "data")
        end
        @test isa(data, DESSEM2Julia.DessemData)
        @test haskey(data.files, "DADGER.DAT")
        @test occursin("PARAM", String(data.files["DADGER.DAT"]))
    end
end
