@doc raw"""
	write_elec_imports(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
TO DO
"""
function write_elec_imports(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    elec_imports = value.(EP[:vElecImports])
    headers = ["Elec_Imports_z$(x)_MWh" for x in 1:size(elec_imports,2)]
    elec_imports = DataFrame(elec_imports, headers)
    # Save to elec_imports.csv
    CSV.write(joinpath(path, "elec_imports.csv"), elec_imports)
    return nothing
end

function write_elec_import_costs(path::AbstractString, sep::AbstractString, inputs::Dict, setup::Dict, EP::Model)
    elec_costs = value.(EP[:eElecImportsCost])'
    headers = ["Elec_Import_Cost_z$(x)_\$" for x in 1:size(elec_costs,2)]
    elec_costs = DataFrame(elec_costs, headers)
    # Save to elec_import_costs.csv
    CSV.write(joinpath(path, "elec_import_costs.csv"), elec_costs)
    return nothing
end