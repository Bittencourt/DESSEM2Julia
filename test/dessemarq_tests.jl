"""
Tests for DESSEM.ARQ parser
"""

using Test
using DESSEM2Julia
using DESSEM2Julia.DessemArqParser

@testset "DessemArq Parser" begin
    sample_file = joinpath(@__DIR__, "..", "docs", "Sample", "DS_CCEE_102025_SEMREDE_RV0D28", "dessem.arq")

    # Skip sample-dependent tests if the sample file isn't present in CI
    has_sample = isfile(sample_file)

    @testset "Parse sample dessem.arq" begin
        if !has_sample
            @info "Sample file not found, skipping DessemArq parsing checks" sample_file
            return
        end
        arq = parse_dessemarq(sample_file)
        
        # Test that we got a DessemArq struct
        @test arq isa DessemArq
        
        # Test required files that should be present
        @test arq.caso == "DAT"
        @test arq.vazoes == "dadvaz.dat"
        @test arq.dadger == "entdados.dat"
        @test arq.cadterm == "termdat.dat"
        @test arq.operuh == "operuh.dat"
        @test arq.operut == "operut.dat"
        @test arq.cadusih == "hidr.dat"
        @test arq.deflant == "deflant.dat"
        @test arq.ilstri == "ils_tri.dat"
        @test arq.cotasr11 == "cotasr11.dat"
        @test arq.areacont == "areacont.dat"
        @test arq.respot == "respot.dat"
        @test arq.mlt == "mlt.dat"
        @test arq.curvtviag == "curvtviag.dat"
        @test arq.ptoper == "ptoper.dat"
        @test arq.infofcf == "infofcf.dat"
        @test arq.eolica == "renovaveis.dat"
        @test arq.rampas == "rampas.dat"
        @test arq.rstlpp == "rstlpp.dat"
        @test arq.restseg == "restseg.dat"
        @test arq.respotele == "respotele.dat"
        @test arq.ilibs == "indice.csv"
        @test arq.dessopc == "dessopc.dat"
        @test arq.rmpflx == "rmpflx.dat"
        
        # Test binary files
        @test arq.mapfcf == "mapcut.rv0"
        @test arq.cortfcf == "cortdeco.rv0"
        
        # Test file that maps to same file as dadger (REE -> entdados.dat)
        @test arq.ree == "entdados.dat"
        @test arq.ree == arq.dadger  # Both point to same file
        
        # Test commented files (should be nothing)
        @test isnothing(arq.indelet)
        @test isnothing(arq.simul)
        @test isnothing(arq.tolperd)
        @test isnothing(arq.meta)
        
        # Test title field (special - contains text, not filename)
        @test !isnothing(arq.titulo)
        @test occursin("PMO", arq.titulo)
    end
    
    @testset "Error handling" begin
        # Test with non-existent file
        @test_throws Exception parse_dessemarq("nonexistent.arq")
    end
    
    @testset "File existence validation" begin
        if !has_sample
            @info "Sample file not found, skipping file existence validation" sample_file
            return
        end
        # Parse the index
        arq = parse_dessemarq(sample_file)
        
        # Get directory
        sample_dir = dirname(sample_file)
        
        # Helper to build full path
        function file_exists_in_case(filename)
            isnothing(filename) && return false
            # Skip special fields that aren't files
            filename == "DAT" && return true  # CASO is special
            occursin("PMO", filename) && return true  # TITULO is text
            
            full_path = joinpath(sample_dir, filename)
            return isfile(full_path)
        end
        
        # Test that referenced files actually exist
        @test file_exists_in_case(arq.caso)
        @test file_exists_in_case(arq.titulo)
        @test file_exists_in_case(arq.vazoes)
        @test file_exists_in_case(arq.dadger)
        @test file_exists_in_case(arq.mapfcf)
        @test file_exists_in_case(arq.cortfcf)
        @test file_exists_in_case(arq.cadusih)
        @test file_exists_in_case(arq.operuh)
        @test file_exists_in_case(arq.deflant)
        @test file_exists_in_case(arq.cadterm)
        @test file_exists_in_case(arq.operut)
        @test file_exists_in_case(arq.ilstri)
        @test file_exists_in_case(arq.cotasr11)
        @test file_exists_in_case(arq.areacont)
        @test file_exists_in_case(arq.respot)
        @test file_exists_in_case(arq.mlt)
        @test file_exists_in_case(arq.curvtviag)
        @test file_exists_in_case(arq.ptoper)
        @test file_exists_in_case(arq.infofcf)
        @test file_exists_in_case(arq.ree)
        @test file_exists_in_case(arq.eolica)
        @test file_exists_in_case(arq.rampas)
        @test file_exists_in_case(arq.rstlpp)
        @test file_exists_in_case(arq.restseg)
        @test file_exists_in_case(arq.respotele)
        @test file_exists_in_case(arq.ilibs)
        @test file_exists_in_case(arq.dessopc)
        @test file_exists_in_case(arq.rmpflx)
    end
    
    @testset "DessemArq constructor" begin
        # Test default constructor
        arq_empty = DessemArq()
        @test all(getfield(arq_empty, f) === nothing for f in fieldnames(DessemArq) if f != :files)
        @test isempty(arq_empty.files)
        
        # Test partial constructor
        arq_partial = DessemArq(dadger="test.dat", cadterm="term.dat")
        @test arq_partial.dadger == "test.dat"
        @test arq_partial.cadterm == "term.dat"
        @test isnothing(arq_partial.vazoes)
    end
end
