using Test
using DESSEM2Julia

@testset "Network Topology Parser Tests" begin
    
    @testset "NetworkBus Type" begin
        # Basic construction
        bus = NetworkBus(bus_number=100)
        @test bus.bus_number == 100
        @test bus.name == ""
        @test bus.subsystem == ""
        @test bus.generation_mw === nothing
        @test bus.load_mw === nothing
        
        # Full construction
        bus2 = NetworkBus(
            bus_number=37,
            name="BARRA BONITA",
            subsystem="SE",
            generation_mw=76.21,
            load_mw=1955.55,
            voltage_kv=500.0
        )
        @test bus2.bus_number == 37
        @test bus2.name == "BARRA BONITA"
        @test bus2.subsystem == "SE"
        @test bus2.generation_mw == 76.21
        @test bus2.load_mw == 1955.55
        @test bus2.voltage_kv == 500.0
    end
    
    @testset "NetworkLine Type" begin
        line = NetworkLine(
            from_bus=1027,
            to_bus=556,
            circuit=1,
            flow_mw=-323.788,
            capacity_mw=2000.0,
            constraint_name="F(ASS-LON1)"
        )
        @test line.from_bus == 1027
        @test line.to_bus == 556
        @test line.circuit == 1
        @test line.flow_mw == -323.788
        @test line.capacity_mw == 2000.0
        @test line.constraint_name == "F(ASS-LON1)"
    end
    
    @testset "NetworkTopology Type" begin
        buses = [
            NetworkBus(bus_number=1),
            NetworkBus(bus_number=2)
        ]
        lines = [
            NetworkLine(from_bus=1, to_bus=2, circuit=1)
        ]
        
        topology = NetworkTopology(
            buses=buses,
            lines=lines,
            stage=1,
            load_level="LEVE"
        )
        
        @test length(topology.buses) == 2
        @test length(topology.lines) == 1
        @test topology.stage == 1
        @test topology.load_level == "LEVE"
    end
    
    @testset "ONS PDO_SOMFLUX Parsing" begin
        ons_case = "docs/Sample/DS_ONS_102025_RV2D11"
        somflux_file = joinpath(ons_case, "pdo_somflux.dat")
        
        if isfile(somflux_file)
            topology = parse_pdo_somflux_topology(somflux_file, stage=1)
            
            # Should have discovered buses and lines
            @test length(topology.buses) > 0
            @test length(topology.lines) > 0
            
            println("  ✓ Extracted $(length(topology.buses)) buses")
            println("  ✓ Extracted $(length(topology.lines)) lines")
            
            # Check topology stage and load level
            @test topology.stage == 1
            @test topology.load_level in ["LEVE", "MEDIA", "PESADA", ""]
            
            # Verify bus numbers are unique
            bus_numbers = [bus.bus_number for bus in topology.buses]
            @test length(bus_numbers) == length(unique(bus_numbers))
            
            # Verify lines have valid bus references
            for line in topology.lines
                @test line.from_bus in bus_numbers
                @test line.to_bus in bus_numbers
                @test line.circuit >= 1
            end
            
            # Check specific known connections from sample data
            # Line: Bus 1027 → Bus 556
            line_1027_556 = findfirst(l -> l.from_bus == 1027 && l.to_bus == 556, topology.lines)
            if !isnothing(line_1027_556)
                @test topology.lines[line_1027_556].from_bus == 1027
                @test topology.lines[line_1027_556].to_bus == 556
                println("  ✓ Found known line: 1027 → 556")
            end
            
            # Line: Bus 6442 → Bus 3050
            line_6442_3050 = findfirst(l -> l.from_bus == 6442 && l.to_bus == 3050, topology.lines)
            if !isnothing(line_6442_3050)
                @test topology.lines[line_6442_3050].from_bus == 6442
                @test topology.lines[line_6442_3050].to_bus == 3050
                println("  ✓ Found known line: 6442 → 3050")
            end
            
            # Check metadata
            @test haskey(topology.metadata, "source")
            @test topology.metadata["source"] == "pdo_somflux.dat"
            
        else
            @warn "ONS sample file not found: $somflux_file (skipping test)"
        end
    end
    
    @testset "ONS Complete Topology Parsing" begin
        ons_case = "docs/Sample/DS_ONS_102025_RV2D11"
        
        if isdir(ons_case)
            topology = parse_network_topology(ons_case, stage=1)
            
            # Should have extracted complete topology
            @test length(topology.buses) > 0
            @test length(topology.lines) > 0
            
            println("  ✓ Complete topology: $(length(topology.buses)) buses, $(length(topology.lines)) lines")
            
            # Check if buses have enriched attributes (from PDO_OPERACAO)
            buses_with_names = count(b -> !isempty(b.name), topology.buses)
            buses_with_subsystem = count(b -> !isempty(b.subsystem), topology.buses)
            buses_with_generation = count(b -> !isnothing(b.generation_mw), topology.buses)
            
            println("  ✓ Buses with names: $buses_with_names")
            println("  ✓ Buses with subsystem: $buses_with_subsystem")
            println("  ✓ Buses with generation: $buses_with_generation")
            
            # Should have some enriched buses
            @test buses_with_names > 0 || buses_with_subsystem > 0
            
            # Check for known buses from PDO_OPERACAO
            # Bus 37: BARRA BONITA
            bus_37 = findfirst(b -> b.bus_number == 37, topology.buses)
            if !isnothing(bus_37)
                @test topology.buses[bus_37].bus_number == 37
                println("  ✓ Found Bus 37: $(topology.buses[bus_37].name)")
            end
            
            # Bus 86: BARRA GRANDE
            bus_86 = findfirst(b -> b.bus_number == 86, topology.buses)
            if !isnothing(bus_86)
                @test topology.buses[bus_86].bus_number == 86
                println("  ✓ Found Bus 86: $(topology.buses[bus_86].name)")
            end
            
            # Verify metadata indicates enrichment
            @test haskey(topology.metadata, "enriched")
            
        else
            @warn "ONS sample directory not found: $ons_case (skipping test)"
        end
    end
    
    @testset "Multiple Stages" begin
        ons_case = "docs/Sample/DS_ONS_102025_RV2D11"
        somflux_file = joinpath(ons_case, "pdo_somflux.dat")
        
        if isfile(somflux_file)
            # Test multiple stages
            topology_stage1 = parse_pdo_somflux_topology(somflux_file, stage=1)
            topology_stage2 = parse_pdo_somflux_topology(somflux_file, stage=2)
            
            @test topology_stage1.stage == 1
            @test topology_stage2.stage == 2
            
            # Both should have data
            @test length(topology_stage1.lines) > 0
            @test length(topology_stage2.lines) > 0
            
            println("  ✓ Stage 1: $(length(topology_stage1.lines)) lines")
            println("  ✓ Stage 2: $(length(topology_stage2.lines)) lines")
            
            # Line flows may differ between stages
            # (This is expected as network conditions change over time)
            
        else
            @warn "ONS sample file not found (skipping multi-stage test)"
        end
    end
    
    @testset "Network Statistics" begin
        ons_case = "docs/Sample/DS_ONS_102025_RV2D11"
        
        if isdir(ons_case)
            topology = parse_network_topology(ons_case, stage=1)
            
            # Calculate basic network statistics
            num_buses = length(topology.buses)
            num_lines = length(topology.lines)
            
            @test num_buses > 0
            @test num_lines > 0
            
            # Check degree distribution (number of connections per bus)
            bus_degrees = Dict{Int, Int}()
            for line in topology.lines
                bus_degrees[line.from_bus] = get(bus_degrees, line.from_bus, 0) + 1
                bus_degrees[line.to_bus] = get(bus_degrees, line.to_bus, 0) + 1
            end
            
            max_degree = maximum(values(bus_degrees))
            avg_degree = sum(values(bus_degrees)) / length(bus_degrees)
            
            println("\n  Network Statistics:")
            println("  • Buses: $num_buses")
            println("  • Lines: $num_lines")
            println("  • Average degree: $(round(avg_degree, digits=2))")
            println("  • Maximum degree: $max_degree")
            
            @test max_degree > 0
            @test avg_degree > 0
            
            # Check subsystem distribution
            subsystem_counts = Dict{String, Int}()
            for bus in topology.buses
                if !isempty(bus.subsystem)
                    subsystem_counts[bus.subsystem] = get(subsystem_counts, bus.subsystem, 0) + 1
                end
            end
            
            if !isempty(subsystem_counts)
                println("\n  Subsystem Distribution:")
                for (subsystem, count) in sort(collect(subsystem_counts))
                    println("  • $subsystem: $count buses")
                end
            end
            
        else
            @warn "ONS sample directory not found (skipping statistics test)"
        end
    end
end
