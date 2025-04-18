using YAML
using DataFrames
using StatsBase
using Clustering
using Distances
using CSV

using Random
using LinearAlgebra
using Flux
using Flux: glorot_uniform, leakyrelu, Dense, Conv, flatten, params, update!, gradient
import Zygote
import Flux.Optimise: update!
Zygote.@nograd fill!
Zygote.@nograd Flux.create_bias

using Distances: Euclidean, pairwise


@doc raw"""
    run_time_domain_reduction(inpath, settings_path, mysetup, v=false)

    Use various clustering algorithms: kmeans, kmedoids, autoencoder (sequential or simultaneous) to cluster raw load profiles and resource capacity factor profiles
    into representative periods. Use Extreme Periods to capture noteworthy periods or
    periods with notably poor fits.

"""

function run_time_domain_reduction(inpath, settings_path, mysetup, v=false)

    ##### Step 1: Load YAML settings and inputs
    myTDRsetup, mysetup, myinputs = load_settings_and_inputs(inpath, settings_path, mysetup, v)   

    ##### Step 2: Parse data from inputs
    parsed_data = parse_data(myinputs, mysetup)

    ##### Step 3: Prepare inputs for clustering: Normalize profiles, identify extreme periods, reshape for clustering
    InputData, Ncols, ConstData, ConstCols, col_to_zone_map, ExtremeWksList, 
    ModifiedData, ClusteringInputDF, NClusters, NumDataPoints, 
    ColumnNames, Flags = prepare_clustering_inputs(parsed_data, myinputs, myTDRsetup, v)
    
    ##### Step 4: Clustering and iterative add periods of input dataframe to obtain A: Assignments, W: Weights, M: Medoids
    A, W, M = run_clustering(myTDRsetup, ClusteringInputDF, NClusters, ColumnNames, ExtremeWksList, v)

    ##### Step 5: Post-processing of cluster results
    FinalOutputData, OutputData, PeriodMap, W, M, A, RMSE = aggregate_cluster_results(A, W, M,
                                                            ClusteringInputDF, ModifiedData, InputData,
                                                            ConstCols, ConstData, ColumnNames, Flags,
                                                            NClusters, ExtremeWksList, Ncols, NumDataPoints, 
                                                            mysetup, myTDRsetup, v)
    
    ##### Step 6: Write cluster results
    write_cluster_outputs(W, OutputData, PeriodMap, ColumnNames, inpath, myinputs, mysetup, myTDRsetup, v)

    return FinalOutputData, W, RMSE, myTDRsetup, col_to_zone_map
end
