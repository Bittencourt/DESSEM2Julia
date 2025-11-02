"""
Binary HIDR.DAT Parser

This module implements a parser for the binary format of HIDR.DAT files (792 bytes per plant).
Based on the IDESSEM reference implementation (rjmalves/idessem).

Binary Structure (792 bytes total):
- Complete field layout with exact byte positions from IDESSEM
- 111 fields per hydroelectric plant record
- Fixed record size: 792 bytes

Reference: idessem/dessem/modelos/hidr.py
"""

using ...DESSEM2Julia: BinaryHidrRecord, BinaryHidrData

"""
    read_hidr_binary_record(io::IO) -> BinaryHidrRecord

Read a single 792-byte binary record from HIDR.DAT file.

Returns a BinaryHidrRecord with all 111 fields from IDESSEM specification.
String fields are converted from fixed-length byte arrays (stripped of nulls and trailing spaces).

# Binary Layout (from IDESSEM):
All 111 fields exactly as specified in idessem/dessem/modelos/hidr.py

# Returns
- `BinaryHidrRecord`: Complete struct with all 111 plant fields

# Note
Binary format uses little-endian byte order (x86/x64 standard).
Total record size: exactly 792 bytes.
"""
function read_hidr_binary_record(io::IO)
    # Fields 0-2: Basic Identification (0-23)
    nome_bytes = read(io, 12)
    nome = String(nome_bytes) |> strip |> x -> replace(x, '\0' => "")
    posto = read(io, Int32)
    posto_bdh = read(io, Int64)  # Special 8-byte field!

    # Fields 3-6: System and Connectivity (24-39)
    subsistema = read(io, Int32)
    empresa = read(io, Int32)
    jusante = read(io, Int32)
    desvio = read(io, Int32)

    # Fields 7-12: Volumes and Elevations (40-63)
    volume_minimo = Float64(read(io, Float32))
    volume_maximo = Float64(read(io, Float32))
    volume_vertedouro = Float64(read(io, Float32))
    volume_desvio = Float64(read(io, Float32))
    cota_minima = Float64(read(io, Float32))
    cota_maxima = Float64(read(io, Float32))

    # Fields 13-17: Volume-Elevation Polynomial (64-83)
    polinomio_volume_cota = [Float64(read(io, Float32)) for _ in 1:5]

    # Fields 18-22: Elevation-Area Polynomial (84-103)
    polinomio_cota_area = [Float64(read(io, Float32)) for _ in 1:5]

    # Fields 23-34: Monthly Evaporation (104-151)
    evaporacao = [read(io, Int32) for _ in 1:12]

    # Field 35: Number of Machine Sets (152-155)
    numero_conjuntos_maquinas = read(io, Int32)

    # Fields 36-40: Machines per Set (156-175)
    numero_maquinas_conjunto = [read(io, Int32) for _ in 1:5]

    # Fields 41-45: Nominal Power per Set (176-195)
    potef_conjunto = [Float64(read(io, Float32)) for _ in 1:5]

    # SPECIAL: Skip 300-byte ignored block (196-495)
    # This is a large reserved/unused section in the binary format
    seek(io, position(io) + 300)

    # Fields 46-50: Nominal Head per Set (496-515)
    hef_conjunto = [Float64(read(io, Float32)) for _ in 1:5]

    # Fields 51-55: Nominal Flow per Set (516-535)
    qef_conjunto = [read(io, Int32) for _ in 1:5]

    # Field 56: Specific Productivity (536-539)
    produtibilidade_especifica = Float64(read(io, Float32))

    # Field 57: Losses (540-543)
    perdas = Float64(read(io, Float32))

    # Field 58: Number of Tailrace Polynomial Families (544-547)
    numero_polinomios_jusante = read(io, Int32)

    # Fields 59-94: Tailrace Polynomials (548-691)
    # 6 families × 6 values (5 coefficients + 1 reference) = 36 Float32 values
    polinomios_jusante = [Float64(read(io, Float32)) for _ in 1:36]

    # Field 95: Average Tailrace Level (692-695)
    canal_fuga_medio = Float64(read(io, Float32))

    # Field 96: Spillway Influence on Tailrace (696-699)
    influencia_vertimento_canal_fuga = read(io, Int32)

    # Field 97: Maximum Load Factor (700-703)
    fator_carga_maximo = Float64(read(io, Float32))

    # Field 98: Minimum Load Factor (704-707)
    fator_carga_minimo = Float64(read(io, Float32))

    # Field 99: Historical Minimum Flow (708-711)
    vazao_minima_historica = read(io, Int32)

    # Field 100: Base Number of Units (712-715)
    numero_unidades_base = read(io, Int32)

    # Field 101: Turbine Type (716-719)
    tipo_turbina = read(io, Int32)

    # Field 102: Set Representation (720-723)
    representacao_conjunto = read(io, Int32)

    # Field 103: TEIF - Equivalent Forced Outage Rate (724-727)
    teif = Float64(read(io, Float32))

    # Field 104: IP - Programmed Outage (728-731)
    ip = Float64(read(io, Float32))

    # Field 105: Loss Type (732-735)
    tipo_perda = read(io, Int32)

    # Field 106: Reference Date (736-747)
    data_referencia_bytes = read(io, 12)
    data_referencia = String(data_referencia_bytes) |> strip |> x -> replace(x, '\0' => "")

    # Field 107: Observation/Notes (748-786)
    observacao_bytes = read(io, 39)
    observacao = String(observacao_bytes) |> strip |> x -> replace(x, '\0' => "")

    # Field 108: Reference Volume (787-790)
    volume_referencia = Float64(read(io, Float32))

    # Field 109: Regulation Type (791)
    tipo_regulacao_bytes = read(io, 1)
    tipo_regulacao = String(tipo_regulacao_bytes) |> strip |> x -> replace(x, '\0' => "")

    # TOTAL: 792 bytes (0-791)

    return BinaryHidrRecord(
        nome = nome,
        posto = posto,
        posto_bdh = posto_bdh,
        subsistema = subsistema,
        empresa = empresa,
        jusante = jusante,
        desvio = desvio,
        volume_minimo = volume_minimo,
        volume_maximo = volume_maximo,
        volume_vertedouro = volume_vertedouro,
        volume_desvio = volume_desvio,
        cota_minima = cota_minima,
        cota_maxima = cota_maxima,
        polinomio_volume_cota = polinomio_volume_cota,
        polinomio_cota_area = polinomio_cota_area,
        evaporacao = evaporacao,
        numero_conjuntos_maquinas = numero_conjuntos_maquinas,
        numero_maquinas_conjunto = numero_maquinas_conjunto,
        potef_conjunto = potef_conjunto,
        hef_conjunto = hef_conjunto,
        qef_conjunto = qef_conjunto,
        produtibilidade_especifica = produtibilidade_especifica,
        perdas = perdas,
        numero_polinomios_jusante = numero_polinomios_jusante,
        polinomios_jusante = polinomios_jusante,
        canal_fuga_medio = canal_fuga_medio,
        influencia_vertimento_canal_fuga = influencia_vertimento_canal_fuga,
        fator_carga_maximo = fator_carga_maximo,
        fator_carga_minimo = fator_carga_minimo,
        vazao_minima_historica = vazao_minima_historica,
        numero_unidades_base = numero_unidades_base,
        tipo_turbina = tipo_turbina,
        representacao_conjunto = representacao_conjunto,
        teif = teif,
        ip = ip,
        tipo_perda = tipo_perda,
        data_referencia = data_referencia,
        observacao = observacao,
        volume_referencia = volume_referencia,
        tipo_regulacao = tipo_regulacao,
    )
end

"""
    is_binary_hidr(filepath::String) -> Bool

Detect if HIDR.DAT file is in binary format.

Binary format detection:
1. Check file size is multiple of 792 bytes
2. Read first 12 bytes (plant name field)
3. Check if bytes are printable ASCII (text) or binary

# Arguments
- `filepath::String`: Path to HIDR.DAT file

# Returns
- `true` if file appears to be binary format
- `false` if file appears to be text format
"""
function is_binary_hidr(filepath::String)::Bool
    # Check if file exists
    if !isfile(filepath)
        error("File not found: $filepath")
    end

    # Get file size
    filesize_bytes = stat(filepath).size

    # Binary files should be multiple of 792 bytes (with possible small header/footer)
    # If file size is very small, likely not binary
    if filesize_bytes < 792
        return false
    end

    # Check if size is close to multiple of 792
    # Allow small header/footer (within 100 bytes)
    remainder = filesize_bytes % 792
    if remainder > 100 && remainder < (792 - 100)
        # Not close to multiple of 792, likely text
        return false
    end

    # Read first 12 bytes (should be plant name in both formats)
    open(filepath, "r") do io
        first_12_bytes = read(io, 12)

        # In text format, plant names are ASCII with possible spaces
        # In binary format, plant names are also ASCII but may have null bytes

        # Check for non-printable characters (excluding null, space, tab)
        # If we find characters outside ASCII printable range (excluding whitespace/null),
        # it's likely binary data that's not a plant name

        # Count printable ASCII characters (0x20-0x7E) plus null (0x00)
        printable_count = count(b -> (b >= 0x20 && b <= 0x7E) || b == 0x00, first_12_bytes)

        # If less than 75% of first 12 bytes are printable, likely binary
        # But this heuristic doesn't work well since both formats have ASCII names

        # Better heuristic: Try to read second field (posto) at offset 12
        # In text format, offset 12 is still part of the first line (spaces or newline)
        # In binary format, offset 12 is an Int32 (posto field)

        seek(io, 12)
        next_4_bytes = read(io, 4)
        posto_value = reinterpret(Int32, next_4_bytes)[1]

        # Valid posto values are typically 1-999 (station codes)
        # If we get a reasonable posto value, likely binary
        # If we get gibberish (like 0x20202020 = spaces), likely text

        if posto_value >= 1 && posto_value <= 9999
            # Could be binary with valid posto
            return true
        else
            # Likely text format
            return false
        end
    end
end

"""
    parse_hidr_binary(filepath::String) -> BinaryHidrData

Parse a binary HIDR.DAT file.

Reads all 792-byte plant records and returns a BinaryHidrData structure
with complete 111-field records.

Binary format is used by ONS (Brazilian Grid Operator) official data.

# Arguments
- `filepath::String`: Path to binary HIDR.DAT file

# Returns
- `BinaryHidrData`: Container with all complete plant records

# Example
```julia
data = parse_hidr_binary("docs/Sample/DS_ONS_102025_RV2D11/hidr.dat")
println("Number of plants: ", length(data.records))
println("First plant: ", data.records[1].nome)
println("Volume-elevation polynomial: ", data.records[1].polinomio_volume_cota)
println("Installed capacity: ", sum(data.records[1].potef_conjunto), " MW")
```

# Reference
Based on IDESSEM (rjmalves/idessem) binary format specification.
All 111 fields from RegistroUHEHidr are parsed.
"""
function parse_hidr_binary(filepath::String)
    records = BinaryHidrRecord[]

    open(filepath, "r") do io
        # Calculate number of records
        file_size = stat(filepath).size
        num_records = div(file_size, 792)

        if file_size % 792 != 0
            @warn "File size ($file_size bytes) is not exact multiple of 792. Last record may be incomplete."
        end

        # Read all records
        for i in 1:num_records
            try
                record = read_hidr_binary_record(io)
                push!(records, record)
            catch e
                @warn "Failed to read record $i at byte $(position(io))" exception =
                    (e, catch_backtrace())
                break
            end
        end
    end

    return BinaryHidrData(records = records)
end
