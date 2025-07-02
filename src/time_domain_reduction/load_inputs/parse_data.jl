@doc raw"""
    parse_data(myinputs)

Get load, solar, wind, and other curves from the input data.

"""
function parse_data(myinputs, mysetup)
    
    model_h2_flag = mysetup["ModelH2"]
    RESOURCES = myinputs["RESOURCE_ZONES"]
    ZONES = myinputs["R_ZONES"]

    # Assuming no missing data
    solar_col_names = String[]
    wind_col_names = String[]
    var_col_names = String[]
    solar_profiles = Vector{Vector{Float64}}()
    wind_profiles = Vector{Vector{Float64}}()
    var_profiles = Vector{Vector{Float64}}()

    h2_var_col_names = String[]
    h2_g2p_var_col_names = String[]
    h2_var_profiles = Vector{Vector{Float64}}()
    h2_g2p_var_profiles = Vector{Vector{Float64}}()
    h2_col_to_zone_map = Dict{String, Int}()
    h2_load_col_names = String[]
    h2_load_liq_col_names = String[]
    h2_load_profiles = Vector{Vector{Float64}}()
    h2_load_liq_profiles = Vector{Vector{Float64}}()

    # What does this mean? Is this default value
    AllHRVarConst = true
    AllHG2PVarConst = true

    # LOAD - Load_data.csv
    load_profiles = [ myinputs["pD"][:,l] for l in 1:size(myinputs["pD"],2) ]
    load_col_names = ["Load_MW_z"*string(l) for l in 1:size(load_profiles)[1]]
    col_to_zone_map = Dict("Load_MW_z"*string(l) => l for l in 1:size(load_profiles)[1])

    # CAPACITY FACTORS - Generators_variability.csv
    for r in 1:length(RESOURCES)
               
        if occursin("PV", RESOURCES[r]) || occursin("pv", RESOURCES[r]) || occursin("Pv", RESOURCES[r]) || occursin("Solar", RESOURCES[r]) || occursin("SOLAR", RESOURCES[r]) || occursin("solar", RESOURCES[r])
            push!(solar_col_names, RESOURCES[r])
            push!(solar_profiles, myinputs["pP_Max"][r,:])
        elseif occursin("Wind", RESOURCES[r]) || occursin("WIND", RESOURCES[r]) || occursin("wind", RESOURCES[r])
            push!(wind_col_names, RESOURCES[r])
            push!(wind_profiles, myinputs["pP_Max"][r,:])
        end
        push!(var_col_names, RESOURCES[r])
        push!(var_profiles, myinputs["pP_Max"][r,:])
        col_to_zone_map[RESOURCES[r]] = ZONES[r]
    end

    
    #Fuel costs
    fuel_col_names = string.(myinputs["fuels"])
    fuel_profiles = []
    AllFuelsConst = true
    for f in 1:length(fuel_col_names)
        push!(fuel_profiles, myinputs["fuel_costs"][fuel_col_names[f]])
        if AllFuelsConst && (minimum(myinputs["fuel_costs"][fuel_col_names[f]]) != maximum(myinputs["fuel_costs"][fuel_col_names[f]]))
            AllFuelsConst = false
        end
    end
    
    #Parse H2 Data
    if model_h2_flag == 1
        H2_RESOURCES = myinputs["H2_RESOURCE_ZONES"]    
        H2_ZONES = myinputs["H2_R_ZONES"]

        # Parsing HSC_load_data.csv
        h2_load_profiles = [ myinputs["H2_D"][:,l] for l in 1:size(myinputs["H2_D"],2) ]
        h2_load_col_names = ["Load_H2_MW_z"*string(l) for l in 1:size(h2_load_profiles)[1]]
        h2_col_to_zone_map = Dict("Load_H2_MW_z"*string(l) => l for l in 1:size(h2_load_profiles)[1])


        if mysetup["ModelH2Liquid"] ==1
        # Parsing HSC_load_data_liquid.csv
            h2_load_liq_profiles = [ myinputs["H2_D_L"][:,l] for l in 1:size(myinputs["H2_D_L"],2) ]
            h2_load_liq_col_names = ["Load_liqH2_MW_z"*string(l) for l in 1:size(h2_load_liq_profiles)[1]]
            #h2_col_to_zone_liq_map = Dict("Load_H2_MW_z"*string(l) => l for l in 1:size(h2_load_liq_profiles)[1])
        end

        # CAPACITY FACTORS - HSC_Generators_variability.csv
        for r in 1:length(H2_RESOURCES)
            push!(h2_var_col_names, H2_RESOURCES[r])
            push!(h2_var_profiles, myinputs["pH2_Max"][r,:])
            h2_col_to_zone_map[H2_RESOURCES[r]] = H2_ZONES[r]

            if AllHRVarConst && (minimum(myinputs["pH2_Max"][r,:]) != maximum(myinputs["pH2_Max"][r,:]))
                AllHRVarConst = false
            end
        end

        if mysetup["ModelH2G2P"] == 1
            
            H2_G2P= myinputs["H2_G2P_RESOURCE_ZONES"]    

            for r in 1:length(H2_G2P)
                push!(h2_g2p_var_col_names, H2_G2P[r])
                push!(h2_g2p_var_profiles, myinputs["pH2_g2p_Max"][r,:])

                if AllHG2PVarConst && (minimum(myinputs["pH2_g2p_Max"][r,:]) != maximum(myinputs["pH2_g2p_Max"][r,:]))
                    AllHG2PVarConst = false
                end
            end
        end
    end

    all_col_names = [load_col_names; h2_load_col_names; h2_load_liq_col_names; var_col_names; h2_var_col_names; h2_g2p_var_col_names; fuel_col_names]
    all_profiles = [load_profiles..., h2_load_profiles..., h2_load_liq_profiles..., var_profiles..., h2_var_profiles..., h2_g2p_var_profiles..., fuel_profiles...]

    parsed_data = Dict(
        "load_col_names" => load_col_names,
        "h2_load_col_names" => h2_load_col_names,
        "h2_load_liq_col_names" => h2_load_liq_col_names,
        "var_col_names" => var_col_names,
        "solar_col_names" => solar_col_names,
        "wind_col_names" => wind_col_names,
        "h2_var_col_names" => h2_var_col_names,
        "h2_g2p_var_col_names" => h2_g2p_var_col_names,
        "fuel_col_names" => fuel_col_names,
        "all_col_names" => all_col_names,
        "load_profiles" => load_profiles,
        "var_profiles" => var_profiles,
        "solar_profiles" => solar_profiles,
        "wind_profiles" => wind_profiles,
        "h2_var_profiles" => h2_var_profiles,
        "h2_g2p_var_profiles" => h2_g2p_var_profiles,
        "fuel_profiles" => fuel_profiles,
        "all_profiles" => all_profiles,
        "col_to_zone_map" => col_to_zone_map,
        "h2_col_to_zone_map" => h2_col_to_zone_map,
        "AllFuelsConst" => AllFuelsConst,
        "AllHRVarConst" => AllHRVarConst,
        "AllHG2PVarConst" => AllHG2PVarConst
    )

    return parsed_data

end