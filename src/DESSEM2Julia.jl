module DESSEM2Julia

export greet
export DessemData, convert_inputs
export ThermalRegistry, CADUSIT, CADUNIDT, CURVACOMB
export GeneralData, TMRecord, SISTRecord, UHRecord, UTRecord, DPRecord
export OperuhData,
    HydroConstraintREST, HydroConstraintELEM, HydroConstraintLIM, HydroConstraintVAR
export OperutData, INITRecord, OPERRecord
export DadvazData, DadvazHeader, DadvazInflowRecord
export DeflantData, DeflantRecord
export DesseletData, DesseletBaseCase, DesseletPatamar
export HidrData,
    CADUSIH,
    USITVIAG,
    POLCOT,
    POLARE,
    POLJUS,
    COEFEVA,
    CADCONJ,
    BinaryHidrRecord,
    BinaryHidrData
export SimulData, SimulHeader, DiscRecord, VoliRecord, OperRecord
export DessOpcData
export parse_termdat,
    parse_entdados, parse_operuh, parse_operut, parse_init_record, parse_oper_record
export parse_dadvaz
export parse_deflant
export parse_desselet
export parse_hidr
export parse_simul
export parse_dessopc
export DessemArq, DessemFileRecord, parse_dessemarq
export AreaRecord, UsinaRecord, AreaContData, parse_areacont
export CotaR11Record, CotasR11Data, parse_cotasr11
export CurvTviagRecord, CurvTviagData, parse_curvtviag
export RenovaveisRecord,
    RenovaveisSubsystemRecord,
    RenovaveisBusRecord,
    RenovaveisGenerationRecord,
    RenovaveisData,
    parse_renovaveis,
    parse_renovaveis_record
export RespotRP, RespotLM, RespotData, parse_respot, parse_rp_record, parse_lm_record
export NetworkBus,
    NetworkLine, NetworkTopology, parse_network_topology, parse_pdo_somflux_topology
export RestsegIndice,
    RestsegTabela, RestsegLimite, RestsegCelula, RestsegData, parse_restseg
export RampasRecord, RampasData, parse_rampas

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

include("types.jl")
using .Types:
    DessemData,
    ThermalRegistry,
    CADUSIT,
    CADUNIDT,
    CURVACOMB,
    GeneralData,
    TMRecord,
    SISTRecord,
    UHRecord,
    UTRecord,
    DPRecord,
    OperuhData,
    HydroConstraintREST,
    HydroConstraintELEM,
    HydroConstraintLIM,
    HydroConstraintVAR,
    OperutData,
    INITRecord,
    OPERRecord,
    DadvazData,
    DadvazHeader,
    DadvazInflowRecord,
    DeflantData,
    DeflantRecord,
    DesseletData,
    DesseletBaseCase,
    DesseletPatamar,
    HidrData,
    CADUSIH,
    USITVIAG,
    POLCOT,
    POLARE,
    POLJUS,
    COEFEVA,
    CADCONJ,
    BinaryHidrRecord,
    BinaryHidrData,
    SimulData,
    SimulHeader,
    DiscRecord,
    VoliRecord,
    OperRecord,
    DessOpcData,
    AreaRecord,
    UsinaRecord,
    AreaContData,
    CotaR11Record,
    CotasR11Data,
    CurvTviagRecord,
    CurvTviagData,
    RenovaveisRecord,
    RenovaveisSubsystemRecord,
    RenovaveisBusRecord,
    RenovaveisGenerationRecord,
    RenovaveisData,
    RespotRP,
    RespotLM,
    RespotData,
    NetworkBus,
    NetworkLine,
    NetworkTopology,
    RestsegIndice,
    RestsegTabela,
    RestsegLimite,
    RestsegCelula,
    RestsegData,
    RampasRecord,
    RampasData
include("models/core_types.jl")
using .CoreTypes
include("io.jl")
using .IO
include("parser/common.jl")
using .ParserCommon
include("parser/termdat.jl")
using .TermdatParser: parse_termdat, parse_cadusit, parse_cadunidt, parse_curvacomb
include("parser/entdados.jl")
using .EntdadosParser: parse_entdados
include("parser/operuh.jl")
using .OperuhParser: parse_operuh
include("parser/operut.jl")
using .OperutParser: parse_operut, parse_init_record, parse_oper_record
include("parser/dadvaz.jl")
using .DadvazParser: parse_dadvaz
include("parser/deflant.jl")
using .DeflantParser: parse_deflant
include("parser/desselet.jl")
using .DesseletParser: parse_desselet
include("parser/simul.jl")
using .SimulParser: parse_simul
include("parser/dessopc.jl")
using .DessOpcParser: parse_dessopc
include("parser/dessemarq.jl")
using .DessemArqParser: DessemArq, DessemFileRecord, parse_dessemarq
include("parser/hidr.jl")
using .HidrParser: parse_hidr
include("parser/areacont.jl")
using .AreaContParser: parse_areacont
include("parser/cotasr11.jl")
using .CotasR11Parser: parse_cotasr11
include("parser/curvtviag.jl")
using .CurvTviagParser: parse_curvtviag
include("parser/renovaveis.jl")
using .RenovaveisParser:
    parse_renovaveis,
    parse_renovaveis_record,
    parse_renovaveis_subsystem_record,
    parse_renovaveis_bus_record,
    parse_renovaveis_generation_record
include("parser/respot.jl")
using .RespotParser: parse_respot, parse_rp_record, parse_lm_record
include("parser/network_topology.jl")
using .NetworkTopologyParser: parse_network_topology, parse_pdo_somflux_topology
include("parser/restseg.jl")
using .RestsegParser: parse_restseg
include("parser/rampas.jl")
using .RampasParser: parse_rampas
include("parser/registry.jl")
using .ParserRegistry
include("api.jl")
using .API: convert_inputs

"""
    greet(name::AbstractString = "world") -> String

Return a friendly greeting. Used for initial package smoke test.
"""
greet(name::AbstractString = "world")::String = "Hello, $(name)! 👋"

end # module
