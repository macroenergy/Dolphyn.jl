function parse_data(myinputs, mysetup)

    model_h2_flag = mysetup["ModelH2"]
    RESOURCES = myinputs["RESOURCE_ZONES"]
    ZONES = myinputs["R_ZONES"]

    # Assuming no missing data
    solar_col_names = []
    wind_col_names = []
    var_col_names = []
    solar_profiles = []
    wind_profiles = []
    var_profiles = []
    h2_var_col_names = []
    h2_g2p_var_col_names = []
    h2_var_profiles = []
    h2_g2p_var_profiles = []
    h2_col_to_zone_map = []
    h2_load_col_names = []
    h2_load_profiles = []

    # What does this mean? Is this default value
    AllHRVarConst = true
    AllHG2PVarConst = true

    # LOAD - Load_data.csv
    load_profiles = [ myinputs["pD"][:,l] for l in 1:size(myinputs["pD"],2) ]
    load_col_names = ["Load_MW_z"*string(l) for l in 1:size(load_profiles)[1]]
    load_zones = [l for l in 1:size(load_profiles)[1]]
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
        h2_load_col_names = ["Load_H2_tonne_per_hr_z"*string(l) for l in 1:size(h2_load_profiles)[1]]
        h2_load_zones = [l for l in 1:size(h2_load_profiles)[1]]
        h2_col_to_zone_map = Dict("Load_H2_tonne_per_hr_z"*string(l) => l for l in 1:size(h2_load_profiles)[1])

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
            H2_G2P_ZONES = myinputs["H2_G2P_ZONES"]

            for r in 1:length(H2_G2P)
                push!(h2_g2p_var_col_names, H2_G2P[r])
                push!(h2_g2p_var_profiles, myinputs["pH2_g2p_Max"][r,:])

                if AllHG2PVarConst && (minimum(myinputs["pH2_g2p_Max"][r,:]) != maximum(myinputs["pH2_g2p_Max"][r,:]))
                    AllHG2PVarConst = false
                end
            end
        end
    end

    all_col_names = [load_col_names; h2_load_col_names; var_col_names; h2_var_col_names; h2_g2p_var_col_names; fuel_col_names]
    all_profiles = [load_profiles..., h2_load_profiles..., var_profiles..., h2_var_profiles..., h2_g2p_var_profiles..., fuel_profiles...]


    return load_col_names, h2_load_col_names, var_col_names, solar_col_names, wind_col_names, h2_var_col_names, h2_g2p_var_col_names,
    fuel_col_names, all_col_names, load_profiles, var_profiles, solar_profiles, wind_profiles, h2_var_profiles, h2_g2p_var_profiles,
    fuel_profiles, all_profiles, col_to_zone_map, h2_col_to_zone_map, AllFuelsConst, AllHRVarConst, AllHG2PVarConst

end

function RemoveConstCols(all_profiles, all_col_names, v=false)
    ConstData = []
    ConstIdx = []
    ConstCols = []
    for c in 1:length(all_col_names)
        Const = minimum(all_profiles[c]) == maximum(all_profiles[c])
        if Const
            if v println("Removing constant col: ", all_col_names[c]) end
            push!(ConstData, all_profiles[c])
            push!(ConstCols, all_col_names[c])
            push!(ConstIdx, c)
        end
    end
    all_profiles = [all_profiles[i] for i in 1:length(all_profiles) if i ∉ ConstIdx]
    all_col_names = [all_col_names[i] for i in 1:length(all_col_names) if i ∉ ConstIdx]
    return all_profiles, all_col_names, ConstData, ConstCols, ConstIdx
end

function rmse_score(y_true, y_pred)
    errors = y_pred - y_true
    errors² = errors .^ 2
    mse = mean(errors²)
    rmse = sqrt(mse)
    return rmse
end

function check_condition(Threshold, R, OldColNames, ScalingMethod, TimestepsPerRepPeriod)
    if ScalingMethod == "N"
        return maximum(R.costs)/(length(OldColNames)*TimestepsPerRepPeriod) < Threshold
    elseif ScalingMethod == "S"
        return maximum(R.costs)/(length(OldColNames)*TimestepsPerRepPeriod*4) < Threshold
    else
        println("INVALID Scaling Method ", ScalingMethod, " / Choose N for Normalization or S for Standardization. Proceeding with N.")
    end
    return maximum(R.costs)/(length(OldColNames)*TimestepsPerRepPeriod) < Threshold
end

function get_worst_period_idx(R)
    return argmax(R.costs)
end

function cluster(ClusterMethod, ClusteringInputDF, NClusters, nIters, v=false)
    if ClusterMethod == "kmeans"
        DistMatrix = pairwise(Euclidean(), Matrix(ClusteringInputDF), dims=2)
        R = kmeans(Matrix(ClusteringInputDF), NClusters, init=:kmcen)

        for i in 1:nIters
            R_i = kmeans(Matrix(ClusteringInputDF), NClusters)

            if R_i.totalcost < R.totalcost
                R = R_i
            end
            if v && (i % (nIters/10) == 0)
                println(string(i) * " : " * string(round(R_i.totalcost, digits=3)) * " " * string(round(R.totalcost, digits=3)) )
            end
        end

        A = R.assignments # get points to clusters mapping - A for Assignments
        W = R.counts # get the cluster sizes - W for Weights
        Centers = R.centers # get the cluster centers - M for Medoids

        M = []
        for i in 1:NClusters
            dists = [euclidean(Centers[:,i], ClusteringInputDF[!, j]) for j in 1:size(ClusteringInputDF, 2)]
            push!(M,argmin(dists))
        end

    elseif ClusterMethod == "kmedoids"
        DistMatrix = pairwise(Euclidean(), Matrix(ClusteringInputDF), dims=2)
        R = kmedoids(DistMatrix, NClusters, init=:kmcen)

        for i in 1:nIters
            R_i = kmedoids(DistMatrix, NClusters)
            if R_i.totalcost < R.totalcost
                R = R_i
            end
            if v && (i % (nIters/10) == 0)
                println(string(i) * " : " * string(round(R_i.totalcost, digits=3)) * " " * string(round(R.totalcost, digits=3)) )
            end
        end

        A = R.assignments # get points to clusters mapping - A for Assignments
        W = R.counts # get the cluster sizes - W for Weights
        M = R.medoids # get the cluster centers - M for Medoids
    else
        println("INVALID ClusterMethod. Select kmeans or kmedoids. Running kmeans instead.")
        return cluster("kmeans", ClusteringInputDF, NClusters, nIters)
    end
    return [R, A, W, M, DistMatrix]
end

function get_extreme_period(DF, GDF, profKey, typeKey, statKey,
    ConstCols, load_col_names, solar_col_names, wind_col_names, v=false)
    if v println(profKey," ", typeKey," ", statKey) end
    if typeKey == "Integral"
        if profKey == "Load"
            (stat, group_idx) = get_integral_extreme(GDF, statKey, load_col_names, ConstCols)
        elseif profKey == "PV"
            (stat, group_idx) = get_integral_extreme(GDF, statKey, solar_col_names, ConstCols)
        elseif profKey == "Wind"
            (stat, group_idx) = get_integral_extreme(GDF, statKey, wind_col_names, ConstCols)
        else
            println("Error: Profile Key ", profKey, " is invalid. Choose `Load', `PV' or `Wind'.")
        end
    elseif typeKey == "Absolute"
        if profKey == "Load"
            (stat, group_idx) = get_absolute_extreme(DF, statKey, load_col_names, ConstCols)
        elseif profKey == "PV"
            (stat, group_idx) = get_absolute_extreme(DF, statKey, solar_col_names, ConstCols)
        elseif profKey == "Wind"
            (stat, group_idx) = get_absolute_extreme(DF, statKey, wind_col_names, ConstCols)
        else
            println("Error: Profile Key ", profKey, " is invalid. Choose `Load', `PV' or `Wind'.")
        end
   else
       println("Error: Type Key ", typeKey, " is invalid. Choose `Absolute' or `Integral'.")
       stat = 0
       group_idx = 0
   end
    return (stat, group_idx)
end

function get_integral_extreme(GDF, statKey, col_names, ConstCols)
    if statKey == "Max"
        (stat, stat_idx) = findmax( sum([GDF[!, Symbol(c)] for c in setdiff(col_names, ConstCols) ]) )
    elseif statKey == "Min"
        (stat, stat_idx) = findmin( sum([GDF[!, Symbol(c)] for c in setdiff(col_names, ConstCols) ]) )
    else
        println("Error: Statistic Key ", statKey, " is invalid. Choose `Max' or `Min'.")
    end
    return (stat, stat_idx)
end

function get_absolute_extreme(DF, statKey, col_names, ConstCols)
    if statKey == "Max"
        (stat, stat_idx) = findmax( sum([DF[!, Symbol(c)] for c in setdiff(col_names, ConstCols) ]) )
        group_idx = DF.Group[stat_idx]
    elseif statKey == "Min"
        (stat, stat_idx) = findmin( sum([DF[!, Symbol(c)] for c in setdiff(col_names, ConstCols) ]) )
        group_idx = DF.Group[stat_idx]
    else
        println("Error: Statistic Key ", statKey, " is invalid. Choose `Max' or `Min'.")
    end
    return (stat, group_idx)
end

function scale_weights(W, H, v=false)
    if v println("Weights before scaling: ", W) end
    W = [ float(w)/sum(W) * H for w in W] # Scale to number of hours in input data
    if v
        println("Weights after scaling: ", W)
        println("Sum of Updated Cluster Weights: ", sum(W))
    end
    return W
end

function get_load_multipliers(ClusterOutputData, InputData, M, W, LoadCols, TimestepsPerRepPeriod, NewColNames, NClusters, Ncols, v=false)

    # Compute original zonal total loads
    zone_sums = Dict()
    for loadcol in LoadCols
        zone_sums[loadcol] = sum(InputData[:, loadcol])
    end

    # Compute zonal loads per representative period
    cluster_zone_sums = Dict()
    for m in 1:NClusters
        clustered_lp_DF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in LoadCols)) )
        cluster_zone_sums[m] = Dict()
        for loadcol in LoadCols
            cluster_zone_sums[m][loadcol] = sum(clustered_lp_DF[:, loadcol])
        end
    end

    # Use representative period weights to compute total zonal load of the representative profile
    # Determine multiplier to bridge the gap between original zonal loads and representative zonal loads
    weighted_cluster_zone_sums = Dict(loadcol => 0.0 for loadcol in LoadCols)
    load_mults = Dict()
    for loadcol in LoadCols
        for m in 1:NClusters
            weighted_cluster_zone_sums[loadcol] += (W[m]/(TimestepsPerRepPeriod))*cluster_zone_sums[m][loadcol]
        end
        load_mults[loadcol] = zone_sums[loadcol]/weighted_cluster_zone_sums[loadcol]
        if v println(loadcol, ": ", weighted_cluster_zone_sums[loadcol], " vs. ", zone_sums[loadcol], " => ", load_mults[loadcol]) end
    end

    # Zone-wise validation that scaled clustered load equals original load (Don't actually scale load in this function)
    if v
        new_zone_sums = Dict(loadcol => 0.0 for loadcol in LoadCols)
        for m in 1:NClusters
            for i in 1:Ncols
                if (NewColNames[i] in LoadCols)
                    # Uncomment this line if we decide to scale load here instead of later. (Also remove "load_mults[NewColNames[i]]*" term from new_zone_sums computation)
                    #ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] *= load_mults[NewColNames[i]]
                    println("   Scaling ", M[m], " (", NewColNames[i], ") : ", cluster_zone_sums[m][NewColNames[i]], " => ", load_mults[NewColNames[i]]*sum(ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i]))
                    new_zone_sums[NewColNames[i]] += (W[m]/(TimestepsPerRepPeriod))*load_mults[NewColNames[i]]*sum(ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i])
                end
            end
        end
        for loadcol in LoadCols
            println(loadcol, ": ", new_zone_sums[loadcol], " =?= ", zone_sums[loadcol])
        end
    end

    return load_mults
end

