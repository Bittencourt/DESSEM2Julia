module DESSEM2Julia

export greet, DessemData, convert_inputs, load_jld2, save_jld2
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
export RespoteleRP, RespoteLM, RespoteleData, parse_respotele
export NetworkBus,
    NetworkLine, NetworkTopology, parse_network_topology, parse_pdo_somflux_topology
export RestsegIndice,
    RestsegTabela, RestsegLimite, RestsegCelula, RestsegData, parse_restseg
export RampasRecord, RampasData, parse_rampas
export parse_rstlpp
export parse_rmpflx
export PtoperRecord, PtoperData, parse_ptoper
export ModifRecord, ModifData, parse_modif
export parse_mlt
export parse_cortdeco, get_water_value, get_active_cuts, get_cut_statistics
export BateriaRecord, BateriaData, parse_bateria
export IlstriData, parse_ilstri
export TolperdData, parse_tolperd
export MetasData, parse_metas
export RivarData, parse_rivar
export InfofcfDatTviag,
    InfofcfDatSisgnl, InfofcfDatDurpat, InfofcfDatFix, InfofcfDatData, parse_infofcf_dat
export parse_fcf, evaluate_fcf, water_value, water_values
export build_fcf_from_cuts, parse_mapcut_enhanced

# Core type system (comprehensive data model)
export DessemCase, FileRegistry
export HydroSystem, HydroPlant, HydroOperation, HydroReservoir
export ThermalSystem, ThermalPlant, ThermalUnit, ThermalOperation
export PowerSystem, Subsystem, LoadDemand, PowerReserve
export NetworkSystem, ElectricBus, TransmissionLine
export OperationalConstraints, RampConstraint, LPPConstraint, TableConstraint
export RenewableSystem, WindPlant, SolarPlant
export TimeDiscretization, TimePeriod
export CutInfo, FCFCut, FCFCutsData, DecompCut
export BendersCut, FCFData
export MapcutGeneralData, MapcutCaseData, MapcutStageData
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
    RespoteleRP,
    RespoteLM,
    RespoteleData,
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
    BateriaRecord,
    BateriaData,
    IlstriData,
    TolperdData,
    MetasData,
    InfofcfDatTviag,
    InfofcfDatSisgnl,
    InfofcfDatDurpat,
    InfofcfDatFix,
    InfofcfDatData
include("models/core_types.jl")
using .CoreTypes
include("io.jl")
using .IO
include("parser/common.jl")
using .ParserCommon
include("parser/registry.jl")
using .ParserRegistry
include("api.jl")
using .API
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
include("parser/respotele.jl")
using .RespoteleParser: parse_respotele
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
include("parser/modif.jl")
using .ModifParser: parse_modif
include("parser/mlt.jl")
using .MltParser: parse_mlt
include("parser/cortdeco.jl")
using .CortdecoParser: parse_cortdeco, get_water_value, get_active_cuts, get_cut_statistics
include("parser/binary_dec.jl")
using .BinaryDecParser: parse_infofcf, parse_mapcut, parse_cortes
include("parser/bateria.jl")
using .BateriaParser: parse_bateria
include("parser/ilstri.jl")
using .IlstriParser: parse_ilstri
include("parser/tolperd.jl")
using .TolperdParser: parse_tolperd
include("parser/metas.jl")
using .MetasParser: parse_metas
include("parser/rivar.jl")
using .RivarParser: parse_rivar
include("parser/infofcf.jl")
using .InfofcfDatParser: parse_infofcf_dat
include("parser/fcf.jl")
using .FCFModule: parse_fcf, evaluate_fcf, water_value, water_values, build_fcf_from_cuts, parse_mapcut_enhanced

# Optionally include PWF parser if PWF.jl is available
# Check for PWF package before including to avoid module compilation warnings
pwf_available = try
    Base.require(Base.PkgId(Base.UUID("0f4c3beb-4231-4c4d-93e1-709cb40a89e6"), "PWF"))
    true
catch
    false
end

if pwf_available
    try
        include("parser/pwf.jl")
        using .PWFParser: parse_pwf, parse_pwf_to_topology
        @eval export parse_pwf, parse_pwf_to_topology
    catch e
        @warn "Failed to load PWF parser: $e"
    end
end

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
    MltData,
    InfofcfRecord,
    InfofcfData,
    MapcutRecord,
    MapcutData,
    CortesRecord,
    CortesData,
    BateriaRecord,
    BateriaData,
    IlstriData,
    TolperdData,
    MetasData,
    RivarData,

    # Functions
    parse_file,
    parse_termdat,
    parse_entdados,
    parse_operuh,
    parse_operut,
    parse_init_record,
    parse_oper_record,
    parse_dadvaz,
    parse_deflant,
    parse_desselet,
    parse_hidr,
    parse_simul,
    parse_dessopc,
    parse_dessemarq,
    parse_areacont,
    parse_cotasr11,
    parse_curvtviag,
    parse_renovaveis,
    parse_respot,
    parse_rp_record,
    parse_lm_record,
    parse_network_topology,
    parse_pdo_somflux_topology,
    parse_restseg,
    parse_rampas,
    parse_rstlpp,
    parse_rmpflx,
    parse_ptoper,
    parse_mlt,
    parse_infofcf,
    parse_mapcut,
    parse_cortes,
    parse_bateria,
    parse_ilstri,
    parse_tolperd,
    parse_metas,
    parse_rivar

function greet(name = "world")
    return "Hello, $(name)! 👋"
end

function __init__()
    # Register all parsers
    register_parser!("TERMDAT.DAT", parse_termdat)
    register_parser!("ENTDADOS.DAT", parse_entdados)
    register_parser!("OPERUH.DAT", parse_operuh)
    register_parser!("OPERUT.DAT", parse_operut)
    register_parser!("OPERUT.AUX", parse_operut)  # Same format as OPERUT.DAT
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
    register_parser!("BATERIA.XXX", parse_bateria)
    register_parser!("ILSTRI.DAT", parse_ilstri)
    register_parser!("TOLPERD.DAT", parse_tolperd)
    register_parser!("METAS.DAT", parse_metas)
    register_parser!("RIVAR.DAT", parse_rivar)
    register_parser!("INFOFCF.DAT", parse_infofcf_dat)
    register_parser!("RESPOTELE.DAT", parse_respotele)
    register_parser!("ILS_TRI.DAT", parse_ilstri)
    register_parser!("PDO_SOMFLUX.DAT", parse_pdo_somflux_topology)
    register_parser!("MODIF.DAT", parse_modif)
    register_parser!("BATERIA.DAT", parse_bateria)
end

end # module
