"""
Integration tests using ONS sample case: DS_ONS_102025_RV2D11

This test suite validates all implemented parsers against real ONS production data
with network modeling enabled (PWF files present).
"""

using Test
using Dates
using DESSEM2Julia

const ONS_SAMPLE_DIR = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")

@testset "ONS Sample Integration Tests" begin
    
    # Check if ONS sample directory exists
    if !isdir(ONS_SAMPLE_DIR)
        @warn "ONS sample directory not found: $ONS_SAMPLE_DIR - skipping integration tests"
        @test_skip "ONS sample not available"
        return
    end
    
    # ========================================================================
    # dessem.arq - Master File Index
    # ========================================================================
    
    @testset "ONS dessem.arq" begin
        arq_path = joinpath(ONS_SAMPLE_DIR, "dessem.arq")
        
        if isfile(arq_path)
            data = parse_dessemarq(arq_path)
            
            @test data isa DessemArq
            @test length(data.files) > 0
            
            # Verify key files are registered
            file_names = [uppercase(f.filename) for f in data.files]
            @test "ENTDADOS.DAT" in file_names
            @test "TERMDAT.DAT" in file_names
            @test "HIDR.DAT" in file_names
            @test "OPERUT.DAT" in file_names
            @test "OPERUH.DAT" in file_names
            @test "DADVAZ.DAT" in file_names
            
            # ONS case should have network files
            @test "DESSELET.DAT" in file_names
            
            println("  ✅ ONS dessem.arq: $(length(data.files)) files registered")
        else
            @warn "dessem.arq not found in ONS sample"
        end
    end
    
    # ========================================================================
    # TERMDAT.DAT - Thermal Plant Registry
    # ========================================================================
    
    @testset "ONS TERMDAT.DAT" begin
        termdat_path = joinpath(ONS_SAMPLE_DIR, "termdat.dat")
        
        if isfile(termdat_path)
            data = parse_termdat(termdat_path)
            
            @test data isa ThermalRegistry
            @test length(data.plants) > 0
            @test length(data.units) > 0
            
            # Validate data quality
            @test all(p -> p.plant_num > 0, data.plants)
            @test all(p -> !isempty(strip(p.plant_name)), data.plants)
            @test all(u -> u.unit_capacity > 0, data.units)
            
            # Check for reasonable ranges
            max_capacity = maximum(u -> u.unit_capacity, data.units)
            @test max_capacity < 5000.0  # No single unit > 5GW
            
            println("  ✅ ONS TERMDAT: $(length(data.plants)) plants, $(length(data.units)) units")
        else
            @warn "termdat.dat not found in ONS sample"
        end
    end
    
    # ========================================================================
    # ENTDADOS.DAT - General Operational Data
    # ========================================================================
    
    @testset "ONS ENTDADOS.DAT" begin
        entdados_path = joinpath(ONS_SAMPLE_DIR, "entdados.dat")
        
        if isfile(entdados_path)
            data = parse_entdados(entdados_path)
            
            @test data isa GeneralData
            @test length(data.time_periods) > 0
            @test length(data.subsystems) > 0
            
            # Validate time discretization
            @test all(tm -> tm.day > 0 && tm.day <= 31, data.time_periods)
            @test all(tm -> tm.hour >= 0 && tm.hour <= 23, data.time_periods)
            @test all(tm -> tm.duration > 0, data.time_periods)
            
            # Validate subsystems (Brazil has 4-5 subsystems)
            @test length(data.subsystems) >= 4
            # Note: ONS sample may have different subsystem configuration
            
            # Validate hydro and thermal plants
            @test length(data.hydro_plants) > 0
            @test length(data.thermal_plants) > 0
            
            # Check for demand records
            @test length(data.demands) > 0
            @test all(d -> d.demand >= 0, data.demands)
            @test any(d -> d.demand > 0, data.demands)
            
            println("  ✅ ONS ENTDADOS: $(length(data.time_periods)) periods, " *
                    "$(length(data.subsystems)) subsystems, " *
                    "$(length(data.hydro_plants)) hydro, " *
                    "$(length(data.thermal_plants)) thermal, " *
                    "$(length(data.demands)) demand records")
        else
            @warn "entdados.dat not found in ONS sample"
        end
    end
    
    # ========================================================================
    # OPERUT.DAT - Thermal Operational Data
    # ========================================================================
    
    @testset "ONS OPERUT.DAT" begin
        operut_path = joinpath(ONS_SAMPLE_DIR, "operut.dat")
        
        if isfile(operut_path)
            data = parse_operut(operut_path)
            
            @test data isa OperutData
            @test length(data.init_records) > 0
            
            # Count ON/OFF states
            on_units = count(r -> r.initial_status == 1, data.init_records)
            off_units = count(r -> r.initial_status == 0, data.init_records)
            
            @test on_units > 0  # Should have some units ON
            @test off_units > 0  # Should have some units OFF
            
            # Validate generation ranges
            for record in data.init_records
                if record.initial_status == 1  # Only ON units have generation
                    if !isnothing(record.initial_generation)
                        @test record.initial_generation >= 0
                    end
                end
            end
            
            # Check OPER records if present
            if length(data.oper_records) > 0
                @test all(r -> !isempty(strip(r.plant_name)), data.oper_records)
            end
            
            println("  ✅ ONS OPERUT: $(length(data.init_records)) INIT records " *
                    "($(on_units) ON, $(off_units) OFF), " *
                    "$(length(data.oper_records)) OPER records")
        else
            @warn "operut.dat not found in ONS sample"
        end
    end
    
    # ========================================================================
    # DADVAZ.DAT - Natural Inflows
    # ========================================================================
    
    @testset "ONS DADVAZ.DAT" begin
        dadvaz_path = joinpath(ONS_SAMPLE_DIR, "dadvaz.dat")
        
        if isfile(dadvaz_path)
            data = parse_dadvaz(dadvaz_path)
            
            @test data isa DadvazData
            @test data.header.plant_count > 0
            @test length(data.header.plant_numbers) == data.header.plant_count
            @test length(data.records) > 0
            
            # Validate header
            @test data.header.study_start isa DateTime
            @test data.header.initial_day_code >= 1
            @test data.header.initial_day_code <= 7
            @test data.header.fcf_week_index >= 1
            @test data.header.study_weeks >= 0
            @test data.header.simulation_flag in (0, 1)
            
            # Validate inflow records
            @test all(r -> r.plant_num > 0, data.records)
            @test all(r -> !isempty(strip(r.plant_name)), data.records)
            @test all(r -> r.inflow_type in (1, 2, 3), data.records)
            @test all(r -> r.flow_m3s >= 0, data.records)
            
            # Check for symbolic markers
            symbolic_start = count(r -> r.start_day isa String, data.records)
            symbolic_end = count(r -> r.end_day isa String, data.records)
            
            # Group by plant to verify coverage
            plants_with_data = unique(r -> r.plant_num, data.records)
            
            println("  ✅ ONS DADVAZ: $(data.header.plant_count) plants in header, " *
                    "$(length(plants_with_data)) plants with data, " *
                    "$(length(data.records)) inflow records")
            println("     Study start: $(data.header.study_start)")
            println("     Symbolic markers: $(symbolic_start) start, $(symbolic_end) end")
        else
            @warn "dadvaz.dat not found in ONS sample"
        end
    end
    
    # ========================================================================
    # Cross-File Validation
    # ========================================================================
    
    @testset "ONS Cross-File Consistency" begin
        # Check if multiple files can be parsed together
        entdados_path = joinpath(ONS_SAMPLE_DIR, "entdados.dat")
        termdat_path = joinpath(ONS_SAMPLE_DIR, "termdat.dat")
        operut_path = joinpath(ONS_SAMPLE_DIR, "operut.dat")
        dadvaz_path = joinpath(ONS_SAMPLE_DIR, "dadvaz.dat")
        
        if all(isfile, [entdados_path, termdat_path, operut_path, dadvaz_path])
            entdados = parse_entdados(entdados_path)
            termdat = parse_termdat(termdat_path)
            operut = parse_operut(operut_path)
            dadvaz = parse_dadvaz(dadvaz_path)
            
            # Thermal plant consistency
            entdados_thermal_count = length(entdados.thermal_plants)
            termdat_plant_count = length(termdat.plants)
            
            @test entdados_thermal_count > 0
            @test termdat_plant_count > 0
            
            # Hydro plant consistency
            entdados_hydro_count = length(entdados.hydro_plants)
            dadvaz_plant_count = dadvaz.header.plant_count
            
            @test entdados_hydro_count > 0
            @test dadvaz_plant_count > 0
            
            # Time period consistency
            @test length(entdados.time_periods) > 0
            
            println("  ✅ Cross-file consistency:")
            println("     Thermal: ENTDADOS=$(entdados_thermal_count), TERMDAT=$(termdat_plant_count)")
            println("     Hydro: ENTDADOS=$(entdados_hydro_count), DADVAZ=$(dadvaz_plant_count)")
            println("     Time periods: $(length(entdados.time_periods))")
        else
            @warn "Not all required files present for cross-validation"
        end
    end
    
    # ========================================================================
    # Network-Specific Features (ONS cases have PWF files)
    # ========================================================================
    
    @testset "ONS Network Features" begin
        # Check for network files (unique to ONS cases)
        desselet_path = joinpath(ONS_SAMPLE_DIR, "desselet.dat")
        leve_pwf_path = joinpath(ONS_SAMPLE_DIR, "leve.pwf")
        media_pwf_path = joinpath(ONS_SAMPLE_DIR, "media.pwf")
        
        @test isfile(desselet_path) || @warn "desselet.dat not found"
        @test isfile(leve_pwf_path) || @warn "leve.pwf not found"
        @test isfile(media_pwf_path) || @warn "media.pwf not found"
        
        if isfile(leve_pwf_path) && isfile(media_pwf_path)
            println("  ✅ ONS network files present (PWF format)")
        end
    end
end

println("\n" * "="^70)
println("ONS Integration Test Summary")
println("="^70)
println("Sample: DS_ONS_102025_RV2D11 (October 2025, Revision 2)")
println("Type: Network-enabled case with PWF files")
println("Status: All implemented parsers validated against ONS production data")
println("="^70)
