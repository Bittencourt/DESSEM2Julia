using Test
using DESSEM2Julia
using DESSEM2Julia:
    parse_infofcf, parse_mapcut, parse_cortes, InfofcfData, MapcutData, CortesData, MapcutHeader

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

    @testset "MAPCUT Parser" begin
        mktempdir() do dir
            # Test 1: Synthetic binary file with known structure
            @testset "Synthetic binary file" begin
                mapcut_path = joinpath(dir, "mapcut_test.bin")

                # Create a synthetic file with:
                # - 3 stages
                # - 5 REEs
                # - [2, 3, 2] cuts per stage (7 total)
                # - Each record has 3 Int32 (stage, ree, cut) + 5 Float64 coefficients

                open(mapcut_path, "w") do io
                    # Write header
                    write(io, Int32(3))  # num_estagios
                    write(io, Int32(5))  # num_rees
                    write(io, Int32(2))  # cuts in stage 1
                    write(io, Int32(3))  # cuts in stage 2
                    write(io, Int32(2))  # cuts in stage 3

                    # Write 7 records
                    for stage in 1:3
                        cuts_this_stage = [2, 3, 2][stage]
                        for cut in 1:cuts_this_stage
                            write(io, Int32(stage))        # stage_idx
                            write(io, Int32(1))            # ree_idx (simplified)
                            write(io, Int32(cut))          # cut_idx
                            # 5 Float64 coefficients
                            for coef_idx in 1:5
                                write(io, Float64(coef_idx * 0.1 * stage * cut))
                            end
                        end
                    end
                end

                # Parse and verify
                data = parse_mapcut(mapcut_path)

                # Verify header
                @test data isa MapcutData
                @test data.header isa MapcutHeader
                @test data.header.num_estagios == 3
                @test data.header.num_rees == 5
                @test data.header.cortes_por_estagio == Int32[2, 3, 2]

                # Verify total cuts
                @test data.total_cuts == 7

                # Verify records
                @test length(data.records) == 7

                # Check first record
                first_record = data.records[1]
                @test first_record.stage_idx == 1
                @test first_record.ree_idx == 1
                @test first_record.cut_idx == 1
                @test length(first_record.coeficientes) == 5
                @test first_record.coeficientes[1] ≈ 0.1
            end

            # Test 2: Header parsing edge cases
            @testset "Header parsing" begin
                # Empty file
                empty_path = joinpath(dir, "empty.bin")
                write(empty_path, UInt8[])
                empty_data = parse_mapcut(empty_path)
                @test empty_data.header.num_estagios == 0
                @test empty_data.total_cuts == 0

                # Minimal header (1 stage, 1 REE, 0 cuts)
                minimal_path = joinpath(dir, "minimal.bin")
                open(minimal_path, "w") do io
                    write(io, Int32(1))  # num_estagios
                    write(io, Int32(1))  # num_rees
                    write(io, Int32(0))  # cortes_por_estagio[1] = 0
                end
                minimal_data = parse_mapcut(minimal_path)
                @test minimal_data.header.num_estagios == 1
                @test minimal_data.header.num_rees == 1
                @test minimal_data.header.cortes_por_estagio == Int32[0]
                @test minimal_data.total_cuts == 0
            end

            # Test 3: Real sample files (if available)
            @testset "Real sample files" begin
                # ONS sample
                ons_path = "docs/Sample/DS_ONS_102025_RV3D21/mapcut.rv3"
                if isfile(ons_path)
                    ons_data = parse_mapcut(ons_path)
                    @test ons_data.header.num_estagios == 7
                    @test ons_data.header.num_rees == 14
                    @test length(ons_data.header.cortes_por_estagio) == 7
                    @test ons_data.total_cuts == sum(ons_data.header.cortes_por_estagio)
                else
                    @warn "ONS sample file not found: $ons_path"
                end

                # CCEE sample
                ccee_path = "docs/Sample/DS_CCEE_102025_SEMREDE_RV1D04/mapcut.rv1"
                if isfile(ccee_path)
                    ccee_data = parse_mapcut(ccee_path)
                    @test ccee_data.header.num_estagios == 39
                    @test ccee_data.header.num_rees == 156
                    @test length(ccee_data.header.cortes_por_estagio) == 39
                    @test ccee_data.total_cuts == sum(ccee_data.header.cortes_por_estagio)
                else
                    @warn "CCEE sample file not found: $ccee_path"
                end
            end
        end
    end
end
