using Test
using DESSEM2Julia

@testset "INFOFCF Parser Tests" begin
    @testset "Parse TVIAG Record" begin
        # Test MAPFCF TVIAG parsing
        line = "MAPFCF  TVIAG     1 156"
        io = IOBuffer(line)
        data = parse_infofcf_dat(io, "test")

        @test length(data.tviag) == 1
        @test data.tviag[1].index == 1
        @test data.tviag[1].plant_code == 156
    end

    @testset "Parse SISGNL Record" begin
        # Test MAPFCF SISGNL parsing
        line = "MAPFCF  SISGNL   1   1   2   3"
        io = IOBuffer(line)
        data = parse_infofcf_dat(io, "test")

        @test length(data.sisgnl) == 1
        @test data.sisgnl[1].index == 1
        @test data.sisgnl[1].subsystem == 1
        @test data.sisgnl[1].num_lags == 2
        @test data.sisgnl[1].num_patterns == 3
    end

    @testset "Parse DURPAT Record" begin
        # Test MAPFCF DURPAT parsing
        line = "MAPFCF  DURPAT   2   1      172.84"
        io = IOBuffer(line)
        data = parse_infofcf_dat(io, "test")

        @test length(data.durpat) == 1
        @test data.durpat[1].lag == 2
        @test data.durpat[1].pattern == 1
        @test data.durpat[1].duration ≈ 172.84
    end

    @testset "Parse FCFFIX Record" begin
        # Test FCFFIX parsing
        line = "FCFFIX USIT    86 GTERF    2   1     500.00 Usina termica GNL."
        io = IOBuffer(line)
        data = parse_infofcf_dat(io, "test")

        @test length(data.fcffix) == 1
        @test data.fcffix[1].entity_type == "USIT"
        @test data.fcffix[1].entity_id == 86
        @test data.fcffix[1].variable_type == "GTERF"
        @test data.fcffix[1].lag == 2
        @test data.fcffix[1].pattern == 1
        @test data.fcffix[1].value ≈ 500.00
        @test occursin("GNL", data.fcffix[1].justification)
    end

    @testset "Skip Comments and Empty Lines" begin
        content = """
        &===========================================================================
        &Usinas com tempo de viagem
        &
        MAPFCF  TVIAG     1 156
        """
        io = IOBuffer(content)
        data = parse_infofcf_dat(io, "test")

        @test length(data.tviag) == 1
        @test data.tviag[1].plant_code == 156
    end

    @testset "Parse Complete Sample Content" begin
        content = """
        &===========================================================================
        &Usinas com tempo de viagem
        &
        &       Mnem    Ind Num
        &XXXXX  XXXXXXX XXX XXX
        MAPFCF  TVIAG     1 156
        MAPFCF  TVIAG     2 162
        &
        &===========================================================================
        &Subsistemas com usinas termicas a GNL na FCF
        &
        &       Mnem   Ind Num Nlag Npat
        &XXXXX  XXXXXX XXX XXX XXX XXX
        MAPFCF  SISGNL   1   1   2   3
        MAPFCF  SISGNL   2   3   2   3
        &
        &===========================================================================
        &Duracoes dos patamares de carga para os periodos futuros na FCF
        &
        &       Mnem   Lag Pat    Dur (h)
        &XXXXX  XXXXXX XXX XXX  XXXXXXXXXX
        MAPFCF  DURPAT   2   1      172.84
        MAPFCF  DURPAT   2   2      256.26
        MAPFCF  DURPAT   2   3      301.40
        &
        &===========================================================================
        & Abatimentos futuros na FCF (GNL)
        &
        &      TpEnt IdEnt IdVar lag Pat    Valor        Justificativa
        XXXXXX XXXXXX XXX XXXXXX XXX XXX XXXXXXXXXX XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
        FCFFIX USIT    86 GTERF    2   1     500.00 Usina termica GNL.
        FCFFIX USIT    86 GTERF    2   2     500.00 Usina termica GNL.
        &
        """
        io = IOBuffer(content)
        data = parse_infofcf_dat(io, "test")

        @test length(data.tviag) == 2
        @test length(data.sisgnl) == 2
        @test length(data.durpat) == 3
        @test length(data.fcffix) == 2

        # Check specific values
        @test data.tviag[1].plant_code == 156
        @test data.tviag[2].plant_code == 162

        @test data.sisgnl[1].subsystem == 1
        @test data.sisgnl[2].subsystem == 3

        @test data.durpat[1].duration ≈ 172.84
        @test data.durpat[2].duration ≈ 256.26
        @test data.durpat[3].duration ≈ 301.40

        @test data.fcffix[1].value ≈ 500.00
        @test data.fcffix[2].value ≈ 500.00
    end

    @testset "Real ONS Data" begin
        filepath = joinpath(
            @__DIR__,
            "..",
            "docs",
            "Sample",
            "DS_ONS_102025_RV2D11",
            "infofcf.dat",
        )
        if isfile(filepath)
            data = parse_infofcf_dat(filepath)

            # Check that we parsed data
            @test length(data.tviag) > 0
            @test length(data.sisgnl) > 0
            @test length(data.durpat) > 0
            @test length(data.fcffix) > 0

            # Check known values from the sample file
            @test data.tviag[1].index == 1
            @test data.tviag[1].plant_code == 156
            @test data.tviag[2].plant_code == 162

            @test data.sisgnl[1].num_lags == 2
            @test data.sisgnl[1].num_patterns == 3

            println("\n📊 INFOFCF.DAT ONS Sample Statistics:")
            println("  Travel time plants: $(length(data.tviag))")
            println("  GNL subsystems: $(length(data.sisgnl))")
            println("  Pattern durations: $(length(data.durpat))")
            println("  Fixed future values: $(length(data.fcffix))")

            # Print some details
            println("\n  Travel time plants:")
            for t in data.tviag
                println("    Index $(t.index): Plant $(t.plant_code)")
            end

            println("\n  GNL Subsystems:")
            for s in data.sisgnl
                println(
                    "    Index $(s.index): Subsystem $(s.subsystem), Lags=$(s.num_lags), Patterns=$(s.num_patterns)",
                )
            end

            println("\n  First 3 pattern durations:")
            for d in data.durpat[1:min(3, end)]
                println("    Lag $(d.lag), Pattern $(d.pattern): $(d.duration) hours")
            end

            println("\n  First 3 fixed values:")
            for f in data.fcffix[1:min(3, end)]
                println(
                    "    $(f.entity_type) $(f.entity_id) $(f.variable_type): $(f.value) ($(f.justification))",
                )
            end
        else
            @warn "ONS sample file not found: $filepath"
        end
    end
end
