"""
PWF file parser using PWF.jl library.

This module provides a wrapper around the PWF.jl library (developed by LAMPS/PUC-Rio)
to read ANAREDE .pwf (power flow) files and convert them to DESSEM2Julia network types.

## PWF.jl Library
- **Repository**: https://github.com/LAMPSPUC/PWF.jl
- **Documentation**: https://lampspuc.github.io/PWF.jl/
- **Developer**: LAMPS research group at PUC-Rio (Brazil)
- **Purpose**: Read ANAREDE power system data files

## Why Use PWF.jl Instead of Custom Parser?
1. ✅ Well-tested, specialized library for Brazilian power systems
2. ✅ Handles complex binary ANAREDE format
3. ✅ Maintained by domain experts (PUC-Rio)
4. ✅ Avoids reinventing the wheel
5. ✅ Regular updates for format changes

## ANAREDE File Context
ANAREDE files (.pwf, .afp) are used in DESSEM for electrical network modeling:
- `.pwf`: Base case network data (power flow)
- `.afp`: Pattern/modification files for stage-specific changes
- Referenced by DESSELET.DAT (network case mapping)

## IDESSEM Alignment
This approach maintains consistency with IDESSEM philosophy:
- IDESSEM does NOT parse binary ANAREDE files
- Only extracts filenames from DESSELET.DAT index
- By using PWF.jl, we get the best of both worlds:
  * Don't reimplement complex binary parsing
  * Still provide access to network data when needed
  * Leverage specialized, maintained library

## PWF.jl Reference
PWF.jl returns a Dictionary with the following structure (typical):
```julia
Dict{
    "buses" => Vector{Dict} with bus data,
    "branches" => Vector{Dict} with branch data,
    "generators" => Vector{Dict} with generator data,
    # ... other ANAREDE data blocks
}
```
"""
module PWFParser

using PWF
using Dates
using ..Types: NetworkBus, NetworkLine, NetworkTopology
using ..ParserCommon: ParserError

export parse_pwf, parse_pwf_to_topology

"""
    parse_pwf(filepath::AbstractString) -> Dict{String, Any}

Parse an ANAREDE .pwf file using the PWF.jl library.

# Arguments
- `filepath`: Path to .pwf file

# Returns
- Dictionary with PWF.jl parsed data structure

# Note
This is a thin wrapper around PWF.jl's reading function.
The returned structure is PWF.jl's native format.

# Example
```julia
pwf_data = parse_pwf("leve.pwf")
# Access bus data
buses = pwf_data["buses"]
# Access branch data
branches = pwf_data["branches"]
```

# PWF.jl Documentation
See https://lampspuc.github.io/PWF.jl/ for full data structure reference.

# IDESSEM Alignment
IDESSEM does not parse .pwf files - it only stores filenames from DESSELET.DAT.
This function provides optional network data access when needed.
"""
function parse_pwf(filepath::AbstractString)::Dict{String,Any}
    try
        # Use PWF.jl to read the file
        pwf_data = PWF.parse_file(filepath)

        # Add metadata
        if pwf_data !== nothing
            pwf_data["_metadata"] = Dict{String,Any}(
                "source" => String(filepath),
                "parser" => "PWF.jl",
                "parsed_at" => Dates.now(),
            )
        end

        return pwf_data
    catch e
        if isa(e, ParserError)
            rethrow(e)
        else
            throw(
                ParserError(
                    "Failed to parse PWF file: $(sprint(showerror, e))",
                    filepath,
                    0,
                    "",
                ),
            )
        end
    end
end

"""
    parse_pwf_to_topology(filepath::AbstractString; kwargs...) -> NetworkTopology

Parse an ANAREDE .pwf file and convert to DESSEM2Julia NetworkTopology.

# Arguments
- `filepath`: Path to .pwf file
- `kwargs`: Additional keyword arguments passed to PWF.jl

# Returns
- `NetworkTopology`: DESSEM2Julia network topology structure with:
  * `buses`: Vector of NetworkBus (from ANAREDE DBAR data)
  * `lines`: Vector of NetworkLine (from ANAREDE DLIN data)
  * `metadata`: Includes source file and parser info

# Conversion Mapping

## Bus Data (DBAR → NetworkBus)
- `bus_number`: Bus ID
- `name`: Bus name
- `voltage_kv`: Nominal voltage (kV)
- `subsystem`: Mapped from area code or derived from voltage level
- `generation_mw`: Total generation at bus
- `load_mw`: Load at bus

## Line Data (DLIN → NetworkLine)
- `from_bus`: From bus number
- `to_bus`: To bus number
- `circuit`: Circuit identifier
- `capacity_mw`: Flow limit (from ANAREDE ratings)
- Other parameters available in PWF.jl data

# Example
```julia
# Parse PWF file to topology
topology = parse_pwf_to_topology("leve.pwf")

# Access buses
println("Number of buses: \$(length(topology.buses))")

# Access lines
println("Number of lines: \$(length(topology.lines))")

# Find buses by subsystem
se_buses = filter(b -> b.subsystem == "SE", topology.buses)
```

# Integration with DESSELET
```julia
# Parse DESSELET to get PWF filenames
desselet_data = parse_desselet("desselet.dat")

# For each base case
for base_case in desselet_data.base_cases
    pwf_file = base_case.filename  # e.g., "leve.pwf"
    topology = parse_pwf_to_topology(pwf_file)

    # Use topology for network analysis
    # ...
end
```

# Limitations
1. **Subsystem mapping**: PWF files may not have explicit subsystem codes.
   We attempt to derive from area codes or voltage levels, but may be incomplete.
2. **Generation/Load**: These values may represent initial conditions, not optimized values.
3. **Stage-specific**: Each PWF file represents a single load level (LEVE, MEDIA, PESADA).

# See Also
- `parse_desselet`: Parse DESSELET.DAT to get PWF filenames
- `NetworkTopology`: DESSEM2Julia network topology type
- PWF.jl documentation: https://lampspuc.github.io/PWF.jl/

# IDESSEM Alignment
Optional function for users who need network topology analysis.
Not required for basic DESSEM workflow.
"""
function parse_pwf_to_topology(filepath::AbstractString; kwargs...)::NetworkTopology
    # Parse PWF file
    pwf_data = parse_pwf(filepath)

    buses = NetworkBus[]
    lines = NetworkLine[]

    # Extract bus data from PWF structure (PowerModels format uses "bus" as Dict)
    if haskey(pwf_data, "bus")
        bus_dict = pwf_data["bus"]
        for (bus_id, bus_data) in bus_dict
            try
                # Convert PWF bus to NetworkBus
                bus = convert_pwfbus_to_networkbus(bus_data)
                push!(buses, bus)
            catch e
                if isa(e, ParserError)
                    rethrow(e)
                else
                    throw(
                        ParserError(
                            "Failed to convert bus data: $(sprint(showerror, e))",
                            filepath,
                            0,
                            string(bus_data),
                        ),
                    )
                end
            end
        end
    elseif haskey(pwf_data, "buses") || haskey(pwf_data, "bars")
        # Fallback for different naming conventions
        bus_list = get(pwf_data, "buses", get(pwf_data, "bars", []))
        for bus_data in bus_list
            try
                bus = convert_pwfbus_to_networkbus(bus_data)
                push!(buses, bus)
            catch e
                if isa(e, ParserError)
                    rethrow(e)
                else
                    throw(
                        ParserError(
                            "Failed to convert bus data: $(sprint(showerror, e))",
                            filepath,
                            0,
                            string(bus_data),
                        ),
                    )
                end
            end
        end
    end

    # Extract branch/line data from PWF structure (PowerModels format uses "branch" as Dict)
    if haskey(pwf_data, "branch")
        branch_dict = pwf_data["branch"]
        for (branch_id, branch_data) in branch_dict
            try
                # Convert PWF branch to NetworkLine
                line = convert_pwfbranch_to_networkline(branch_data)
                push!(lines, line)
            catch e
                if isa(e, ParserError)
                    rethrow(e)
                else
                    throw(
                        ParserError(
                            "Failed to convert branch data: $(sprint(showerror, e))",
                            filepath,
                            0,
                            string(branch_data),
                        ),
                    )
                end
            end
        end
    elseif haskey(pwf_data, "branches") || haskey(pwf_data, "linhas")
        # Fallback for different naming conventions
        branch_list = get(pwf_data, "branches", get(pwf_data, "linhas", []))
        for branch_data in branch_list
            try
                line = convert_pwfbranch_to_networkline(branch_data)
                push!(lines, line)
            catch e
                if isa(e, ParserError)
                    rethrow(e)
                else
                    throw(
                        ParserError(
                            "Failed to convert branch data: $(sprint(showerror, e))",
                            filepath,
                            0,
                            string(branch_data),
                        ),
                    )
                end
            end
        end
    end

    # Create topology with metadata
    return NetworkTopology(
        buses = buses,
        lines = lines,
        stage = nothing,
        load_level = "",
        metadata = Dict{String,Any}(
            "source_file" => String(filepath),
            "parser" => "PWF.jl",
            "pwf_data" => pwf_data,
            "num_buses" => length(buses),
            "num_lines" => length(lines),
        ),
    )
end

"""
    convert_pwfbus_to_networkbus(pwf_bus::Dict) -> NetworkBus

Convert a PWF.jl bus dictionary to DESSEM2Julia NetworkBus.

# Conversion Details
PWF.jl bus structure → NetworkBus:
- Bus code/number → `bus_number`
- Bus name → `name`
- Base voltage → `voltage_kv`
- Area code → subsystem (SE, S, NE, N)
- Generation → `generation_mw`
- Load → `load_mw`

# Subsystem Mapping
ANAREDE uses area codes that map to Brazilian subsystems:
- Area 1, 2, 3 → SE (Southeast)
- Area 4 → S (South)
- Area 5 → NE (Northeast)
- Area 6 → N (North)

If area code not available, subsystem is left empty.
"""
function convert_pwfbus_to_networkbus(pwf_bus::Dict)
    # Extract bus number (may be named "bus_i", "codigo", "number", "bus_id", etc.)
    bus_num = nothing
    for key in ["bus_i", "codigo", "number", "bus_id", "bus", "nb"]
        if haskey(pwf_bus, key)
            bus_num = pwf_bus[key]
            break
        end
    end
    bus_num === nothing &&
        throw(ParserError("Bus number not found in PWF bus data", "", 0, ""))

    # Extract bus name
    name = ""
    for key in ["name", "nome", "bus_name", "descricao"]
        if haskey(pwf_bus, key)
            name = String(pwf_bus[key])
            break
        end
    end

    # Extract voltage
    voltage_kv = nothing
    for key in ["base_kv", "vbase", "basekv", "voltage", "tensao", "kv"]
        if haskey(pwf_bus, key)
            voltage_kv = Float64(pwf_bus[key])
            break
        end
    end

    # Extract subsystem from area code
    subsystem = ""
    if haskey(pwf_bus, "area") || haskey(pwf_bus, "area_code")
        area_code = get(pwf_bus, "area", get(pwf_bus, "area_code", nothing))
        if area_code !== nothing
            area_int = Int(area_code)
            subsystem = if area_int in [1, 2, 3]
                "SE"
            elseif area_int == 4
                "S"
            elseif area_int == 5
                "NE"
            elseif area_int == 6
                "N"
            else
                ""
            end
        end
    end

    # Extract generation
    gen_mw = nothing
    for key in ["pg", "geracao", "generation", "pload", "potencia"]
        if haskey(pwf_bus, key)
            gen_mw = Float64(pwf_bus[key])
            break
        end
    end

    # Extract load
    load_mw = nothing
    for key in ["pl", "carga", "load", "pdemanda"]
        if haskey(pwf_bus, key)
            load_mw = Float64(pwf_bus[key])
            break
        end
    end

    return NetworkBus(
        bus_number = Int(bus_num),
        name = name,
        subsystem = subsystem,
        generation_mw = gen_mw,
        load_mw = load_mw,
        voltage_kv = voltage_kv,
    )
end

"""
    convert_pwfbranch_to_networkline(pwf_branch::Dict) -> NetworkLine

Convert a PWF.jl branch (transmission line) dictionary to DESSEM2Julia NetworkLine.

# Conversion Details
PWF.jl branch structure → NetworkLine:
- From bus → `from_bus`
- To bus → `to_bus`
- Circuit ID → `circuit`
- Flow limit/rating → `capacity_mw`
- Reactance/Resistance → stored in metadata if needed

# Note
Flow values in PWF files are typically base case or initial conditions.
For actual DESSEM optimization results, use PDO output files.
"""
function convert_pwfbranch_to_networkline(pwf_branch::Dict)
    # Extract from bus (PowerModels uses "f_bus")
    from_bus = nothing
    for key in ["f_bus", "de", "from", "bus_from", "nb1"]
        if haskey(pwf_branch, key)
            from_bus = pwf_branch[key]
            break
        end
    end
    from_bus === nothing &&
        throw(ParserError("From bus not found in PWF branch data", "", 0, ""))

    # Extract to bus (PowerModels uses "t_bus")
    to_bus = nothing
    for key in ["t_bus", "para", "to", "bus_to", "nb2"]
        if haskey(pwf_branch, key)
            to_bus = pwf_branch[key]
            break
        end
    end
    to_bus === nothing &&
        throw(ParserError("To bus not found in PWF branch data", "", 0, ""))

    # Extract circuit
    circuit = 1
    for key in ["circuito", "circuit", "ck", "index"]
        if haskey(pwf_branch, key)
            circuit = Int(pwf_branch[key])
            break
        end
    end

    # Extract capacity/rating (PowerModels uses "rate_a")
    capacity_mw = nothing
    for key in ["rate_a", "rating", "capacidade", "fluxo_max", "limit"]
        if haskey(pwf_branch, key)
            capacity_mw = Float64(pwf_branch[key])
            break
        end
    end

    return NetworkLine(
        from_bus = Int(from_bus),
        to_bus = Int(to_bus),
        circuit = circuit,
        flow_mw = nothing,  # PWF base case doesn't have flow
        capacity_mw = capacity_mw,
        constraint_name = "",
    )
end

end # module
