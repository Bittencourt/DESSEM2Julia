module DESSEM2Julia

export greet
export DessemData, convert_inputs
export ThermalRegistry, CADUSIT, CADUNIDT, CURVACOMB
export GeneralData, TMRecord, SISTRecord, UHRecord, UTRecord, DPRecord
export OperuhData, HydroConstraintREST, HydroConstraintELEM, HydroConstraintLIM, HydroConstraintVAR
export OperutData, INITRecord, OPERRecord
export DadvazData, DadvazHeader, DadvazInflowRecord
export DeflantData, DeflantRecord
export DesseletData, DesseletBaseCase, DesseletPatamar
export HidrData, CADUSIH, USITVIAG, POLCOT, POLARE, POLJUS, COEFEVA, CADCONJ, BinaryHidrRecord, BinaryHidrData
export parse_termdat, parse_entdados, parse_operuh, parse_operut, parse_init_record, parse_oper_record
export parse_dadvaz
export parse_deflant
export parse_desselet
export parse_hidr
export DessemArq, DessemFileRecord, parse_dessemarq
export AreaRecord, UsinaRecord, AreaContData, parse_areacont
export CotaR11Record, CotasR11Data, parse_cotasr11
export CurvTviagRecord, CurvTviagData, parse_curvtviag
export NetworkBus, NetworkLine, NetworkTopology, parse_network_topology, parse_pdo_somflux_topology

# Core type system (comprehensive data model)
export DessemCase, FileRegistry
export HydroSystem, HydroPlant, HydroOperation, HydroReservoir
export ThermalSystem, ThermalPlant, ThermalUnit, ThermalOperation
export PowerSystem, Subsystem, LoadDemand, PowerReserve
export NetworkSystem, ElectricBus, TransmissionLine
export OperationalConstraints, RampConstraint, LPPConstraint, TableConstraint
export RenewableSystem, WindPlant, SolarPlant
export TimeDiscretization, TimePeriod
export CutInfo, FCFCut, DecompCut
export ExecutionOptions

include("types.jl"); using .Types: DessemData, ThermalRegistry, CADUSIT, CADUNIDT, CURVACOMB, GeneralData, TMRecord, SISTRecord, UHRecord, UTRecord, DPRecord, OperuhData, HydroConstraintREST, HydroConstraintELEM, HydroConstraintLIM, HydroConstraintVAR, OperutData, INITRecord, OPERRecord, DadvazData, DadvazHeader, DadvazInflowRecord, DeflantData, DeflantRecord, DesseletData, DesseletBaseCase, DesseletPatamar, HidrData, CADUSIH, USITVIAG, POLCOT, POLARE, POLJUS, COEFEVA, CADCONJ, BinaryHidrRecord, BinaryHidrData, AreaRecord, UsinaRecord, AreaContData, CotaR11Record, CotasR11Data, CurvTviagRecord, CurvTviagData, NetworkBus, NetworkLine, NetworkTopology
include("models/core_types.jl"); using .CoreTypes
include("io.jl"); using .IO
include("parser/common.jl"); using .ParserCommon
include("parser/termdat.jl"); using .TermdatParser: parse_termdat, parse_cadusit, parse_cadunidt, parse_curvacomb
include("parser/entdados.jl"); using .EntdadosParser: parse_entdados
include("parser/operuh.jl"); using .OperuhParser: parse_operuh
include("parser/operut.jl"); using .OperutParser: parse_operut, parse_init_record, parse_oper_record
include("parser/dadvaz.jl"); using .DadvazParser: parse_dadvaz
include("parser/deflant.jl"); using .DeflantParser: parse_deflant
include("parser/desselet.jl"); using .DesseletParser: parse_desselet
include("parser/dessemarq.jl"); using .DessemArqParser: DessemArq, DessemFileRecord, parse_dessemarq
include("parser/hidr.jl"); using .HidrParser: parse_hidr
include("parser/areacont.jl"); using .AreaContParser: parse_areacont
include("parser/cotasr11.jl"); using .CotasR11Parser: parse_cotasr11
include("parser/curvtviag.jl"); using .CurvTviagParser: parse_curvtviag
include("parser/network_topology.jl"); using .NetworkTopologyParser: parse_network_topology, parse_pdo_somflux_topology
include("parser/registry.jl"); using .ParserRegistry
include("api.jl"); using .API: convert_inputs

"""
    greet(name::AbstractString = "world") -> String

Return a friendly greeting. Used for initial package smoke test.
"""
greet(name::AbstractString = "world")::String = "Hello, $(name)! 👋"

end # module
