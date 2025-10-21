#!/usr/bin/env julia

using DESSEM2Julia

# Test parsing ONS binary HIDR.DAT file
filepath = "docs/Sample/DS_ONS_102025_RV2D11/hidr.dat"
println("Parsing: $filepath")

data = parse_hidr(filepath)
println("Parsed $(length(data.records)) plants")
println("\nFirst plant details:")
plant = data.records[1]
println("  Nome: $(plant.nome)")
println("  Posto: $(plant.posto)")
println("  Subsistema: $(plant.subsistema)")
println("  Volume mínimo: $(plant.volume_minimo) hm³")
println("  Volume máximo: $(plant.volume_maximo) hm³")
println("  Potência instalada: $(sum(plant.potef_conjunto)) MW")
println("  Produtibilidade: $(plant.produtibilidade_especifica)")
println("  Polynomial volume-cota: $(plant.polinomio_volume_cota)")
println("  Evaporação (12 meses): $(plant.evaporacao)")
println("\nAll plants:")
for (i, p) in enumerate(data.records[1:min(10, length(data.records))])
    println("  $i. $(rpad(p.nome, 15)) - Posto $(p.posto) - $(sum(p.potef_conjunto)) MW")
end
