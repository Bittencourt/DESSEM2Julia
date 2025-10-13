using DESSEM2Julia

filepath = "docs/Sample/DS_ONS_102025_RV2D11/operuh.dat"
println("Parsing: $filepath")

try
    open(filepath, "r") do io
        result = DESSEM2Julia.parse_operuh(io, filepath)
        println("✓ Success! Parsed:")
        println("  REST records: ", length(result.rest_records))
        println("  ELEM records: ", length(result.elem_records))
        println("  LIM records: ", length(result.lim_records))
        println("  VAR records: ", length(result.var_records))
    end
catch e
    println("ERROR: ", e)
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
end
