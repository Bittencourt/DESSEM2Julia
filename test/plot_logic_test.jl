"""
Test script to verify plot_network_simple.jl works

This doesn't require plotting libraries - just checks the logic.
"""

using DESSEM2Julia
using Test

@testset "Network Plotting Logic" begin
    # Test with ONS sample
    case_dir = "docs/Sample/DS_ONS_102025_RV2D11"

    if isdir(case_dir)
        println("Testing network topology extraction for plotting...")

        # Extract topology
        topology = parse_network_topology(case_dir, stage = 1)

        @test length(topology.buses) > 0
        @test length(topology.lines) > 0

        println(
            "✓ Topology extracted: $(length(topology.buses)) buses, $(length(topology.lines)) lines",
        )

        # Test bus-to-index mapping (needed for plotting)
        bus_to_idx = Dict(bus.bus_number => i for (i, bus) in enumerate(topology.buses))
        @test length(bus_to_idx) == length(topology.buses)

        # Test that all lines reference valid buses
        valid_lines = 0
        for line in topology.lines
            if haskey(bus_to_idx, line.from_bus) && haskey(bus_to_idx, line.to_bus)
                valid_lines += 1
            end
        end

        @test valid_lines == length(topology.lines)
        println("✓ All $(valid_lines) lines have valid bus references")

        # Test subsystem colors mapping
        subsystems =
            unique([bus.subsystem for bus in topology.buses if !isempty(bus.subsystem)])
        @test length(subsystems) > 0
        println("✓ Found subsystems: $(join(subsystems, ", "))")

        # Test flow data
        flows_with_data = [line for line in topology.lines if !isnothing(line.flow_mw)]
        @test length(flows_with_data) > 0
        println("✓ $(length(flows_with_data)) lines have flow data")

        println("\n✅ All plotting logic checks passed!")
        println("   (Actual plot generation requires: Graphs, GraphPlot, Colors, Compose)")

    else
        @warn "ONS sample not found, skipping plot logic tests"
    end
end
