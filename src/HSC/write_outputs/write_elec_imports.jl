@doc raw"""
	write_elec_imports(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)

TO DO
"""
function write_elec_imports(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    elec_imports = value.(EP[:vElecImports_HSC])
    elec_imports = DataFrame(elec_imports, :auto)
    # Save to elec_imports.csv
    CSV.write(joinpath(path, "elec_imports.csv"), elec_imports)
    return elec_imports
end

function write_elec_import_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    elec_costs = value.(EP[:eElecImportsCost_HSC])
    elec_costs = DataFrame(elec_costs, :auto)
    # Save to elec_import_costs.csv
    CSV.write(joinpath(path, "elec_import_costs.csv"), elec_costs, delim = sep)
    return elec_costs
end