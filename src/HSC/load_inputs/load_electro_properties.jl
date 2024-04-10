@doc raw"""
    load_electro_efficiency(setup::Dict, path::AbstractString, sep::AbstractString, inputs_load::Dict)

"""
function load_electro_efficiency!(inputs::Dict, path::AbstractString, filename="HSC_electro_efficiency.csv")

    # Load the efficiency data
    filepath = joinpath(path, filename)
    electro_efficiency_df = DataFrame(CSV.File(filepath, header=true), copycols=true)

    h2_gen_in = inputs["dfH2Gen"]::DataFrame
    H2_GEN_COMMIT_PW = inputs["H2_GEN_COMMIT_PW"]

    electro_efficiency = Dict{Int64, Vector{Vector{Float64}}}()
    
    # Loop through the piecewise electrolyzers, 
    # saving the output and power vectors for each
    # as a Dictionary, indexed on the electrolyzer R_ID
    for k in H2_GEN_COMMIT_PW
        resource_name = h2_gen_in[k, :H2_Resource]
        electro_efficiency[k] = [
            electro_efficiency_df[!,Symbol("$(resource_name)_output")],
            electro_efficiency_df[!,Symbol("$(resource_name)_power")],
        ]
    end

    # Save the efficiency data
    inputs["H2ElectroEff"] = electro_efficiency

end