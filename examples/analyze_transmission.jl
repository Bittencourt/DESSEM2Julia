using DESSEM2Julia
using Printf

# Define path to sample file
const SAMPLE_DIR = joinpath(dirname(@__DIR__), "docs", "Sample", "DS_ONS_102025_RV2D11")

function analyze_transmission()
    println("Analyzing Transmission Network Congestion...")
    println("Case Directory: $SAMPLE_DIR")

    # Parse topology (Stage 1)
    # This automatically combines PDO_SOMFLUX (flows) and PDO_OPERACAO (bus names)
    topology = parse_network_topology(SAMPLE_DIR, stage = 1)

    if isempty(topology.lines)
        println(
            "Error: No transmission lines found. Check if pdo_somflux.dat exists and is populated.",
        )
        return
    end

    println("\nNetwork Summary (Stage 1):")
    println("  Buses: $(length(topology.buses))")
    println("  Lines: $(length(topology.lines))")

    # Create a map for bus names
    bus_map = Dict(b.bus_number => b.name for b in topology.buses)
    get_bus_name(id) = get(bus_map, id, "Bus $id")

    # ------------------------------------------------------------------------
    # 1. Analyze Aggregate Constraints (from Metadata)
    # ------------------------------------------------------------------------
    if haskey(topology.metadata, "constraints")
        constraints = topology.metadata["constraints"]
        println(
            "\n================================================================================",
        )
        println("TOP 20 CRITICAL AGGREGATE CONSTRAINTS (Highest Loading %)")
        println(
            "================================================================================",
        )
        @printf(
            "%-40s | %12s | %12s | %12s | %8s\n",
            "Constraint Name",
            "Flow (MW)",
            "Limit (MW)",
            "Slack (MW)",
            "Load %"
        )
        println(
            "----------------------------------------------------------------------------------------------------",
        )

        constraint_list = []
        for (name, data) in constraints
            flow = data["flow"]
            lsup = data["Lsup"]
            linf = data["Linf"]

            if isnothing(flow) || isnothing(lsup)
                continue
            end

            # Calculate loading based on upper limit (most common)
            loading = 0.0
            limit = lsup
            slack = lsup - flow

            # Simple loading calculation for display
            if lsup != 0
                loading = (flow / lsup) * 100.0
            end

            push!(constraint_list, (name, flow, lsup, slack, loading))
        end

        # Sort by Loading (Descending)
        sort!(constraint_list, by = x -> x[5], rev = true)

        for i in 1:min(20, length(constraint_list))
            name, flow, limit, slack, loading = constraint_list[i]
            status = loading > 100 ? "(!)" : ""
            @printf(
                "%-40s | %12.1f | %12.1f | %12.1f | %8.1f%% %s\n",
                name,
                flow,
                limit,
                slack,
                loading,
                status
            )
        end
    end

    # ------------------------------------------------------------------------
    # 2. Analyze Individual Lines
    # ------------------------------------------------------------------------

    # Filter lines with flow data
    active_lines = filter(l -> !isnothing(l.flow_mw), topology.lines)

    if isempty(active_lines)
        println("Warning: No lines with flow data found.")
        return
    end

    # Separate lines with and without capacity
    lines_with_cap =
        filter(l -> !isnothing(l.capacity_mw) && l.capacity_mw > 0.1, active_lines)
    lines_no_cap =
        filter(l -> isnothing(l.capacity_mw) || l.capacity_mw <= 0.1, active_lines)

    # --- Lines WITH Capacity ---
    if !isempty(lines_with_cap)
        line_loading = []
        for line in lines_with_cap
            abs_flow = abs(line.flow_mw)
            loading = (abs_flow / line.capacity_mw) * 100.0
            push!(line_loading, (line, loading, abs_flow))
        end
        sort!(line_loading, by = x -> x[2], rev = true)

        println(
            "\n================================================================================",
        )
        println("TOP 20 MOST CONGESTED LINES (Highest Loading %)")
        println(
            "================================================================================",
        )
        @printf(
            "%-30s -> %-30s | %-4s | %10s | %10s | %8s\n",
            "From Bus",
            "To Bus",
            "Cir",
            "Flow",
            "Limit",
            "Load %"
        )
        println(
            "----------------------------------------------------------------------------------------------------------",
        )

        for i in 1:min(20, length(line_loading))
            line, loading, abs_flow = line_loading[i]
            from_name = get_bus_name(line.from_bus)
            to_name = get_bus_name(line.to_bus)
            from_name = length(from_name) > 30 ? from_name[1:27] * "..." : from_name
            to_name = length(to_name) > 30 ? to_name[1:27] * "..." : to_name
            status = loading > 100 ? "(!)" : ""

            @printf(
                "%-30s -> %-30s | %-4d | %10.1f | %10.1f | %8.1f%% %s\n",
                from_name,
                to_name,
                line.circuit,
                abs_flow,
                line.capacity_mw,
                loading,
                status
            )
        end
    end

    # --- Lines WITHOUT Capacity (Just Flows) ---
    if !isempty(lines_no_cap)
        # Sort by Absolute Flow
        sort!(lines_no_cap, by = l -> abs(l.flow_mw), rev = true)

        println(
            "\n================================================================================",
        )
        println("TOP 20 HIGHEST FLOW LINES (Limit Unknown/Aggregate)")
        println(
            "================================================================================",
        )
        @printf(
            "%-30s -> %-30s | %-4s | %10s | %-20s\n",
            "From Bus",
            "To Bus",
            "Cir",
            "Flow (MW)",
            "Constraint Name"
        )
        println(
            "----------------------------------------------------------------------------------------------------------",
        )

        for i in 1:min(20, length(lines_no_cap))
            line = lines_no_cap[i]
            from_name = get_bus_name(line.from_bus)
            to_name = get_bus_name(line.to_bus)
            from_name = length(from_name) > 30 ? from_name[1:27] * "..." : from_name
            to_name = length(to_name) > 30 ? to_name[1:27] * "..." : to_name

            @printf(
                "%-30s -> %-30s | %-4d | %10.1f | %-20s\n",
                from_name,
                to_name,
                line.circuit,
                line.flow_mw,
                line.constraint_name
            )
        end
    end

    println("\nAnalysis Complete.")
end

analyze_transmission()
