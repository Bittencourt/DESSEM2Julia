"""
Network topology extraction from DESSEM PDO output files.

This module extracts complete network topology (buses and lines) from:
- PDO_SOMFLUX.DAT: Line flows and connectivity
- PDO_OPERACAO.DAT: Bus attributes (generation, load)

The extracted topology can be used for:
- Network visualization
- Connectivity analysis
- Flow pattern analysis
- Graph-based network studies
"""
module NetworkTopologyParser

using ..Types: NetworkBus, NetworkLine, NetworkTopology

export parse_pdo_somflux_topology, parse_network_topology

# ============================================================================
# PDO_SOMFLUX Parser - Line Connectivity
# ============================================================================

"""
    parse_pdo_somflux_topology(filepath; stage=1) -> NetworkTopology

Extract network topology from PDO_SOMFLUX.DAT file.

This file contains line flow results with bus connections:
```
IPER ; Bar De/; Bar Para ;Cir;   Valor   ;   Linf    ;   Lsup    
  1  ;  1027  ;   556   ; 1 ; -323.788 ;    -      ;    -      
  1  ;  1027  ;   556   ; 2 ; -181.185 ;    -      ;    -      
```

# Arguments
- `filepath`: Path to pdo_somflux.dat file
- `stage`: Time stage to extract (default: 1, range: 1-48)

# Returns
- `NetworkTopology`: Topology with lines and discovered buses

# DESSEM Output File
PDO_SOMFLUX.DAT - Line flow summary by electrical constraint
"""
function parse_pdo_somflux_topology(filepath::AbstractString; stage::Int=1)
    lines = NetworkLine[]
    buses_set = Set{Int}()
    load_level = ""
    in_data = false
    
    open(filepath, "r") do io
        for (line_num, raw_line) in enumerate(eachline(io))
            # Detect data start (second dash line after IPER label line)
            if occursin(r"^-----;.*-----;", raw_line)
                in_data = true
                continue
            end
            
            # Skip until we find data
            !in_data && continue
            
            # Parse semicolon-delimited line
            !occursin(";", raw_line) && continue
            
            parts = split(raw_line, ";")
            length(parts) < 12 && continue
            
            # Extract fields
            stage_str = strip(parts[1])
            isempty(stage_str) && continue
            
            try
                line_stage = parse(Int, stage_str)
                
                # Only process requested stage
                line_stage != stage && continue
                
                # Extract load level
                load_level_str = strip(parts[3])
                if isempty(load_level)
                    load_level = load_level_str
                end
                
                # Extract bus numbers (fields 8 and 9)
                from_bus_str = strip(parts[8])
                to_bus_str = strip(parts[9])
                
                # Skip summary rows (no bus numbers)
                (from_bus_str == "-" || to_bus_str == "-") && continue
                (isempty(from_bus_str) || isempty(to_bus_str)) && continue
                
                from_bus = parse(Int, from_bus_str)
                to_bus = parse(Int, to_bus_str)
                
                # Extract circuit ID (field 10)
                circuit_str = strip(parts[10])
                circuit = (circuit_str == "-" || isempty(circuit_str)) ? 1 : parse(Int, circuit_str)
                
                # Extract flow value (field 11)
                flow_str = strip(parts[11])
                flow = nothing
                if !isempty(flow_str) && flow_str != "-"
                    flow = parse(Float64, replace(flow_str, "," => "."))
                end
                
                # Extract capacity - Lsup (field 13)
                capacity_str = strip(parts[13])
                capacity = nothing
                if !isempty(capacity_str) && capacity_str != "-"
                    capacity = parse(Float64, replace(capacity_str, "," => "."))
                end
                
                # Constraint name
                constraint_name = strip(parts[6])
                
                # Add line
                push!(lines, NetworkLine(
                    from_bus=from_bus,
                    to_bus=to_bus,
                    circuit=circuit,
                    flow_mw=flow,
                    capacity_mw=capacity,
                    constraint_name=constraint_name
                ))
                
                # Track buses
                push!(buses_set, from_bus)
                push!(buses_set, to_bus)
                
            catch e
                # Skip malformed lines
                @debug "Failed to parse line $line_num" exception=(e, catch_backtrace())
                continue
            end
        end
    end
    
    # Create bus objects from discovered bus numbers
    buses = [NetworkBus(bus_number=num) for num in sort(collect(buses_set))]
    
    return NetworkTopology(
        buses=buses,
        lines=lines,
        stage=stage,
        load_level=load_level,
        metadata=Dict(
            "source" => "pdo_somflux.dat",
            "stage" => stage
        )
    )
end

# ============================================================================
# PDO_OPERACAO Parser - Bus Attributes
# ============================================================================

"""
    parse_pdo_operacao_buses(filepath; stage=1) -> Dict{Int, NetworkBus}

Extract bus attributes from PDO_OPERACAO.DAT file.

Parses the hydro plant section which contains:
```
IND     NOME     SIST    QTMAQ   VARM      GTER   QTUR   QINC   ...
 37 BARRA BONITA  SE  76.21   1955.55     0.17   ...
 86 BARRA GRANDE  S   97.49   2137.62     0.45   ...
```

# Arguments
- `filepath`: Path to pdo_operacao.dat file
- `stage`: Time stage to extract (default: 1)

# Returns
- `Dict{Int, NetworkBus}`: Map of bus_number => NetworkBus with attributes
"""
function parse_pdo_operacao_buses(filepath::AbstractString; stage::Int=1)
    buses = Dict{Int, NetworkBus}()
    
    open(filepath, "r") do io
        in_hydro_section = false
        
        for raw_line in eachline(io)
            # Detect hydro generation section
            if occursin(r"GERACAO\s+HIDR", raw_line) || occursin(r"IND\s+NOME\s+SIST", raw_line)
                in_hydro_section = true
                continue
            end
            
            # Exit section markers
            if in_hydro_section && (
                occursin(r"GERACAO\s+TERM", raw_line) ||
                occursin(r"^\s*$", raw_line) && length(raw_line) < 5
            )
                in_hydro_section = false
                continue
            end
            
            # Parse hydro plant lines
            if in_hydro_section && !occursin("---", raw_line)
                # Try to parse: IND NAME SUBSYSTEM ...
                parts = split(strip(raw_line))
                length(parts) < 3 && continue
                
                try
                    bus_num = parse(Int, parts[1])
                    
                    # Extract name (may be multiple parts)
                    name_start = 2
                    name_parts = String[]
                    subsystem_idx = name_start
                    
                    # Find subsystem marker (SE, S, N, NE)
                    for i in name_start:length(parts)
                        if parts[i] in ["SE", "S", "N", "NE"]
                            subsystem_idx = i
                            break
                        else
                            push!(name_parts, parts[i])
                        end
                    end
                    
                    name = join(name_parts, " ")
                    subsystem = subsystem_idx <= length(parts) ? parts[subsystem_idx] : ""
                    
                    # Extract generation (after subsystem)
                    generation = nothing
                    if subsystem_idx + 1 <= length(parts)
                        gen_str = parts[subsystem_idx + 1]
                        if gen_str != "-"
                            generation = parse(Float64, replace(gen_str, "," => "."))
                        end
                    end
                    
                    # Extract load (after generation)
                    load = nothing
                    if subsystem_idx + 2 <= length(parts)
                        load_str = parts[subsystem_idx + 2]
                        if load_str != "-"
                            load = parse(Float64, replace(load_str, "," => "."))
                        end
                    end
                    
                    buses[bus_num] = NetworkBus(
                        bus_number=bus_num,
                        name=name,
                        subsystem=subsystem,
                        generation_mw=generation,
                        load_mw=load
                    )
                    
                catch e
                    # Skip malformed lines
                    continue
                end
            end
        end
    end
    
    return buses
end

# ============================================================================
# Combined Topology Extraction
# ============================================================================

"""
    parse_network_topology(case_dir::String; stage=1) -> NetworkTopology

Extract complete network topology from DESSEM case directory.

Combines data from:
1. PDO_SOMFLUX.DAT - Line connectivity and flows
2. PDO_OPERACAO.DAT - Bus attributes (generation, load, names)

# Arguments
- `case_dir`: Path to DESSEM case directory
- `stage`: Time stage to extract (default: 1, range: 1-48)

# Returns
- `NetworkTopology`: Complete network with enriched bus and line data

# Example
```julia
topology = parse_network_topology("docs/Sample/DS_ONS_102025_RV2D11", stage=1)
println("Buses: ", length(topology.buses))
println("Lines: ", length(topology.lines))
```
"""
function parse_network_topology(case_dir::AbstractString; stage::Int=1)
    # Parse line connectivity from PDO_SOMFLUX
    somflux_path = joinpath(case_dir, "pdo_somflux.dat")
    topology = parse_pdo_somflux_topology(somflux_path, stage=stage)
    
    # Parse bus attributes from PDO_OPERACAO
    operacao_path = joinpath(case_dir, "pdo_operacao.dat")
    if isfile(operacao_path)
        bus_attrs = parse_pdo_operacao_buses(operacao_path, stage=stage)
        
        # Enrich topology buses with attributes
        enriched_buses = NetworkBus[]
        for bus in topology.buses
            if haskey(bus_attrs, bus.bus_number)
                # Use enriched version
                push!(enriched_buses, bus_attrs[bus.bus_number])
            else
                # Keep original
                push!(enriched_buses, bus)
            end
        end
        
        topology = NetworkTopology(
            buses=enriched_buses,
            lines=topology.lines,
            stage=topology.stage,
            load_level=topology.load_level,
            metadata=merge(topology.metadata, Dict("enriched" => true))
        )
    end
    
    return topology
end

end # module
