"""
    plot_network_simple.jl

Simple example: Create a typical electrical network diagram from DESSEM case.

This creates a visual representation with:
- Buses as nodes (colored by subsystem)
- Transmission lines as edges (thickness by power flow)
- Labels for important buses

Requirements:
    julia> using Pkg
    julia> Pkg.add(["DESSEM2Julia", "Graphs", "GraphPlot", "Colors", "Compose"])

Usage:
    julia --project=. examples/plot_network_simple.jl [case_directory] [stage]

Example:
    julia --project=. examples/plot_network_simple.jl docs/Sample/DS_ONS_102025_RV2D11 1
"""

using DESSEM2Julia

# Check for plotting libraries
try
    using Graphs
    using GraphPlot
    using Colors
    using Colors: @colorant_str  # Make sure colorant macro is available
    using Compose
catch e
    println("❌ Required plotting libraries not installed!")
    println("\nPlease install:")
    println("  julia> using Pkg")
    println("  julia> Pkg.add([\"Graphs\", \"GraphPlot\", \"Colors\", \"Compose\"])")
    exit(1)
end

function plot_electrical_network(
    case_dir::String;
    stage::Int = 1,
    output_file::String = "electrical_network.png",
    max_buses::Int = 500,
)
    """
    Create a typical electrical network diagram.
    
    Buses shown as:
    - Red nodes: Southeast (SE) subsystem
    - Cyan nodes: South (S) subsystem  
    - Yellow nodes: Northeast (NE) subsystem
    - Green nodes: North (N) subsystem
    - Gray nodes: Unknown subsystem
    
    Lines shown with:
    - Thickness proportional to power flow
    - Opacity indicating flow magnitude
    """

    println("="^70)
    println("Electrical Network Diagram")
    println("="^70)
    println("Case: $case_dir")
    println("Stage: $stage")
    println()

    # Extract topology
    println("📊 Extracting network topology...")
    topology = parse_network_topology(case_dir, stage = stage)

    num_buses = length(topology.buses)
    num_lines = length(topology.lines)

    println("   ✓ $num_buses buses")
    println("   ✓ $num_lines transmission lines")
    println()

    # Limit for performance
    if num_buses > max_buses
        println("⚠️  Limiting to $max_buses buses for performance")
        println("   (adjust with max_buses parameter)")
    end

    # Build graph structure
    println("🔧 Building graph...")
    bus_to_idx = Dict(bus.bus_number => i for (i, bus) in enumerate(topology.buses))
    g = SimpleGraph(min(num_buses, max_buses))

    edge_flows = Float64[]
    for line in topology.lines
        if haskey(bus_to_idx, line.from_bus) && haskey(bus_to_idx, line.to_bus)
            from_idx = bus_to_idx[line.from_bus]
            to_idx = bus_to_idx[line.to_bus]

            if from_idx <= max_buses && to_idx <= max_buses
                add_edge!(g, from_idx, to_idx)
                push!(edge_flows, isnothing(line.flow_mw) ? 0.0 : abs(line.flow_mw))
            end
        end
    end

    println("   ✓ Graph: $(nv(g)) nodes, $(ne(g)) edges")
    println()

    # Color nodes by subsystem (typical power system colors)
    println("🎨 Styling network elements...")
    subsystem_colors = Dict(
        "SE" => colorant"#E74C3C",  # Red
        "S" => colorant"#3498DB",  # Blue
        "NE" => colorant"#F39C12",  # Orange
        "N" => colorant"#2ECC71",  # Green
        "" => colorant"#95A5A6",   # Gray
    )

    node_colors = [
        i <= length(topology.buses) ? subsystem_colors[topology.buses[i].subsystem] :
        colorant"gray" for i in 1:nv(g)
    ]

    # Size nodes by connectivity (degree)
    degrees = degree(g)
    max_degree = maximum(degrees)
    node_sizes = [0.015 + 0.035 * d / max_degree for d in degrees]

    # Color edges by flow magnitude
    if !isempty(edge_flows)
        max_flow = maximum(edge_flows)
        # Create colors with alpha channel based on flow magnitude
        edge_colors = [RGBA(0.24, 0.24, 0.24, 0.3 + 0.7 * f / max_flow) for f in edge_flows]
        edge_widths = [0.3 + 3.0 * f / max_flow for f in edge_flows]
    else
        edge_colors = [colorant"gray" for _ in 1:ne(g)]
        edge_widths = ones(ne(g))
    end

    # Label important buses
    node_labels = String[]
    for i in 1:nv(g)
        if i <= length(topology.buses)
            bus = topology.buses[i]
            # Show labels for hubs (>10 connections) or named buses
            if degrees[i] > 10 || !isempty(bus.name)
                label = !isempty(bus.name) ? bus.name : "Bus $(bus.bus_number)"
                push!(node_labels, label)
            else
                push!(node_labels, "")
            end
        else
            push!(node_labels, "")
        end
    end

    println("   ✓ Styled $(nv(g)) nodes and $(ne(g)) edges")
    println()

    # Compute layout
    println("📐 Computing spring layout...")
    loc_x, loc_y = spring_layout(g, C = 2.0)

    # Create plot
    println("🖼️  Rendering diagram...")
    p = gplot(
        g,
        loc_x,
        loc_y,
        nodefillc = node_colors,
        nodesize = node_sizes,
        nodelabel = node_labels,
        edgestrokec = edge_colors,
        edgelinewidth = edge_widths,
        NODESIZE = 0.02,
        NODELABELSIZE = 2.5,
        EDGELINEWIDTH = 0.5,
    )

    # Determine figure size
    fig_width = min(30, 15 + num_buses / 30)
    fig_height = min(30, 15 + num_buses / 30)

    # Save
    println("💾 Saving to: $output_file")
    draw(PNG(output_file, fig_width * 100, fig_height * 100), p)

    println()
    println("="^70)
    println("✓ Diagram created successfully!")
    println("="^70)
    println()
    println("📊 Network Statistics:")
    println("   • Buses: $num_buses")
    println("   • Lines: $num_lines")
    println("   • Average connections: $(round(mean(degrees), digits=2))")
    println("   • Max connections: $max_degree")
    println()

    # Show subsystem distribution
    subsystems = Dict{String,Int}()
    for bus in topology.buses
        if !isempty(bus.subsystem)
            subsystems[bus.subsystem] = get(subsystems, bus.subsystem, 0) + 1
        end
    end

    if !isempty(subsystems)
        println("🗺️  Subsystem Distribution:")
        for (ss, count) in sort(collect(subsystems))
            color_name =
                Dict("SE" => "Red", "S" => "Blue", "NE" => "Orange", "N" => "Green")[ss]
            println("   • $ss: $count buses ($color_name)")
        end
        println()
    end

    println("Legend:")
    println("  🔴 Red nodes    = Southeast (SE)")
    println("  🔵 Blue nodes   = South (S)")
    println("  🟠 Orange nodes = Northeast (NE)")
    println("  🟢 Green nodes  = North (N)")
    println("  ⚪ Gray nodes   = Unknown")
    println()
    println("  Node size       = Number of connections")
    println("  Edge thickness  = Power flow magnitude (MW)")
    println("  Edge darkness   = Flow intensity")
    println()

    return p
end

# Main execution
if !isinteractive()
    # Parse arguments
    if length(ARGS) == 0
        case_dir = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")
        stage = 1
    elseif length(ARGS) == 1
        case_dir = ARGS[1]
        stage = 1
    else
        case_dir = ARGS[1]
        stage = parse(Int, ARGS[2])
    end

    # Check directory exists
    if !isdir(case_dir)
        println("❌ ERROR: Directory not found: $case_dir")
        println()
        println("Usage:")
        println("  julia examples/plot_network_simple.jl [case_directory] [stage]")
        println()
        println("Example:")
        println(
            "  julia examples/plot_network_simple.jl docs/Sample/DS_ONS_102025_RV2D11 1",
        )
        exit(1)
    end

    # Create diagram
    try
        plot_electrical_network(
            case_dir,
            stage = stage,
            output_file = "electrical_network.png",
            max_buses = 500,
        )
    catch e
        println("❌ ERROR: Failed to create diagram")
        println("   $e")
        showerror(stdout, e, catch_backtrace())
        exit(1)
    end
end
