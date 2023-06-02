#include("helper_files.jl")
function step0_load_settings_and_data(inpath, settings_path, mysetup, v = false)
    # Function body
    # Code to be executed
    # Return statement (optional)
    ##### Step 0: Load in settings and data
    #using YAML
    #println("I am inside")

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

    #println("I Loaded the data")

    # Set output filenames for later
    Load_Outfile = joinpath(TimeDomainReductionFolder, "Load_data.csv")
    GVar_Outfile = joinpath(TimeDomainReductionFolder, "Generators_variability.csv")
    Fuel_Outfile = joinpath(TimeDomainReductionFolder, "Fuels_data.csv")
    PMap_Outfile = joinpath(TimeDomainReductionFolder, "Period_map.csv")
    H2Load_Outfile = joinpath(TimeDomainReductionFolder, "HSC_load_data.csv")
    H2RVar_Outfile = joinpath(TimeDomainReductionFolder, "HSC_generators_variability.csv")
    H2G2PVar_Outfile = joinpath(TimeDomainReductionFolder, "HSC_g2p_variability.csv")
    YAML_Outfile = joinpath(TimeDomainReductionFolder, "time_domain_reduction_settings.yml")

    #println("The time domain reduction folder is: ")

    #println(TimeDomainReductionFolder)

    # Define a local version of the setup so that you can modify the mysetup["ParameterScale"] value to be zero in case it is 1
    mysetup_local = copy(mysetup)
    # If ParameterScale =1 then make it zero, since clustered inputs will be scaled prior to generating model
    mysetup_local["ParameterScale"]=0  # Performing cluster and report outputs in user-provided units
    if v println("Loading inputs") end

    myinputs=Dict()
    myinputs = load_inputs(mysetup_local,inpath)

    if mysetup["ModelH2"] == 1
        myinputs = load_h2_inputs(myinputs, mysetup_local, inpath)
    end

    println(myinputs["RESOURCE_ZONES"])

    if v println() end

    #Copy Original Parameter Scale Variable
    parameter_scale_org = mysetup["ParameterScale"]
    #Copy setup from set-up local. Set-up local contains some H2 setup inputs, except for correct parameter scale
    mysetup = copy(mysetup_local)
    #Overwrites paramater scale
    mysetup["ParameterScale"] = parameter_scale_org

    load_col_names, h2_load_col_names, var_col_names, solar_col_names, wind_col_names, h2_var_col_names, h2_g2p_var_col_names, fuel_col_names,
    all_col_names, load_profiles, var_profiles, solar_profiles, wind_profiles, h2_var_profiles, h2_g2p_var_profiles,
    fuel_profiles, all_profiles, col_to_zone_map, h2_col_to_zone_map, AllFuelsConst, AllHRVarConst, AllHG2PVarConst = parse_data(myinputs, mysetup)

    # Remove Constant Columns - Add back later in final output
    all_profiles, all_col_names, ConstData, ConstCols, ConstIdx = RemoveConstCols(all_profiles, all_col_names, v)

    # Determine whether or not to time domain reduce fuel profiles as well based on user choice and file structure (i.e., variable fuels in Fuels_data.csv)
    IncludeFuel = true
    if (ClusterFuelPrices != 1) || (AllFuelsConst) IncludeFuel = false end

    # Put it together!
    InputData = DataFrame( Dict( all_col_names[c]=>all_profiles[c] for c in 1:length(all_col_names) ) )
    if v
        println("Load (MW) and Capacity Factor Profiles: ")
        println(describe(InputData))
        println()
    end
    OldColNames = names(InputData)
    NewColNames = [Symbol.(OldColNames); :GrpWeight]
    Nhours = nrow(InputData) # Timesteps
    Ncols = length(NewColNames) - 1

    println("Ncols: ")
    print(Ncols)


    return InputData, OldColNames, NewColNames, Nhours, Ncols, TimestepsPerRepPeriod, ClusterMethod, ScalingMethod, MinPeriods, MaxPeriods, UseExtremePeriods, ExtPeriodSelections, Iterate, IterateMethod, Threshold, nReps, LoadWeight, WeightTotal, ClusterFuelPrices, TimeDomainReductionFolder, ConstCols, load_col_names, solar_col_names, wind_col_names, IncludeFuel, ConstData, h2_g2p_var_col_names, h2_var_col_names, h2_load_col_names, var_col_names, fuel_col_names, AllHRVarConst, AllHG2PVarConst, Load_Outfile, GVar_Outfile, Fuel_Outfile, PMap_Outfile, YAML_Outfile,  myTDRsetup, myinputs, H2Load_Outfile, H2RVar_Outfile, H2G2PVar_Outfile, col_to_zone_map

end
