module DESSEM2Julia

export greet
export DessemData, convert_inputs
export ThermalRegistry, CADUSIT, CADUNIDT, CURVACOMB
export GeneralData, TMRecord, SISTRecord, UHRecord, UTRecord, DPRecord
export OperuhData, HydroConstraintREST, HydroConstraintELEM, HydroConstraintLIM, HydroConstraintVAR
export OperutData, INITRecord, OPERRecord
export parse_termdat, parse_entdados, parse_operuh, parse_operut, parse_init_record, parse_oper_record
export DessemArq, parse_dessemarq

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

include("types.jl"); using .Types: DessemData, ThermalRegistry, CADUSIT, CADUNIDT, CURVACOMB, GeneralData, TMRecord, SISTRecord, UHRecord, UTRecord, DPRecord, OperuhData, HydroConstraintREST, HydroConstraintELEM, HydroConstraintLIM, HydroConstraintVAR, OperutData, INITRecord, OPERRecord
include("models/core_types.jl"); using .CoreTypes
include("io.jl"); using .IO
include("parser/common.jl"); using .ParserCommon
include("parser/termdat.jl"); using .TermdatParser: parse_termdat, parse_cadusit, parse_cadunidt, parse_curvacomb
include("parser/entdados.jl"); using .EntdadosParser: parse_entdados
include("parser/operuh.jl"); using .OperuhParser: parse_operuh
include("parser/operut.jl"); using .OperutParser: parse_operut, parse_init_record, parse_oper_record
include("parser/dessemarq.jl"); using .DessemArqParser: DessemArq, parse_dessemarq
include("parser/registry.jl"); using .ParserRegistry
include("api.jl"); using .API: convert_inputs

"""
    greet(name::AbstractString = "world") -> String

Return a friendly greeting. Used for initial package smoke test.
"""
greet(name::AbstractString = "world")::String = "Hello, $(name)! 👋"

end # module
