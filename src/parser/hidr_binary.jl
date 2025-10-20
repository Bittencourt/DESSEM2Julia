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

using ...DESSEM2Julia: CADUSIH, HidrData

"""
    read_hidr_binary_record(io::IO) -> CADUSIH

Read a single 792-byte binary record from HIDR.DAT file.

Returns a CADUSIH struct with all plant data. String fields are converted from
fixed-length byte arrays (stripped of nulls and trailing spaces).

# Binary Layout (from IDESSEM):
- Offset 0-11: Nome (12 bytes, string)
- Offset 12-15: Posto (4 bytes, Int32)
- Offset 16-23: Posto BDH (8 bytes, Int64) ← Special case!
- Offset 24-27: Subsistema (4 bytes, Int32)
- ... (see IDESSEM for complete 111-field layout)

# Returns
- `CADUSIH`: Struct containing plant data (only includes key fields)

# Note
Binary format uses little-endian byte order (x86/x64 standard).
Many fields from IDESSEM are not included in CADUSIH - only the essential ones
are read for now. Full implementation would require 111 fields.
"""
function read_hidr_binary_record(io::IO)
    # Field 0: Nome (12 bytes) - Plant name
    nome_bytes = read(io, 12)
    nome = String(nome_bytes) |> strip |> x -> replace(x, '\0' => "")
    
    # Field 1: Posto (4 bytes, Int32) - Station code
    posto = read(io, Int32)
    
    # Field 2: Posto BDH (8 bytes, Int64) - BDH station code (SPECIAL: 8 bytes!)
    posto_bdh = read(io, Int64)
    
    # Field 3: Subsistema (4 bytes, Int32) - Subsystem
    subsistema = read(io, Int32)
    
    # Field 4: Empresa (4 bytes, Int32) - Company/Agent
    empresa = read(io, Int32)
    
    # Field 5: Jusante (4 bytes, Int32) - Downstream plant
    jusante = read(io, Int32)
    
    # Field 6: Desvio (4 bytes, Int32) - Diversion
    desvio = read(io, Int32)
    
    # Field 7: Volume Mínimo (4 bytes, Float32) - Minimum volume (hm³)
    volume_minimo = read(io, Float32)
    
    # Field 8: Volume Máximo (4 bytes, Float32) - Maximum volume (hm³)
    volume_maximo = read(io, Float32)
    
    # Field 9: Volume Vertedouro (4 bytes, Float32) - Spillway volume (hm³)
    volume_vertedouro = read(io, Float32)
    
    # Field 10: Volume Desvio (4 bytes, Float32) - Diversion volume (hm³)
    volume_desvio = read(io, Float32)
    
    # Field 11: Cota Mínima (4 bytes, Float32) - Minimum elevation (m)
    cota_minima = read(io, Float32)
    
    # Field 12: Cota Máxima (4 bytes, Float32) - Maximum elevation (m)
    cota_maxima = read(io, Float32)
    
    # Fields 13-17: Polinômio Volume-Cota (5 × 4 bytes, Float32)
    # Polynomial coefficients a0, a1, a2, a3, a4 for V(h)
    polinomio_volume_cota = [read(io, Float32) for _ in 1:5]
    
    # Fields 18-22: Polinômio Cota-Área (5 × 4 bytes, Float32)
    # Polynomial coefficients a0, a1, a2, a3, a4 for A(h)
    polinomio_cota_area = [read(io, Float32) for _ in 1:5]
    
    # Fields 23-34: Evaporação (12 × 4 bytes, Int32)
    # Monthly evaporation coefficients (JAN through DEC)
    evaporacao = [read(io, Int32) for _ in 1:12]
    
    # Field 35: Número de Conjuntos de Máquinas (4 bytes, Int32)
    num_conjuntos_maquinas = read(io, Int32)
    
    # Fields 36-40: Número de Máquinas por Conjunto (5 × 4 bytes, Int32)
    num_maquinas_conjunto = [read(io, Int32) for _ in 1:5]
    
    # Fields 41-45: Potência Efetiva por Conjunto (5 × 4 bytes, Float32) - MW
    potef_conjunto = [read(io, Float32) for _ in 1:5]
    
    # Skip ignored section: 300 bytes at offset 196
    # This is a large reserved block in the IDESSEM format
    seek(io, position(io) + 300)
    
    # Fields 46-50: H Nominal (5 × 4 bytes, Float32) - Nominal head (m)
    h_nominal = [read(io, Float32) for _ in 1:5]
    
    # Fields 51-55: Q Nominal (5 × 4 bytes, Int32) - Nominal flow (m³/s)
    q_nominal = [read(io, Int32) for _ in 1:5]
    
    # Field 56: Produtibilidade Específica (4 bytes, Float32) - Specific productivity
    produtibilidade_especifica = read(io, Float32)
    
    # Field 57: Perdas (4 bytes, Float32) - Losses (MW)
    perdas = read(io, Float32)
    
    # Field 58: Número de Polinômios de Jusante (4 bytes, Int32)
    num_polinomios_jusante = read(io, Int32)
    
    # Fields 59-94: Polinômios de Jusante (6 families × 6 coefficients = 36 × 4 bytes, Float32)
    # Each family: 5 polynomial coefficients + 1 reference value
    # Total: 6 families × 6 values = 36 Float32 values = 144 bytes
    polinomios_jusante = [read(io, Float32) for _ in 1:36]
    
    # Field 95: Canal de Fuga Médio (4 bytes, Float32) - Average tailrace level (m)
    canal_fuga_medio = read(io, Float32)
    
    # Field 96: Influência do Vertimento no Canal de Fuga (4 bytes, Int32)
    influencia_vertimento = read(io, Int32)
    
    # Field 97: Fator de Carga Máximo (4 bytes, Float32) - Maximum load factor
    fator_carga_maximo = read(io, Float32)
    
    # Field 98: Fator de Carga Mínimo (4 bytes, Float32) - Minimum load factor
    fator_carga_minimo = read(io, Float32)
    
    # Field 99: Vazão Mínima Histórica (4 bytes, Int32) - Historical minimum flow
    vazao_minima_historica = read(io, Int32)
    
    # Field 100: Número de Unidades Base (4 bytes, Int32) - Base number of units
    numero_unidades_base = read(io, Int32)
    
    # Field 101: Tipo de Turbina (4 bytes, Int32) - Turbine type
    tipo_turbina = read(io, Int32)
    
    # Field 102: Representação do Conjunto (4 bytes, Int32)
    representacao_conjunto = read(io, Int32)
    
    # Field 103: TEIF (4 bytes, Float32) - Equivalent forced outage rate
    teif = read(io, Float32)
    
    # Field 104: IP (4 bytes, Float32) - Programmed outage
    ip = read(io, Float32)
    
    # Field 105: Tipo de Perda (4 bytes, Int32) - Loss type
    tipo_perda = read(io, Int32)
    
    # Field 106: Data de Referência (12 bytes, string) - Reference date
    data_referencia_bytes = read(io, 12)
    data_referencia = String(data_referencia_bytes) |> strip |> x -> replace(x, '\0' => "")
    
    # Field 107: Observação (39 bytes, string) - Observation/notes
    observacao_bytes = read(io, 39)
    observacao = String(observacao_bytes) |> strip |> x -> replace(x, '\0' => "")
    
    # Field 108: Volume de Referência (4 bytes, Float32) - Reference volume (hm³)
    volume_referencia = read(io, Float32)
    
    # Field 109: Tipo de Regularização (1 byte, string) - Regulation type
    tipo_regulacao_bytes = read(io, 1)
    tipo_regulacao = String(tipo_regulacao_bytes) |> strip |> x -> replace(x, '\0' => "")
    
    # TOTAL: 792 bytes read
    # Verify we're at the right position (should be at 792 bytes from start of record)
    
    # Convert to CADUSIH format (only includes subset of fields)
    # Note: CADUSIH was designed for text format and doesn't have all 111 fields
    # We map what we can to the existing structure
    
    # For now, create a simplified CADUSIH with key fields
    # TODO: Consider creating a new BinaryHIDRRecord struct with all 111 fields
    
    # Derive installed capacity from potef_conjunto (sum of all sets)
    installed_capacity_mw = sum(potef_conjunto)
    
    return CADUSIH(
        plant_num=posto,
        plant_name=nome,
        subsystem=subsistema,
        commission_year=nothing,  # Not in binary format (text format only)
        commission_month=nothing,  # Not in binary format
        commission_day=nothing,  # Not in binary format
        downstream_plant=jusante,
        diversion_downstream=desvio,
        plant_type=tipo_turbina,
        min_volume=Float64(volume_minimo),
        max_volume=Float64(volume_maximo),
        max_turbine_flow=0.0,  # Could derive from q_nominal
        installed_capacity=Float64(installed_capacity_mw),
        productivity=Float64(produtibilidade_especifica)
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
    parse_hidr_binary(filepath::String) -> HidrData

Parse a binary HIDR.DAT file.

Reads all 792-byte plant records and returns a HidrData structure.
Binary format is used by ONS (Brazilian Grid Operator) official data.

# Arguments
- `filepath::String`: Path to binary HIDR.DAT file

# Returns
- `HidrData`: Container with parsed data (currently only CADUSIH vector populated)

# Example
```julia
hidr_data = parse_hidr_binary("docs/Sample/DS_ONS_102025_RV2D11/hidr.dat")
println("Number of plants: ", length(hidr_data.cadusih))
println("First plant: ", hidr_data.cadusih[1].plant_name)
```

# Reference
Based on IDESSEM (rjmalves/idessem) binary format specification.
"""
function parse_hidr_binary(filepath::String)
    cadusih_records = CADUSIH[]
    
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
                push!(cadusih_records, record)
            catch e
                @warn "Failed to read record $i" exception=(e, catch_backtrace())
                break
            end
        end
    end
    
    # Return HidrData with only CADUSIH populated
    # Other record types (USITVIAG, POLCOT, etc.) are not in binary format
    # They would need to be derived from the binary data or read from other files
    return HidrData(
        plants=cadusih_records,
        travel_times=USITVIAG[],
        volume_elevation=POLCOT[],
        volume_area=POLARE[],
        tailrace=POLJUS[],
        evaporation=COEFEVA[],
        unit_sets=CADCONJ[]
    )
end
