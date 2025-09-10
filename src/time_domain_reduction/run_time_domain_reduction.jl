@doc raw"""
    run_time_domain_reduction(inpath, settings_path, mysetup, v=false)

    Use various clustering algorithms: kmeans, kmedoids, autoencoder (sequential or simultaneous) to cluster raw load profiles and resource capacity factor profiles
    into representative periods. Use Extreme Periods to capture noteworthy periods or
    periods with notably poor fits.

"""

function run_time_domain_reduction(inpath, settings_path, mysetup, v=false)

    ##### Step 1: Load YAML settings and inputs
    mysetup, myinputs = load_settings_and_inputs(inpath, settings_path, mysetup, v)   

    ##### Step 2: Parse data from inputs
    parsed_data = parse_data(myinputs, mysetup)

    ##### Step 3: Prepare inputs for clustering: Normalize profiles, identify extreme periods, reshape for clustering
    InputData, Ncols, ConstData, ConstCols, col_to_zone_map, ExtremeWksList, 
    ModifiedData, ClusteringInputDF, NClusters, NumDataPoints, 
    ColumnNames, Flags = prepare_clustering_inputs(parsed_data, myinputs, mysetup, v)
    
    ##### Step 4: Clustering and iterative add periods of input dataframe to obtain A: Assignments, W: Weights, M: Medoids
    A, W, M, autoencoder_training_time, clustering_time = run_clustering(inpath, mysetup, ClusteringInputDF, NClusters, ColumnNames, ExtremeWksList, v)

    
    ##### Step 5: Post-processing of cluster results
    FinalOutputData, OutputData, PeriodMap, W, M, A, RMSE = aggregate_cluster_results(A, W, M,
                                                            ClusteringInputDF, ModifiedData, InputData,
                                                            ConstCols, ConstData, ColumnNames, Flags,
                                                            NClusters, ExtremeWksList, Ncols, NumDataPoints, 
                                                            mysetup, v)
    
    ##### Step 6: Write cluster results
    write_cluster_outputs(W, OutputData, PeriodMap, ColumnNames, inpath, myinputs, mysetup, v)

    return FinalOutputData, W, RMSE, col_to_zone_map, autoencoder_training_time, clustering_time
end
