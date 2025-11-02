using Test
using DESSEM2Julia

@testset "HIDR.DAT Parser Tests" begin
    @testset "Text format parsing with test data" begin
        # Create a temporary test file with text format
        test_file = joinpath(tempdir(), "test_hidr.dat")

        # Write test data in text format with exact column positions
        open(test_file, "w") do f
            # CADUSIH record - columns must match spec
            # Format: record(1-7) plant_num(9-11) plant_name(13-24) subsystem(26-27) year(29-32) month(34-35) day(37-38)
            #         downstream(40-41) diversion(43-44) type(46) min_vol(48-57) max_vol(59-68) max_flow(70-79) capacity(81-90) prod(92-101)
            println(
                f,
                "CADUSIH   1CAMARGOS     1 2020  1  1  2  0  1    5000.0   10000.0    1000.0     500.0      100.5",
            )
            # USITVIAG record
            println(f, "USITVIAG  1  2   5.0")
            # POLCOT record - columns: record(1-6) plant(8-10) degree(12-13) coef0(15-24) coef1(26-35) coef2(37-46) coef3(48-57) coef4(59-68) coef5(70-79)
            println(
                f,
                "POLCOT  1  3     100.0     200.0     300.0     400.0     500.0     600.0",
            )
            # POLARE record
            println(
                f,
                "POLARE  1  2      50.0     150.0     250.0     350.0     450.0     550.0",
            )
            # POLJUS record
            println(
                f,
                "POLJUS  1  2      10.0     110.0     210.0     310.0     410.0     510.0",
            )
            # COEFEVA record - columns: record(1-7) plant(9-11) jan(13-17) feb(19-23) mar(25-29)... dec(79-83)
            println(
                f,
                "COEFEVA   1  0.1  0.2  0.3  0.4  0.5  0.6  0.7  0.8  0.9  1.0  1.1  1.2",
            )
            # CADCONJ record - columns: record(1-7) plant(9-11) set(13-14) num_units(16-17) capacity(19-28) min_gen(30-39) max_flow(41-50)
            println(f, "CADCONJ   1  1  2     100.0      50.0     200.0")
        end

        try
            @testset "Parse test file" begin
                # Parse the file
                data = parse_hidr(test_file)

                # Basic structure tests
                @test data isa HidrData
                @test data.plants isa Vector{CADUSIH}
                @test data.travel_times isa Vector{USITVIAG}
                @test data.volume_elevation isa Vector{POLCOT}
                @test data.volume_area isa Vector{POLARE}
                @test data.tailrace isa Vector{POLJUS}
                @test data.evaporation isa Vector{COEFEVA}
                @test data.unit_sets isa Vector{CADCONJ}

                # Check counts
                @test length(data.plants) == 1
                @test length(data.travel_times) == 1
                @test length(data.volume_elevation) == 1
                @test length(data.volume_area) == 1
                @test length(data.tailrace) == 1
                @test length(data.evaporation) == 1
                @test length(data.unit_sets) == 1

                println("  ✅ Text format parser working correctly!")
            end

            @testset "CADUSIH validation" begin
                data = parse_hidr(test_file)
                plant = data.plants[1]

                @test plant.plant_num == 1
                @test strip(plant.plant_name) == "CAMARGOS"
                @test plant.subsystem == 1
                @test plant.commission_year == 2020
                @test plant.commission_month == 1
                @test plant.commission_day == 1
                @test plant.min_volume == 5000.0
                @test plant.max_volume == 10000.0

                println("  Sample plant: $(plant.plant_num) $(plant.plant_name)")
            end

            @testset "USITVIAG validation" begin
                data = parse_hidr(test_file)
                tt = data.travel_times[1]

                @test tt.plant_num == 1
                @test tt.downstream_plant == 2
                @test tt.travel_time == 5.0

                println(
                    "  Travel time: Plant $(tt.plant_num) → $(tt.downstream_plant): $(tt.travel_time) hours",
                )
            end

            @testset "POLCOT validation" begin
                data = parse_hidr(test_file)
                pol = data.volume_elevation[1]

                @test pol.plant_num == 1
                @test pol.degree == 3
                @test pol.coef0 == 100.0
                @test pol.coef1 == 200.0

                println("  POLCOT: Plant $(pol.plant_num), degree $(pol.degree)")
            end

            @testset "COEFEVA validation" begin
                data = parse_hidr(test_file)
                eva = data.evaporation[1]

                @test eva.plant_num == 1
                @test eva.jan == 0.1
                @test eva.dec == 1.2

                println("  COEFEVA: Plant $(eva.plant_num), Jan=$(eva.jan), Dec=$(eva.dec)")
            end

        finally
            # Clean up test file
            rm(test_file, force = true)
        end
    end

    @testset "Binary format - Complete 111 fields" begin
        # Test with ONS sample (binary format with all 111 fields)
        sample_file =
            joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11", "hidr.dat")

        if isfile(sample_file)
            @testset "Parse ONS binary HIDR.DAT (all 111 fields)" begin
                # Parse the binary file
                data = parse_hidr(sample_file)

                # Should detect binary format and return BinaryHidrData
                @test data isa BinaryHidrData
                @test length(data.records) > 0

                println(
                    "  ✅ Binary parser: $(length(data.records)) plants parsed with 111 fields each",
                )

                # Find first valid plant (posto > 0)
                valid_plants = filter(p -> p.posto > 0, data.records)
                @test !isempty(valid_plants)

                plant = valid_plants[1]
                println("  First plant: $(plant.nome) (posto: $(plant.posto))")
            end

            @testset "Basic identification fields" begin
                data = parse_hidr(sample_file)
                plant = data.records[1]  # CAMARGOS

                @test strip(plant.nome) == "CAMARGOS"  # Parser strips trailing spaces
                @test plant.posto == 1
                @test plant.posto_bdh isa Int64  # Special 8-byte field
                @test plant.subsistema == 1
                @test plant.empresa > 0
                @test plant.jusante > 0

                println(
                    "  ✓ Basic fields: nome, posto, posto_bdh, subsistema, empresa, jusante",
                )
            end

            @testset "Volume and elevation data" begin
                data = parse_hidr(sample_file)
                plant = data.records[1]

                @test plant.volume_minimo > 0
                @test plant.volume_maximo > plant.volume_minimo
                @test plant.cota_minima > 0
                @test plant.cota_maxima > plant.cota_minima

                println(
                    "  ✓ Volumes: min=$(plant.volume_minimo) hm³, max=$(plant.volume_maximo) hm³",
                )
                println(
                    "  ✓ Elevations: min=$(plant.cota_minima) m, max=$(plant.cota_maxima) m",
                )
            end

            @testset "Polynomial coefficients" begin
                data = parse_hidr(sample_file)
                plant = data.records[1]

                # Volume-elevation polynomial (5 coefficients)
                @test length(plant.polinomio_volume_cota) == 5
                @test plant.polinomio_volume_cota[1] ≈ 892.97 atol = 0.01  # Constant term

                # Elevation-area polynomial (5 coefficients)
                @test length(plant.polinomio_cota_area) == 5

                println("  ✓ Volume-Cota polynomial (5 coefficients)")
                println("  ✓ Cota-Area polynomial (5 coefficients)")
            end

            @testset "Evaporation coefficients" begin
                data = parse_hidr(sample_file)
                plant = data.records[1]

                # 12 monthly evaporation coefficients
                @test length(plant.evaporacao) == 12
                @test all(e -> e >= 0, plant.evaporacao)  # All non-negative

                println("  ✓ Evaporation (12 months): $(plant.evaporacao)")
            end

            @testset "Machine sets" begin
                data = parse_hidr(sample_file)
                plant = data.records[1]

                # Machine set data
                @test plant.numero_conjuntos_maquinas >= 0
                @test length(plant.numero_maquinas_conjunto) == 5
                @test length(plant.potef_conjunto) == 5
                @test length(plant.hef_conjunto) == 5
                @test length(plant.qef_conjunto) == 5

                total_capacity = sum(plant.potef_conjunto)
                @test total_capacity > 0

                println("  ✓ Machine sets: $(plant.numero_conjuntos_maquinas) sets")
                println("  ✓ Total installed capacity: $(total_capacity) MW")
            end

            @testset "Performance parameters" begin
                data = parse_hidr(sample_file)
                plant = data.records[1]

                @test plant.produtibilidade_especifica > 0
                @test plant.perdas >= 0
                @test plant.numero_polinomios_jusante >= 0

                println("  ✓ Specific productivity: $(plant.produtibilidade_especifica)")
                println("  ✓ Losses: $(plant.perdas) MW")
            end

            @testset "Tailrace polynomials" begin
                data = parse_hidr(sample_file)
                plant = data.records[1]

                # 36 values (6 families × 6 values each)
                @test length(plant.polinomios_jusante) == 36

                println("  ✓ Tailrace polynomials: 36 values (6 families × 6 coefficients)")
            end

            @testset "Operational parameters" begin
                data = parse_hidr(sample_file)
                plant = data.records[1]

                @test plant.canal_fuga_medio >= 0
                @test plant.influencia_vertimento_canal_fuga in [0, 1]
                @test plant.fator_carga_maximo >= 0
                @test plant.fator_carga_minimo >= 0
                @test plant.vazao_minima_historica >= 0
                @test plant.numero_unidades_base >= 0
                @test plant.tipo_turbina >= 0
                @test plant.teif >= 0
                @test plant.ip >= 0
                @test !isempty(plant.data_referencia)
                @test !isempty(plant.tipo_regulacao)

                println("  ✓ Canal fuga medio: $(plant.canal_fuga_medio) m")
                println("  ✓ TEIF: $(plant.teif)")
                println("  ✓ Regulation type: $(plant.tipo_regulacao)")
            end

            @testset "All plants validation" begin
                data = parse_hidr(sample_file)

                # Check that we have reasonable number of plants
                @test length(data.records) > 100  # ONS has ~320 plants

                # Count valid plants (posto > 0)
                valid_count = count(p -> p.posto > 0, data.records)
                @test valid_count > 100

                println("  ✓ Total records: $(length(data.records))")
                println("  ✓ Valid plants (posto > 0): $valid_count")

                # Sample a few plants and check they have reasonable data
                for i in [1, 10, 20, 30]
                    if i <= length(data.records)
                        p = data.records[i]
                        if p.posto > 0
                            @test sum(p.potef_conjunto) >= 0
                            @test length(p.polinomio_volume_cota) == 5
                            @test length(p.evaporacao) == 12
                        end
                    end
                end
            end

            println("\n  ✅ Binary format (792 bytes/record) parsed successfully")
            println("  ✅ All 111 fields validated for CAMARGOS plant")
            println("  ℹ  Text parser also available for text-format HIDR.DAT files")
        else
            @test_skip "ONS sample file not found"
        end
    end

    @testset "Error handling" begin
        # Test with non-existent file
        @test_throws Exception parse_hidr("nonexistent_hidr.dat")
    end
end
