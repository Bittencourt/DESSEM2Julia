using Test
using DESSEM2Julia

@testset "DESSOPC.DAT Parser Tests" begin
    
    @testset "Single Line Parsing" begin
        @testset "Flag Keywords" begin
            # PINT - interior points flag
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("PINT")
            @test result !== nothing
            @test result[1] == :pint
            @test result[2] == true
            
            # CPLEXLOG - CPLEX logging flag
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("CPLEXLOG")
            @test result !== nothing
            @test result[1] == :cplexlog
            @test result[2] == true
            
            # UCTBUSLOC - local search flag
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("UCTBUSLOC")
            @test result !== nothing
            @test result[1] == :uctbusloc
            @test result[2] == true
        end
        
        @testset "Single Value Keywords" begin
            # UCTPAR - parallel processing threads
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("UCTPAR 2")
            @test result !== nothing
            @test result[1] == :uctpar
            @test result[2] == 2
            
            # UCTERM - solution methodology
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("UCTERM 2")
            @test result !== nothing
            @test result[1] == :ucterm
            @test result[2] == 2
            
            # AVLCMO - CMO evaluation flag
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("AVLCMO 1")
            @test result !== nothing
            @test result[1] == :avlcmo
            @test result[2] == 1
            
            # TOLERILH - island tolerance
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("TOLERILH 1")
            @test result !== nothing
            @test result[1] == :tolerilh
            @test result[2] == 1
            
            # ENGOLIMENTO - maximum engulfment
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("ENGOLIMENTO 0")
            @test result !== nothing
            @test result[1] == :engolimento
            @test result[2] == 0
        end
        
        @testset "Multi-Value Keywords" begin
            # REGRANPTV - with extra spaces
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("REGRANPTV     1")
            @test result !== nothing
            @test result[1] == :regranptv
            @test result[2] == [1]
            
            # CONSTDADOS - two values
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("CONSTDADOS 0  1")
            @test result !== nothing
            @test result[1] == :constdados
            @test result[2] == [0, 1]
            
            # CONSTDADOS - different values
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("CONSTDADOS 1  1 ")
            @test result !== nothing
            @test result[1] == :constdados
            @test result[2] == [1, 1]
            
            # UCTHEURFP - multiple parameters
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("UCTHEURFP   1 100")
            @test result !== nothing
            @test result[1] == :uctheurfp
            @test result[2] == [1, 100]
            
            # CROSSOVER - four parameters
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("CROSSOVER 0 0 0 0")
            @test result !== nothing
            @test result[1] == :crossover
            @test result[2] == [0, 0, 0, 0]
            
            # UCTERM with extended syntax (3 values) - returns vector
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("UCTERM 2 1 1")
            @test result !== nothing
            @test result[1] == :ucterm
            @test result[2] == [2, 1, 1]
            
            # TRATA_INVIAB_ILHA
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("TRATA_INVIAB_ILHA 1")
            @test result !== nothing
            @test result[1] == :trata_inviab_ilha
            @test result[2] == [1]
        end
        
        @testset "Comment and Blank Lines" begin
            # Standard comment
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("& OPCOES DE EXECUCAO")
            @test result === nothing
            
            # Comment with text
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("&Flags Inativos")
            @test result === nothing
            
            # Blank line
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("")
            @test result === nothing
            
            # Whitespace only
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("    ")
            @test result === nothing
        end
        
        @testset "Commented Keywords" begin
            # Should return nothing for commented keywords
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("&UCTBUSLOC")
            @test result === nothing
            
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("&UCTHEURFP   1 100")
            @test result === nothing
            
            result = DESSEM2Julia.DessOpcParser.parse_dessopc_line("&AJUSTEFCF")
            @test result === nothing
        end
    end
    
    @testset "Full File Parsing - CCEE Sample" begin
        filepath = "docs/Sample/DS_CCEE_102025_SEMREDE_RV0D28/dessopc.dat"
        
        if isfile(filepath)
            result = parse_dessopc(filepath)
            
            # Check basic structure
            @test result isa DessOpcData
            
            # Verify active keywords from CCEE file
            @test result.uctpar == 2
            @test result.ucterm == 2
            @test result.pint == true
            @test result.regranptv == [1]
            @test result.avlcmo == 1
            @test result.cplexlog == true
            @test result.constdados == [0, 1]
            
            # Verify inactive keywords (should be nothing/false)
            @test result.uctbusloc == false
            @test result.uctheurfp === nothing
            @test result.ajustefcf === nothing
            @test result.tolerilh === nothing
            @test result.engolimento === nothing
        else
            @warn "CCEE sample file not found: $filepath"
        end
    end
    
    @testset "Full File Parsing - ONS Sample" begin
        filepath = "docs/Sample/DS_ONS_102025_RV2D11/dessopc.dat"
        
        if isfile(filepath)
            result = parse_dessopc(filepath)
            
            # Check basic structure
            @test result isa DessOpcData
            
            # Verify active keywords from ONS file
            @test result.uctpar == 2
            @test result.ucterm == 2
            @test result.pint == true
            @test result.regranptv == [1]
            @test result.avlcmo == 1
            @test result.cplexlog == true
            @test result.constdados == [1, 1]  # Different from CCEE
            
            # Verify inactive keywords
            @test result.uctbusloc == false
            @test result.uctheurfp === nothing
            @test result.ajustefcf === nothing
            @test result.tolerilh === nothing
            @test result.engolimento === nothing
        else
            @warn "ONS sample file not found: $filepath"
        end
    end
    
    @testset "IO Stream Parsing" begin
        # Test parsing from IO stream
        content = """
        & Test DESSOPC file
        UCTPAR 4
        UCTERM 1
        PINT
        REGRANPTV 2
        AVLCMO 0
        & Inactive option
        &CPLEXLOG
        CONSTDADOS 1 0
        """
        
        result = parse_dessopc(IOBuffer(content), "test.dat")
        
        @test result isa DessOpcData
        @test result.uctpar == 4
        @test result.ucterm == 1
        @test result.pint == true
        @test result.regranptv == [2]
        @test result.avlcmo == 0
        @test result.cplexlog == false  # Was commented
        @test result.constdados == [1, 0]
    end
    
    @testset "Edge Cases" begin
        @testset "Empty File" begin
            result = parse_dessopc(IOBuffer(""), "empty.dat")
            @test result isa DessOpcData
            @test result.uctpar === nothing
            @test result.pint == false
        end
        
        @testset "Comments Only" begin
            content = """
            & Header comment
            & Another comment
            &
            & More comments
            """
            result = parse_dessopc(IOBuffer(content), "comments.dat")
            @test result isa DessOpcData
            @test result.uctpar === nothing
        end
        
        @testset "Mixed Active and Inactive" begin
            content = """
            UCTPAR 2
            &UCTERM 3
            PINT
            &CPLEXLOG
            AVLCMO 1
            """
            result = parse_dessopc(IOBuffer(content), "mixed.dat")
            @test result.uctpar == 2
            @test result.ucterm === nothing
            @test result.pint == true
            @test result.cplexlog == false
            @test result.avlcmo == 1
        end
        
        @testset "Extra Whitespace" begin
            content = """
            UCTPAR    2
            REGRANPTV         1
            CONSTDADOS   0    1  
            """
            result = parse_dessopc(IOBuffer(content), "whitespace.dat")
            @test result.uctpar == 2
            @test result.regranptv == [1]
            @test result.constdados == [0, 1]
        end
        
        @testset "Lowercase Keywords" begin
            # Parser should handle case variations
            content = """
            uctpar 2
            pint
            """
            result = parse_dessopc(IOBuffer(content), "lowercase.dat")
            @test result.uctpar == 2
            @test result.pint == true
        end
    end
    
    @testset "Type Consistency" begin
        # Ensure all fields have correct types
        data = DessOpcData()
        
        # Nothing/union types
        @test data.uctpar === nothing || data.uctpar isa Int
        @test data.ucterm === nothing || data.ucterm isa Int
        @test data.regranptv === nothing || data.regranptv isa Vector{Int}
        @test data.avlcmo === nothing || data.avlcmo isa Int
        @test data.uctheurfp === nothing || data.uctheurfp isa Vector{Int}
        @test data.constdados === nothing || data.constdados isa Vector{Int}
        @test data.ajustefcf === nothing || data.ajustefcf isa Vector{Int}
        @test data.tolerilh === nothing || data.tolerilh isa Int
        @test data.crossover === nothing || data.crossover isa Vector{Int}
        @test data.engolimento === nothing || data.engolimento isa Int
        @test data.trata_inviab_ilha === nothing || data.trata_inviab_ilha isa Int
        @test data.uctesperto === nothing || data.uctesperto isa Int
        
        # Boolean types
        @test data.pint isa Bool
        @test data.cplexlog isa Bool
        @test data.uctbusloc isa Bool
        @test data.trata_term_ton isa Bool
        
        # Dict
        @test data.other_options isa Dict{String, Any}
    end
    
    @testset "Keyword Coverage" begin
        # Test all known keywords from IDESSEM
        content = """
        UCTPAR 2
        UCTERM 2
        PINT
        REGRANPTV 1
        AVLCMO 1
        CPLEXLOG
        UCTBUSLOC
        UCTHEURFP 1 100
        CONSTDADOS 1 1
        AJUSTEFCF 0 1 0
        TOLERILH 1
        CROSSOVER 0 0 0 0
        ENGOLIMENTO 0
        TRATA_INVIAB_ILHA 1
        """
        
        result = parse_dessopc(IOBuffer(content), "complete.dat")
        
        @test result.uctpar == 2
        @test result.ucterm == 2
        @test result.pint == true
        @test result.regranptv == [1]
        @test result.avlcmo == 1
        @test result.cplexlog == true
        @test result.uctbusloc == true
        @test result.uctheurfp == [1, 100]
        @test result.constdados == [1, 1]
        @test result.ajustefcf == [0, 1, 0]
        @test result.tolerilh == 1
        @test result.crossover == [0, 0, 0, 0]
        @test result.engolimento == 0
        @test result.trata_inviab_ilha == 1
    end
    
end
