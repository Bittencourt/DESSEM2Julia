using Test
using DESSEM2Julia
using DESSEM2Julia:
    parse_infofcf, parse_mapcut, parse_cortes, InfofcfData, MapcutData, CortesData

@testset "Binary DEC Parsers Tests" begin

    # Create temporary binary files
    mktempdir() do dir

        # Test INFOFCF.DEC
        infofcf_path = joinpath(dir, "INFOFCF.DEC")
        test_bytes_info = UInt8[0x01, 0x02, 0x03, 0x04]
        write(infofcf_path, test_bytes_info)

        @testset "INFOFCF Parser" begin
            data = parse_infofcf(infofcf_path)
            @test data isa InfofcfData
            @test length(data.records) == 1
            @test data.records[1].raw_data == test_bytes_info
        end

        # Test MAPCUT.DEC
        mapcut_path = joinpath(dir, "MAPCUT.DEC")
        test_bytes_map = UInt8[0xAA, 0xBB, 0xCC]
        write(mapcut_path, test_bytes_map)

        @testset "MAPCUT Parser" begin
            data = parse_mapcut(mapcut_path)
            @test data isa MapcutData
            @test length(data.records) == 1
            @test data.records[1].raw_data == test_bytes_map
        end

        # Test CORTES.DEC
        cortes_path = joinpath(dir, "CORTES.DEC")
        test_bytes_cortes = UInt8[0xFF, 0x00, 0xFF]
        write(cortes_path, test_bytes_cortes)

        @testset "CORTES Parser" begin
            data = parse_cortes(cortes_path)
            @test data isa CortesData
            @test length(data.records) == 1
            @test data.records[1].raw_data == test_bytes_cortes
        end
    end
end
