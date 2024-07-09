##############################################
#
#   Time Domain Reduction
#    - Jack Morris
#
# Use kmeans or kemoids to cluster raw load profiles and resource capacity factor profiles
# into representative periods. Use Extreme Periods to capture noteworthy periods or
# periods with notably poor fits.
#
#  Inputs
#
#  In time_domain_reduction_settings.yml, include the following:
#
#  - Timesteps_per_Rep_Period - Typically 168 timesteps (e.g., hours) per period, this designates the length
#     of each representative period.
#  - UseExtremePeriods - Either 1 or 0, this designates whether or not to include
#     outliers (by performance or load/resource extreme) as their own representative periods.
#     This setting automatically includes the periods with maximum load, minimum solar cf and
#     minimum wind cf as extreme periods.
#  - ClusterMethod - Either 'kmeans' or 'kmedoids', this designates the method used to cluster
#     periods and determine each point's representative period.
#  - ScalingMethod - Either 'N' or 'S', this designates directs the module to normalize ([0,1])
#     or standardize (mean 0, variance 1) the input data.
#  - MinPeriods - The minimum number of periods used to represent the input data. If using
#     UseExtremePeriods, this must be at least three. If IterativelyAddPeriods if off,
#    this will be the total number of periods.
#  - MaxPeriods - The maximum number of periods - both clustered periods and extreme periods -
#     that may be used to represent the input data.
#  - IterativelyAddPeriods - Either 1 or 0, this designates whether or not to add periods
#     until the error threshold between input data and represented data is met or the maximum
#     number of periods is reached.
#  - Threshold - Iterative period addition will end if the period farthest (Euclidean Distance)
#     from its representative period is within this percentage of the total possible error (for normalization)
#     or ~95% of the total possible error (for standardization). E.g., for a threshold of 0.01,
#     every period must be within 1% of the spread of possible error before the clustering
#     iterations will terminate (or until the max number of periods is reached).
#  - IterateMethod - Either 'cluster' (Default) or 'extreme', this designates whether to add clusters to
#     the kmeans/kmedoids method or to set aside the worst-fitting periods as a new extreme periods.
#  - nReps - Default 200, the number of times to repeat each kmeans/kmedoids clustering at the same setting.
#  - LoadWeight - Default 1, this is an optional multiplier on load columns in order to prioritize
#     better fits for load profiles over resource capacity factor profiles.
#  - WeightTotal - Default 8760, the sum to which the relative weights of representative periods will be scaled.
#  - ClusterFuelPrices - Either 1 or 0, this indicates whether or not to use the fuel price
#     time series in Fuels_data.csv in the clustering process. If 'no', this function will still write
#     Fuels_data_clustered.csv with reshaped fuel prices based on the number and size of the
#     representative weeks, assuming a constant time series of fuel prices with length equal to the
#     number of timesteps in the raw input data.
#
#
#############################################

using YAML
using DataFrames
using StatsBase
using Clustering
using Distances
using CSV

@doc raw"""
    parse_data(myinputs)

Get load, solar, wind, and other curves from the input data.

"""
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
    h2_load_liq_col_names = []
    h2_load_profiles = []
    h2_load_liq_profiles = []

    # What does this mean? Is this default value
    AllHRVarConst = true
    AllHG2PVarConst = true

    # LOAD - Load_data.csv
    load_profiles = [ myinputs["pD"][:,l] for l in 1:size(myinputs["pD"],2) ]
    load_col_names = ["Load_MW_z"*string(l) for l in 1:size(load_profiles)[1]]
    load_zones = [l for l in 1:size(load_profiles)[1]]
    col_to_zone_map = Dict("Load_MW_z"*string(l) => l for l in 1:size(load_profiles)[1])

    # CAPACITY FACTORS - Generators_variability.csv
    for r in eachindex(RESOURCES)
               
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
    for f in eachindex(fuel_col_names)
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


        if mysetup["ModelH2Liquid"] ==1
        # Parsing HSC_load_data_liquid.csv
            h2_load_liq_profiles = [ myinputs["H2_D_L"][:,l] for l in 1:size(myinputs["H2_D_L"],2) ]
            h2_load_liq_col_names = ["Load_liqH2_tonne_per_hr_z"*string(l) for l in 1:size(h2_load_liq_profiles)[1]]
            h2_load_liq_zones = [l for l in 1:size(h2_load_liq_profiles)[1]]
            #h2_col_to_zone_liq_map = Dict("Load_H2_tonne_per_hr_z"*string(l) => l for l in 1:size(h2_load_liq_profiles)[1])
        end

        # CAPACITY FACTORS - HSC_Generators_variability.csv
        for r in eachindex(H2_RESOURCES)
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

            for r in eachindex(H2_G2P)
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


    return load_col_names, h2_load_col_names, h2_load_liq_col_names, var_col_names, solar_col_names, wind_col_names, h2_var_col_names, h2_g2p_var_col_names,
    fuel_col_names, all_col_names, load_profiles, var_profiles, solar_profiles, wind_profiles, h2_var_profiles, h2_g2p_var_profiles, 
    fuel_profiles, all_profiles, col_to_zone_map, h2_col_to_zone_map, AllFuelsConst, AllHRVarConst, AllHG2PVarConst

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
        println(" -- INVALID Scaling Method $ScalingMethod \n Choose N for Normalization or S for Standardization. Proceeding with N.")
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
    cluster(ClusterMethod, ClusteringInputDF, NClusters, nIters)

Get representative periods using cluster centers from kmeans or kmedoids.

K-Means:
https://juliastats.org/Clustering.jl/dev/kmeans.html

K-Medoids:
 https://juliastats.org/Clustering.jl/stable/kmedoids.html
"""
function cluster(ClusterMethod, ClusteringInputDF, NClusters, nIters, v=false)
    if ClusterMethod == "kmeans"
        DistMatrix = pairwise(Euclidean(), Matrix(ClusteringInputDF), dims=2)
        R = kmeans(Matrix(ClusteringInputDF), NClusters, init=:kmcen)

        for i in 1:nIters
            R_i = kmeans(Matrix(ClusteringInputDF), NClusters)

            if R_i.totalcost < R.totalcost
                R = R_i
            end
            if (i % (nIters/10) == 0)
                @debug " -- Iteration: $i : $(round(R_i.totalcost, digits=3)) $(round(R.totalcost, digits=3))"
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
            if (i % (nIters/10) == 0)
                @debug " -- Iteration: $i : $(round(R_i.totalcost, digits=3)) $(round(R.totalcost, digits=3))"
            end
        end

        A = R.assignments # get points to clusters mapping - A for Assignments
        W = R.counts # get the cluster sizes - W for Weights
        M = R.medoids # get the cluster centers - M for Medoids
    else
        @warn " -- INVALID ClusterMethod. Select kmeans or kmedoids. Running kmeans instead."
        return cluster("kmeans", ClusteringInputDF, NClusters, nIters)
    end
    return [R, A, W, M, DistMatrix]
end

@doc raw"""
    RemoveConstCols(all_profiles, all_col_names)

Remove and store the columns that do not vary during the period.

"""
function RemoveConstCols(all_profiles, all_col_names, v=false)
    ConstData = []
    ConstIdx = []
    ConstCols = []
    for c in eachindex(all_col_names)
        Const = minimum(all_profiles[c]) == maximum(all_profiles[c])
        if Const
            @debug " -- Removing constant col: $(all_col_names[c])"
            push!(ConstData, all_profiles[c])
            push!(ConstCols, all_col_names[c])
            push!(ConstIdx, c)
        end
    end
    all_profiles = [all_profiles[i] for i in eachindex(all_profiles) if i ∉ ConstIdx]
    all_col_names = [all_col_names[i] for i in eachindex(all_col_names) if i ∉ ConstIdx]
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
    @debug " -- Getting extreme period for $profKey, $typeKey, $statKey"
    if typeKey == "Integral"
        if profKey == "Load"
            (stat, group_idx) = get_integral_extreme(GDF, statKey, load_col_names, ConstCols)
        elseif profKey == "PV"
            (stat, group_idx) = get_integral_extreme(GDF, statKey, solar_col_names, ConstCols)
        elseif profKey == "Wind"
            (stat, group_idx) = get_integral_extreme(GDF, statKey, wind_col_names, ConstCols)
        else
            println(" -- Error: Profile Key $profKey is invalid. Choose `Load', `PV' or `Wind'.")
        end
    elseif typeKey == "Absolute"
        if profKey == "Load"
            (stat, group_idx) = get_absolute_extreme(DF, statKey, load_col_names, ConstCols)
        elseif profKey == "PV"
            (stat, group_idx) = get_absolute_extreme(DF, statKey, solar_col_names, ConstCols)
        elseif profKey == "Wind"
            (stat, group_idx) = get_absolute_extreme(DF, statKey, wind_col_names, ConstCols)
        else
            println(" -- Error: Profile Key $profKey is invalid. Choose `Load', `PV' or `Wind'.")
        end
   else
       println(" -- Error: Type Key $typeKey is invalid. Choose `Absolute' or `Integral'.")
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
        println(" -- Error: Statistic Key $statKey is invalid. Choose `Max' or `Min'.")
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
        println(" -- Error: Statistic Key $statKey is invalid. Choose `Max' or `Min'.")
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
    @debug " -- Weights before scaling: $W"
    W = [ float(w)/sum(W) * H for w in W] # Scale to number of hours in input data
    @debug " -- Weights after scaling: $W"
    @debug " -- Sum of Updated Cluster Weights: $(sum(W))"
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
        @debug "$loadcol: $(weighted_cluster_zone_sums[loadcol]) vs. $(zone_sums[loadcol]) => $(load_mults[loadcol])"
    end

    # Zone-wise validation that scaled clustered load equals original load (Don't actually scale load in this function)
    if v
        new_zone_sums = Dict(loadcol => 0.0 for loadcol in LoadCols)
        for m in 1:NClusters
            for i in 1:Ncols
                if (NewColNames[i] in LoadCols)
                    # Uncomment this line if we decide to scale load here instead of later. (Also remove "load_mults[NewColNames[i]]*" term from new_zone_sums computation)
                    #ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] *= load_mults[NewColNames[i]]
                    println(" -- Scaling $(M[m]) ($(NewColNames[i])): $(cluster_zone_sums[m][NewColNames[i]]) => $(load_mults[NewColNames[i]] * sum(ClusterOutputData[!,m][TimestepsPerRepPeriod * (i-1)+1 : TimestepsPerRepPeriod * i]))")
                    new_zone_sums[NewColNames[i]] += (W[m]/(TimestepsPerRepPeriod))*load_mults[NewColNames[i]]*sum(ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i])
                end
            end
        end
        for loadcol in LoadCols
            println(" -- $loadcol: $(new_zone_sums[loadcol]) =?= $(zone_sums[loadcol])")
        end
    end

    return load_mults
end


@doc raw"""
    cluster_inputs(inpath, settings_path, v=false, norm_plot=false, silh_plot=false, res_plots=false, indiv_plots=false, pair_plots=false)

Use kmeans or kmedoids to cluster raw load profiles and resource capacity factor profiles
into representative periods. Use Extreme Periods to capture noteworthy periods or
periods with notably poor fits.

In Load_data.csv, include the following:

 - Timesteps\_per\_Rep\_Period - Typically 168 timesteps (e.g., hours) per period, this designates the length
     of each representative period.
 - UseExtremePeriods - Either 1 or 0, this designates whether or not to include
    outliers (by performance or load/resource extreme) as their own representative periods.
    This setting automatically includes the periods with maximum load, minimum solar cf and
    minimum wind cf as extreme periods.
 - ClusterMethod - Either 'kmeans' or 'kmedoids', this designates the method used to cluster
    periods and determine each point's representative period.
 - ScalingMethod - Either 'N' or 'S', this designates directs the module to normalize ([0,1])
    or standardize (mean 0, variance 1) the input data.
 - MinPeriods - The minimum number of periods used to represent the input data. If using
    UseExtremePeriods, this must be at least three. If IterativelyAddPeriods if off,
    this will be the total number of periods.
 - MaxPeriods - The maximum number of periods - both clustered periods and extreme periods -
    that may be used to represent the input data.
 - IterativelyAddPeriods - Either 1 or 0, this designates whether or not to add periods
    until the error threshold between input data and represented data is met or the maximum
    number of periods is reached.
 - Threshold - Iterative period addition will end if the period farthest (Euclidean Distance)
    from its representative period is within this percentage of the total possible error (for normalization)
    or ~95% of the total possible error (for standardization). E.g., for a threshold of 0.01,
    every period must be within 1% of the spread of possible error before the clustering
    iterations will terminate (or until the max number of periods is reached).
 - IterateMethod - Either 'cluster' or 'extreme', this designates whether to add clusters to
    the kmeans/kmedoids method or to set aside the worst-fitting periods as a new extreme periods.
 - nReps - The number of times to repeat each kmeans/kmedoids clustering at the same setting.
 - LoadWeight - Default 1, this is an optional multiplier on load columns in order to prioritize
    better fits for load profiles over resource capacity factor profiles.
 - WeightTotal - Default 8760, the sum to which the relative weights of representative periods will be scaled.
 - ClusterFuelPrices - Either 1 or 0, this indicates whether or not to use the fuel price
    time series in Fuels\_data.csv in the clustering process. If 'no', this function will still write
    Fuels\_data\_clustered.csv with reshaped fuel prices based on the number and size of the
    representative weeks, assuming a constant time series of fuel prices with length equal to the
    number of timesteps in the raw input data.
"""
function cluster_inputs(inpath, settings_path, mysetup, v=false)

    @debug " -- Starting Time Domain Reduction: $(now())"

    ##### Step 0: Load in settings and data

    # Read time domain reduction settings file time_domain_reduction_settings.yml
    myTDRsetup = YAML.load(open(joinpath(settings_path,"time_domain_reduction_settings.yml")))

    # Accept model parameters from the settings file time_domain_reduction_settings.yml
    TimestepsPerRepPeriod = myTDRsetup["TimestepsPerRepPeriod"]
    ClusterMethod = myTDRsetup["ClusterMethod"]
    ScalingMethod = myTDRsetup["ScalingMethod"]
    MinPeriods = myTDRsetup["MinPeriods"]
    MaxPeriods = myTDRsetup["MaxPeriods"]
    UseExtremePeriods = myTDRsetup["UseExtremePeriods"]
    ExtPeriodSelections = myTDRsetup["ExtremePeriods"]
    Iterate = myTDRsetup["IterativelyAddPeriods"]
    IterateMethod = myTDRsetup["IterateMethod"]
    Threshold = myTDRsetup["Threshold"]
    nReps = myTDRsetup["nReps"]
    LoadWeight = myTDRsetup["LoadWeight"]
    WeightTotal = myTDRsetup["WeightTotal"]
    ClusterFuelPrices = myTDRsetup["ClusterFuelPrices"]
    TimeDomainReductionFolder = mysetup["TimeDomainReductionFolder"]

    # Set output filenames for later
    Load_Outfile = joinpath(TimeDomainReductionFolder, "Load_data.csv")
    GVar_Outfile = joinpath(TimeDomainReductionFolder, "Generators_variability.csv")
    Fuel_Outfile = joinpath(TimeDomainReductionFolder, "Fuels_data.csv")
    PMap_Outfile = joinpath(TimeDomainReductionFolder, "Period_map.csv")
    H2Load_Outfile = joinpath(TimeDomainReductionFolder, "HSC_load_data.csv")
    H2Load_Liq_Outfile = joinpath(TimeDomainReductionFolder, "HSC_load_data_liquid.csv")
    H2RVar_Outfile = joinpath(TimeDomainReductionFolder, "HSC_generators_variability.csv")
    H2G2PVar_Outfile = joinpath(TimeDomainReductionFolder, "HSC_g2p_variability.csv")
    YAML_Outfile = joinpath(TimeDomainReductionFolder, "time_domain_reduction_settings.yml")

    # Define a local version of the setup so that you can modify the mysetup["ParameterScale"] value to be zero in case it is 1
    mysetup_local = copy(mysetup)
    # If ParameterScale =1 then make it zero, since clustered inputs will be scaled prior to generating model
    mysetup_local["ParameterScale"]=0  # Performing cluster and report outputs in user-provided units
    @debug " -- Loading inputs from $inpath"

    myinputs=Dict()
    myinputs = load_inputs(mysetup_local,inpath)

    if mysetup["ModelH2"] == 1
      myinputs = load_h2_inputs(myinputs, mysetup_local, inpath)
    end

    #Copy Original Parameter Scale Variable
    parameter_scale_org = mysetup["ParameterScale"]
    #Copy setup from set-up local. Set-up local contains some H2 setup inputs, except for correct parameter scale
    mysetup = copy(mysetup_local)
    #Overwrites paramater scale
    mysetup["ParameterScale"] = parameter_scale_org 

    # Parse input data into useful structures divided by type (load, wind, solar, fuel, groupings thereof, etc.)
    # TO DO LATER: Replace these with collections of col_names, profiles, zones
    load_col_names, h2_load_col_names, h2_load_liq_col_names, var_col_names, solar_col_names, wind_col_names, h2_var_col_names, h2_g2p_var_col_names, fuel_col_names, 
    all_col_names, load_profiles, var_profiles, solar_profiles, wind_profiles, h2_var_profiles, h2_g2p_var_profiles, 
    fuel_profiles, all_profiles, col_to_zone_map, h2_col_to_zone_map, AllFuelsConst, AllHRVarConst, AllHG2PVarConst = parse_data(myinputs, mysetup)

    # Remove Constant Columns - Add back later in final output
    all_profiles, all_col_names, ConstData, ConstCols, ConstIdx = RemoveConstCols(all_profiles, all_col_names, v)

    # Determine whether or not to time domain reduce fuel profiles as well based on user choice and file structure (i.e., variable fuels in Fuels_data.csv)
    IncludeFuel = true
    if (ClusterFuelPrices != 1) || (AllFuelsConst) IncludeFuel = false end

    # Put it together!
    InputData = DataFrame( Dict( all_col_names[c]=>all_profiles[c] for c in eachindex(all_col_names) ) )

    @debug " -- Load (MW) and Capacity Factor Profiles: \n $(describe(InputData))"

    OldColNames = names(InputData)
    NewColNames = [Symbol.(OldColNames); :GrpWeight]
    Nhours = nrow(InputData) # Timesteps
    Ncols = length(NewColNames) - 1


    ##### Step 1: Normalize or standardize all load, renewables, and fuel data / optionally scale with LoadWeight

    # Normalize/standardize data based on user-provided method
    if ScalingMethod == "N"
        normProfiles = [ StatsBase.transform(fit(UnitRangeTransform, InputData[:,c]; dims=1, unit=true), InputData[:,c]) for c in eachindex(OldColNames)  ]
    elseif ScalingMethod == "S"
        normProfiles = [ StatsBase.transform(fit(ZScoreTransform, InputData[:,c]; dims=1, center=true, scale=true), InputData[:,c]) for c in eachindex(OldColNames)  ]
    else
        println(" -- ERROR InvalidScalingMethod: Use N for Normalization or S for Standardization.")
        println(" -- CONTINUING using 0->1 normalization...")
        normProfiles = [ StatsBase.transform(fit(UnitRangeTransform, InputData[:,c]; dims=1, unit=true), InputData[:,c]) for c in eachindex(OldColNames)  ]
    end

    # Compile newly normalized/standardized profiles
    AnnualTSeriesNormalized = DataFrame(Dict(  OldColNames[c] => normProfiles[c] for c in eachindex(OldColNames) ))

    # Optional pre-scaling of load in order to give it more preference in clutering algorithm
    if LoadWeight != 1   # If we want to value load more/less than capacity factors. Assume nonnegative. LW=1 means no scaling.
        for c in load_col_names
            AnnualTSeriesNormalized[!, Symbol(c)] .= AnnualTSeriesNormalized[!, Symbol(c)] .* LoadWeight
        end
    end

    @debug " -- Load (MW) and Capacity Factor Profiles NORMALIZED: \n $(describe(AnnualTSeriesNormalized))"

    ##### STEP 2: Identify extreme periods in the model, Reshape data for clustering

    # Total number of subperiods available in the dataset, where each subperiod length = TimestepsPerRepPeriod
    NumDataPoints = Nhours÷TimestepsPerRepPeriod # 364 weeks in 7 years
    @debug " -- Total Subperiods in the data set: $NumDataPoints"
    InputData[:, :Group] .= (1:Nhours) .÷ (TimestepsPerRepPeriod+0.0001) .+ 1    # Group col identifies the subperiod ID of each hour (e.g., all hours in week 2 have Group=2 if using TimestepsPerRepPeriod=168)

    # Group by period (e.g., week)
    cgdf = combine(groupby(InputData, :Group), [c .=> sum for c in OldColNames])
    cgdf = cgdf[setdiff(1:end, NumDataPoints+1), :]
    rename!(cgdf, [:Group; Symbol.(OldColNames)])

    # Extreme period identification based on user selection in time_domain_reduction_settings.yml
    LoadExtremePeriod = false        # Used when deciding whether or not to scale load curves to equal original total load
    ExtremeWksList = []
    if UseExtremePeriods == 1
      for profKey in keys(ExtPeriodSelections)
          for geoKey in keys(ExtPeriodSelections[profKey])
              for typeKey in keys(ExtPeriodSelections[profKey][geoKey])
                  for statKey in keys(ExtPeriodSelections[profKey][geoKey][typeKey])
                      if ExtPeriodSelections[profKey][geoKey][typeKey][statKey] == 1
                          if profKey == "Load"
                              LoadExtremePeriod = true
                          end
                          if geoKey == "System"
                              (stat, group_idx) = get_extreme_period(InputData, cgdf, profKey, typeKey, statKey, ConstCols, load_col_names, solar_col_names, wind_col_names, v)
                              push!(ExtremeWksList, floor(Int, group_idx))
                              @debug " -- Extreme Period: $geoKey $(group_idx) : $(stat)"
                          elseif geoKey == "Zone"
                              for z in sort(unique(myinputs["R_ZONES"]))
                                    z_cols = [k for (k,v) in col_to_zone_map if v==z]
                                    if profKey == "Load" z_cols_type = intersect(z_cols, load_col_names)
                                    elseif profKey == "PV" z_cols_type = intersect(z_cols, solar_col_names)
                                    elseif profKey == "Wind" z_cols_type = intersect(z_cols, wind_col_names)
                                    else z_cols_type = []
                                    end
                                    z_cols_type = setdiff(z_cols_type, ConstCols)
                                    if length(z_cols_type) > 0
                                        (stat, group_idx) = get_extreme_period(select(InputData, [:Group; Symbol.(z_cols_type)]), select(cgdf, [:Group; Symbol.(z_cols_type)]), profKey, typeKey, statKey, ConstCols, z_cols_type, z_cols_type, z_cols_type, v)
                                        push!(ExtremeWksList, floor(Int, group_idx))
                                        @debug " -- Extreme Period: $geoKey $(group_idx) : $(stat)($z)"
                                  else
                                        @debug " -- Zone $z has no time series profiles of type $profKey"
                                  end
                              end
                          else
                              println(" -- Error: Geography Key $geoKey is invalid. Select `System' or `Zone'.")
                          end
                      end
                  end
              end
          end
      end
      @debug " -- Extreme Weeks: $(ExtremeWksList)"
      sort!(unique!(ExtremeWksList))
      @debug " -- Reduced to: $(ExtremeWksList)"
    end

    ### DATA MODIFICATION - Shifting InputData and Normalized InputData
    #    from 8760 (# hours) by n (# profiles) DF to
    #    168*n (n period-stacked profiles) by 52 (# periods) DF
    DFsToConcat = [stack(InputData[isequal.(InputData.Group,w),:], OldColNames)[!,:value] for w in 1:NumDataPoints if w <= NumDataPoints ]
    ModifiedData = DataFrame(Dict(Symbol(i) => DFsToConcat[i] for i in 1:NumDataPoints))

    AnnualTSeriesNormalized[:, :Group] .= (1:Nhours) .÷ (TimestepsPerRepPeriod+0.0001) .+ 1
    DFsToConcatNorm = [stack(AnnualTSeriesNormalized[isequal.(AnnualTSeriesNormalized.Group,w),:], OldColNames)[!,:value] for w in 1:NumDataPoints if w <= NumDataPoints ]
    ModifiedDataNormalized = DataFrame(Dict(Symbol(i) => DFsToConcatNorm[i] for i in 1:NumDataPoints))

    # Remove extreme periods from normalized data before clustering
    NClusters = MinPeriods
    if UseExtremePeriods == 1
        @debug " -- Pre-removal: $(names(ModifiedDataNormalized))"
        @debug " -- Extreme Periods: $(string.(ExtremeWksList))"
        ClusteringInputDF = select(ModifiedDataNormalized, Not(string.(ExtremeWksList)))
        @debug " -- Post-removal: $(names(ClusteringInputDF))"
        NClusters -= length(ExtremeWksList)
    else
        ClusteringInputDF = ModifiedDataNormalized
    end


    ##### STEP 3: Clustering
    cluster_results = []

    # Cluster once regardless of iteration decisions
    push!(cluster_results, cluster(ClusterMethod, ClusteringInputDF, NClusters, nReps, v))

    # Iteratively add worst periods as extreme periods OR increment number of clusters k
    #    until threshold is met or maximum periods are added (If chosen in inputs)
    if (Iterate == 1)
        while (!check_condition(Threshold, last(cluster_results)[1], OldColNames, ScalingMethod, TimestepsPerRepPeriod)) & ((length(ExtremeWksList)+NClusters) < MaxPeriods)
            if IterateMethod == "cluster"
                @debug " -- Adding a new Cluster!"
                NClusters += 1
                push!(cluster_results, cluster(ClusterMethod, ClusteringInputDF, NClusters, nReps, v))
            elseif (IterateMethod == "extreme") & (UseExtremePeriods == 1)
                @debug " -- Adding a new Extreme Period!"
                worst_period_idx = get_worst_period_idx(last(cluster_results)[1])
                removed_period = string(names(ClusteringInputDF)[worst_period_idx])
                select!(ClusteringInputDF, Not(worst_period_idx))
                push!(ExtremeWksList, parse(Int, removed_period))
                @debug " -- Worst Period: $(worst_period_idx) ($(removed_period)) $(ExtremeWksList)"
                push!(cluster_results, cluster(ClusterMethod, ClusteringInputDF, NClusters, nReps, v))
            elseif IterateMethod == "extreme"
                println(" -- INVALID IterateMethod $IterateMethod because UseExtremePeriods is off. Set to 1 if you wish to add extreme periods.")
                break
            else
                println(" -- INVALID IterateMethod $IterateMethod. Choose 'cluster' or 'extreme'.")
                break
            end
        end
        if (length(ExtremeWksList)+NClusters == MaxPeriods)
            @debug " -- Stopped iterating by hitting the maximum number of periods."
        else
            @debug " -- Stopped by meeting the accuracy threshold."
        end
    end

    # Interpret Final Clustering Result
    R = last(cluster_results)[1]  # Cluster Object
    A = last(cluster_results)[2]  # Assignments
    W = last(cluster_results)[3]  # Weights
    M = last(cluster_results)[4]  # Centers or Medoids
    DistMatrix = last(cluster_results)[5]  # Pairwise distances
    @debug " -- Total Groups Assigned to Each Cluster: $W \n -- Sum Cluster Weights: $(sum(W)) \n -- Representative Periods: $M"

    # K-means/medoids returns indices from DistMatrix as its medoids.
    #   This does not account for missing extreme weeks.
    #   This is corrected retroactively here.
    M = [parse(Int64, string(names(ClusteringInputDF)[i])) for i in M]
    @debug " -- Fixed M: $M"

    ##### Step 4: Aggregation
    # Add the subperiods corresponding to the extreme periods back into the data.
    # Rescale weights to total user-specified number of hours (e.g., 8760 for one year).
    # If LoadExtremePeriod=false (because we don't want to change peak load day), rescale load to ensure total demand is equal

    # Add extreme periods into the clustering result with # of occurences = 1 for each
    ExtremeWksList = sort(ExtremeWksList)
    if UseExtremePeriods == 1
        @debug " -- Extreme Periods: $(ExtremeWksList)"
        M = [M; ExtremeWksList]
        for w in eachindex(ExtremeWksList)
            insert!(A, ExtremeWksList[w], NClusters+w)
            push!(W, 1)
        end
        NClusters += length(ExtremeWksList) #NClusers from this point forward is the ending number of periods
    end

    N = W  # Keep cluster version of weights stored as N, number of periods represented by RP

    # Rescale weights to total user-specified number of hours
    W = scale_weights(W, WeightTotal, v)

    # Order representative periods chronologically
    #   SORT A W M in conjunction, chronologically by M, before handling them elsewhere to be consistent
    #   A points to an index of M. We need it to point to a new index of sorted M. Hence, AssignMap.
    old_M = M
    df_sort = DataFrame( Weights = W, NumPeriods = N, Rep_Period = M)
    sort!(df_sort, [:Rep_Period])
    W = df_sort[!, :Weights]
    N = df_sort[!, :NumPeriods]
    M = df_sort[!, :Rep_Period]
    AssignMap = Dict( i => findall(x->x==old_M[i], M)[1] for i in eachindex(M))
    A = [AssignMap[a] for a in A]

    # Make PeriodMap, maps each period to its representative period
    PeriodMap = DataFrame(Period_Index = 1:length(A),
                            Rep_Period = [M[a] for a in A],
                            Rep_Period_Index = [a for a in A])

    # Get Symbol-version of column names by type for later analysis
    LoadCols = [Symbol("Load_MW_z"*string(i)) for i in eachindex(load_col_names) ]
    VarCols = [Symbol(var_col_names[i]) for i in eachindex(var_col_names) ]
    FuelCols = [Symbol(fuel_col_names[i]) for i in eachindex(fuel_col_names) ]
    ConstCol_Syms = [Symbol(ConstCols[i]) for i in eachindex(ConstCols) ]

    LoadColsNoConst = setdiff(LoadCols, ConstCol_Syms)

    if mysetup["ModelH2"] == 1
        H2LoadCols = [Symbol("Load_H2_tonne_per_hr_z"*string(i)) for i in eachindex(h2_load_col_names) ]
        H2LoadLiqCols = [Symbol("Load_liqH2_tonne_per_hr_z"*string(i)) for i in eachindex(h2_load_liq_col_names) ]
        H2VarCols = [Symbol(h2_var_col_names[i]) for i in eachindex(h2_var_col_names) ]
        H2G2PVarCols = [Symbol(h2_g2p_var_col_names[i]) for i in eachindex(h2_g2p_var_col_names) ]
    end

    # Cluster Ouput: The original data at the medoids/centers
    ClusterOutputData = ModifiedData[:,Symbol.(M)]

    # Get zone-wise load multipliers for later scaling in order for weighted-representative-total-zonal load to equal original total-zonal load
    #  (Only if we don't have load-related extreme periods because we don't want to change peak load periods)
    if !LoadExtremePeriod
        load_mults = get_load_multipliers(ClusterOutputData, InputData, M, W, LoadColsNoConst, TimestepsPerRepPeriod, NewColNames, NClusters, Ncols)
    end

    # Reorganize Data by Load, Solar, Wind, Fuel, and GrpWeight by Hour, Add Constant Data Back In
    rpDFs = [] # Representative Period DataFrames - Load and Resource Profiles
    gvDFs = [] # Generators Variability DataFrames - Just Resource Profiles
    lpDFs = [] # Load Profile DataFrames - Just Load Profiles
    fpDFs = [] # Fuel Profile DataFrames - Just Fuel Profiles

    if mysetup["ModelH2"] == 1
        hrvDFs = [] # Hydrogen resource variability DataFrames
        hlpDFs = [] # Hydrogen load profiles
        hllpDFs = [] # liquid Hydrogen load profiles
        hrvg2pDFs = []
    end
    
    for m in 1:NClusters
        rpDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols) )
        gvDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in VarCols)) )
        lpDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in LoadCols)) )
        if IncludeFuel fpDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in FuelCols)) ) end
        if !IncludeFuel fpDF = DataFrame(Placeholder = 1:TimestepsPerRepPeriod) end

        if mysetup["ModelH2"] == 1
            hrvDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in H2VarCols)) )
            hlpDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in H2LoadCols)) )

            AllH2LoadVarConst =  length(intersect(H2LoadCols, ConstCol_Syms)) == length(H2LoadCols)

            if AllH2LoadVarConst
                hlpDF = DataFrame(Placeholder = 1:TimestepsPerRepPeriod)
            end

            if AllHRVarConst
                hrvDF = DataFrame(Placeholder = 1:TimestepsPerRepPeriod)
            end
            
            if mysetup["ModelH2Liquid"] == 1
                hllpDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in H2LoadLiqCols)) )
            end

            if mysetup["ModelH2G2P"] == 1

                hrvg2pDF = DataFrame( Dict( NewColNames[i] => ClusterOutputData[!,m][TimestepsPerRepPeriod*(i-1)+1 : TimestepsPerRepPeriod*i] for i in 1:Ncols if (Symbol(NewColNames[i]) in H2G2PVarCols)))

                if AllHG2PVarConst
                    hrvg2pDF = DataFrame(Placeholder = 1:TimestepsPerRepPeriod)
                end

            else
                hrvg2pDF = []
            end


        else
            hrvDF = []
            hlpDF = []
            hllpDF = []
            hrvg2pDF = []
        end
                
        # Add Constant Columns back in
        for c in eachindex(ConstCols)
            rpDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
            if Symbol(ConstCols[c]) in VarCols
                gvDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
            elseif Symbol(ConstCols[c]) in FuelCols
                fpDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
            elseif Symbol(ConstCols[c]) in LoadCols
                lpDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
            elseif mysetup["ModelH2"] == 1
                if Symbol(ConstCols[c]) in H2VarCols
                    hrvDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
                elseif Symbol(ConstCols[c]) in H2LoadCols
                    hlpDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
                end

                if mysetup["ModelH2Liquid"] == 1
                    if Symbol(ConstCols[c]) in H2LoadLiqCols
                        hllpDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
                    end
                end
                
                if mysetup["ModelH2G2P"] == 1
                    if Symbol(ConstCols[c]) in H2G2PVarCols
                        hrvg2pDF[!,Symbol(ConstCols[c])] .= ConstData[c][1]
                    end
                end

            end
        end

        if !IncludeFuel select!(fpDF, Not(:Placeholder)) end
        

        # Scale Load using previously identified multipliers
        #   Scale lpDF but not rpDF which compares to input data but is not written to file.
        if !LoadExtremePeriod
            for loadcol in LoadCols
                if loadcol ∉ ConstCol_Syms
                    lpDF[!,loadcol] .*= load_mults[loadcol]
                end
            end
        end

        rpDF[!,:GrpWeight] .= W[m]
        rpDF[!,:Cluster] .= M[m]
        push!(rpDFs, rpDF)
        push!(gvDFs, gvDF)
        push!(lpDFs, lpDF)
        push!(fpDFs, fpDF)
        
        if mysetup["ModelH2"] == 1
            if AllHRVarConst select!(hrvDF, Not(:Placeholder)) end 
            push!(hrvDFs, hrvDF)
            push!(hlpDFs, hlpDF)

            if mysetup["ModelH2Liquid"] == 1
                push!(hllpDFs, hllpDF)
            end

            if mysetup["ModelH2G2P"] == 1
                if AllHG2PVarConst select!(hrvg2pDF, Not(:Placeholder))end
                push!(hrvg2pDFs, hrvg2pDF)
            end

        end
    end
    FinalOutputData = vcat(rpDFs...)  # For comparisons with input data to evaluate clustering process
    GVOutputData = vcat(gvDFs...)     # Generators Variability
    LPOutputData = vcat(lpDFs...)     # Load Profiles
    FPOutputData = vcat(fpDFs...)     # Load Profiles

    if mysetup["ModelH2"] == 1
        HLPOutputData = vcat(hlpDFs...) #Hydrogen Load Profiles
        HRVOutputData = vcat(hrvDFs...) #Hydrogen Resource Variability Profiles
        
        if mysetup["ModelH2Liquid"] == 1
            HLLPOutputData = vcat(hllpDFs...) #Hydrogen Load Profiles
        end
        
        if mysetup["ModelH2G2P"] == 1
            HG2POutputData = vcat(hrvg2pDFs...)
        end

    end

    ##### Step 5: Evaluation

    InputDataTest = InputData[(InputData.Group .<= NumDataPoints*1.0), :]
    ClusterDataTest = vcat([rpDFs[a] for a in A]...) # To compare fairly, load is not scaled here
    RMSE = Dict( c => rmsd(InputDataTest[:, c], ClusterDataTest[:, c])  for c in OldColNames)


    ##### Step 6: Print to File

    if Sys.isunix()
        sep = "/"
    elseif Sys.iswindows()
        sep = "\U005c"
    else
        sep = "/"
    end

    mkpath(joinpath(inpath, TimeDomainReductionFolder))

    ### Load_data_clustered.csv
    load_in = DataFrame(CSV.File(string(inpath,sep,"Load_data.csv"), header=true), copycols=true) #Setting header to false doesn't take the names of the columns; not including it, not including copycols, or, setting copycols to false has no effect
    load_in[!,:Sub_Weights] = load_in[!,:Sub_Weights] * 1.
    load_in[1:length(W),:Sub_Weights] .= W
    load_in[!,:Rep_Periods][1] = length(W)
    load_in[!,:Timesteps_per_Rep_Period][1] = TimestepsPerRepPeriod
    select!(load_in, Not(LoadCols))
    select!(load_in, Not(:Time_Index))
    Time_Index_M = Union{Int64, Missings.Missing}[missing for i in 1:size(load_in,1)]
    Time_Index_M[1:size(LPOutputData,1)] = 1:size(LPOutputData,1)
    load_in[!,:Time_Index] .= Time_Index_M

    for c in LoadCols
        new_col = Union{Float64, Missings.Missing}[missing for i in 1:size(load_in,1)]
        new_col[1:size(LPOutputData,1)] = LPOutputData[!,c]
        load_in[!,c] .= new_col
    end
    load_in = load_in[1:size(LPOutputData,1),:]

    @debug " -- Writing load file..."
    CSV.write(string(inpath,sep,Load_Outfile), load_in)

    ### Generators_variability_clustered.csv

    # Reset column ordering, add time index, and solve duplicate column name trouble with CSV.write's header kwarg
    GVColMap = Dict(myinputs["RESOURCE_ZONES"][i] => myinputs["RESOURCES"][i] for i in eachindex(myinputs["RESOURCES"]))
    GVColMap["Time_Index"] = "Time_Index"
    GVOutputData = GVOutputData[!, Symbol.(myinputs["RESOURCE_ZONES"])]
    insertcols!(GVOutputData, 1, :Time_Index => 1:size(GVOutputData,1))
    NewGVColNames = [GVColMap[string(c)] for c in names(GVOutputData)]
    @debug " -- Writing resource file..."
    CSV.write(string(inpath,sep,GVar_Outfile), GVOutputData, header=NewGVColNames)

    ### Fuels_data_clustered.csv

    fuel_in = DataFrame(CSV.File(string(inpath,sep,"Fuels_data.csv"), header=true), copycols=true)
    select!(fuel_in, Not(:Time_Index))
    SepFirstRow = DataFrame(fuel_in[1, :])
    NewFuelOutput = vcat(SepFirstRow, FPOutputData)
    rename!(NewFuelOutput, FuelCols)
    insertcols!(NewFuelOutput, 1, :Time_Index => 0:size(NewFuelOutput,1)-1)
    @debug " -- Writing fuel profiles..."
    CSV.write(string(inpath,sep,Fuel_Outfile), NewFuelOutput)

    ### Period_map.csv
    @debug " -- Writing period map..."
    CSV.write(string(inpath,sep,PMap_Outfile), PeriodMap)

    ### Write Hydrogen Outputs
    if mysetup["ModelH2"] == 1
        #Write h2_load_data.csv
        h2_load_in = DataFrame(CSV.File(string(inpath,sep,"HSC_load_data.csv"), header=true), copycols=true)
        h2_load_in[!,:Sub_Weights] = h2_load_in[!,:Sub_Weights] * 1.
        h2_load_in[1:length(W),:Sub_Weights] .= W
        h2_load_in[!,:Rep_Periods][1] = length(W)
        h2_load_in[!,:Timesteps_per_Rep_Period][1] = TimestepsPerRepPeriod
        select!(h2_load_in, Not(H2LoadCols))
        select!(h2_load_in, Not(:Time_Index))
        Time_Index_M = Union{Int64, Missings.Missing}[missing for i in 1:size(h2_load_in,1)]
        Time_Index_M[1:size(HLPOutputData,1)] = 1:size(HLPOutputData,1)
        h2_load_in[!,:Time_Index] .= Time_Index_M

        for c in H2LoadCols
            new_col = Union{Float64, Missings.Missing}[missing for i in 1:size(h2_load_in,1)]
            new_col[1:size(HLPOutputData,1)] = HLPOutputData[!,c]
            h2_load_in[!,c] .= new_col
        end
        
        h2_load_in = h2_load_in[1:size(HLPOutputData,1),:]

        @debug " -- Writing load file..."
        CSV.write(string(inpath,sep,H2Load_Outfile), h2_load_in)


        #Write h2_load_data_liquid.csv
        if mysetup["ModelH2Liquid"] ==1
            h2_load_in = DataFrame(CSV.File(string(inpath,sep,"HSC_load_data_liquid.csv"), header=true), copycols=true)
            h2_load_in[!,:Sub_Weights] = h2_load_in[!,:Sub_Weights] * 1.
            h2_load_in[1:length(W),:Sub_Weights] .= W
            h2_load_in[!,:Rep_Periods][1] = length(W)
            h2_load_in[!,:Timesteps_per_Rep_Period][1] = TimestepsPerRepPeriod
            select!(h2_load_in, Not(H2LoadLiqCols))
            select!(h2_load_in, Not(:Time_Index))
            Time_Index_M = Union{Int64, Missings.Missing}[missing for i in 1:size(h2_load_in,1)]
            Time_Index_M[1:size(HLLPOutputData,1)] = 1:size(HLLPOutputData,1)
            h2_load_in[!,:Time_Index] .= Time_Index_M

            for c in H2LoadLiqCols
                new_col = Union{Float64, Missings.Missing}[missing for i in 1:size(h2_load_in,1)]
                new_col[1:size(HLLPOutputData,1)] = HLLPOutputData[!,c]
                h2_load_in[!,c] .= new_col
            end
            
            h2_load_in = h2_load_in[1:size(HLLPOutputData,1),:]

            @debug " -- Writing liquid load file..."
            CSV.write(string(inpath,sep,H2Load_Liq_Outfile), h2_load_in)
        end


        #Write HSC Resource Variability 
        # Reset column ordering, add time index, and solve duplicate column name trouble with CSV.write's header kwarg
        HRVColMap = Dict(myinputs["H2_RESOURCE_ZONES"][i] => myinputs["H2_RESOURCES_NAME"][i] for i in eachindex(myinputs["H2_RESOURCES_NAME"]))
        HRVColMap["Time_Index"] = "Time_Index"
        HRVOutputData = HRVOutputData[!, Symbol.(myinputs["H2_RESOURCE_ZONES"])]
        insertcols!(HRVOutputData, 1, :Time_Index => 1:size(HRVOutputData,1))
        NewHRVColNames = [HRVColMap[string(c)] for c in names(HRVOutputData)]
        @debug " -- Writing resource file..."
        CSV.write(string(inpath,sep,H2RVar_Outfile), HRVOutputData, header=NewHRVColNames)

        if mysetup["ModelH2G2P"] == 1
            #Write HSC Resource Variability 
            # Reset column ordering, add time index, and solve duplicate column name trouble with CSV.write's header kwarg
            # Dharik - string conversion needed to change from inlinestring to string type
            HG2PVColMap = Dict(myinputs["H2_G2P_RESOURCE_ZONES"][i] => String(myinputs["H2_G2P_NAME"][i]) for i in eachindex(myinputs["H2_G2P_NAME"]))
            HG2PVColMap["Time_Index"] = "Time_Index"
            HG2POutputData = HG2POutputData[!, Symbol.(myinputs["H2_G2P_RESOURCE_ZONES"])]
            insertcols!(HG2POutputData, 1, :Time_Index => 1:size(HG2POutputData,1))
            NewHG2PVColNames = [HG2PVColMap[string(c)] for c in names(HG2POutputData)]
            @debug " -- Writing resource file..."
            CSV.write(string(inpath,sep,H2G2PVar_Outfile), HG2POutputData, header=NewHG2PVColNames)
        end
    end

    ### time_domain_reduction_settings.yml
    @debug " -- Writing .yml settings..."
    YAML.write_file(string(inpath,sep,YAML_Outfile), myTDRsetup)

    return FinalOutputData, W, RMSE, myTDRsetup, col_to_zone_map
end
