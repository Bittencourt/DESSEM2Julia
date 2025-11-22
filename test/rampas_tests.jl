using Test
using DESSEM2Julia

@testset "RAMPAS.DAT Parser Tests" begin
    @testset "Single Record Parsing" begin
        # Test case from sample file
        #   1   1      S   A     122.000     0 1
        line = "  1   1      S   A     122.000     0 1"
        record = DESSEM2Julia.RampasParser.parse_rampas_record(line, "test.dat", 1)

        @test record.usina == 1
        @test record.unidade == 1
        @test record.configuracao == "S"
        @test record.tipo == "A"
        @test record.potencia == 122.0
        @test record.tempo == 0
        @test record.flag_meia_hora == 1
    end

    @testset "Another Record Parsing" begin
        # Test case from sample file
        #  47  16      C   A     791.000     7 0
        line = " 47  16      C   A     791.000     7 0"
        record = DESSEM2Julia.RampasParser.parse_rampas_record(line, "test.dat", 2)

        @test record.usina == 47
        @test record.unidade == 16
        @test record.configuracao == "C"
        @test record.tipo == "A"
        @test record.potencia == 791.0
        @test record.tempo == 7
        @test record.flag_meia_hora == 0
    end

    @testset "Real File Parsing" begin
        # Create a temporary file with sample content
        content = """
RAMP
&& 
& 1-ANGRA 1
&us uni seg  C   T  Potencia   Tempo Flag meia hora
&XX XXX XXX  X   X  XXXXXXXXXX XXXXX X
  1   1      S   A     122.000     0 1
  1   1      S   A     212.000     1 0
  1   1      S   D     517.000     0 1
"""
        path = "temp_rampas.dat"
        open(path, "w") do io
            write(io, content)
        end

        try
            data = parse_rampas(path)
            @test length(data.records) == 3

            @test data.records[1].usina == 1
            @test data.records[1].potencia == 122.0

            @test data.records[2].usina == 1
            @test data.records[2].potencia == 212.0

            @test data.records[3].tipo == "D"
            @test data.records[3].potencia == 517.0
        finally
            rm(path, force = true)
        end
    end

    @testset "Real CCEE Sample File" begin
        # Check if the sample file exists in the workspace
        sample_path = joinpath(
            dirname(@__DIR__),
            "docs",
            "Sample",
            "DS_CCEE_102025_SEMREDE_RV0D28",
            "rampas.dat",
        )
        if isfile(sample_path)
            data = parse_rampas(sample_path)
            @test length(data.records) > 0
            println("Parsed $(length(data.records)) records from real sample file.")

            # Verify first record
            #   1   1      S   A     122.000     0 1
            first_rec = data.records[1]
            @test first_rec.usina == 1
            @test first_rec.unidade == 1
            @test first_rec.configuracao == "S"
            @test first_rec.tipo == "A"
            @test first_rec.potencia == 122.0
        else
            println("Sample file not found at $sample_path, skipping real file test.")
        end
    end
end
