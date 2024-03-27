

@doc raw"""
    load_h2_g2p(setup::Dict, path::AbstractString, sep::AbstractString, inputs_gen::Dict)
    
Function for reading input parameters related to hydrogen to power generators.
"""
function load_h2_g2p(setup::Dict, path::AbstractString, sep::AbstractString, inputs_gen::Dict)

    #Read in H2 generation related inputs
    h2_g2p_in = DataFrame(CSV.File(joinpath(path, "HSC_G2P.csv"), header=true), copycols=true)
    
    # Add Resource IDs after reading to prevent user errors
    h2_g2p_in[!,:R_ID] = 1:size(collect(skipmissing(h2_g2p_in[!,1])),1)

    # Store DataFrame of generators/resources input data for use in model
    inputs_gen["dfH2G2P"] = h2_g2p_in

    # Index of H2 resources - can be either commit, no_commit production technologies, demand side, G2P, or storage resources
    inputs_gen["H2_G2P_ALL"] = size(collect(skipmissing(h2_g2p_in[!,:R_ID])),1)

    # Name of H2 Generation resources
    inputs_gen["H2_G2P_NAME"] = collect(skipmissing(h2_g2p_in[!,:H2_Resource][1:inputs_gen["H2_G2P_ALL"]]))
    
    # Resource identifiers by zone (just zones in resource order + resource and zone concatenated)
    h2_zones = collect(skipmissing(h2_g2p_in[!,:Zone][1:inputs_gen["H2_G2P_ALL"]]))
    inputs_gen["H2_G2P_ZONES"] = h2_zones
    inputs_gen["H2_G2P_RESOURCE_ZONES"] = inputs_gen["H2_G2P_NAME"] .* "_z" .* string.(h2_zones)

    # Set of H2 G2P resources
    # Set of H2 G2P resources eligible for unit committment - either continuous or discrete capacity -set by setup["H2GenCommit"]
    inputs_gen["H2_G2P_COMMIT"] = intersect(h2_g2p_in[h2_g2p_in.Commit.==1 ,:R_ID])
    # Set of h2 resources eligible for unit committment
    inputs_gen["H2_G2P_NO_COMMIT"] = intersect(h2_g2p_in[h2_g2p_in.Commit.==0 ,:R_ID])

    #Set of all H2 production Units - can be either commit or new commit
    inputs_gen["H2_G2P"] = union(inputs_gen["H2_G2P_COMMIT"],inputs_gen["H2_G2P_NO_COMMIT"])

    # Set of all resources eligible for new capacity - includes both storage and generation
    # DEV NOTE: Should we allow investment in flexible demand capacity later on?
    inputs_gen["H2_G2P_NEW_CAP"] = intersect(inputs_gen["H2_G2P"], h2_g2p_in[h2_g2p_in.New_Build.==1 ,:R_ID], h2_g2p_in[h2_g2p_in.Max_Cap_MW.!=0,:R_ID]) 
    # Set of all resources eligible for capacity retirements
    # DEV NOTE: Should we allow retirement of flexible demand capacity later on?
    inputs_gen["H2_G2P_RET_CAP"] = intersect(inputs_gen["H2_G2P"], h2_g2p_in[h2_g2p_in.New_Build.!=-1,:R_ID], h2_g2p_in[h2_g2p_in.Existing_Cap_MW.>=0,:R_ID])

    # Fixed cost per start-up ($ per MW per start) if unit commitment is modelled
    start_cost_G2P = convert(Array{Float64}, collect(skipmissing(inputs_gen["dfH2G2P"][!,:Start_Cost_per_MW])))

    inputs_gen["C_G2P_Start"] = inputs_gen["dfH2G2P"][!,:Cap_Size_MW].* start_cost_G2P

    return inputs_gen

end