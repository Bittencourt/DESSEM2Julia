using Test
using DESSEM2Julia
using DESSEM2Julia.RstlppParser
using DESSEM2Julia.Types

@testset "RSTLPP Parser Tests" begin
    # Create a temporary file with sample data
    sample_content = """
&LPPs PARA OPERACAO EM N-2
& ==========================================================================================================================
& Fluxo Norte Sudeste (FNS) Nº 1 
& Em função do FXGET + FXGTR e UHE S. Mesa
&
&MNEM  CHA1    NUM  DREF CHAVE IDENT   DESCRICAO
&XXXXX xxxxxxx XXXX XXXX xxxxx xxxxx XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
RSTSEG FNS        1 9007 DREF   9042 FNS Em função do somatorio FXGTR e FXGET
ADICRS FNS        1 9007 DREF   9036 UHE S. Mesa
&&&&&&
&XXXX XXXX XXXXX XXXXX
PARAM    1 CARGA   SIN
&&&&&&
&XXXX XXXX XX XXXXXXXXXX
VPARM    1  1          0
VPARM    1  2      76000
&&&&&&
&mnem   num p i coefangula coeflin    2 contro  
&xxxxx xxxx x x xxxxxxxxxx xxxxxxxxxx xxxxxxxxxx
RESLPP    1 1 1      0.000       5000      0.000
RESLPP    1 1 2      0.000       5100     -0.339
RESLPP    1 1 3     -0.572       7270      0.000
RESLPP    1 1 4     -0.572       7370     -0.339
&
RESLPP    1 2 1      0.000       5200      0.000
"""

    path = "test_rstlpp.dat"
    open(path, "w") do io
        write(io, sample_content)
    end

    try
        constraints = parse_rstlpp(path)

        @test length(constraints) == 5

        # Check first constraint (Period 1, Segment 1)
        c1 = constraints[1]
        @test c1.constraint_id == 1
        @test c1.constraint_name == "FNS"
        @test c1.period == 1
        @test c1.segment == 1
        @test c1.rhs == 5000.0
        # AngCoeff = 0.000 -> Coeff = -0.000
        @test c1.coefficients[("DREF", 9042)] == -0.0
        # Coeff2 = 0.000 -> Coeff = -0.000
        @test c1.coefficients[("DREF", 9036)] == -0.0

        # Check second constraint (Period 1, Segment 2)
        c2 = constraints[2]
        @test c2.constraint_id == 1
        @test c2.period == 1
        @test c2.segment == 2
        @test c2.rhs == 5100.0
        # AngCoeff = 0.000 -> Coeff = -0.000
        @test c2.coefficients[("DREF", 9042)] == -0.0
        # Coeff2 = -0.339 -> Coeff = 0.339
        @test c2.coefficients[("DREF", 9036)] == 0.339

        # Check third constraint (Period 1, Segment 3)
        c3 = constraints[3]
        @test c3.rhs == 7270.0
        # AngCoeff = -0.572 -> Coeff = 0.572
        @test c3.coefficients[("DREF", 9042)] == 0.572
        @test c3.coefficients[("DREF", 9036)] == -0.0

        # Check fifth constraint (Period 2, Segment 1)
        c5 = constraints[5]
        @test c5.period == 2
        @test c5.segment == 1
        @test c5.rhs == 5200.0

    finally
        rm(path, force = true)
    end
end
