@doc raw"""
    rmse_score(y_true, y_pred)

Calculates Root Mean Square Error.

```math
RMSE = \sqrt{\frac{1}{n}\Sigma_{i=1}^{n}{\Big(\frac{d_i -f_i}{\sigma_i}\Big)^2}}
```

"""

function rmse_score(y_true, y_pred)
    errors = y_pred .- y_true
    rmse = sqrt(mean(errors .^ 2))

    # Normalized RMSE
    normalized_y_pred = y_pred ./ maximum(y_true)
    normalized_y_true = y_true ./ maximum(y_true)
    rmse_normalized = sqrt(mean((normalized_y_pred .- normalized_y_true) .^ 2))

    #println("Normalized RMSE: ", rmse_normalized)
    return rmse
end


@doc raw"""
    check_condition(Threshold, R, OldColNames, ScalingMethod, TimestepsPerRepPeriod)

Check whether the greatest Euclidean deviation in the input data and the clustered
representation is within a given proportion of the "maximum" possible deviation.

(1 for Normalization covers 100%, 4 for Standardization covers ~95%)

"""
function check_condition(Threshold, R, OldColNames, ScalingMethod, TimestepsPerRepPeriod)
    if ScalingMethod == "N"
        return maximum(R.costs)/(length(OldColNames)*TimestepsPerRepPeriod) < Threshold
    elseif ScalingMethod == "S"
        return maximum(R.costs)/(length(OldColNames)*TimestepsPerRepPeriod*4) < Threshold
    else
        println(" -- INVALID Scaling Method ", ScalingMethod, " / Choose N for Normalization or S for Standardization. Proceeding with N.")
    end
    return maximum(R.costs)/(length(OldColNames)*TimestepsPerRepPeriod) < Threshold
end

@doc raw"""
    get_worst_period_idx(R)

Get the index of the period that is farthest from its representative
period by Euclidean distance.

"""
function get_worst_period_idx(R)
    return argmax(R.costs)
end


@doc raw"""
    RemoveConstCols(all_profiles, all_col_names)

Remove and store the columns that do not vary during the period.

"""
function RemoveConstCols(all_profiles, all_col_names, v=false)
    ConstData = []
    ConstIdx = []
    ConstCols = []
    for c in 1:length(all_col_names)
        Const = minimum(all_profiles[c]) == maximum(all_profiles[c])
        if Const
            if v println(" -- Removing constant col: ", all_col_names[c]) end
            push!(ConstData, all_profiles[c])
            push!(ConstCols, all_col_names[c])
            push!(ConstIdx, c)
        end
    end
    all_profiles = [all_profiles[i] for i in 1:length(all_profiles) if i ∉ ConstIdx]
    all_col_names = [all_col_names[i] for i in 1:length(all_col_names) if i ∉ ConstIdx]
    return all_profiles, all_col_names, ConstData, ConstCols, ConstIdx
end

@doc raw"""
    get_extreme_period(DF, GDF, profKey, typeKey, statKey,
       ConstCols, load_col_names, solar_col_names, wind_col_names)

Identify extreme week by specification of profile type (Load, PV, Wind),
measurement type (absolute (timestep with min/max value) vs. integral
(period with min/max summed value)), and statistic (minimum or maximum).
I.e., the user could want the hour with the most load across the whole
system to be included among the extreme periods. They would select
"Load", "System, "Absolute, and "Max".

"""
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
            println(" -- Error: Profile Key ", profKey, " is invalid. Choose `Load', `PV' or `Wind'.")
        end
    elseif typeKey == "Absolute"
        if profKey == "Load"
            (stat, group_idx) = get_absolute_extreme(DF, statKey, load_col_names, ConstCols)
        elseif profKey == "PV"
            (stat, group_idx) = get_absolute_extreme(DF, statKey, solar_col_names, ConstCols)
        elseif profKey == "Wind"
            (stat, group_idx) = get_absolute_extreme(DF, statKey, wind_col_names, ConstCols)
        else
            println(" -- Error: Profile Key ", profKey, " is invalid. Choose `Load', `PV' or `Wind'.")
        end
   else
       println(" -- Error: Type Key ", typeKey, " is invalid. Choose `Absolute' or `Integral'.")
       stat = 0
       group_idx = 0
   end
    return (stat, group_idx)
end


@doc raw"""
    get_integral_extreme(GDF, statKey, col_names, ConstCols)

Get the period index with the minimum or maximum load or capacity factor
summed over the period.

"""
function get_integral_extreme(GDF, statKey, col_names, ConstCols)
    if statKey == "Max"
        (stat, stat_idx) = findmax( sum([GDF[!, Symbol(c)] for c in setdiff(col_names, ConstCols) ]) )
    elseif statKey == "Min"
        (stat, stat_idx) = findmin( sum([GDF[!, Symbol(c)] for c in setdiff(col_names, ConstCols) ]) )
    else
        println(" -- Error: Statistic Key ", statKey, " is invalid. Choose `Max' or `Min'.")
    end
    return (stat, stat_idx)
end

@doc raw"""
    get_absolute_extreme(DF, statKey, col_names, ConstCols)

Get the period index of the single timestep with the minimum or maximum load or capacity factor.

"""
function get_absolute_extreme(DF, statKey, col_names, ConstCols)
    if statKey == "Max"
        (stat, stat_idx) = findmax( sum([DF[!, Symbol(c)] for c in setdiff(col_names, ConstCols) ]) )
        group_idx = DF.Group[stat_idx]
    elseif statKey == "Min"
        (stat, stat_idx) = findmin( sum([DF[!, Symbol(c)] for c in setdiff(col_names, ConstCols) ]) )
        group_idx = DF.Group[stat_idx]
    else
        println(" -- Error: Statistic Key ", statKey, " is invalid. Choose `Max' or `Min'.")
    end
    return (stat, group_idx)
end


@doc raw"""
    scale_weights(W, H)

Linearly scale weights W such that they sum to the desired number of timesteps (hours) H.

```math
w_j \leftarrow H \cdot \frac{w_j}{\sum_i w_i} \: \: \: \forall w_j \in W
```

"""
function scale_weights(W, H, v=false)
    if v println(" -- Weights before scaling: ", W) end
    W = [ float(w)/sum(W) * H for w in W] # Scale to number of hours in input data
    if v
        println(" -- Weights after scaling: ", W)
        println(" -- Sum of Updated Cluster Weights: ", sum(W))
    end
    return W
end


@doc raw"""
    get_load_multipliers(ClusterOutputData, ModifiedData, M, W, LoadCols, TimestepsPerRepPeriod, NewColNames, NClusters, Ncols)

Get multipliers to linearly scale clustered load profiles L zone-wise such that their weighted sum equals the original zonal total load.
Scale load profiles later using these multipliers in order to ensure that a copy of the original load is kept for validation.

Find $k_z$ such that:

```math
\sum_{i \in I} L_{i,z} = \sum_{t \in T, m \in M} C_{t,m,z} \cdot \frac{w_m}{T} \cdot k_z   \: \: \: \forall z \in Z
```

where $Z$ is the set of zones, $I$ is the full time domain, $T$ is the length of one period (e.g., 168 for one week in hours),
$M$ is the set of representative periods, $L_{i,z}$ is the original zonal load profile over time (hour) index $i$, $C_{i,m,z}$ is the
load in timestep $i$ for representative period $m$ in zone $z$, $w_m$ is the weight of the representative period equal to the total number of
hours that one hour in representative period $m$ represents in the original profile, and $k_z$ is the zonal load multiplier returned by the function.

"""
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
                    println(" --    Scaling ", M[m], " (", NewColNames[i], ") : ", cluster_zone_sums[m][NewColNames[i]], " => ", load_mults[NewColNames[i]]*sum(ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i]))
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