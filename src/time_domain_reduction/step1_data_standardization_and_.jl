function step1_data_standardization_and_scaling(InputData, ScalingMethod, OldColNames, LoadWeight)

    # Normalize/standardize data based on user-provided method
    if ScalingMethod == "N"
        normProfiles = [ StatsBase.transform(fit(UnitRangeTransform, InputData[:,c]; dims=1, unit=true), InputData[:,c]) for c in 1:length(OldColNames)  ]
    elseif ScalingMethod == "S"
        normProfiles = [ StatsBase.transform(fit(ZScoreTransform, InputData[:,c]; dims=1, center=true, scale=true), InputData[:,c]) for c in 1:length(OldColNames)  ]
    else
        println("ERROR InvalidScalingMethod: Use N for Normalization or S for Standardization.")
        println("CONTINUING using 0->1 normalization...")
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
        println("Load (MW) and Capacity Factor Profiles NORMALIZED! ")
        println(describe(AnnualTSeriesNormalized))
        println()
    end

    return AnnualTSeriesNormalized

end
