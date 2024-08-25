@doc raw"""
    select_zones!(inputs::Dict, setup::Dict, path::String)
Function to select which zones from the zones in the input data will be included in the model
"""
function select_zones!(inputs::Dict, setup::Dict, path::String)
    if !haskey(setup, "Zones") || isempty(setup["Zones"])
        inputs["Zones"] = enumerate_zones(setup,path)
    else
        inputs["Zones"] = setup["Zones"]
    end
    inputs["Z"] = length(inputs["Zones"])
end