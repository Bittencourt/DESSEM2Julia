using Test
using DESSEM2Julia

@testset "FCF Module Tests" begin

    # ====================================================================
    # Test BendersCut and FCFData types
    # ====================================================================
    @testset "BendersCut Type" begin
        cut = BendersCut(
            id = 1,
            stage = 2,
            rhs = 1000.0,
            reservoir_coefficients = Dict(1 => 10.0, 2 => 20.0, 3 => 30.0),
            travel_time_coefficients = [0.5, 0.3],
            gnl_coefficients = [1.0, 2.0],
        )

        @test cut.id == 1
        @test cut.stage == 2
        @test cut.rhs == 1000.0
        @test cut.reservoir_coefficients[1] == 10.0
        @test cut.reservoir_coefficients[2] == 20.0
        @test cut.reservoir_coefficients[3] == 30.0
        @test length(cut.travel_time_coefficients) == 2
        @test length(cut.gnl_coefficients) == 2
    end

    @testset "BendersCut Default Values" begin
        cut = BendersCut()
        @test cut.id == 0
        @test cut.stage == 0
        @test cut.rhs == 0.0
        @test isempty(cut.reservoir_coefficients)
        @test isempty(cut.travel_time_coefficients)
        @test isempty(cut.gnl_coefficients)
    end

    @testset "FCFData Type" begin
        cuts = [
            BendersCut(id = 1, rhs = 100.0, reservoir_coefficients = Dict(1 => 5.0)),
            BendersCut(id = 2, rhs = 200.0, reservoir_coefficients = Dict(1 => 10.0)),
        ]
        fcf = FCFData(
            cuts = cuts,
            reservoir_ids = [1, 2, 3],
            n_stages = 5,
            n_cuts = 2,
            record_length = 1664,
            source_model = :decomp,
        )

        @test length(fcf.cuts) == 2
        @test fcf.reservoir_ids == [1, 2, 3]
        @test fcf.n_stages == 5
        @test fcf.n_cuts == 2
        @test fcf.record_length == 1664
        @test fcf.source_model == :decomp
    end

    @testset "FCFData Default Values" begin
        fcf = FCFData()
        @test isempty(fcf.cuts)
        @test isempty(fcf.reservoir_ids)
        @test fcf.n_stages == 0
        @test fcf.n_cuts == 0
        @test fcf.record_length == 0
        @test fcf.source_model == :decomp
    end

    # ====================================================================
    # Test Mapcut Enhanced Types
    # ====================================================================
    @testset "MapcutGeneralData Type" begin
        gd = MapcutGeneralData(
            numero_iteracoes = Int32(50),
            numero_cortes = Int32(200),
            numero_submercados = Int32(4),
            numero_uhes = Int32(156),
            numero_cenarios = Int32(10),
            registro_ultimo_corte_no = Int32[
                100,
                110,
                120,
                130,
                140,
                150,
                160,
                170,
                180,
                190,
            ],
        )

        @test gd.numero_iteracoes == 50
        @test gd.numero_cortes == 200
        @test gd.numero_submercados == 4
        @test gd.numero_uhes == 156
        @test gd.numero_cenarios == 10
        @test length(gd.registro_ultimo_corte_no) == 10
    end

    @testset "MapcutCaseData Type" begin
        cd = MapcutCaseData(
            tamanho_corte = Int32(2512),
            dia_inicio = Int32(15),
            mes_inicio = Int32(10),
            ano_inicio = Int32(2025),
        )

        @test cd.tamanho_corte == 2512
        @test cd.dia_inicio == 15
        @test cd.mes_inicio == 10
        @test cd.ano_inicio == 2025
    end

    @testset "MapcutStageData Type" begin
        sd = MapcutStageData(
            numero_estagios = Int32(7),
            numero_semanas = Int32(5),
            numero_uhes_tempo_viagem = Int32(3),
            maximo_lag_tempo_viagem = Int32(2),
            indice_primeiro_no_estagio = Int32[1, 2, 4, 8, 16, 32, 64],
            patamares_por_estagio = Int32[3, 3, 3, 3, 3, 3, 3],
        )

        @test sd.numero_estagios == 7
        @test sd.numero_semanas == 5
        @test sd.numero_uhes_tempo_viagem == 3
        @test sd.maximo_lag_tempo_viagem == 2
        @test length(sd.indice_primeiro_no_estagio) == 7
        @test length(sd.patamares_por_estagio) == 7
    end

    # ====================================================================
    # Test evaluate_fcf
    # ====================================================================
    @testset "evaluate_fcf Basic" begin
        # Two cuts:
        # Cut 1: α₀ = 100, π₁ = 2, π₂ = 3
        # Cut 2: α₀ = 50,  π₁ = 5, π₂ = 1
        cuts = [
            BendersCut(
                id = 1,
                rhs = 100.0,
                reservoir_coefficients = Dict(1 => 2.0, 2 => 3.0),
            ),
            BendersCut(
                id = 2,
                rhs = 50.0,
                reservoir_coefficients = Dict(1 => 5.0, 2 => 1.0),
            ),
        ]
        fcf = FCFData(cuts = cuts, reservoir_ids = [1, 2], n_cuts = 2)

        # At V₁=10, V₂=20:
        # Cut 1: 100 + 2*10 + 3*20 = 100 + 20 + 60 = 180
        # Cut 2: 50 + 5*10 + 1*20 = 50 + 50 + 20 = 120
        # Max = 180, active cut = 1
        cost, active = evaluate_fcf(fcf, Dict(1 => 10.0, 2 => 20.0))
        @test cost ≈ 180.0
        @test active == 1

        # At V₁=30, V₂=5:
        # Cut 1: 100 + 2*30 + 3*5 = 100 + 60 + 15 = 175
        # Cut 2: 50 + 5*30 + 1*5 = 50 + 150 + 5 = 205
        # Max = 205, active cut = 2
        cost2, active2 = evaluate_fcf(fcf, Dict(1 => 30.0, 2 => 5.0))
        @test cost2 ≈ 205.0
        @test active2 == 2
    end

    @testset "evaluate_fcf Empty" begin
        fcf = FCFData()
        cost, active = evaluate_fcf(fcf, Dict(1 => 10.0))
        @test cost == 0.0
        @test active == 0
    end

    @testset "evaluate_fcf Missing Volumes" begin
        # When a reservoir volume is not provided, it defaults to 0.0
        cuts = [
            BendersCut(
                id = 1,
                rhs = 100.0,
                reservoir_coefficients = Dict(1 => 2.0, 2 => 3.0),
            ),
        ]
        fcf = FCFData(cuts = cuts, reservoir_ids = [1, 2], n_cuts = 1)

        # Only provide volume for reservoir 1
        cost, active = evaluate_fcf(fcf, Dict(1 => 10.0))
        @test cost ≈ 120.0  # 100 + 2*10 + 3*0
        @test active == 1
    end

    @testset "evaluate_fcf Single Cut" begin
        cuts = [BendersCut(id = 1, rhs = 500.0, reservoir_coefficients = Dict(1 => -1.5))]
        fcf = FCFData(cuts = cuts, reservoir_ids = [1], n_cuts = 1)

        cost, active = evaluate_fcf(fcf, Dict(1 => 100.0))
        @test cost ≈ 350.0  # 500 + (-1.5)*100
        @test active == 1
    end

    @testset "evaluate_fcf Negative Coefficients" begin
        # Water values are typically negative (more water → lower future cost)
        cuts = [
            BendersCut(
                id = 1,
                rhs = 10000.0,
                reservoir_coefficients = Dict(1 => -50.0, 2 => -30.0),
            ),
            BendersCut(
                id = 2,
                rhs = 8000.0,
                reservoir_coefficients = Dict(1 => -20.0, 2 => -10.0),
            ),
        ]
        fcf = FCFData(cuts = cuts, reservoir_ids = [1, 2], n_cuts = 2)

        # At V₁=100, V₂=50:
        # Cut 1: 10000 - 50*100 - 30*50 = 10000 - 5000 - 1500 = 3500
        # Cut 2: 8000 - 20*100 - 10*50 = 8000 - 2000 - 500 = 5500
        cost, active = evaluate_fcf(fcf, Dict(1 => 100.0, 2 => 50.0))
        @test cost ≈ 5500.0
        @test active == 2
    end

    # ====================================================================
    # Test water_value
    # ====================================================================
    @testset "water_value Basic" begin
        cuts = [
            BendersCut(
                id = 1,
                rhs = 100.0,
                reservoir_coefficients = Dict(1 => 2.0, 2 => 3.0),
            ),
            BendersCut(
                id = 2,
                rhs = 50.0,
                reservoir_coefficients = Dict(1 => 5.0, 2 => 1.0),
            ),
        ]
        fcf = FCFData(cuts = cuts, reservoir_ids = [1, 2], n_cuts = 2)

        # At V₁=10, V₂=20: active cut is 1
        wv1 = water_value(fcf, Dict(1 => 10.0, 2 => 20.0), 1)
        @test wv1 ≈ 2.0

        wv2 = water_value(fcf, Dict(1 => 10.0, 2 => 20.0), 2)
        @test wv2 ≈ 3.0

        # At V₁=30, V₂=5: active cut is 2
        wv1_b = water_value(fcf, Dict(1 => 30.0, 2 => 5.0), 1)
        @test wv1_b ≈ 5.0

        wv2_b = water_value(fcf, Dict(1 => 30.0, 2 => 5.0), 2)
        @test wv2_b ≈ 1.0
    end

    @testset "water_value Missing Reservoir" begin
        cuts = [BendersCut(id = 1, rhs = 100.0, reservoir_coefficients = Dict(1 => 2.0))]
        fcf = FCFData(cuts = cuts, reservoir_ids = [1], n_cuts = 1)

        # Reservoir 999 doesn't exist → returns 0.0
        wv = water_value(fcf, Dict(1 => 10.0), 999)
        @test wv == 0.0
    end

    @testset "water_value Empty FCF" begin
        fcf = FCFData()
        wv = water_value(fcf, Dict(1 => 10.0), 1)
        @test wv == 0.0
    end

    # ====================================================================
    # Test water_values (all at once)
    # ====================================================================
    @testset "water_values Basic" begin
        cuts = [
            BendersCut(
                id = 1,
                rhs = 100.0,
                reservoir_coefficients = Dict(1 => 2.0, 2 => 3.0),
            ),
            BendersCut(
                id = 2,
                rhs = 50.0,
                reservoir_coefficients = Dict(1 => 5.0, 2 => 1.0),
            ),
        ]
        fcf = FCFData(cuts = cuts, reservoir_ids = [1, 2], n_cuts = 2)

        # At V₁=10, V₂=20: active cut is 1
        wvs = water_values(fcf, Dict(1 => 10.0, 2 => 20.0))
        @test wvs[1] ≈ 2.0
        @test wvs[2] ≈ 3.0

        # At V₁=30, V₂=5: active cut is 2
        wvs2 = water_values(fcf, Dict(1 => 30.0, 2 => 5.0))
        @test wvs2[1] ≈ 5.0
        @test wvs2[2] ≈ 1.0
    end

    @testset "water_values Empty FCF" begin
        fcf = FCFData()
        wvs = water_values(fcf, Dict(1 => 10.0))
        @test isempty(wvs)
    end

    # ====================================================================
    # Test build_fcf_from_cuts
    # ====================================================================
    @testset "build_fcf_from_cuts" begin
        # Create raw FCFCutsData with 2 cuts and 3 UHEs
        raw_cuts = FCFCutsData(
            cortes = [
                FCFCut(
                    indice_corte = Int32(1),
                    iteracao_construcao = Int32(1),
                    indice_forward = Int32(1),
                    iteracao_desativacao = Int32(0),
                    rhs = 1000.0,
                    coeficientes = [10.0, 20.0, 30.0, 0.5, 0.3],  # 3 water values + 2 other
                ),
                FCFCut(
                    indice_corte = Int32(2),
                    iteracao_construcao = Int32(2),
                    indice_forward = Int32(2),
                    iteracao_desativacao = Int32(0),
                    rhs = 2000.0,
                    coeficientes = [15.0, 25.0, 35.0, 0.6, 0.4],
                ),
            ],
            tamanho_registro = 1664,
            numero_total_cortes = 2,
            codigos_uhes = [101, 102, 103],
        )

        reservoir_ids = [101, 102, 103]
        fcf = build_fcf_from_cuts(raw_cuts, reservoir_ids)

        @test fcf isa FCFData
        @test length(fcf.cuts) == 2
        @test fcf.reservoir_ids == [101, 102, 103]
        @test fcf.n_cuts == 2
        @test fcf.source_model == :decomp

        # Check first cut
        @test fcf.cuts[1].id == 1
        @test fcf.cuts[1].rhs == 1000.0
        @test fcf.cuts[1].reservoir_coefficients[101] ≈ 10.0
        @test fcf.cuts[1].reservoir_coefficients[102] ≈ 20.0
        @test fcf.cuts[1].reservoir_coefficients[103] ≈ 30.0

        # Check second cut
        @test fcf.cuts[2].id == 2
        @test fcf.cuts[2].rhs == 2000.0
        @test fcf.cuts[2].reservoir_coefficients[101] ≈ 15.0
        @test fcf.cuts[2].reservoir_coefficients[102] ≈ 25.0
        @test fcf.cuts[2].reservoir_coefficients[103] ≈ 35.0
    end

    @testset "build_fcf_from_cuts Zero Coefficients Excluded" begin
        raw_cuts = FCFCutsData(
            cortes = [
                FCFCut(
                    indice_corte = Int32(1),
                    iteracao_construcao = Int32(1),
                    indice_forward = Int32(1),
                    iteracao_desativacao = Int32(0),
                    rhs = 500.0,
                    coeficientes = [10.0, 0.0, 30.0],
                ),
            ],
            tamanho_registro = 40,
            numero_total_cortes = 1,
        )

        fcf = build_fcf_from_cuts(raw_cuts, [1, 2, 3])

        # Reservoir 2 has coefficient 0.0 → should not be in dict
        @test haskey(fcf.cuts[1].reservoir_coefficients, 1)
        @test !haskey(fcf.cuts[1].reservoir_coefficients, 2)
        @test haskey(fcf.cuts[1].reservoir_coefficients, 3)
    end

    @testset "build_fcf_from_cuts Empty" begin
        raw_cuts = FCFCutsData()
        fcf = build_fcf_from_cuts(raw_cuts, Int[])
        @test isempty(fcf.cuts)
        @test fcf.n_cuts == 0
    end

    # ====================================================================
    # Test parse_mapcut_enhanced with synthetic binary files
    # ====================================================================
    @testset "parse_mapcut_enhanced Synthetic" begin
        mktempdir() do tmpdir
            mapcut_path = joinpath(tmpdir, "mapcut.rv2")

            # Create a synthetic mapcut binary file
            open(mapcut_path, "w") do io
                # Record 1: General data (at offset 0)
                # 5 Int32: iterations, cuts, submarkets, uhes, scenarios
                write(io, Int32(25))   # numero_iteracoes
                write(io, Int32(100))  # numero_cortes
                write(io, Int32(4))    # numero_submercados
                write(io, Int32(5))    # numero_uhes
                write(io, Int32(3))    # numero_cenarios
                # 3 Int32: registro_ultimo_corte for each scenario
                write(io, Int32(90))
                write(io, Int32(95))
                write(io, Int32(100))

                # Pad to REGISTER_SIZE (48020 bytes)
                # Already wrote 8 Int32 = 32 bytes
                write(io, zeros(UInt8, 48020 - 32))

                # Record 2: Case data (at offset 48020)
                write(io, Int32(1664))  # tamanho_corte
                write(io, Int32(15))    # dia_inicio
                write(io, Int32(10))    # mes_inicio
                write(io, Int32(2025))  # ano_inicio
                write(io, zeros(UInt8, 48020 - 16))

                # Record 3: UHE codes (at offset 2*48020)
                write(io, Int32(1))
                write(io, Int32(6))
                write(io, Int32(11))
                write(io, Int32(14))
                write(io, Int32(24))
                write(io, zeros(UInt8, 48020 - 20))
            end

            general, case_data, uhes, stage_data = parse_mapcut_enhanced(mapcut_path)

            @test general.numero_iteracoes == 25
            @test general.numero_cortes == 100
            @test general.numero_submercados == 4
            @test general.numero_uhes == 5
            @test general.numero_cenarios == 3
            @test general.registro_ultimo_corte_no == Int32[90, 95, 100]

            @test case_data.tamanho_corte == 1664
            @test case_data.dia_inicio == 15
            @test case_data.mes_inicio == 10
            @test case_data.ano_inicio == 2025

            @test uhes == Int32[1, 6, 11, 14, 24]
        end
    end

    @testset "parse_mapcut_enhanced Empty File" begin
        mktempdir() do tmpdir
            empty_path = joinpath(tmpdir, "empty.bin")
            touch(empty_path)

            general, case_data, uhes, stage_data = parse_mapcut_enhanced(empty_path)
            @test general.numero_iteracoes == 0
            @test general.numero_uhes == 0
            @test isempty(uhes)
        end
    end

    # ====================================================================
    # Test parse_fcf with synthetic binary files
    # ====================================================================
    @testset "parse_fcf End-to-End" begin
        mktempdir() do tmpdir
            mapcut_path = joinpath(tmpdir, "mapcut.rv2")
            cortdeco_path = joinpath(tmpdir, "cortdeco.rv2")

            num_uhes = 3
            record_size = 16 + (1 + num_uhes) * 8  # header + (RHS + 3 coefficients) * 8 bytes = 48

            # Create mapcut
            open(mapcut_path, "w") do io
                # Record 1: General data
                write(io, Int32(10))   # iterations
                write(io, Int32(2))    # cuts
                write(io, Int32(4))    # submarkets
                write(io, Int32(num_uhes))  # uhes
                write(io, Int32(1))    # scenarios
                write(io, Int32(2))    # ultimo corte for scenario 1
                write(io, zeros(UInt8, 48020 - 24))

                # Record 2: Case data
                write(io, Int32(record_size))  # tamanho_corte
                write(io, Int32(1))    # dia
                write(io, Int32(1))    # mes
                write(io, Int32(2025)) # ano
                write(io, zeros(UInt8, 48020 - 16))

                # Record 3: UHE codes
                write(io, Int32(1))    # UHE 1
                write(io, Int32(6))    # UHE 6
                write(io, Int32(14))   # UHE 14
                write(io, zeros(UInt8, 48020 - 12))
            end

            # Create cortdeco with 2 linked-list cuts
            open(cortdeco_path, "w") do io
                # Cut 1 (index 1): no previous cut
                write(io, Int32(0))   # pointer to previous (0 = none)
                write(io, Int32(1))   # iteracao_construcao
                write(io, Int32(1))   # indice_forward
                write(io, Int32(0))   # iteracao_desativacao (active)
                write(io, Float64(5000.0))  # RHS
                write(io, Float64(-10.0))   # pi for UHE 1
                write(io, Float64(-20.0))   # pi for UHE 6
                write(io, Float64(-30.0))   # pi for UHE 14

                # Cut 2 (index 2): points to cut 1
                write(io, Int32(1))   # pointer to previous (cut 1)
                write(io, Int32(2))   # iteracao_construcao
                write(io, Int32(2))   # indice_forward
                write(io, Int32(0))   # iteracao_desativacao (active)
                write(io, Float64(3000.0))  # RHS
                write(io, Float64(-5.0))    # pi for UHE 1
                write(io, Float64(-15.0))   # pi for UHE 6
                write(io, Float64(-25.0))   # pi for UHE 14
            end

            fcf = parse_fcf(mapcut_path, cortdeco_path)

            @test fcf isa FCFData
            @test length(fcf.cuts) == 2
            @test fcf.reservoir_ids == [1, 6, 14]
            @test fcf.source_model == :decomp

            # Verify cut 1 (first chronologically)
            @test fcf.cuts[1].rhs == 5000.0
            @test fcf.cuts[1].reservoir_coefficients[1] ≈ -10.0
            @test fcf.cuts[1].reservoir_coefficients[6] ≈ -20.0
            @test fcf.cuts[1].reservoir_coefficients[14] ≈ -30.0

            # Verify cut 2
            @test fcf.cuts[2].rhs == 3000.0
            @test fcf.cuts[2].reservoir_coefficients[1] ≈ -5.0
            @test fcf.cuts[2].reservoir_coefficients[6] ≈ -15.0
            @test fcf.cuts[2].reservoir_coefficients[14] ≈ -25.0

            # Evaluate FCF at specific volumes
            # Cut 1: 5000 + (-10)*50 + (-20)*30 + (-30)*40 = 5000 - 500 - 600 - 1200 = 2700
            # Cut 2: 3000 + (-5)*50 + (-15)*30 + (-25)*40 = 3000 - 250 - 450 - 1000 = 1300
            # Max = 2700, active = 1
            cost, active = evaluate_fcf(fcf, Dict(1 => 50.0, 6 => 30.0, 14 => 40.0))
            @test cost ≈ 2700.0
            @test active == 1

            # Water value at this point
            wv_1 = water_value(fcf, Dict(1 => 50.0, 6 => 30.0, 14 => 40.0), 1)
            @test wv_1 ≈ -10.0

            wv_6 = water_value(fcf, Dict(1 => 50.0, 6 => 30.0, 14 => 40.0), 6)
            @test wv_6 ≈ -20.0

            wv_14 = water_value(fcf, Dict(1 => 50.0, 6 => 30.0, 14 => 40.0), 14)
            @test wv_14 ≈ -30.0
        end
    end

    # ====================================================================
    # Test edge cases for FCF evaluation
    # ====================================================================
    @testset "evaluate_fcf Many Cuts" begin
        # Create 100 cuts with varying coefficients
        cuts = BendersCut[]
        for k in 1:100
            push!(
                cuts,
                BendersCut(
                    id = k,
                    rhs = Float64(k * 100),
                    reservoir_coefficients = Dict(1 => Float64(k), 2 => Float64(-k * 0.5)),
                ),
            )
        end
        fcf = FCFData(cuts = cuts, reservoir_ids = [1, 2], n_cuts = 100)

        # At V₁=10, V₂=20:
        # Cut k: k*100 + k*10 + (-k*0.5)*20 = k*100 + k*10 - k*10 = k*100
        # Max at k=100: 10000
        cost, active = evaluate_fcf(fcf, Dict(1 => 10.0, 2 => 20.0))
        @test cost ≈ 10000.0
        @test active == 100
    end

    @testset "evaluate_fcf All Zeros" begin
        cuts = [BendersCut(id = 1, rhs = 0.0, reservoir_coefficients = Dict{Int,Float64}())]
        fcf = FCFData(cuts = cuts, reservoir_ids = Int[], n_cuts = 1)

        cost, active = evaluate_fcf(fcf, Dict(1 => 100.0))
        @test cost ≈ 0.0
        @test active == 1
    end

    @testset "water_value Switches Active Cut" begin
        # Design cuts so different volumes activate different cuts
        cuts = [
            BendersCut(id = 1, rhs = 1000.0, reservoir_coefficients = Dict(1 => -10.0)),
            BendersCut(id = 2, rhs = 500.0, reservoir_coefficients = Dict(1 => -2.0)),
        ]
        fcf = FCFData(cuts = cuts, reservoir_ids = [1], n_cuts = 2)

        # At V₁=0: Cut 1 = 1000, Cut 2 = 500 → active = 1, wv = -10
        wv_low = water_value(fcf, Dict(1 => 0.0), 1)
        @test wv_low ≈ -10.0

        # At V₁=80: Cut 1 = 1000-800=200, Cut 2 = 500-160=340 → active = 2, wv = -2
        wv_high = water_value(fcf, Dict(1 => 80.0), 1)
        @test wv_high ≈ -2.0
    end
end
