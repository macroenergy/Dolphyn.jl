#include("helper_files.jl")
function step2_identify_extreme_periods_and_reshape_data(AnnualTSeriesNormalized, MinPeriods, InputData, Nhours, TimestepsPerRepPeriod, OldColNames, ExtPeriodSelections, UseExtremePeriods, ConstCols, load_col_names, solar_col_names, wind_col_names, v)

    # Total number of subperiods available in the dataset, where each subperiod length = TimestepsPerRepPeriod
    NumDataPoints = Nhours÷TimestepsPerRepPeriod # 364 weeks in 7 years
    if v println("Total Subperiods in the data set: ", NumDataPoints) end
    InputData[:, :Group] .= (1:Nhours) .÷ (TimestepsPerRepPeriod+0.0001) .+ 1    # Group col identifies the subperiod ID of each hour (e.g., all hours in week 2 have Group=2 if using TimestepsPerRepPeriod=168)

    # Group by period (e.g., week)
    cgdf = combine(groupby(InputData, :Group), [c .=> sum for c in OldColNames])
    cgdf = cgdf[setdiff(1:end, NumDataPoints+1), :]
    rename!(cgdf, [:Group; Symbol.(OldColNames)])

    println("Num Data Points: ")

    # Extreme period identification based on user selection in time_domain_reduction_settings.yml
    LoadExtremePeriod = false        # Used when deciding whether or not to scale load curves to equal original total load
    ExtremeWksList = []

    # The script below is reading the part from time_domain_reduction_settings.yml file which if UseExtremePeriods is set to 1 reads the fields under ExtremePeriods

    if UseExtremePeriods == 1
        for profKey in keys(ExtPeriodSelections) # profKey specifies one of the following: Load, PV, Wind
            for geoKey in keys(ExtPeriodSelections[profKey]) # geoKey specifies one of the following: System, Zone
                for typeKey in keys(ExtPeriodSelections[profKey][geoKey]) # Identifies whether it is related to Absolute or Integral value specified at either zone or system level
                    for statKey in keys(ExtPeriodSelections[profKey][geoKey][typeKey]) # statKey specifies one of the following: Min, and Max
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
                                        if v println("Zone ", z, " has no time series profiles of type ", profKey) end
                                    end
                                end
                            else
                                println("Error: Geography Key ", geoKey, " is invalid. Select `System' or `Zone'.")
                            end
                        end
                    end
                end
            end
        end


    if v println(ExtremeWksList) end
      sort!(unique!(ExtremeWksList))
      if v println("Reduced to ", ExtremeWksList) end
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
        if v println("Pre-removal: ", names(ModifiedDataNormalized)) end
        if v println("Extreme Periods: ", string.(ExtremeWksList)) end
        ClusteringInputDF = select(ModifiedDataNormalized, Not(string.(ExtremeWksList)))
        if v println("Post-removal: ", names(ClusteringInputDF)) end
        NClusters -= length(ExtremeWksList)
    else
        ClusteringInputDF = ModifiedDataNormalized
    end

    return ClusteringInputDF, NClusters, ExtremeWksList, ModifiedData, LoadExtremePeriod, NumDataPoints
end
