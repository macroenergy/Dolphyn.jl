@doc raw"""
run_clustering(myTDRsetup::Dict, ClusteringInputDF::DataFrame, NClusters::Int, ColumnNames::Dict, ExtremeWksList::Vector{Int}, v::Bool=false)
"""

function run_clustering(myTDRsetup::Dict, ClusteringInputDF::DataFrame, NClusters::Int, ColumnNames::Dict, ExtremeWksList::Vector{Int}, v::Bool=false)

    # Accept model parameters from the settings file time_domain_reduction_settings.yml
    TimestepsPerRepPeriod = myTDRsetup["TimestepsPerRepPeriod"]
    ClusterMethod = myTDRsetup["ClusterMethod"]
    ScalingMethod = myTDRsetup["ScalingMethod"]
    MaxPeriods = myTDRsetup["MaxPeriods"]
    UseExtremePeriods = myTDRsetup["UseExtremePeriods"]
    Iterate = myTDRsetup["IterativelyAddPeriods"]
    IterateMethod = myTDRsetup["IterateMethod"]
    Threshold = myTDRsetup["Threshold"]
    nReps = myTDRsetup["nReps"]

    # Accept OldColNames from ColumnNames dictionary
    OldColNames = ColumnNames["OldColNames"]

    ####################################################################################

    cluster_results = []

    # Cluster once regardless of iteration decisions
    
    push!(cluster_results, cluster(myTDRsetup, ClusterMethod, ClusteringInputDF, NClusters, nReps, v))

    # Iteratively add worst periods as extreme periods OR increment number of clusters k
    #    until threshold is met or maximum periods are added (If chosen in inputs)
    if (Iterate == 1)
        while (!check_condition(Threshold, last(cluster_results)[1], OldColNames, ScalingMethod, TimestepsPerRepPeriod)) & ((length(ExtremeWksList)+NClusters) < MaxPeriods)
            if IterateMethod == "cluster"
                if v println(" -- Adding a new Cluster! ") end
                NClusters += 1
                push!(cluster_results, cluster(ClusterMethod, ClusteringInputDF, NClusters, nReps, v))
            elseif (IterateMethod == "extreme") & (UseExtremePeriods == 1)
                if v println(" -- Adding a new Extreme Period! ") end
                worst_period_idx = get_worst_period_idx(last(cluster_results)[1])
                removed_period = string(names(ClusteringInputDF)[worst_period_idx])
                select!(ClusteringInputDF, Not(worst_period_idx))
                push!(ExtremeWksList, parse(Int, removed_period))
                if v println(worst_period_idx, " (", removed_period, ") ", ExtremeWksList) end
                push!(cluster_results, cluster(ClusterMethod, ClusteringInputDF, NClusters, nReps, v))
            elseif IterateMethod == "extreme"
                println(" -- INVALID IterateMethod ", IterateMethod, " because UseExtremePeriods is off. Set to 1 if you wish to add extreme periods.")
                break
            else
                println(" -- INVALID IterateMethod ", IterateMethod, ". Choose 'cluster' or 'extreme'.")
                break
            end
        end
        if v && (length(ExtremeWksList)+NClusters == MaxPeriods)
            println(" -- Stopped iterating by hitting the maximum number of periods.")
        elseif v
            println(" -- Stopped by meeting the accuracy threshold.")
        end
    end

    # Interpret Final Clustering Result
    R = last(cluster_results)[1]  # Cluster Object
    A = last(cluster_results)[2]  # Assignments
    W = last(cluster_results)[3]  # Weights
    M = last(cluster_results)[4]  # Centers or Medoids
    DistMatrix = last(cluster_results)[5]  # Pairwise distances
    if v # Diagnostic checks
        println("Total Groups Assigned to Each Cluster: ", W)
        println("Sum Cluster Weights: ", sum(W))
        println("Representative Periods: ", M)
    end

    A = Int.(A)
    M = Int.(M)

    return A, W, M
end