@doc raw"""
    prepare_clustering_inputs(parsed_data::Dict, myinputs::Dict, myTDRsetup::Dict, v::Bool=false)
"""

function prepare_clustering_inputs(parsed_data::Dict, myinputs::Dict, myTDRsetup::Dict, v::Bool=false)

    # Accept model parameters from the settings file time_domain_reduction_settings.yml
    TimestepsPerRepPeriod = myTDRsetup["TimestepsPerRepPeriod"]
    ScalingMethod = myTDRsetup["ScalingMethod"]
    MinPeriods = myTDRsetup["MinPeriods"]
    UseExtremePeriods = myTDRsetup["UseExtremePeriods"]
    ExtPeriodSelections = myTDRsetup["ExtremePeriods"]
    LoadWeight = myTDRsetup["LoadWeight"]
    ClusterFuelPrices = myTDRsetup["ClusterFuelPrices"]
    
    ####################################################################################

    load_col_names         = parsed_data["load_col_names"]
    h2_load_col_names      = parsed_data["h2_load_col_names"]
    h2_load_liq_col_names  = parsed_data["h2_load_liq_col_names"]
    var_col_names          = parsed_data["var_col_names"]
    solar_col_names        = parsed_data["solar_col_names"]
    wind_col_names         = parsed_data["wind_col_names"]
    h2_var_col_names       = parsed_data["h2_var_col_names"]
    h2_g2p_var_col_names   = parsed_data["h2_g2p_var_col_names"]
    fuel_col_names         = parsed_data["fuel_col_names"]
    all_col_names          = parsed_data["all_col_names"]
    all_profiles           = parsed_data["all_profiles"]
    col_to_zone_map        = parsed_data["col_to_zone_map"]
    AllFuelsConst          = parsed_data["AllFuelsConst"]
    AllHRVarConst          = parsed_data["AllHRVarConst"]
    AllHG2PVarConst        = parsed_data["AllHG2PVarConst"]

    ####################################################################################

    # Remove Constant Columns - Add back later in final output
    all_profiles, all_col_names, ConstData, ConstCols, ConstIdx = RemoveConstCols(all_profiles, all_col_names, v)

    # Determine whether or not to time domain reduce fuel profiles as well based on user choice and file structure (i.e., variable fuels in Fuels_data.csv)
    IncludeFuel = true
    if (ClusterFuelPrices != 1) || (AllFuelsConst) IncludeFuel = false end

    # Put it together!
    InputData = DataFrame( Dict( all_col_names[c]=>all_profiles[c] for c in 1:length(all_col_names) ) )
    if v
        println(" -- Load (MW) and Capacity Factor Profiles: ")
        println(describe(InputData))
        println()
    end

    desc_df = describe(InputData)
    println(" -- Full Describe Output -- ")
    show(desc_df; allcols=true, allrows=true, truncate=0)

    OldColNames = names(InputData)
    NewColNames = [Symbol.(OldColNames); :GrpWeight]
    Nhours = nrow(InputData) # Timesteps
    Ncols = length(NewColNames) - 1


    ##### Normalize or standardize all load, renewables, and fuel data / optionally scale with LoadWeight

    # Normalize/standardize data based on user-provided method
    if ScalingMethod == "N"
        normProfiles = [ StatsBase.transform(fit(UnitRangeTransform, InputData[:,c]; dims=1, unit=true), InputData[:,c]) for c in 1:length(OldColNames)  ]
    elseif ScalingMethod == "S"
        normProfiles = [ StatsBase.transform(fit(ZScoreTransform, InputData[:,c]; dims=1, center=true, scale=true), InputData[:,c]) for c in 1:length(OldColNames)  ]
    else
        println(" -- ERROR InvalidScalingMethod: Use N for Normalization or S for Standardization.")
        println(" -- CONTINUING using 0->1 normalization...")
        normProfiles = [ StatsBase.transform(fit(UnitRangeTransform, InputData[:,c]; dims=1, unit=true), InputData[:,c]) for c in 1:length(OldColNames)  ]
    end

    # Compile newly normalized/standardized profiles
    AnnualTSeriesNormalized = DataFrame(Dict(  OldColNames[c] => normProfiles[c] for c in 1:length(OldColNames) ))

    # Optional pre-scaling of load in order to give it more preference in clutering algorithm
    if LoadWeight != 1   # If we want to value load more/less than capacity factors. Assume nonnegative. LW=1 means no scaling.
        for c in load_col_names
            AnnualTSeriesNormalized[!, Symbol(c)] .= AnnualTSeriesNormalized[!, Symbol(c)] .* LoadWeight
        end
    end

    if v
        println(" -- Load (MW) and Capacity Factor Profiles NORMALIZED! ")
        println(describe(AnnualTSeriesNormalized))
        println()
    end

    # Total number of subperiods available in the dataset, where each subperiod length = TimestepsPerRepPeriod
    NumDataPoints = Nhours÷TimestepsPerRepPeriod # 364 weeks in 7 years
    if v println(" -- Total Subperiods in the data set: ", NumDataPoints) end
    InputData[:, :Group] .= (1:Nhours) .÷ (TimestepsPerRepPeriod+0.0001) .+ 1    # Group col identifies the subperiod ID of each hour (e.g., all hours in week 2 have Group=2 if using TimestepsPerRepPeriod=168)

    # Group by period (e.g., week)
    cgdf = combine(groupby(InputData, :Group), [c .=> sum for c in OldColNames])
    cgdf = cgdf[setdiff(1:end, NumDataPoints+1), :]
    rename!(cgdf, [:Group; Symbol.(OldColNames)])

    # Extreme period identification based on user selection in time_domain_reduction_settings.yml
    LoadExtremePeriod = false        # Used when deciding whether or not to scale load curves to equal original total load
    ExtremeWksList = Int[]
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
                              if v print(geoKey, " ") end
                              (stat, group_idx) = get_extreme_period(InputData, cgdf, profKey, typeKey, statKey, ConstCols, load_col_names, solar_col_names, wind_col_names, v)
                              push!(ExtremeWksList, floor(Int, group_idx))
                              if v println(group_idx, " : ", stat) end
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
                                      if v print(geoKey, " ") end
                                      (stat, group_idx) = get_extreme_period(select(InputData, [:Group; Symbol.(z_cols_type)]), select(cgdf, [:Group; Symbol.(z_cols_type)]), profKey, typeKey, statKey, ConstCols, z_cols_type, z_cols_type, z_cols_type, v)
                                      push!(ExtremeWksList, floor(Int, group_idx))
                                      if v println(group_idx, " : ", stat, "(", z, ")") end
                                  else
                                      if v println(" -- Zone ", z, " has no time series profiles of type ", profKey) end
                                  end
                              end
                          else
                              println(" -- Error: Geography Key ", geoKey, " is invalid. Select `System' or `Zone'.")
                          end
                      end
                  end
              end
          end
      end
      if v println(ExtremeWksList) end
      sort!(unique!(ExtremeWksList))
      if v println(" -- Reduced to ", ExtremeWksList) end
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
        if v println(" -- Pre-removal: ", names(ModifiedDataNormalized)) end
        if v println(" -- Extreme Periods: ", string.(ExtremeWksList)) end
        ClusteringInputDF = select(ModifiedDataNormalized, Not(string.(ExtremeWksList)))
        if v println(" -- Post-removal: ", names(ClusteringInputDF)) end
        NClusters -= length(ExtremeWksList)
    else
        ClusteringInputDF = ModifiedDataNormalized
    end

    ConstCols = string.(ConstCols)

    ColumnNames = Dict(
        "OldColNames" => OldColNames,
        "NewColNames" => NewColNames,
        "load_col_names" => load_col_names,
        "h2_load_col_names" => h2_load_col_names,
        "h2_load_liq_col_names" => h2_load_liq_col_names,
        "var_col_names" => var_col_names,
        "h2_var_col_names" => h2_var_col_names,
        "h2_g2p_var_col_names" => h2_g2p_var_col_names,
        "fuel_col_names" => fuel_col_names
    )

    Flags = Dict(
        "AllHRVarConst" => AllHRVarConst,
        "AllHG2PVarConst" => AllHG2PVarConst,
        "LoadExtremePeriod" => LoadExtremePeriod,
        "IncludeFuel" => IncludeFuel
    )

    return InputData, Ncols, ConstData, 
    ConstCols, col_to_zone_map, ExtremeWksList, ModifiedData, ClusteringInputDF, NClusters, NumDataPoints, ColumnNames, Flags
end