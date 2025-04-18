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
    cluster_inputs(inpath, settings_path, v=false, norm_plot=false, silh_plot=false, res_plots=false, indiv_plots=false, pair_plots=false)

Use kmeans or kmedoids to cluster raw load profiles and resource capacity factor profiles
into representative periods. Use Extreme Periods to capture noteworthy periods or
periods with notably poor fits.

"""

function cluster_inputs(inpath, settings_path, mysetup, v=false)

    ##### Step 1: Load YAML settings and inputs
    myTDRsetup, mysetup, myinputs = load_settings_and_inputs(inpath, settings_path, mysetup, v)   

    ##### Step 2: Parse data from inputs
    parsed_data = parse_data(myinputs, mysetup)

    ##### Step 3: Prepare inputs for clustering: Normalize profiles, identify extreme periods, reshape for clustering
    InputData, Ncols, ConstData, 
    ConstCols, col_to_zone_map, ExtremeWksList, 
    ModifiedData, ClusteringInputDF, NClusters, NumDataPoints, 
    ColumnNames, Flags = prepare_clustering_inputs(parsed_data, myinputs, mysetup, myTDRsetup, v)
    
    ##### Step 4: Clustering and iterative add periods of input dataframe to obtain A: Assignments, W: Weights, M: Medoids
    A, W, M = run_clustering(myTDRsetup, ClusteringInputDF, NClusters, ColumnNames, ExtremeWksList, v)

    ##### Step 5: Post-processing of cluster results
    FinalOutputData, GVOutputData, LPOutputData, FPOutputData, PeriodMap, 
    W, M, A, HLPOutputData, HRVOutputData, rpDFs, HLLPOutputData, 
    HG2POutputData = aggregate_cluster_results(
                        myTDRsetup,
                        A, W, M,
                        ClusteringInputDF,
                        ModifiedData,
                        InputData,
                        ConstCols,
                        ConstData,
                        ColumnNames,
                        Flags,
                        NClusters,
                        ExtremeWksList,
                        Ncols,
                        mysetup,
                        v
                    )
    
    ##### Step 6: Write cluster results
    write_cluster_outputs(
        inpath,
        mysetup,
        myinputs,
        myTDRsetup,
        W,
        LPOutputData,
        GVOutputData,
        FPOutputData,
        PeriodMap,
        HLPOutputData,
        HLLPOutputData,
        HRVOutputData,
        HG2POutputData,
        ColumnNames,
        v
    )

    OldColNames = ColumnNames["OldColNames"]
    
    ##### Step 7: Evaluation of results
    InputDataTest = InputData[(InputData.Group .<= NumDataPoints*1.0), :]
    ClusterDataTest = vcat([rpDFs[a] for a in A]...) # To compare fairly, load is not scaled here
    RMSE = Dict( c => rmse_score(InputDataTest[:, c], ClusterDataTest[:, c])  for c in OldColNames)


    return FinalOutputData, W, RMSE, myTDRsetup, col_to_zone_map
end
