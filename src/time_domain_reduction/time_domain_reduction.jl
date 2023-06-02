include("helper_files.jl")
include("step0_load_settings_and_data.jl")
include("step1_data_standardization_and_scaling.jl")
include("step2_identify_extreme_periods_and_reshape_data.jl")
include("step3_execute_clustering.jl")
include("step4_data_aggregation.jl")
include("step5_RMSE_based_Evaluation.jl")
include("step6_print_to_File.jl")

# Store the paths of the current working directory, GenX, and Settings YAML file

if isfile("PreCluster.jl")
    genx_path = cd(pwd, "../..") # pwd() grandparent <--- TDR called from PreCluster.jl
else
    genx_path = pwd()    # <--- TDR called from Run_test.jl
end

settings_path = joinpath(genx_path, "GenX_settings.yml")

# Load GenX modules

push!(LOAD_PATH, genx_path)
push!(LOAD_PATH, pwd())

using YAML
using DataFrames
using StatsBase
using Clustering
using Distances
using CSV

function cluster_inputs(inpath, settings_path, mysetup, v = false)
    # Executing Step 0
    InputData, OldColNames, NewColNames, Nhours, Ncols, TimestepsPerRepPeriod, ClusterMethod, ScalingMethod, MinPeriods, MaxPeriods, UseExtremePeriods, ExtPeriodSelections, Iterate, IterateMethod, Threshold, nReps, LoadWeight, WeightTotal, ClusterFuelPrices, TimeDomainReductionFolder, ConstCols, load_col_names, solar_col_names, wind_col_names, IncludeFuel, ConstData, h2_g2p_var_col_names, h2_var_col_names, h2_load_col_names, var_col_names, fuel_col_names, AllHRVarConst, AllHG2PVarConst, Load_Outfile, GVar_Outfile, Fuel_Outfile, PMap_Outfile, YAML_Outfile, myTDRsetup, myinputs, H2Load_Outfile, H2RVar_Outfile, H2G2PVar_Outfile, col_to_zone_map = step0_load_settings_and_data(inpath, settings_path, mysetup, v)

    # Executing Step 1
    AnnualTSeriesNormalized = step1_data_standardization_and_scaling(InputData, ScalingMethod, OldColNames, LoadWeight)

    # Executing Step 2
    ClusteringInputDF, NClusters, ExtremeWksList, ModifiedData, LoadExtremePeriod, NumDataPoints = step2_identify_extreme_periods_and_reshape_data(AnnualTSeriesNormalized, MinPeriods, InputData, Nhours, TimestepsPerRepPeriod, OldColNames, ExtPeriodSelections, UseExtremePeriods, ConstCols, load_col_names, solar_col_names, wind_col_names, v)

    # Executing Step 3
    R, A, W, M, DistMatrix = step3_execute_clustering(ClusterMethod, nReps, OldColNames, ScalingMethod, TimestepsPerRepPeriod, MaxPeriods, Threshold, ClusteringInputDF, NClusters, ExtremeWksList, Iterate, IterateMethod, v)

    ## This line should be removed later on when figured output

    mysetup["ModelH2G2P"] = 1

    # Executing Step 4
    FinalOutputData, GVOutputData, LPOutputData, FPOutputData, HLPOutputData, HRVOutputData, HG2POutputData, rpDFs, LoadCols, PeriodMap, FuelCols, H2LoadCols = step4_data_aggregation(WeightTotal, load_col_names, var_col_names, fuel_col_names, ConstCols, h2_load_col_names, h2_var_col_names, h2_g2p_var_col_names, InputData, TimestepsPerRepPeriod, NewColNames, Ncols, ConstData, IncludeFuel, AllHRVarConst, AllHG2PVarConst, ExtremeWksList, NClusters, ModifiedData, LoadExtremePeriod, M, W, A, UseExtremePeriods, mysetup, v)

    # Executing Step 5
    RMSE = step5_RMSE_based_Evaluation(InputData, NumDataPoints, A, rpDFs, OldColNames)

    # Executing Step 6
    final_step = step6_print_to_File(inpath, TimeDomainReductionFolder, W, TimestepsPerRepPeriod, LoadCols, LPOutputData, Load_Outfile, GVOutputData, GVar_Outfile, FPOutputData, Fuel_Outfile, PeriodMap, PMap_Outfile, myTDRsetup, YAML_Outfile, myinputs, FuelCols, H2LoadCols, HLPOutputData, H2Load_Outfile, HRVOutputData, H2RVar_Outfile, HG2POutputData, H2G2PVar_Outfile, mysetup, v)

    return FinalOutputData, W, RMSE, myTDRsetup, col_to_zone_map

end
