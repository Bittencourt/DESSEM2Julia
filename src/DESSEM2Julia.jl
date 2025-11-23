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
export parse_rstlpp
export parse_rmpflx
export PtoperRecord, PtoperData, parse_ptoper

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
include("parser/rstlpp.jl")
using .RstlppParser: parse_rstlpp
include("parser/rmpflx.jl")
using .RmpflxParser: parse_rmpflx
include("parser/ptoper.jl")
using .PtoperParser: parse_ptoper
include("parser/registry.jl")
using .ParserRegistry
include("api.jl")
using .API: convert_inputs
include("parser/mlt.jl")
include("parser/binary_dec.jl")

using .EntdadosParser
using .OperutParser
using .DadvazParser
using .DeflantParser
using .DesseletParser
using .SimulParser
using .DessOpcParser
using .DessemArqParser
using .HidrParser
using .AreaContParser
using .CotasR11Parser
using .CurvTviagParser
using .RenovaveisParser
using .RespotParser
using .NetworkTopologyParser
using .RestsegParser
using .RampasParser
using .RstlppParser
using .RmpflxParser
using .PtoperParser
using .ParserRegistry
using .API
using .MltParser
using .BinaryDecParser

export
    # Types
    AbstractRecord,
    AbstractData,
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
    RampasData,
    MltRecord, MltData,
    InfofcfRecord, InfofcfData,
    MapcutRecord, MapcutData,
    CortesRecord, CortesData,

    # Functions
    parse_file,
    parse_termdat,
    parse_entdados, parse_operuh, parse_operut, parse_init_record, parse_oper_record
    parse_dadvaz
    parse_deflant
    parse_desselet
    parse_hidr
    parse_simul
    parse_dessopc
    DessemArq, DessemFileRecord, parse_dessemarq
    parse_areacont
    parse_cotasr11
    parse_curvtviag
    parse_renovaveis
    parse_respot, parse_rp_record, parse_lm_record
    parse_network_topology, parse_pdo_somflux_topology
    parse_restseg
    parse_rampas
    parse_rstlpp
    parse_rmpflx
    parse_ptoper
    parse_mlt,
    parse_infofcf,
    parse_mapcut,
    parse_cortes

function __init__()
    # Register all parsers
    register_parser!("TERMDAT.DAT", parse_termdat)
    register_parser!("ENTDADOS.DAT", parse_entdados)
    register_parser!("OPERUH.DAT", parse_operuh)
    register_parser!("OPERUT.DAT", parse_operut)
    register_parser!("DADVAZ.DAT", parse_dadvaz)
    register_parser!("DEFLANT.DAT", parse_deflant)
    register_parser!("DESSELET.DAT", parse_desselet)
    register_parser!("SIMUL.DAT", parse_simul)
    register_parser!("DESSOPC.DAT", parse_dessopc)
    register_parser!("DESSEM.ARQ", parse_dessemarq)
    register_parser!("HIDR.DAT", parse_hidr)
    register_parser!("AREACONT.DAT", parse_areacont)
    register_parser!("COTASR11.DAT", parse_cotasr11)
    register_parser!("CURVTVIAG.DAT", parse_curvtviag)
    register_parser!("RENOVAVEIS.DAT", parse_renovaveis)
    register_parser!("RESPOT.DAT", parse_respot)
    register_parser!("RESTSEG.DAT", parse_restseg)
    register_parser!("RAMPAS.DAT", parse_rampas)
    register_parser!("RSTLPP.DAT", parse_rstlpp)
    register_parser!("RMPFLX.DAT", parse_rmpflx)
    register_parser!("PTOPER.DAT", parse_ptoper)
    register_parser!("MLT.DAT", parse_mlt)
    register_parser!("INFOFCF.DEC", parse_infofcf)
    register_parser!("MAPCUT.DEC", parse_mapcut)
    register_parser!("CORTES.DEC", parse_cortes)
end

end # module
