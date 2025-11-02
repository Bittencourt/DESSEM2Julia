"""
    visualize_network_topology.jl

Example: Extract and visualize electrical network topology from DESSEM case.

This script demonstrates how to:
1. Extract network topology from PDO output files
2. Create a graph representation of buses and lines
3. Visualize the network with buses colored by subsystem
4. Calculate basic network statistics

Requirements:
- DESSEM2Julia package
- Graphs.jl for network analysis
- GraphPlot.jl or similar for visualization

Run with:
    julia --project=. examples/visualize_network_topology.jl
"""

using DESSEM2Julia
using Statistics  # For mean()

# For graph analysis (install if needed: ] add Graphs)
try
    using Graphs
    using LinearAlgebra
catch e
    println("Note: Graphs.jl not installed. Install with: ] add Graphs")
    println("Continuing with basic analysis only...")
end

# For plotting (install if needed: ] add GraphPlot, Colors, Plots)
PLOTTING_AVAILABLE = false
try
    using GraphPlot
    using Colors
    using Colors: @colorant_str  # Make sure colorant macro is available
    using Plots
    global PLOTTING_AVAILABLE = true
catch e
    # Plotting libraries not available
end

function analyze_network_topology(case_dir::String; stage::Int = 1)
    """
    Extract and analyze network topology from DESSEM case.
    """
    println("="^80)
    println("Network Topology Analysis")
    println("="^80)
    println("Case directory: $case_dir")
    println("Stage: $stage")
    println()

    # Parse topology from PDO files
    println("Extracting network topology...")
    topology = parse_network_topology(case_dir, stage = stage)

    # Basic statistics
    num_buses = length(topology.buses)
    num_lines = length(topology.lines)

    println("\n" * "="^80)
    println("NETWORK OVERVIEW")
    println("="^80)
    println("Buses: $num_buses")
    println("Lines: $num_lines")
    println("Stage: $(topology.stage)")
    println("Load Level: $(topology.load_level)")
    println()

    # Subsystem distribution
    subsystem_counts = Dict{String,Int}()
    buses_with_names = 0
    buses_with_generation = 0
    buses_with_load = 0

    for bus in topology.buses
        if !isempty(bus.subsystem)
            subsystem_counts[bus.subsystem] = get(subsystem_counts, bus.subsystem, 0) + 1
        end
        !isempty(bus.name) && (buses_with_names += 1)
        !isnothing(bus.generation_mw) && (buses_with_generation += 1)
        !isnothing(bus.load_mw) && (buses_with_load += 1)
    end

    if !isempty(subsystem_counts)
        println("Subsystem Distribution:")
        for (subsystem, count) in sort(collect(subsystem_counts))
            percentage = round(100 * count / num_buses, digits = 1)
            println("  • $subsystem: $count buses ($percentage%)")
        end
        println()
    end

    println("Bus Attributes:")
    println(
        "  • With names: $buses_with_names ($(round(100*buses_with_names/num_buses, digits=1))%)",
    )
    println(
        "  • With generation: $buses_with_generation ($(round(100*buses_with_generation/num_buses, digits=1))%)",
    )
    println(
        "  • With load: $buses_with_load ($(round(100*buses_with_load/num_buses, digits=1))%)",
    )
    println()

    # Line statistics
    lines_with_capacity = count(l -> !isnothing(l.capacity_mw), topology.lines)
    lines_with_constraint = count(l -> !isempty(l.constraint_name), topology.lines)

    println("Line Attributes:")
    println(
        "  • With capacity: $lines_with_capacity ($(round(100*lines_with_capacity/num_lines, digits=1))%)",
    )
    println(
        "  • With constraint names: $lines_with_constraint ($(round(100*lines_with_constraint/num_lines, digits=1))%)",
    )
    println()

    # Connectivity analysis
    println("="^80)
    println("CONNECTIVITY ANALYSIS")
    println("="^80)

    # Calculate degree for each bus
    bus_degrees = Dict{Int,Int}()
    for line in topology.lines
        bus_degrees[line.from_bus] = get(bus_degrees, line.from_bus, 0) + 1
        bus_degrees[line.to_bus] = get(bus_degrees, line.to_bus, 0) + 1
    end

    degrees = collect(values(bus_degrees))
    avg_degree = sum(degrees) / length(degrees)
    max_degree = maximum(degrees)
    min_degree = minimum(degrees)

    println("Bus Degree Statistics:")
    println("  • Average: $(round(avg_degree, digits=2)) connections/bus")
    println("  • Maximum: $max_degree connections")
    println("  • Minimum: $min_degree connections")
    println()

    # Find highly connected buses (hubs)
    hubs = sort(collect(bus_degrees), by = x -> x[2], rev = true)[1:min(
        10,
        length(bus_degrees),
    )]
    println("Top 10 Most Connected Buses:")
    for (i, (bus_num, degree)) in enumerate(hubs)
        bus_idx = findfirst(b -> b.bus_number == bus_num, topology.buses)
        bus_name =
            !isnothing(bus_idx) && !isempty(topology.buses[bus_idx].name) ?
            topology.buses[bus_idx].name : "Bus $bus_num"
        subsystem =
            !isnothing(bus_idx) && !isempty(topology.buses[bus_idx].subsystem) ?
            " ($(topology.buses[bus_idx].subsystem))" : ""
        println("  $i. $bus_name$subsystem - $degree connections")
    end
    println()

    # Power flow statistics
    if any(l -> !isnothing(l.flow_mw), topology.lines)
        flows = [l.flow_mw for l in topology.lines if !isnothing(l.flow_mw)]

        println("="^80)
        println("POWER FLOW ANALYSIS")
        println("="^80)
        println("Line Flow Statistics:")
        println("  • Total flows recorded: $(length(flows))")
        println("  • Max flow: $(round(maximum(abs.(flows)), digits=2)) MW")
        println("  • Average flow: $(round(mean(abs.(flows)), digits=2)) MW")
        println("  • Total power transfer: $(round(sum(abs.(flows)), digits=2)) MW")
        println()

        # Find most loaded lines
        loaded_lines = sort(
            [
                (i, abs(topology.lines[i].flow_mw)) for
                i in 1:length(topology.lines) if !isnothing(topology.lines[i].flow_mw)
            ],
            by = x -> x[2],
            rev = true,
        )[1:min(10, length(flows))]

        println("Top 10 Most Loaded Lines:")
        for (rank, (idx, flow)) in enumerate(loaded_lines)
            line = topology.lines[idx]
            from_name = "Bus $(line.from_bus)"
            to_name = "Bus $(line.to_bus)"

            # Get bus names if available
            from_idx = findfirst(b -> b.bus_number == line.from_bus, topology.buses)
            to_idx = findfirst(b -> b.bus_number == line.to_bus, topology.buses)

            if !isnothing(from_idx) && !isempty(topology.buses[from_idx].name)
                from_name = topology.buses[from_idx].name
            end
            if !isnothing(to_idx) && !isempty(topology.buses[to_idx].name)
                to_name = topology.buses[to_idx].name
            end

            println("  $rank. $from_name → $to_name: $(round(flow, digits=2)) MW")
        end
        println()
    end

    # Graph analysis (if Graphs.jl is available)
    if @isdefined Graphs
        println("="^80)
        println("GRAPH THEORY ANALYSIS")
        println("="^80)

        # Create graph
        g = SimpleGraph(num_buses)

        # Map bus numbers to graph indices
        bus_to_idx = Dict(bus.bus_number => i for (i, bus) in enumerate(topology.buses))

        # Add edges
        for line in topology.lines
            if haskey(bus_to_idx, line.from_bus) && haskey(bus_to_idx, line.to_bus)
                add_edge!(g, bus_to_idx[line.from_bus], bus_to_idx[line.to_bus])
            end
        end

        # Calculate graph metrics
        println("Graph Metrics:")
        println("  • Number of edges: $(ne(g))")
        println("  • Is connected: $(is_connected(g))")

        if is_connected(g)
            println("  • Diameter: $(diameter(g))")
            println("  • Radius: $(radius(g))")
        else
            components = connected_components(g)
            println("  • Number of connected components: $(length(components))")
            println("  • Largest component size: $(maximum(length.(components)))")
            println("  • Smallest component size: $(minimum(length.(components)))")
        end
        println()
    end

    return topology
end

function export_topology_summary(topology::NetworkTopology, output_file::String)
    """
    Export topology summary to CSV file.
    """
    println("Exporting topology summary to: $output_file")

    open(output_file, "w") do io
        # Write buses
        println(io, "BUSES")
        println(io, "bus_number,name,subsystem,generation_mw,load_mw,voltage_kv")
        for bus in topology.buses
            println(
                io,
                "$(bus.bus_number),$(bus.name),$(bus.subsystem)," *
                "$(bus.generation_mw),$(bus.load_mw),$(bus.voltage_kv)",
            )
        end

        println(io, "")

        # Write lines
        println(io, "LINES")
        println(io, "from_bus,to_bus,circuit,flow_mw,capacity_mw,constraint_name")
        for line in topology.lines
            println(
                io,
                "$(line.from_bus),$(line.to_bus),$(line.circuit)," *
                "$(line.flow_mw),$(line.capacity_mw),$(line.constraint_name)",
            )
        end
    end

    println(
        "  ✓ Exported $(length(topology.buses)) buses and $(length(topology.lines)) lines",
    )
end

"""
    plot_network_diagram(topology; output_file="network_diagram.png", 
                        highlight_flows=true, max_buses=500)

Create a typical electrical network diagram showing buses and transmission lines.

# Arguments
- `topology`: NetworkTopology object
- `output_file`: Path to save the diagram (PNG, PDF, SVG supported)
- `highlight_flows`: Color lines by power flow magnitude
- `max_buses`: Maximum number of buses to plot (for performance)
- `layout`: Layout algorithm (:spring, :stress, :circular, :shell)

# Requirements
- Graphs.jl
- GraphPlot.jl
- Colors.jl
- Plots.jl (optional, for enhanced styling)

# Example
```julia
topology = parse_network_topology("path/to/case")
plot_network_diagram(topology, output_file="network.png")
```
"""
function plot_network_diagram(
    topology::NetworkTopology;
    output_file::String = "network_diagram.png",
    highlight_flows::Bool = true,
    max_buses::Int = 500,
    layout::Symbol = :spring,
)
    if !PLOTTING_AVAILABLE
        println("\n⚠️  Plotting libraries not available!")
        println("Install required packages:")
        println("  julia> using Pkg")
        println("  julia> Pkg.add([\"Graphs\", \"GraphPlot\", \"Colors\", \"Plots\"])")
        return nothing
    end

    if !@isdefined(Graphs) || !@isdefined(GraphPlot)
        println("\n⚠️  Graphs.jl and GraphPlot.jl required for plotting")
        return nothing
    end

    println("\n" * "="^80)
    println("Creating Network Diagram")
    println("="^80)

    num_buses = length(topology.buses)
    num_lines = length(topology.lines)

    # Limit buses for performance
    if num_buses > max_buses
        println("⚠️  Network has $num_buses buses. Limiting to $max_buses for performance.")
        println("   Use max_buses parameter to adjust.")
    end

    # Create bus index mapping
    bus_to_idx = Dict(bus.bus_number => i for (i, bus) in enumerate(topology.buses))

    # Build graph
    println("Building graph structure...")
    g = SimpleGraph(min(num_buses, max_buses))

    edge_flows = Float64[]
    edge_labels = String[]

    for line in topology.lines
        if haskey(bus_to_idx, line.from_bus) && haskey(bus_to_idx, line.to_bus)
            from_idx = bus_to_idx[line.from_bus]
            to_idx = bus_to_idx[line.to_bus]

            # Skip if exceeding max_buses
            if from_idx > max_buses || to_idx > max_buses
                continue
            end

            add_edge!(g, from_idx, to_idx)
            push!(edge_flows, isnothing(line.flow_mw) ? 0.0 : abs(line.flow_mw))
            push!(edge_labels, "C$(line.circuit)")
        end
    end

    println("Graph: $(nv(g)) nodes, $(ne(g)) edges")

    # Node colors by subsystem
    subsystem_colors = Dict(
        "SE" => colorant"#FF6B6B",  # Red - Southeast
        "S" => colorant"#4ECDC4",  # Cyan - South
        "NE" => colorant"#FFD93D",  # Yellow - Northeast
        "N" => colorant"#95E1D3",  # Green - North
        "" => colorant"#CCCCCC",   # Gray - Unknown
    )

    node_colors = [
        subsystem_colors[get(bus_to_idx, i, 1) <= length(topology.buses) ?
                         topology.buses[get(bus_to_idx, i, 1)].subsystem : ""] for
        i in 1:nv(g)
    ]

    # Node sizes by degree (number of connections)
    node_degrees = degree(g)
    node_sizes = [0.02 + 0.01 * log(1 + d) for d in node_degrees]

    # Edge colors by flow magnitude
    if highlight_flows && !isempty(edge_flows)
        max_flow = maximum(edge_flows)
        # Create colors with alpha channel based on flow magnitude
        edge_colors = [RGBA(0.4, 0.4, 0.4, 0.2 + 0.8 * f / max_flow) for f in edge_flows]
        edge_widths = [0.5 + 2.0 * f / max_flow for f in edge_flows]
    else
        edge_colors = [colorant"gray" for _ in 1:ne(g)]
        edge_widths = ones(ne(g))
    end

    # Node labels (show bus numbers for important buses)
    node_labels = String[]
    for i in 1:nv(g)
        if i <= length(topology.buses)
            bus = topology.buses[i]
            # Label high-degree buses or named buses
            if node_degrees[i] > 8 || !isempty(bus.name)
                if !isempty(bus.name)
                    push!(node_labels, bus.name)
                else
                    push!(node_labels, string(bus.bus_number))
                end
            else
                push!(node_labels, "")
            end
        else
            push!(node_labels, "")
        end
    end

    # Choose layout
    println("Computing layout (algorithm: $layout)...")
    if layout == :spring
        loc_x, loc_y = spring_layout(g)
    elseif layout == :stress
        loc_x, loc_y = stressmajorize_layout(g)
    elseif layout == :circular
        loc_x, loc_y = circular_layout(g)
    elseif layout == :shell
        loc_x, loc_y = shell_layout(g)
    else
        loc_x, loc_y = spring_layout(g)
    end

    # Create plot
    println("Rendering diagram...")

    # Set figure size based on network size
    fig_width = min(20, 10 + num_buses / 50)
    fig_height = min(20, 10 + num_buses / 50)

    # Plot with GraphPlot
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
        NODELABELSIZE = 3.0,
        EDGELINEWIDTH = 0.5,
    )

    # Save to file
    println("Saving to: $output_file")

    # Use Compose to save
    using Compose
    draw(PNG(output_file, fig_width * 100, fig_height * 100), p)

    println("✓ Network diagram saved!")

    # Print legend
    println("\n" * "="^80)
    println("DIAGRAM LEGEND")
    println("="^80)
    println("Node Colors:")
    println("  🔴 Red    - Southeast (SE) subsystem")
    println("  🔵 Cyan   - South (S) subsystem")
    println("  🟡 Yellow - Northeast (NE) subsystem")
    println("  🟢 Green  - North (N) subsystem")
    println("  ⚪ Gray   - Unknown subsystem")
    println("\nNode Size: Proportional to number of connections (degree)")
    println("Edge Thickness: Proportional to power flow magnitude (MW)")
    println("Edge Opacity: Higher for larger power flows")
    println("\nLabels shown for:")
    println("  • Named buses (hydro plants)")
    println("  • High-connectivity buses (>8 connections)")
    println("="^80)

    return p
end

"""
    plot_subsystem_diagram(topology, subsystem; output_file=nothing)

Plot network diagram for a specific subsystem (SE, S, NE, N).
"""
function plot_subsystem_diagram(
    topology::NetworkTopology,
    subsystem::String;
    output_file::Union{String,Nothing} = nothing,
)
    if isnothing(output_file)
        output_file = "network_$(lowercase(subsystem)).png"
    end

    println("\nFiltering topology for subsystem: $subsystem")

    # Filter buses by subsystem
    filtered_buses = [bus for bus in topology.buses if bus.subsystem == subsystem]
    bus_numbers = Set([bus.bus_number for bus in filtered_buses])

    # Filter lines connecting buses in this subsystem
    filtered_lines = [
        line for line in topology.lines if
        line.from_bus in bus_numbers && line.to_bus in bus_numbers
    ]

    # Create filtered topology
    filtered_topology = NetworkTopology(
        buses = filtered_buses,
        lines = filtered_lines,
        stage = topology.stage,
        load_level = topology.load_level,
        metadata = merge(topology.metadata, Dict("subsystem_filter" => subsystem)),
    )

    println("  Filtered: $(length(filtered_buses)) buses, $(length(filtered_lines)) lines")

    # Plot
    return plot_network_diagram(
        filtered_topology,
        output_file = output_file,
        max_buses = 1000,
    )
end

# Main execution
if !isinteractive()
    # Default to ONS sample case
    case_dir = joinpath(@__DIR__, "..", "docs", "Sample", "DS_ONS_102025_RV2D11")

    # Check if case directory exists
    if !isdir(case_dir)
        println("ERROR: Case directory not found: $case_dir")
        println("\nPlease provide a valid DESSEM case directory:")
        println("  julia examples/visualize_network_topology.jl /path/to/dessem/case")
        exit(1)
    end

    # Allow command-line argument for case directory
    if length(ARGS) > 0
        case_dir = ARGS[1]
    end

    # Allow command-line argument for stage
    stage = length(ARGS) > 1 ? parse(Int, ARGS[2]) : 1

    # Analyze topology
    topology = analyze_network_topology(case_dir, stage = stage)

    # Export summary
    output_file = "network_topology_summary.csv"
    export_topology_summary(topology, output_file)

    # Create network diagram if plotting is available
    if PLOTTING_AVAILABLE
        println("\n" * "="^80)
        println("Generating Network Diagram")
        println("="^80)

        try
            # Full network diagram
            plot_network_diagram(
                topology,
                output_file = "network_full.png",
                highlight_flows = true,
                max_buses = 500,
                layout = :spring,
            )

            # Plot individual subsystems if they exist
            subsystems =
                unique([bus.subsystem for bus in topology.buses if !isempty(bus.subsystem)])

            if !isempty(subsystems)
                println("\nGenerating subsystem diagrams...")
                for subsystem in subsystems
                    try
                        plot_subsystem_diagram(topology, subsystem)
                    catch e
                        println("  ⚠️  Could not plot subsystem $subsystem: $e")
                    end
                end
            end

        catch e
            println("⚠️  Could not create network diagram: $e")
            println("Continuing without visualization...")
        end
    else
        println("\n" * "="^80)
        println("Network Visualization")
        println("="^80)
        println("📊 To create network diagrams, install plotting libraries:")
        println("  julia> using Pkg")
        println("  julia> Pkg.add([\"Graphs\", \"GraphPlot\", \"Colors\", \"Compose\"])")
        println()
    end

    println("\n" * "="^80)
    println("Analysis complete!")
    println("="^80)
    println("Summary exported to: $output_file")

    if PLOTTING_AVAILABLE
        println("\nGenerated diagrams:")
        println("  • network_full.png - Complete network topology")
        subsystems =
            unique([bus.subsystem for bus in topology.buses if !isempty(bus.subsystem)])
        for subsystem in subsystems
            println("  • network_$(lowercase(subsystem)).png - $(subsystem) subsystem")
        end
    else
        println("\nTo create network diagrams, install:")
        println("  ] add Graphs GraphPlot Colors Compose")
    end
    println()
end
