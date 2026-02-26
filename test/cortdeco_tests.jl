using Test
using DESSEM2Julia

@testset "Cortdeco Binary Parser Tests" begin
    @testset "Synthetic Binary File Parsing" begin
        # Create a temporary directory for test files
        mktempdir() do tmpdir
            test_file = joinpath(tmpdir, "cortdeco.rv2")

            # Create a synthetic binary file with 2 cuts
            # Record size: 1664 bytes (standard)
            # Header: 4 × Int32 = 16 bytes
            # Coefficients: (1664-16)÷8 = 206 Float64 values

            open(test_file, "w") do io
                # Cut 1 (index 1, points to nothing - index 0)
                write(io, Int32(0))  # indice_corte_anterior (0 = no previous cut)
                write(io, Int32(1))  # iteracao_construcao
                write(io, Int32(1))  # indice_forward
                write(io, Int32(0))  # iteracao_desativacao (0 = active)

                # RHS and coefficients (206 Float64 values)
                write(io, Float64(1000.0))  # RHS
                for i in 1:205
                    write(io, Float64(i * 0.1))  # Coefficients
                end

                # Cut 2 (index 2, points to cut 1)
                write(io, Int32(1))  # indice_corte_anterior (points to cut 1)
                write(io, Int32(2))  # iteracao_construcao
                write(io, Int32(2))  # indice_forward
                write(io, Int32(0))  # iteracao_desativacao

                # RHS and coefficients
                write(io, Float64(2000.0))  # RHS
                for i in 1:205
                    write(io, Float64(i * 0.2))  # Coefficients
                end
            end

            # Test parsing from last cut (index 2)
            cuts = parse_cortdeco(
                test_file,
                tamanho_registro = 1664,
                indice_ultimo_corte = 2,
                numero_total_cortes = 10,
                codigos_uhes = [1, 2, 3, 4, 5],
            )

            @test cuts isa FCFCutsData
            @test cuts.tamanho_registro == 1664
            @test length(cuts.cortes) == 2
            @test cuts.numero_total_cortes == 2

            # Verify cuts are in chronological order (reversed from linked list)
            @test cuts.cortes[1].indice_corte == 1
            @test cuts.cortes[1].rhs == 1000.0
            @test cuts.cortes[1].iteracao_construcao == 1
            @test cuts.cortes[1].iteracao_desativacao == 0
            @test length(cuts.cortes[1].coeficientes) == 205

            @test cuts.cortes[2].indice_corte == 2
            @test cuts.cortes[2].rhs == 2000.0
            @test cuts.cortes[2].iteracao_construcao == 2
            @test length(cuts.cortes[2].coeficientes) == 205

            # Verify coefficient values
            @test cuts.cortes[1].coeficientes[1] ≈ 0.1
            @test cuts.cortes[1].coeficientes[10] ≈ 1.0
            @test cuts.cortes[2].coeficientes[1] ≈ 0.2
            @test cuts.cortes[2].coeficientes[10] ≈ 2.0
        end
    end

    @testset "Water Value Calculation" begin
        mktempdir() do tmpdir
            test_file = joinpath(tmpdir, "cortdeco.rv2")

            # Create 3 cuts with known water values for plant codes [1, 2, 3]
            # Water values will be at coefficients[1:3]
            # Total: 1 RHS + 205 coefficients (3 water values + 202 other)
            open(test_file, "w") do io
                # Cut 1
                write(io, Int32(0))  # No previous cut
                write(io, Int32(1), Int32(1), Int32(0))
                write(io, Float64(1000.0))  # RHS
                write(io, Float64(10.0), Float64(20.0), Float64(30.0))  # Water values for plants 1,2,3
                for i in 1:202  # Remaining 202 coefficients
                    write(io, Float64(i * 0.1))
                end

                # Cut 2
                write(io, Int32(1))  # Points to cut 1
                write(io, Int32(2), Int32(2), Int32(0))
                write(io, Float64(2000.0))
                write(io, Float64(15.0), Float64(25.0), Float64(35.0))  # Water values
                for i in 1:202
                    write(io, Float64(i * 0.1))
                end

                # Cut 3
                write(io, Int32(2))  # Points to cut 2
                write(io, Int32(3), Int32(3), Int32(0))
                write(io, Float64(3000.0))
                write(io, Float64(20.0), Float64(30.0), Float64(40.0))  # Water values
                for i in 1:202
                    write(io, Float64(i * 0.1))
                end
            end

            cuts =
                parse_cortdeco(test_file, indice_ultimo_corte = 3, codigos_uhes = [1, 2, 3])

            @test length(cuts.cortes) == 3

            # Test water value for plant 1 (average of 10, 15, 20)
            wv1 = get_water_value(cuts, 1)
            @test wv1 ≈ 15.0

            # Test water value for plant 2 (average of 20, 25, 30)
            wv2 = get_water_value(cuts, 2)
            @test wv2 ≈ 25.0

            # Test water value for plant 3 (average of 30, 35, 40)
            wv3 = get_water_value(cuts, 3)
            @test wv3 ≈ 35.0

            # Test error for non-existent plant
            @test_throws DESSEM2Julia.ParserCommon.ParserError get_water_value(cuts, 999)
        end
    end

    @testset "Active/Inactive Cuts" begin
        mktempdir() do tmpdir
            test_file = joinpath(tmpdir, "cortdeco.rv2")

            # Create cuts with mixed active/inactive status
            open(test_file, "w") do io
                # Cut 1 - Active (iteracao_desativacao = 0)
                write(io, Int32(0), Int32(1), Int32(1), Int32(0))
                write(io, Float64(1000.0))
                for i in 1:205
                    write(io, Float64(i))
                end

                # Cut 2 - Inactive (iteracao_desativacao = 5)
                write(io, Int32(1), Int32(2), Int32(2), Int32(5))
                write(io, Float64(2000.0))
                for i in 1:205
                    write(io, Float64(i))
                end

                # Cut 3 - Active
                write(io, Int32(2), Int32(3), Int32(3), Int32(0))
                write(io, Float64(3000.0))
                for i in 1:205
                    write(io, Float64(i))
                end
            end

            cuts = parse_cortdeco(test_file, indice_ultimo_corte = 3)

            @test length(cuts.cortes) == 3

            # Test active cuts filter
            active = get_active_cuts(cuts)
            @test length(active) == 2
            @test active[1].indice_corte == 1
            @test active[2].indice_corte == 3

            # Test statistics
            stats = get_cut_statistics(cuts)
            @test stats["total_cuts"] == 3
            @test stats["active_cuts"] == 2
            @test stats["inactive_cuts"] == 1
            @test stats["avg_rhs"] ≈ 2000.0
            @test stats["min_rhs"] == 1000.0
            @test stats["max_rhs"] == 3000.0
            @test stats["num_coefficients"] == 205
        end
    end

    @testset "Empty File Handling" begin
        mktempdir() do tmpdir
            empty_file = joinpath(tmpdir, "empty.rv2")
            touch(empty_file)

            cuts = parse_cortdeco(empty_file)

            @test cuts isa FCFCutsData
            @test isempty(cuts.cortes)
            @test cuts.numero_total_cortes == 0

            # Test statistics on empty cuts
            stats = get_cut_statistics(cuts)
            @test stats["total_cuts"] == 0
            @test stats["active_cuts"] == 0
            @test stats["inactive_cuts"] == 0
        end
    end

    @testset "Custom Record Size" begin
        mktempdir() do tmpdir
            test_file = joinpath(tmpdir, "custom.rv2")

            # Use a smaller record size for testing
            record_size = 40  # 16 header + 24 data (3 Float64)
            num_coef = (record_size - 16) ÷ 8

            open(test_file, "w") do io
                write(io, Int32(0), Int32(1), Int32(1), Int32(0))
                write(io, Float64(100.0))  # RHS
                write(io, Float64(1.0), Float64(2.0))  # 2 coefficients
            end

            cuts = parse_cortdeco(
                test_file,
                tamanho_registro = record_size,
                indice_ultimo_corte = 1,
            )

            @test length(cuts.cortes) == 1
            @test cuts.cortes[1].rhs == 100.0
            @test length(cuts.cortes[1].coeficientes) == 2
            @test cuts.cortes[1].coeficientes[1] == 1.0
            @test cuts.cortes[1].coeficientes[2] == 2.0
        end
    end

    @testset "Configuration Parameters" begin
        # Test that configuration parameters are stored correctly
        # Note: Using non-existent file tests initialization only
        mktempdir() do tmpdir
            empty_file = joinpath(tmpdir, "empty.rv2")
            touch(empty_file)

            cuts = parse_cortdeco(
                empty_file,
                tamanho_registro = 1664,
                codigos_rees = [1, 2, 3],
                codigos_uhes = [10, 20, 30, 40],
                codigos_submercados = [1, 2, 3, 4],
                ordem_maxima_parp = 12,
                numero_patamares_carga = 3,
                lag_maximo_gnl = 2,
            )

            @test cuts.tamanho_registro == 1664
            @test cuts.codigos_rees == [1, 2, 3]
            @test cuts.codigos_uhes == [10, 20, 30, 40]
            @test cuts.codigos_submercados == [1, 2, 3, 4]
            @test cuts.ordem_maxima_parp == 12
            @test cuts.numero_patamares_carga == 3
            @test cuts.lag_maximo_gnl == 2
        end
    end
end
